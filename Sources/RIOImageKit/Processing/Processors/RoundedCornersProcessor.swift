//
//  RoundedCornersProcessor.swift
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

/// Applies rounded corners to images.
///
/// This processor clips the image to a rounded rectangle with the specified
/// corner radius, perfect for profile pictures, cards, and modern UI designs.
///
/// ## Example Usage
/// ```swift
/// // 16pt corner radius
/// let processor = RoundedCornersProcessor(radius: 16)
/// let roundedImage = try await processor.process(image)
///
/// // Circular image
/// let size = image.size.width
/// let circularProcessor = RoundedCornersProcessor(radius: size / 2)
/// ```
public struct RoundedCornersProcessor: ImageProcessor {

    // MARK: - Properties

    /// Corner radius in points
    public let radius: CGFloat

    /// Background color for areas outside the rounded rect
    public let backgroundColor: PlatformColor?


    // MARK: - Initialization

    /// Creates a rounded corners processor.
    ///
    /// - Parameters:
    ///   - radius: The corner radius in points.
    ///   - backgroundColor: Optional background color for transparent areas.
    public init(radius: CGFloat, backgroundColor: PlatformColor? = nil) {
        self.radius = radius
        self.backgroundColor = backgroundColor
    }


    // MARK: - ImageProcessor

    public func process(_ image: PlatformImage) async throws -> PlatformImage {

        try await Task.detached(priority: .userInitiated) {
#if canImport(UIKit)
            let format = UIGraphicsImageRendererFormat()
            format.scale = image.scale
            format.opaque = backgroundColor != nil

            let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

            return renderer.image { context in
                if let bgColor = backgroundColor {
                    bgColor.setFill()
                    context.fill(CGRect(origin: .zero, size: image.size))
                }

                let path = UIBezierPath(
                    roundedRect: CGRect(origin: .zero, size: image.size),
                    cornerRadius: radius
                )
                path.addClip()

                image.draw(at: .zero)
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

            if let bgColor = backgroundColor {
                bgColor.setFill()
                NSRect(origin: .zero, size: targetSize).fill()
            }

            let path = NSBezierPath(
                roundedRect: NSRect(origin: .zero, size: targetSize),
                xRadius: radius,
                yRadius: radius
            )
            path.addClip()

            image.draw(in: NSRect(origin: .zero, size: targetSize))

            let processedImage = NSImage(size: targetSize)
            processedImage.addRepresentation(bitmap)

            return processedImage
#endif
        }.value
    }
}


// MARK: - Platform Color Alias

#if canImport(UIKit)
public typealias PlatformColor = UIColor
#elseif canImport(AppKit)
public typealias PlatformColor = NSColor
#endif
