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
        case .disconnected:         return "Disconnected"
        case .scanning:             return "Scanning…"
        case .connecting:           return "Connecting…"
        case .ready:                return "Ready"
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
    private let serviceUUID   = CBUUID(string: "FF00")
    private let writeCharUUID = CBUUID(string: "FF02")
    private let notifyCharUUID = CBUUID(string: "FF03")

    // MARK: CoreBluetooth objects
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeChar: CBCharacteristic?

    // MARK: Print-job state
    private var printQueue  = Data()
    private var printOffset = 0
    private var isSending   = false

    // MARK: Persistence
    private let savedUUIDKey = "phomemo_peripheral_uuid"

    override init() {
        super.init()
        // Initialise on main queue so @Observable property updates land on the main actor
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Public API

    /// Scans for a nearby Phomemo Q02E and connects.
    func startScan() {
        guard central.state == .poweredOn else { return }
        state = .scanning
        central.scanForPeripherals(withServices: [serviceUUID], options: nil)
        // Auto-stop scan after 12 s
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
            guard let self, case .scanning = state else { return }
            central.stopScan()
            state = .disconnected
        }
    }

    /// Disconnects from the current peripheral and clears saved UUID.
    func disconnectAndForget() {
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
            // Job complete
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

        // If the peripheral can accept more right now, keep going; otherwise wait for callback
        if p.canSendWriteWithoutResponse {
            pumpData()
        }
    }

    // MARK: - Reconnect helpers

    private func tryReconnectSaved() {
        if let uuidStr = UserDefaults.standard.string(forKey: savedUUIDKey),
           let uuid    = UUID(uuidString: uuidStr) {
            let known = central.retrievePeripherals(withIdentifiers: [uuid])
            if let p = known.first {
                connect(to: p)
                return
            }
        }
        // Fall back to already-connected system peripheral with the service
        let connected = central.retrieveConnectedPeripherals(withServices: [serviceUUID])
        if let p = connected.first { connect(to: p) }
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
            tryReconnectSaved()
        case .poweredOff, .resetting:
            state = .disconnected
        case .unauthorized, .unsupported:
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
        state = .error(error?.localizedDescription ?? "Failed to connect")
    }
}

// MARK: - CBPeripheralDelegate

extension PhomemoPrinter: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([writeCharUUID, notifyCharUUID], for: service)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil, let chars = service.characteristics else { return }
        for char in chars {
            switch char.uuid {
            case writeCharUUID:
                writeChar = char
            case notifyCharUUID:
                // Subscribe to notifications — triggers the iOS ↔ printer pairing prompt if needed
                peripheral.setNotifyValue(true, for: char)
            default:
                break
            }
        }
        if writeChar != nil { state = .ready }
    }

    /// Called when the peripheral's transmit buffer has room again.
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        pumpData()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        // Printer status notifications — no specific handling required
    }
}
