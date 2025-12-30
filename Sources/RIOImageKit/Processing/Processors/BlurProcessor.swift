//
//  BlurProcessor.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

import CoreImage
import Foundation

/// Applies gaussian blur to images.
///
/// This processor uses Core Image filters to apply a smooth gaussian blur
/// effect, perfect for backgrounds, privacy overlays, or artistic effects.
///
/// ## Example Usage
/// ```swift
/// // Subtle blur
/// let subtleProcessor = BlurProcessor(radius: 5)
///
/// // Heavy blur for backgrounds
/// let backgroundProcessor = BlurProcessor(radius: 20)
/// ```
public struct BlurProcessor: ImageProcessor {

    // MARK: - Properties

    /// Blur radius in points (larger = more blur)
    public let radius: CGFloat


    // MARK: - Initialization

    /// Creates a blur processor.
    ///
    /// - Parameter radius: The blur radius in points. Typical values: 5-20.
    public init(radius: CGFloat) {
        self.radius = radius
    }


    // MARK: - ImageProcessor

    public func process(_ image: PlatformImage) async throws -> PlatformImage {

        try await Task.detached(priority: .userInitiated) {
#if canImport(UIKit)
            guard let cgImage = image.cgImage else { return image }

            let ciImage = CIImage(cgImage: cgImage)
            let filter = CIFilter(name: "CIGaussianBlur")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(radius, forKey: kCIInputRadiusKey)

            guard let outputImage = filter?.outputImage else { return image }

            let context = CIContext(options: nil)
            guard let blurredCGImage = context.createCGImage(
                outputImage,
                from: ciImage.extent
            ) else {
                return image
            }

            return UIImage(cgImage: blurredCGImage, scale: image.scale, orientation: image.imageOrientation)

#elseif canImport(AppKit)
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let ciImage = CIImage(bitmapImageRep: bitmap) else {
                return image
            }

            let filter = CIFilter(name: "CIGaussianBlur")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(radius, forKey: kCIInputRadiusKey)

            guard let outputImage = filter?.outputImage else { return image }

            let context = CIContext(options: nil)
            guard let blurredCGImage = context.createCGImage(
                outputImage,
                from: ciImage.extent
            ) else {
                return image
            }

            let processedImage = NSImage(cgImage: blurredCGImage, size: image.size)
            return processedImage
#endif
        }.value
    }
}
