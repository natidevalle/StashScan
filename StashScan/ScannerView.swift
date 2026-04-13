//
//  ScannerView.swift
//  StashScan
//
//  Full-screen QR code scanner using AVFoundation.
//  Resolves scanned UUID against SwiftData and calls onFound with the Container.
//

import SwiftUI
import AVFoundation
import SwiftData

// MARK: - ScannerView

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// Called when a container is successfully resolved from a scanned QR code.
    let onFound: (Container) -> Void
    /// When false the Cancel button is hidden (use when embedded in a tab rather than a sheet).
    var cancellable: Bool = true

    @State private var permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var errorMessage: String? = nil
    @State private var isScanPaused = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch permissionStatus {
            case .authorized:
                ScannerCameraView(isScanPaused: $isScanPaused, onCodeDetected: handleCode)
                    .ignoresSafeArea()
                viewfinderOverlay
                if let msg = errorMessage {
                    errorBanner(msg)
                }

            case .denied, .restricted:
                permissionDeniedView

            default:
                // .notDetermined — request on appear
                ProgressView("Requesting camera access…")
                    .foregroundStyle(.white)
            }
        }
        .overlay(alignment: .topLeading) { if cancellable { cancelButton } }
        .task {
            if permissionStatus == .notDetermined {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                permissionStatus = granted ? .authorized : .denied
            }
        }
    }

    // MARK: - Overlay views

    private var viewfinderOverlay: some View {
        VStack(spacing: 16) {
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white, lineWidth: 2.5)
                .frame(width: 240, height: 240)
                .shadow(color: .black.opacity(0.4), radius: 8)
            Text("Align QR code within the frame")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
    }

    private func errorBanner(_ message: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(message)
                    .font(.subheadline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 80)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "camera.slash.fill")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.5))
            Text("Camera Access Required")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("StashScan needs camera access to scan QR code labels.\nEnable it in Settings.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    private var cancelButton: some View {
        Button("Cancel") { dismiss() }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.black.opacity(0.55))
            .clipShape(Capsule())
            .padding(.top, 56)
            .padding(.leading, 16)
    }

    // MARK: - Scan handling

    private func handleCode(_ raw: String) {
        // Must be a valid UUID
        guard let uuid = UUID(uuidString: raw) else {
            triggerError("Not a StashScan QR code.")
            return
        }

        // Fetch all containers and match in memory.
        // A home inventory stays small, so this is fine and avoids #Predicate UUID edge cases.
        let descriptor = FetchDescriptor<Container>()
        guard let all = try? modelContext.fetch(descriptor) else {
            triggerError("Could not read database.")
            return
        }

        guard let container = all.first(where: { $0.id == uuid }) else {
            triggerError("Container not found — it may have been deleted.")
            return
        }

        onFound(container)
    }

    private func triggerError(_ message: String) {
        withAnimation { errorMessage = message }
        isScanPaused = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { errorMessage = nil }
            isScanPaused = false   // re-enables scanning via ScannerCameraView.updateUIViewController
        }
    }
}

// MARK: - ScannerCameraView (UIViewControllerRepresentable)

private struct ScannerCameraView: UIViewControllerRepresentable {
    @Binding var isScanPaused: Bool
    let onCodeDetected: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeDetected: onCodeDetected)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.metadataDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: ScannerViewController, context: Context) {
        // Keep callback current (captures may change across re-renders)
        context.coordinator.onCodeDetected = onCodeDetected
        // Reset the "already fired" guard so the scanner can fire again after an error
        if !isScanPaused {
            context.coordinator.didFire = false
        }
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onCodeDetected: (String) -> Void
        var didFire = false

        init(onCodeDetected: @escaping (String) -> Void) {
            self.onCodeDetected = onCodeDetected
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard
                !didFire,
                let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                obj.type == .qr,
                let value = obj.stringValue
            else { return }

            didFire = true
            // Callback already arrives on main queue (see ScannerViewController.setupSession)
            onCodeDetected(value)
        }
    }
}

// MARK: - ScannerViewController

final class ScannerViewController: UIViewController {
    var metadataDelegate: AVCaptureMetadataOutputObjectsDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !(captureSession?.isRunning ?? false) else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard captureSession?.isRunning == true else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    private func setupSession() {
        let session = AVCaptureSession()

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        // Deliver callbacks on main queue so UI updates are safe without extra dispatch
        output.setMetadataObjectsDelegate(metadataDelegate, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
        captureSession = session
    }
}
