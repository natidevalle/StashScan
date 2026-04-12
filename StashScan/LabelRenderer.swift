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
    static let labelHeightPx: CGFloat = 200
    private static let bytesPerLine   = 48    // 384 / 8

    // MARK: - Label image

    /// Renders a label image at exactly 384 × 200 px.
    ///
    /// IMPORTANT: the renderer is forced to scale = 1.
    /// UIGraphicsImageRenderer defaults to device screen scale (3× on modern iPhones),
    /// which makes the backing cgImage 1152 × 600 px. toMonochromeBitmap then draws
    /// that into a 384 × 600 grayscale context, compressing everything 3× horizontally
    /// while leaving height unchanged — squashing QR columns and stretching rows so the
    /// code cannot be scanned. At scale = 1 the cgImage is exactly 384 × 200 px and
    /// the context dimensions in toMonochromeBitmap always match.
    static func render(container: Container) -> UIImage {
        let size = CGSize(width: labelWidthPx, height: labelHeightPx)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1   // 1 px per point — cgImage will be exactly 384 × 200 px
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            // White background
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            // QR code — left square, fills height minus padding on all sides
            let padding: CGFloat = 10
            let qrSide = labelHeightPx - padding * 2   // 180 px square
            if let qrImage = QRCodeView.generate(container.qrCode) {
                qrImage.draw(in: CGRect(x: padding, y: padding, width: qrSide, height: qrSide))
            }

            // Text area — right of QR
            let textX     = padding + qrSide + padding   // 200 px
            let textWidth = labelWidthPx - textX - padding  // 174 px

            // Paragraph style shared by both text fields:
            // .byTruncatingTail prevents mid-word character wrapping when a name
            // or path is wider than the available rect — shows "…" instead.
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = .byTruncatingTail

            // Container name — bold, large
            let nameFont = UIFont.boldSystemFont(ofSize: 22)
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: nameFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: style
            ]
            let nameString = container.name as NSString
            let nameHeight: CGFloat = 56
            let nameY = padding + (qrSide - nameHeight - 28) / 2
            nameString.draw(
                in: CGRect(x: textX, y: nameY, width: textWidth, height: nameHeight),
                withAttributes: nameAttrs
            )

            // Location path — smaller, gray
            let pathFont = UIFont.systemFont(ofSize: 15)
            let pathAttrs: [NSAttributedString.Key: Any] = [
                .font: pathFont,
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: style
            ]
            let locName  = container.zone?.location?.name ?? "?"
            let zoneName = container.zone?.name ?? "?"
            let path     = "\(locName) › \(zoneName)" as NSString
            let pathY    = nameY + nameHeight + 4
            path.draw(
                in: CGRect(x: textX, y: pathY, width: textWidth, height: 36),
                withAttributes: pathAttrs
            )
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
