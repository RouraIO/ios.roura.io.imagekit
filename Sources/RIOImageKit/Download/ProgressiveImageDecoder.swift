//
//  ProgressiveImageDecoder.swift
//  RouraIOTools
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

/// Decoder for progressive JPEG images that can display partial data.
///
/// This decoder creates incremental images as data arrives, allowing for
/// progressive rendering of JPEGs during download. The image quality improves
/// as more data becomes available.
///
/// ## Benefits
/// - **Faster perceived loading**: Show blurry preview immediately
/// - **Better UX**: Progressive refinement vs. all-or-nothing
/// - **Bandwidth efficient**: Users see content before full download
///
/// ## Example Usage
/// ```swift
/// let decoder = ProgressiveImageDecoder()
///
/// // Feed data incrementally as it arrives
/// decoder.append(chunk1)
/// if let preview = decoder.currentImage {
///     display(preview) // Show blurry preview
/// }
///
/// decoder.append(chunk2)
/// if let better = decoder.currentImage {
///     display(better) // Show improved version
/// }
///
/// decoder.finalize()
/// if let final = decoder.currentImage {
///     display(final) // Show final high-quality image
/// }
/// ```
///
/// ## Supported Formats
/// - Progressive JPEG (best support)
/// - Baseline JPEG (shows once complete)
/// - PNG (shows once complete)
/// - Other formats (shows once complete)
public actor ProgressiveImageDecoder {

    // MARK: - Properties

    /// The incremental image source
    private var imageSource: CGImageSource?

    /// Accumulated data
    private var data = Data()

    /// Whether decoding is finalized
    private var isFinalized = false

    /// Scale factor for the decoded image
    private let scale: CGFloat


    // MARK: - Initialization

    /// Creates a progressive image decoder.
    ///
    /// - Parameter scale: Scale factor for the decoded image. Defaults to screen scale.
    public init(scale: CGFloat = 0) {
#if canImport(UIKit)
        self.scale = scale == 0 ? UIScreen.main.scale : scale
#elseif canImport(AppKit)
        self.scale = scale == 0 ? (NSScreen.main?.backingScaleFactor ?? 1.0) : scale
#endif
    }


    // MARK: - Methods

    /// Appends new data to the decoder.
    ///
    /// Call this method as data arrives during download to enable progressive rendering.
    ///
    /// - Parameter newData: New chunk of image data.
    public func append(_ newData: Data) {
        guard !isFinalized else { return }

        data.append(newData)

        if imageSource == nil {
            imageSource = CGImageSourceCreateIncremental(nil)
        }

        if let source = imageSource {
            CGImageSourceUpdateData(source, data as CFData, false)
        }
    }


    /// Finalizes the image decoding.
    ///
    /// Call this when all data has been received to produce the final image.
    public func finalize() {
        guard !isFinalized else { return }

        isFinalized = true

        if let source = imageSource {
            CGImageSourceUpdateData(source, data as CFData, true)
        }
    }


    /// Gets the current best-quality image from received data.
    ///
    /// Returns progressively better images as more data arrives.
    ///
    /// - Returns: The current image, or `nil` if insufficient data.
    public var currentImage: PlatformImage? {
        guard let source = imageSource else { return nil }

        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        // Try to create image from best available index
        for index in stride(from: count - 1, through: 0, by: -1) {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) {
#if canImport(UIKit)
                return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
#elseif canImport(AppKit)
                let size = CGSize(
                    width: CGFloat(cgImage.width) / scale,
                    height: CGFloat(cgImage.height) / scale
                )
                return NSImage(cgImage: cgImage, size: size)
#endif
            }
        }

        return nil
    }


    /// Resets the decoder to initial state.
    ///
    /// Clears all data and allows starting a new progressive decode.
    public func reset() {
        imageSource = nil
        data.removeAll()
        isFinalized = false
    }


    /// Returns the current decoding progress as a percentage.
    ///
    /// - Returns: Value from 0.0 to 1.0 indicating decode progress.
    public var progress: Double {
        guard let source = imageSource else { return 0 }

        let status = CGImageSourceGetStatus(source)

        switch status {
        case .statusComplete:
            return 1.0
        case .statusIncomplete:
            // Estimate based on available data
            return min(0.9, Double(data.count) / Double(max(data.count, 100_000)))
        case .statusReadingHeader:
            return 0.1
        case .statusUnknownType, .statusInvalidData, .statusUnexpectedEOF:
            return 0
        @unknown default:
            return 0
        }
    }
}
