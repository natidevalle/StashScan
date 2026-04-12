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

    // Compute once; stays stable for the sheet lifetime
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

    // MARK: - Printer status section

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

            case .error(let msg):
                Label(msg, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.subheadline)
                connectButton

            case .scanning:
                progressRow("Scanning for printer…")

            case .connecting:
                progressRow("Connecting…")

            case .ready:
                HStack(spacing: 10) {
                    Image(systemName: "printer.fill")
                        .foregroundStyle(.green)
                    Text("Phomemo Q02E – Ready")
                        .foregroundStyle(.primary)
                    Spacer()
                    Button("Disconnect") {
                        printer.disconnectAndForget()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

            case .printing:
                progressRow("Printing…")
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
