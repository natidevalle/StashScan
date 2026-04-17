//
//  LabelRenderer.swift
//  StashScan
//
//  Renders a container label as a 384×200 UIImage (QR left, name + path right)
//  and converts it to an ESC/POS byte sequence for the Phomemo Q02E.
//

import UIKit

enum LabelRenderer {

    // MARK: - Dimensions

    static let labelWidthPx: CGFloat  = 384   // Q02E paper width
    static let labelHeightPx: CGFloat = 280   // content (200) + ~10 mm bottom tear margin (80 px at 203 dpi)
    private static let bytesPerLine   = 48    // 384 / 8

    // MARK: - Label image

    /// Renders a label image at exactly 384 × 280 px.
    ///
    /// Layout: QR code fills the left 200 px (10 px padding each side = 180 px square).
    /// Text column starts flush with the QR top edge and flows downward.
    /// The bottom 80 px (≈ 10 mm at 203 dpi) is blank — tear margin so the QR is never cut.
    ///
    /// IMPORTANT: format.scale = 1 so the backing cgImage is exactly 384 × 280 px.
    /// At device scale (3×) the cgImage would be 1152 × 840 px and toMonochromeBitmap
    /// would compress it 3× horizontally, distorting QR modules into tall rectangles.
    static func render(container: Container) -> UIImage {
        let size = CGSize(width: labelWidthPx, height: labelHeightPx)

        let format = UIGraphicsImageRendererFormat()
        format.scale  = 1      // 1 px per point — cgImage exactly matches label dimensions
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            // ── Layout constants ───────────────────────────────────────────
            let padding: CGFloat = 10
            // QR and text occupy the top 200 px; the rest is the bottom tear margin.
            let contentHeight: CGFloat = 200
            let qrSide = contentHeight - padding * 2   // 180 px square

            // ── QR code (left column) ──────────────────────────────────────
            if let qrImage = QRCodeView.generate(container.qrCode) {
                qrImage.draw(in: CGRect(x: padding, y: padding, width: qrSide, height: qrSide))
            }

            // ── Text column (right of QR) ──────────────────────────────────
            let textX     = padding + qrSide + padding   // 200 px from left edge
            let textWidth = labelWidthPx - textX - padding  // 174 px wide

            // Wrapping style: allows word-wrap so larger fonts can use a second line.
            let wrapping = NSMutableParagraphStyle()
            wrapping.lineBreakMode = .byWordWrapping

            // Truncating style: used for notes where overflow should be hidden.
            let truncating = NSMutableParagraphStyle()
            truncating.lineBreakMode = .byTruncatingTail

            // Cursor starts at QR top edge — name is top-aligned, not vertically centred.
            var cursorY: CGFloat = padding

            // 1. Container name — bold 28 pt, up to 2 lines
            let nameFont = UIFont.boldSystemFont(ofSize: 28)
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: nameFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: wrapping
            ]
            let nameHeight = ceil(nameFont.lineHeight) * 2   // ≈ 68 px
            (container.name as NSString).draw(
                in: CGRect(x: textX, y: cursorY, width: textWidth, height: nameHeight),
                withAttributes: nameAttrs
            )
            cursorY += nameHeight + 5

            // 2. Location path — 19 pt, up to 2 lines
            let pathFont = UIFont.systemFont(ofSize: 20)
            let pathAttrs: [NSAttributedString.Key: Any] = [
                .font: pathFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: wrapping
            ]
            let locName  = container.zone?.location?.name ?? "?"
            let zoneName = container.zone?.name ?? "?"
            let pathHeight = ceil(pathFont.lineHeight) * 2   // ≈ 46 px
            ("\(locName) > \(zoneName)" as NSString).draw(
                in: CGRect(x: textX, y: cursorY, width: textWidth, height: pathHeight),
                withAttributes: pathAttrs
            )
            cursorY += pathHeight + 4

            // 3. Notes — 14 pt, up to 2 lines, only rendered when non-empty.
            //
            // Color must have luma < 128 to survive toMonochromeBitmap's threshold.
            // UIColor.lightGray is white=0.667 → luma≈170, which is above the threshold
            // and gets treated as white (no ink). white=0.45 → luma≈115, prints reliably
            // while still appearing lighter than darkGray (white=0.33) on screen.
            let notes = container.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            if !notes.isEmpty {
                let notesFont = UIFont.systemFont(ofSize: 20)
                let notesAttrs: [NSAttributedString.Key: Any] = [
                    .font: notesFont,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: truncating
                ]
                let notesHeight = ceil(notesFont.lineHeight) * 2   // ≈ 34 px
                (notes as NSString).draw(
                    in: CGRect(x: textX, y: cursorY, width: textWidth, height: notesHeight),
                    withAttributes: notesAttrs
                )
            }
        }
    }

    // MARK: - 1-bit monochrome conversion

    /// Converts a UIImage to a packed 1-bit bitmap, MSB = leftmost pixel.
    /// 1 = dark (print), 0 = light (no ink).
    /// Returns the packed bytes and the number of scan lines.
    static func toMonochromeBitmap(_ image: UIImage) -> (data: Data, lines: Int) {
        guard let cg = image.cgImage else { return (Data(), 0) }

        let width  = Int(labelWidthPx)
        let height = cg.height

        // Render into an 8-bit grayscale context (no alpha)
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return (Data(), 0) }

        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelPtr = ctx.data else { return (Data(), 0) }
        let pixels = pixelPtr.bindMemory(to: UInt8.self, capacity: width * height)

        var result = Data(capacity: bytesPerLine * height)
        for y in 0..<height {
            for byteIdx in 0..<bytesPerLine {
                var byte: UInt8 = 0
                for bit in 0..<8 {
                    let x     = byteIdx * 8 + bit
                    let luma  = pixels[y * width + x]
                    if luma < 128 {                 // dark → print
                        byte |= (0x80 >> bit)       // MSB = leftmost pixel
                    }
                }
                result.append(byte)
            }
        }
        return (result, height)
    }

    // MARK: - ESC/POS packet

    /// Builds the complete ESC/POS byte sequence to send to the Phomemo Q02E.
    static func buildPrintData(for container: Container) -> Data {
        let labelImage = render(container: container)
        let (bitmap, lines) = toMonochromeBitmap(labelImage)

        var packet = Data()

        // ESC @ — initialize / reset printer
        packet.append(contentsOf: [0x1B, 0x40])

        // GS v 0 m xL xH yL yH <data>
        //   m = 0x00  (normal density)
        //   xL = 48 (0x30), xH = 0  → 48 bytes = 384 dots per row
        //   yL / yH = number of print lines (little-endian)
        let xL = UInt8(bytesPerLine & 0xFF)
        let xH = UInt8((bytesPerLine >> 8) & 0xFF)
        let yL = UInt8(lines & 0xFF)
        let yH = UInt8((lines >> 8) & 0xFF)
        packet.append(contentsOf: [0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH])
        packet.append(bitmap)

        // ESC d 3 — feed 3 blank lines after print
        packet.append(contentsOf: [0x1B, 0x64, 0x03])

        return packet
    }
}
