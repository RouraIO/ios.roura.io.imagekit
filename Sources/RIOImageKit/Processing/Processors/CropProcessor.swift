//
//  CropProcessor.swift
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

/// Crops images to a specific region.
///
/// This processor extracts a rectangular region from the source image,
/// useful for creating thumbnails, focusing on specific areas, or
/// implementing custom aspect ratios.
///
/// ## Example Usage
/// ```swift
/// // Crop to center square
/// let size = min(image.size.width, image.size.height)
/// let origin = CGPoint(
///     x: (image.size.width - size) / 2,
///     y: (image.size.height - size) / 2
/// )
/// let processor = CropProcessor(cropRect: CGRect(origin: origin, size: CGSize(width: size, height: size)))
///
/// // Crop to specific region
/// let processor = CropProcessor(cropRect: CGRect(x: 0, y: 0, width: 100, height: 100))
/// ```
public struct CropProcessor: ImageProcessor {

    // MARK: - Properties

    /// The rectangle to crop from the source image (in image coordinates)
    public let cropRect: CGRect


    // MARK: - Initialization

    /// Creates a crop processor.
    ///
    /// - Parameter cropRect: The region to extract from the source image.
    public init(cropRect: CGRect) {
        self.cropRect = cropRect
    }


    // MARK: - ImageProcessor

    public func process(_ image: PlatformImage) async throws -> PlatformImage {

        try await Task.detached(priority: .userInitiated) {
#if canImport(UIKit)
            let scale = image.scale
            let scaledRect = CGRect(
                x: cropRect.origin.x * scale,
                y: cropRect.origin.y * scale,
                width: cropRect.size.width * scale,
                height: cropRect.size.height * scale
            )

            guard let cgImage = image.cgImage,
                  let croppedCGImage = cgImage.cropping(to: scaledRect) else {
                return image
            }

            return UIImage(cgImage: croppedCGImage, scale: scale, orientation: image.imageOrientation)

#elseif canImport(AppKit)
            let targetSize = cropRect.size
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

            let sourceRect = cropRect
            let destRect = NSRect(origin: .zero, size: targetSize)

            image.draw(
                in: destRect,
                from: sourceRect,
                operation: .copy,
                fraction: 1.0
            )

            let croppedImage = NSImage(size: targetSize)
            croppedImage.addRepresentation(bitmap)

            return croppedImage
#endif
        }.value
    }
}
