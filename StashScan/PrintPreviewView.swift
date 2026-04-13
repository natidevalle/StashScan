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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    printButton
                }
            }
        }
    }

    // MARK: - Label preview

    private var labelPreview: some View {
        Image(uiImage: labelImage)
            .resizable()
            .scaledToFit()
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
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
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var statusColor: Color {
        switch printer.state {
        case .ready:                return .green
        case .error:                return .red
        case .bluetoothUnavailable: return .red
        case .scanning, .connecting, .printing: return .orange
        case .disconnected:         return .secondary
        }
    }

    // MARK: - Printer section

    @ViewBuilder
    private var printerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Printer")
                .font(.headline)

            switch printer.state {
            case .bluetoothUnavailable:
                Label("Bluetooth is unavailable on this device.", systemImage: "bluetooth.slash")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

            case .disconnected:
                firstTimePairingHint
                connectButton

            case .error:
                Text("Tap Connect to try again.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                connectButton

            case .scanning:
                VStack(alignment: .leading, spacing: 8) {
                    progressRow("Scanning for Phomemo Q02E…")
                    Text("Make sure the printer is powered on and within range.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .connecting:
                progressRow("Connecting to printer…")

            case .ready:
                HStack(spacing: 10) {
                    Image(systemName: "printer")
                        .foregroundStyle(.green)
                    Text("Phomemo Q02E – Ready")
                    Spacer()
                    Button("Disconnect") { printer.disconnectAndForget() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            case .printing:
                progressRow("Sending data to printer…")
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var firstTimePairingHint: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("First time using the printer?", systemImage: "info.circle")
                .font(.subheadline.bold())
            Text("Open **Settings → Bluetooth** and pair your Phomemo Q02E, then tap Connect here.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var connectButton: some View {
        Button {
            printer.startScan()
        } label: {
            Label("Connect to Printer", systemImage: "printer")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private func progressRow(_ label: String) -> some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Print button

    private var printButton: some View {
        Button {
            let data = LabelRenderer.buildPrintData(for: container)
            printer.print(data: data)
        } label: {
            Text("Print")
                .fontWeight(.semibold)
        }
        .disabled(printer.state != .ready)
    }
}
