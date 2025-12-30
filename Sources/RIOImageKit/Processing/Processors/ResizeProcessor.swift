//
//  ResizeProcessor.swift
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

/// Resizes images to a target size while maintaining or ignoring aspect ratio.
///
/// This processor provides high-quality image resizing with options for
/// different content modes and scale factors.
///
/// ## Performance
/// Resizing is performed in the background to avoid blocking the main thread.
/// For best performance, resize images to their display size rather than
/// using full-resolution images.
///
/// ## Example Usage
/// ```swift
/// // Aspect fit (maintains aspect ratio, fits within bounds)
/// let fitProcessor = ResizeProcessor(
///     targetSize: CGSize(width: 200, height: 200),
///     contentMode: .aspectFit
/// )
///
/// // Aspect fill (maintains aspect ratio, fills bounds)
/// let fillProcessor = ResizeProcessor(
///     targetSize: CGSize(width: 200, height: 200),
///     contentMode: .aspectFill
/// )
///
/// // Scale to fill (ignores aspect ratio)
/// let scaleProcessor = ResizeProcessor(
///     targetSize: CGSize(width: 200, height: 200),
///     contentMode: .scaleToFill
/// )
/// ```
public struct ResizeProcessor: ImageProcessor {

    /// Content mode for resizing
    public enum ContentMode: Sendable {

        /// Scale to fill the entire target size (ignores aspect ratio)
        case scaleToFill


        /// Scale to fit within target size (maintains aspect ratio)
        case aspectFit


        /// Scale to fill target size (maintains aspect ratio, may crop)
        case aspectFill
    }


    // MARK: - Properties

    /// Target size for the resized image
    public let targetSize: CGSize


    /// Content mode determining how the image should be resized
    public let contentMode: ContentMode


    /// Scale factor for the resized image
    public let scale: CGFloat


    // MARK: - Initialization

    /// Creates a resize processor with the specified parameters.
    ///
    /// - Parameters:
    ///   - targetSize: The desired output size.
    ///   - contentMode: How the image should be scaled. Defaults to `.aspectFill`.
    ///   - scale: The scale factor for the output image. Defaults to screen scale.
    public init(
        targetSize: CGSize,
        contentMode: ContentMode = .aspectFill,
        scale: CGFloat = 0 // 0 means use screen scale
    ) {
        self.targetSize = targetSize
        self.contentMode = contentMode
        self.scale = scale
    }


    // MARK: - ImageProcessor

    public func process(_ image: PlatformImage) async throws -> PlatformImage {

        try await Task.detached(priority: .userInitiated) {
            let finalSize = calculateFinalSize(for: image.size)

#if canImport(UIKit)
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale == 0 ? UIScreen.main.scale : scale
            format.opaque = false

            let renderer = UIGraphicsImageRenderer(size: finalSize, format: format)

            return renderer.image { context in
                let drawRect = calculateDrawRect(
                    imageSize: image.size,
                    targetSize: finalSize
                )
                image.draw(in: drawRect)
            }

#elseif canImport(AppKit)
            let targetScale = scale == 0 ? NSScreen.main?.backingScaleFactor ?? 1.0 : scale
            let scaledSize = CGSize(
                width: finalSize.width * targetScale,
                height: finalSize.height * targetScale
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

            let drawRect = calculateDrawRect(
                imageSize: image.size,
                targetSize: finalSize
            )
            image.draw(in: drawRect)

            let resizedImage = NSImage(size: finalSize)
            resizedImage.addRepresentation(bitmap)

            return resizedImage
#endif
        }.value
    }


    // MARK: - Private Methods

    private func calculateFinalSize(for originalSize: CGSize) -> CGSize {

        switch contentMode {
        case .scaleToFill:
            return targetSize

        case .aspectFit:
            let aspectRatio = originalSize.width / originalSize.height
            let targetAspect = targetSize.width / targetSize.height

            if aspectRatio > targetAspect {
                // Image is wider
                return CGSize(
                    width: targetSize.width,
                    height: targetSize.width / aspectRatio
                )
            } else {
                // Image is taller
                return CGSize(
                    width: targetSize.height * aspectRatio,
                    height: targetSize.height
                )
            }

        case .aspectFill:
            let aspectRatio = originalSize.width / originalSize.height
            let targetAspect = targetSize.width / targetSize.height

            if aspectRatio > targetAspect {
                // Image is wider
                return CGSize(
                    width: targetSize.height * aspectRatio,
                    height: targetSize.height
                )
            } else {
                // Image is taller
                return CGSize(
                    width: targetSize.width,
                    height: targetSize.width / aspectRatio
                )
            }
        }
    }


    private func calculateDrawRect(imageSize: CGSize, targetSize: CGSize) -> CGRect {

        switch contentMode {
        case .scaleToFill, .aspectFit:
            return CGRect(origin: .zero, size: targetSize)

        case .aspectFill:
            // Center the image
            let x = (targetSize.width - imageSize.width) / 2
            let y = (targetSize.height - imageSize.height) / 2
            return CGRect(x: x, y: y, width: imageSize.width, height: imageSize.height)
        }
    }
}
