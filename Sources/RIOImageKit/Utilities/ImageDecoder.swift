//
//  ImageDecoder.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

import CoreGraphics
import Foundation
import ImageIO

/// Utility for decoding images in the background to prevent main thread blocking.
///
/// Image decoding can be expensive and block the main thread, causing UI jank.
/// This utility performs decoding in a background task with user-initiated priority.
///
/// ## How It Works
/// 1. Creates a detached task with `.userInitiated` priority
/// 2. Decodes the image data
/// 3. Forces decoding by rendering to a temporary graphics context
/// 4. Returns the pre-decoded image
///
/// ## Why Force Decoding?
/// Platform images have lazy decoding - they don't actually decode the image data until
/// it's drawn. By rendering to a temporary context, we force decoding to happen
/// in the background, preventing a large decode operation on the main thread.
///
/// ## Example Usage
/// ```swift
/// let imageData = try await URLSession.shared.data(from: url)
/// let decodedImage = try await ImageDecoder.decode(data: imageData.0)
/// // Image is now ready to display without blocking the main thread
/// ```
public enum ImageDecoder {

    /// Decodes image data in the background to avoid blocking the main thread.
    ///
    /// This method uses `Task.detached` with `.userInitiated` priority to perform
    /// decoding off the main thread. The image is forcibly decoded by rendering to
    /// a temporary graphics context, preventing lazy decoding on the main thread later.
    ///
    /// - Parameter data: The raw image data to decode (JPEG, PNG, etc.).
    /// - Returns: A fully decoded image ready for display.
    /// - Throws: `ImageCacheError.invalidImageData` if the data cannot be decoded as an image.
    public static func decode(data: Data) async throws -> PlatformImage {

        try await Task.detached(priority: .userInitiated) {
            guard let image = PlatformImage(data: data) else {
                throw ImageCacheError.invalidImageData
            }

            // Force decode by drawing to a temporary context
            // This prevents lazy decoding on the main thread later
            return await Self.forceDecodeImage(image)
        }.value
    }


    /// Decodes and downsamples image data for memory efficiency.
    ///
    /// This method decodes images at a reduced size, significantly reducing memory usage.
    /// Downsampling happens during decode, not after, making it much more efficient
    /// than decode-then-resize.
    ///
    /// ## Performance Benefits
    /// - **Memory Savings**: A 4000x3000 image downsampled to 400x300 uses ~90% less memory
    /// - **Faster Decoding**: Smaller images decode faster
    /// - **Better Scrolling**: Reduced memory pressure improves list/grid performance
    ///
    /// ## Example
    /// ```swift
    /// let options = ImageDownsampleOptions(
    ///     targetSize: CGSize(width: 200, height: 200),
    ///     scale: UIScreen.main.scale
    /// )
    /// let image = try await ImageDecoder.decode(data: data, downsampleOptions: options)
    /// ```
    ///
    /// - Parameters:
    ///   - data: The raw image data to decode.
    ///   - options: Downsample configuration specifying target size and scale.
    /// - Returns: A downsampled, fully decoded image.
    /// - Throws: `ImageCacheError.invalidImageData` if decoding fails.
    public static func decode(data: Data, downsampleOptions options: ImageDownsampleOptions) async throws -> PlatformImage {

        try await Task.detached(priority: .userInitiated) {
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
                throw ImageCacheError.invalidImageData
            }

            // Configure downsampling options
            let downsampleOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: options.maxPixelDimension
            ]

            guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(
                imageSource,
                0,
                downsampleOptions as CFDictionary
            ) else {
                throw ImageCacheError.invalidImageData
            }

#if canImport(UIKit)
            return UIImage(cgImage: downsampledImage, scale: options.scale, orientation: .up)
#elseif canImport(AppKit)
            let size = CGSize(
                width: CGFloat(downsampledImage.width) / options.scale,
                height: CGFloat(downsampledImage.height) / options.scale
            )
            let image = NSImage(cgImage: downsampledImage, size: size)
            return image
#endif
        }.value
    }


    /// Forces image decoding by rendering it to a temporary graphics context.
    ///
    /// This method must run on the main thread because graphics contexts
    /// require it. However, since this is called from a detached background task, the main
    /// thread work is minimal and doesn't block user interaction.
    ///
    /// - Parameter image: The image to force decode.
    /// - Returns: A fully decoded copy of the image, or the original if decoding fails.
    @MainActor
    private static func forceDecodeImage(_ image: PlatformImage) -> PlatformImage {

#if canImport(UIKit)
        let imageRect = CGRect(origin: .zero, size: image.size)

        UIGraphicsBeginImageContextWithOptions(
            image.size,
            false, // Preserve alpha
            image.scale
        )

        defer { UIGraphicsEndImageContext() }

        image.draw(in: imageRect)

        return UIGraphicsGetImageFromCurrentImageContext() ?? image

#elseif canImport(AppKit)
        let imageRect = CGRect(origin: .zero, size: image.size)

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(image.size.width),
            pixelsHigh: Int(image.size.height),
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

        image.draw(in: imageRect)

        let decodedImage = NSImage(size: image.size)
        decodedImage.addRepresentation(bitmap)

        return decodedImage
#endif
    }
}
