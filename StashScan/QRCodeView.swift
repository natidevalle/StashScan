//
//  QRCodeView.swift
//  StashScan
//
//  Generates and displays a QR code for a Container's UUID using CoreImage.
//  No external libraries — CIQRCodeGenerator is built into iOS.
//

import SwiftUI
import CoreImage

struct QRCodeView: View {
    let uuid: UUID

    var body: some View {
        if let image = Self.generate(uuid) {
            Image(uiImage: image)
                .interpolation(.none)   // nearest-neighbour — keeps QR pixels crisp at any display size
                .resizable()
                .scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "qrcode")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
        }
    }

    // MARK: - Generation

    /// Renders the UUID as a QR code image at 512 × 512 px.
    /// 512 px gives enough resolution to stay sharp when scaled up for printing.
    static func generate(_ uuid: UUID) -> UIImage? {
        guard
            let data = uuid.uuidString.data(using: .ascii),
            let filter = CIFilter(name: "CIQRCodeGenerator")
        else { return nil }

        filter.setValue(data, forKey: "inputMessage")
        // "H" = high error correction (≈30% data recovery) — best choice for printed labels
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let raw = filter.outputImage else { return nil }

        // The native output is tiny (~21 × 21 px). Scale up to 512 px.
        let targetPx: CGFloat = 512
        let scale = targetPx / raw.extent.width
        let scaled = raw.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // CIContext renders without antialiasing, preserving sharp module edges.
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

#Preview {
    QRCodeView(uuid: UUID())
        .frame(width: 200, height: 200)
        .padding()
}
