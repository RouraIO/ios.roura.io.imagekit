//
//  ImageProcessor.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Protocol for processing and transforming images.
///
/// Image processors allow you to apply transformations like resizing, cropping,
/// blurring, and more to images. Processors can be chained together to create
/// complex transformation pipelines.
///
/// ## Built-in Processors
/// - ``ResizeProcessor``: Resize images to specific dimensions
/// - ``CropProcessor``: Crop images to specific regions
/// - ``RoundedCornersProcessor``: Round image corners
/// - ``BlurProcessor``: Apply gaussian blur
/// - ``TintProcessor``: Apply color tinting
///
/// ## Example Usage
/// ```swift
/// let processor = ResizeProcessor(targetSize: CGSize(width: 200, height: 200))
/// let processedImage = try await processor.process(image)
/// ```
///
/// ## Chaining Processors
/// ```swift
/// let pipeline = [
///     ResizeProcessor(targetSize: CGSize(width: 200, height: 200)),
///     RoundedCornersProcessor(radius: 16),
///     BlurProcessor(radius: 2)
/// ]
/// let result = try await processImages(image, with: pipeline)
/// ```
public protocol ImageProcessor: Sendable {

    /// Processes an image and returns the transformed result.
    ///
    /// This method should be implemented to apply the specific transformation
    /// that this processor provides. Processing should be performed off the
    /// main thread to avoid blocking the UI.
    ///
    /// - Parameter image: The input image to process.
    /// - Returns: The processed image.
    /// - Throws: An error if processing fails.
    func process(_ image: PlatformImage) async throws -> PlatformImage
}


// MARK: - Helper Functions

/// Processes an image through a pipeline of processors.
///
/// Applies multiple processors in sequence, passing the output of each
/// processor as input to the next.
///
/// ## Example
/// ```swift
/// let processors: [ImageProcessor] = [
///     ResizeProcessor(targetSize: CGSize(width: 200, height: 200)),
///     RoundedCornersProcessor(radius: 16)
/// ]
/// let result = try await processImage(image, with: processors)
/// ```
///
/// - Parameters:
///   - image: The input image to process.
///   - processors: Array of processors to apply in order.
/// - Returns: The final processed image.
/// - Throws: An error if any processor fails.
public func processImage(
    _ image: PlatformImage,
    with processors: [any ImageProcessor]
) async throws -> PlatformImage {

    var currentImage = image

    for processor in processors {
        currentImage = try await processor.process(currentImage)
    }

    return currentImage
}
