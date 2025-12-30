//
//  ImageDownsampleOptions.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import CoreGraphics
import Foundation

/// Configuration for downsampling images during decoding.
///
/// Downsampling reduces memory usage by decoding images at a smaller size
/// than their original dimensions. This is particularly important for:
/// - Large images displayed at smaller sizes (e.g., thumbnails)
/// - Memory-constrained environments
/// - Smooth scrolling in lists and grids
///
/// ## Example Usage
/// ```swift
/// // Downsample to fit within 200x200 while maintaining aspect ratio
/// let options = ImageDownsampleOptions(
///     targetSize: CGSize(width: 200, height: 200),
///     scale: UIScreen.main.scale
/// )
///
/// let image = try await ImageDecoder.decode(data: imageData, downsampleOptions: options)
/// ```
///
/// ## Performance Benefits
/// Downsampling during decode is significantly more efficient than:
/// 1. Decoding full size then resizing (uses less peak memory)
/// 2. Loading full images into UIImageView/NSImageView (reduces memory pressure)
///
/// A 4000x3000 image downsampled to 400x300 uses ~90% less memory.
public struct ImageDownsampleOptions: Sendable {

    // MARK: - Properties

    /// Target size for the downsampled image.
    ///
    /// The image will be decoded to fit within these dimensions while
    /// maintaining its aspect ratio.
    public let targetSize: CGSize

    /// Scale factor for the target device.
    ///
    /// Use `UIScreen.main.scale` or `NSScreen.main?.backingScaleFactor ?? 1.0`.
    /// Defaults to 1.0 for 1x resolution.
    public let scale: CGFloat


    // MARK: - Initialization

    /// Creates downsample options.
    ///
    /// - Parameters:
    ///   - targetSize: The target size to fit within.
    ///   - scale: The scale factor for the target device. Defaults to 1.0.
    public init(targetSize: CGSize, scale: CGFloat = 1.0) {
        self.targetSize = targetSize
        self.scale = max(1.0, scale)
    }


    // MARK: - Computed Properties

    /// Maximum dimension in pixels accounting for scale.
    ///
    /// This is used by Core Graphics to determine the downsample size.
    var maxPixelDimension: Int {
        Int(max(targetSize.width, targetSize.height) * scale)
    }
}
