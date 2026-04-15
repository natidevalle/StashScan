//
//  PrintPreviewView.swift
//  StashScan
//
//  Label preview sheet: shows the rendered label, printer connection state,
//  first-use pairing guidance, and the Print button.
//

import SwiftUI

struct PrintPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PhomemoPrinter.self) private var printer

    let container: Container

    // Rendered once at init; stable for the sheet's lifetime
    private let labelImage: UIImage

    init(container: Container) {
        self.container  = container
        self.labelImage = LabelRenderer.render(container: container)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    labelPreview
                        .padding(.top, 24)

                    statusBadge

                    printerSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Print Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .regular))
                            Text(container.name)
                                .font(.body)
                        }
                        .foregroundColor(.primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    printButton
                }
            }
        }
    }

    // MARK: - Label preview

    /// The rendered label cropped to the content area only (strips the 80 px
    /// blank tear margin so the preview card sizes to actual content).
    private var previewImage: UIImage {
        let contentH = LabelRenderer.labelHeightPx - 80   // 200 px
        let cropRect = CGRect(x: 0, y: 0,
                              width: LabelRenderer.labelWidthPx,
                              height: contentH)
        if let cgImage = labelImage.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage,
                           scale: labelImage.scale,
                           orientation: labelImage.imageOrientation)
        }
        return labelImage
    }

    private var labelPreview: some View {
        Image(uiImage: previewImage)
            .resizable()
            .scaledToFit()
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Persistent status badge
    // Always visible so the user can see exactly which stage the connection is at.

    private var statusBadge: some View {
        HStack(spacing: 8) {
            statusDot
            Text(printer.state.statusLabel)
                .font(.caption.monospacedDigit())
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.10), in: Capsule())
        .animation(.easeInOut(duration: 0.2), value: printer.state)
    }

    private var statusDot: some View {
        Group {
            if printer.state.isWorking {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(statusColor)
            } else if printer.state == .ready {
                Image(systemName: "printer.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.dsSuccess)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var statusColor: Color {
        switch printer.state {
        case .ready:                return Color.dsSuccess
        case .error:                return .red
        case .bluetoothUnavailable: return .red
        case .scanning, .connecting, .printing: return .orange
        case .disconnected:         return Color(.secondaryLabel)
        }
    }

    // MARK: - Printer section

    @ViewBuilder
    private var printerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PRINTER")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(.secondaryLabel))

            switch printer.state {
            case .bluetoothUnavailable:
                Label("Bluetooth is unavailable on this device.", systemImage: "bluetooth.slash")
                    .foregroundStyle(Color(.secondaryLabel))
                    .font(.subheadline)

            case .disconnected:
                firstTimePairingHint
                connectButton

            case .error:
                Text("Tap Connect to try again.")
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
                connectButton

            case .scanning:
                VStack(alignment: .leading, spacing: 8) {
                    progressRow("Scanning for Phomemo Q02E…")
                    Text("Make sure the printer is powered on and within range.")
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                }

            case .connecting:
                progressRow("Connecting to printer…")

            case .ready:
                HStack(spacing: 8) {
                    Image(systemName: "printer.fill")
                        .foregroundColor(Color.dsSuccess)
                    Text("Phomemo Q02E – Ready")
                        .font(.subheadline)
                    Spacer()
                    Button("Disconnect") { printer.disconnectAndForget() }
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                }

            case .printing:
                progressRow("Sending data to printer…")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var firstTimePairingHint: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("First time using the printer?", systemImage: "info.circle")
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
            Text("Open **Settings → Bluetooth** and pair your Phomemo Q02E, then tap Connect here.")
                .font(.caption)
                .foregroundStyle(Color(.secondaryLabel))
        }
    }

    private var connectButton: some View {
        Button { printer.startScan() } label: {
            HStack(spacing: 8) {
                Image(systemName: "printer")
                    .font(.system(size: 18))
                Text("Connect to Printer")
                    .font(.body)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.dsAccent)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func progressRow(_ label: String) -> some View {
        HStack(spacing: 8) {
            ProgressView()
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
        }
    }

    // MARK: - Print button

    private var printButton: some View {
        Button {
            let data = LabelRenderer.buildPrintData(for: container)
            printer.print(data: data)
        } label: {
            Text("Print")
                .font(.body)
        }
        .disabled(printer.state != .ready)
    }
}
