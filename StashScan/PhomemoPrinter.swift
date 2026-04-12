//
//  PhomemoPrinter.swift
//  StashScan
//
//  CoreBluetooth driver for the Phomemo Q02E thermal label printer.
//  Uses the reverse-engineered GATT profile (Service FF00, Write FF02, Notify FF03).
//  Implements flow-controlled BLE writes via peripheralIsReady(toSendWriteWithoutResponse:).
//

import Foundation
import CoreBluetooth

// MARK: - PrinterState

enum PrinterState: Equatable {
    case bluetoothUnavailable
    case disconnected
    case scanning
    case connecting
    case ready
    case printing
    case error(String)

    var statusLabel: String {
        switch self {
        case .bluetoothUnavailable: return "Bluetooth unavailable"
        case .disconnected:         return "Not connected"
        case .scanning:             return "Scanning for Phomemo Q02E…"
        case .connecting:           return "Connecting…"
        case .ready:                return "Phomemo Q02E – Ready"
        case .printing:             return "Printing…"
        case .error(let msg):       return msg
        }
    }

    var isWorking: Bool {
        switch self { case .scanning, .connecting, .printing: return true; default: return false }
    }
}

// MARK: - PhomemoPrinter

@Observable
final class PhomemoPrinter: NSObject {

    // MARK: Public state
    private(set) var state: PrinterState = .disconnected

    // MARK: BLE identifiers
    private let serviceUUID    = CBUUID(string: "FF00")
    private let writeCharUUID  = CBUUID(string: "FF02")
    private let notifyCharUUID = CBUUID(string: "FF03")

    // MARK: CoreBluetooth objects
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeChar: CBCharacteristic?

    // MARK: Print-job state
    private var printQueue  = Data()
    private var printOffset = 0
    private var isSending   = false

    // MARK: Deferred-scan flag
    // Set when startScan() is called before CBCentralManager reaches .poweredOn.
    // Cleared and acted on inside centralManagerDidUpdateState(.poweredOn).
    private var pendingScan = false

    // MARK: Persistence
    private let savedUUIDKey = "phomemo_peripheral_uuid"

    override init() {
        super.init()
        // Delegate on main queue so @Observable property writes land on the main thread
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Public API

    /// Scans for a nearby Phomemo Q02E and connects.
    /// If CoreBluetooth isn't ready yet, the scan is queued and starts automatically
    /// once the manager reaches .poweredOn.
    func startScan() {
        if central.state == .poweredOn {
            doScan()
        } else {
            // BT not ready yet — show scanning state immediately so the UI updates,
            // and start the actual scan once the manager finishes initializing.
            pendingScan = true
            state = .scanning
        }
    }

    /// Disconnects from the current peripheral and clears saved UUID.
    func disconnectAndForget() {
        pendingScan = false
        if let p = peripheral { central.cancelPeripheralConnection(p) }
        peripheral = nil
        writeChar  = nil
        UserDefaults.standard.removeObject(forKey: savedUUIDKey)
        state = .disconnected
    }

    /// Sends pre-built ESC/POS data to the printer.
    func print(data: Data) {
        guard case .ready = state else { return }
        printQueue  = data
        printOffset = 0
        isSending   = true
        state       = .printing
        pumpData()
    }

    // MARK: - BLE write pump (flow-controlled)

    private func pumpData() {
        guard isSending,
              let p = peripheral,
              let char = writeChar else { return }

        guard printOffset < printQueue.count else {
            isSending = false
            state     = .ready
            return
        }

        let mtu       = p.maximumWriteValueLength(for: .withoutResponse)
        let remaining = printQueue.count - printOffset
        let chunkSize = min(mtu, remaining)
        let chunk     = printQueue.subdata(in: printOffset ..< printOffset + chunkSize)

        p.writeValue(chunk, for: char, type: .withoutResponse)
        printOffset += chunkSize

        if p.canSendWriteWithoutResponse { pumpData() }
    }

    // MARK: - Scan / reconnect internals

    /// Starts a scan with NO service-UUID filter.
    ///
    /// Why: Phomemo printers (and most thermal printers) do NOT include their GATT
    /// service UUID (FF00) in their BLE advertisement packet. Filtering by service UUID
    /// causes iOS to silently drop the printer from scan results before didDiscover fires.
    /// We scan for all peripherals and match by name or advertised service inside
    /// centralManager(_:didDiscover:...).
    private func doScan() {
        pendingScan = false
        state = .scanning
        central.scanForPeripherals(withServices: nil, options: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
            guard let self, case .scanning = state else { return }
            central.stopScan()
            state = .error("No printer found. Make sure the Q02E is on and nearby.")
        }
    }

    /// Tries to reconnect the last-used peripheral without scanning.
    /// Returns true if a reconnect attempt was initiated.
    @discardableResult
    private func tryReconnectSaved() -> Bool {
        // Prefer the exact peripheral by UUID (works even when the device isn't advertising)
        if let uuidStr = UserDefaults.standard.string(forKey: savedUUIDKey),
           let uuid    = UUID(uuidString: uuidStr) {
            let known = central.retrievePeripherals(withIdentifiers: [uuid])
            if let p = known.first { connect(to: p); return true }
        }
        // Fall back to any system-connected peripheral that exposes the print service
        let connected = central.retrieveConnectedPeripherals(withServices: [serviceUUID])
        if let p = connected.first { connect(to: p); return true }
        return false
    }

    private func connect(to p: CBPeripheral) {
        peripheral = p
        p.delegate = self
        state      = .connecting
        central.connect(p, options: nil)
    }
}

// MARK: - CBCentralManagerDelegate

extension PhomemoPrinter: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // If user tapped Connect before BT was ready, honour that request now.
            if pendingScan {
                // Try saved peripheral first; if none found, start the scan.
                let reconnected = tryReconnectSaved()
                if !reconnected { doScan() }
            } else {
                tryReconnectSaved()
            }

        case .poweredOff, .resetting:
            pendingScan = false
            state = .disconnected

        case .unauthorized, .unsupported:
            pendingScan = false
            state = .bluetoothUnavailable

        default:
            break
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        // Match Phomemo Q02E by peripheral name (most reliable) or by advertised service UUID.
        // The name the printer broadcasts varies by firmware: "Phomemo", "Q02E", or "Printer".
        let name = (peripheral.name ?? "").lowercased()
        let nameMatch = name.contains("phomemo") || name.contains("q02") || name.contains("printer")

        let advertisedServices = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        let serviceMatch = advertisedServices.contains(serviceUUID)

        guard nameMatch || serviceMatch else { return }   // ignore unrelated BLE devices

        central.stopScan()
        connect(to: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: savedUUIDKey)
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        writeChar       = nil
        self.peripheral = nil
        isSending       = false
        printQueue      = Data()
        state           = .disconnected
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        self.peripheral = nil
        state = .error(error?.localizedDescription ?? "Connection failed — try again")
    }
}

// MARK: - CBPeripheralDelegate

extension PhomemoPrinter: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            state = .error("Service discovery failed: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([writeCharUUID, notifyCharUUID], for: service)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error {
            state = .error("Characteristic discovery failed: \(error.localizedDescription)")
            return
        }
        guard let chars = service.characteristics else { return }
        for char in chars {
            switch char.uuid {
            case writeCharUUID:
                writeChar = char
            case notifyCharUUID:
                // Subscribing triggers the iOS pairing prompt on first connection
                peripheral.setNotifyValue(true, for: char)
            default:
                break
            }
        }
        if writeChar != nil { state = .ready }
    }

    /// Called when the peripheral's transmit buffer has room again after being full.
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        pumpData()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        // Printer status notifications — no action required
    }
}
