//
//  TintProcessor.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

import Foundation

/// Applies a color tint overlay to images.
///
/// This processor blends a color over the image, useful for creating
/// themed variants, mood effects, or brand-colored images.
///
/// ## Example Usage
/// ```swift
/// // Red tint with 30% opacity
/// let redProcessor = TintProcessor(color: .red, intensity: 0.3)
///
/// // Blue overlay
/// let blueProcessor = TintProcessor(color: .blue, intensity: 0.5)
/// ```
public struct TintProcessor: ImageProcessor {

    // MARK: - Properties

    /// The tint color to apply
    public let color: PlatformColor

    /// Intensity of the tint (0.0 = no tint, 1.0 = full color)
    public let intensity: CGFloat


    // MARK: - Initialization

    /// Creates a tint processor.
    ///
    /// - Parameters:
    ///   - color: The tint color to apply.
    ///   - intensity: The tint intensity (0.0 to 1.0).
    public init(color: PlatformColor, intensity: CGFloat = 0.5) {
        self.color = color
        self.intensity = max(0, min(1, intensity))
    }


    // MARK: - ImageProcessor

    public func process(_ image: PlatformImage) async throws -> PlatformImage {

        try await Task.detached(priority: .userInitiated) {
#if canImport(UIKit)
            let format = UIGraphicsImageRendererFormat()
            format.scale = image.scale
            format.opaque = false

            let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

            return renderer.image { context in
                // Draw original image
                image.draw(at: .zero)

                // Draw tint overlay
                color.withAlphaComponent(intensity).setFill()
                context.fill(CGRect(origin: .zero, size: image.size))
            }

#elseif canImport(AppKit)
            let targetSize = image.size
            let scale = NSScreen.main?.backingScaleFactor ?? 1.0
            let scaledSize = CGSize(
                width: targetSize.width * scale,
                height: targetSize.height * scale
            )

            guard let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(scaledSize.width),
                pixelsHigh: Int(scaledSize.height),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) else {
                return image
            }

            NSGraphicsContext.saveGraphicsState()
            defer { NSGraphicsContext.restoreGraphicsState() }

            let context = NSGraphicsContext(bitmapImageRep: bitmap)
            NSGraphicsContext.current = context

            // Draw original image
            image.draw(in: NSRect(origin: .zero, size: targetSize))

            // Draw tint overlay
            color.withAlphaComponent(intensity).setFill()
            NSRect(origin: .zero, size: targetSize).fill()

            let tintedImage = NSImage(size: targetSize)
            tintedImage.addRepresentation(bitmap)

            return tintedImage
#endif
        }.value
    }
}
