//
//  AnimatedImage.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

import ImageIO
import SwiftUI

/// A SwiftUI view that displays animated images (GIF, animated WebP).
///
/// This view automatically detects animated image formats and plays them
/// with proper frame timing. Static images are displayed normally.
///
/// ## Example Usage
/// ```swift
/// // Display animated GIF
/// AnimatedImage(data: gifData)
///     .frame(width: 200, height: 200)
///
/// // With custom scale
/// AnimatedImage(data: gifData, scale: 2.0)
///     .scaledToFit()
/// ```
///
/// ## Supported Formats
/// - GIF (animated and static)
/// - WebP (animated and static)
/// - All standard image formats (JPEG, PNG, HEIC) displayed as static
///
/// ## Performance
/// - Frames are cached in memory for smooth playback
/// - Animation automatically pauses when view disappears
/// - CPU-efficient timer-based frame updates
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public struct AnimatedImage: View {

    // MARK: - Properties

    /// The image data to display
    private let data: Data

    /// Scale factor for the image
    private let scale: CGFloat

    /// Current frame being displayed
    @State private var currentFrame: PlatformImage?

    /// Animation controller
    @StateObject private var animator: ImageAnimator


    // MARK: - Initialization

    /// Creates an animated image view from data.
    ///
    /// - Parameters:
    ///   - data: The image data (can be animated or static).
    ///   - scale: The scale factor for the image. Defaults to screen scale.
    public init(data: Data, scale: CGFloat = 0) {
        self.data = data
        self.scale = scale == 0 ? Self.defaultScale : scale
        _animator = StateObject(wrappedValue: ImageAnimator(data: data, scale: scale))
    }


    // MARK: - Body

    public var body: some View {
        Group {
            if let frame = currentFrame {
#if canImport(UIKit)
                Image(uiImage: frame)
                    .resizable()
#elseif canImport(AppKit)
                Image(nsImage: frame)
                    .resizable()
#endif
            } else {
                Color.clear
            }
        }
        .onAppear {
            animator.start { frame in
                currentFrame = frame
            }
        }
        .onDisappear {
            animator.stop()
        }
    }


    // MARK: - Private Helpers

    private static var defaultScale: CGFloat {
#if canImport(UIKit)
        UIScreen.main.scale
#elseif canImport(AppKit)
        NSScreen.main?.backingScaleFactor ?? 1.0
#endif
    }
}


// MARK: - Image Animator

/// Controller for animated image playback
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
private final class ImageAnimator: ObservableObject, @unchecked Sendable {

    // MARK: - Properties

    private let frames: [AnimatedFrame]
    private var currentIndex = 0
    private var timer: Timer?
    private var frameHandler: ((PlatformImage) -> Void)?


    // MARK: - Frame

    private struct AnimatedFrame {
        let image: PlatformImage
        let duration: TimeInterval
    }


    // MARK: - Initialization

    init(data: Data, scale: CGFloat) {
        self.frames = Self.extractFrames(from: data, scale: scale)
    }


    // MARK: - Control

    func start(frameHandler: @escaping (PlatformImage) -> Void) {
        self.frameHandler = frameHandler

        // Show first frame immediately
        if let firstFrame = frames.first {
            frameHandler(firstFrame.image)
        }

        // Start animation if multiple frames
        guard frames.count > 1 else { return }

        scheduleNextFrame()
    }


    func stop() {
        timer?.invalidate()
        timer = nil
        frameHandler = nil
    }


    // MARK: - Private Methods

    private func scheduleNextFrame() {
        let frame = frames[currentIndex]

        timer = Timer.scheduledTimer(withTimeInterval: frame.duration, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.currentIndex = (self.currentIndex + 1) % self.frames.count
            let nextFrame = self.frames[self.currentIndex]

            DispatchQueue.main.async {
                self.frameHandler?(nextFrame.image)
                self.scheduleNextFrame()
            }
        }
    }


    private static func extractFrames(from data: Data, scale: CGFloat) -> [AnimatedFrame] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return []
        }

        let frameCount = CGImageSourceGetCount(source)
        var frames: [AnimatedFrame] = []

        for index in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }

            // Get frame duration
            let duration = Self.frameDuration(at: index, source: source)

            // Create platform image
#if canImport(UIKit)
            let image = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
#elseif canImport(AppKit)
            let size = CGSize(
                width: CGFloat(cgImage.width) / scale,
                height: CGFloat(cgImage.height) / scale
            )
            let image = NSImage(cgImage: cgImage, size: size)
#endif

            frames.append(AnimatedFrame(image: image, duration: duration))
        }

        // If no frames extracted, try as static image
        if frames.isEmpty, let staticImage = PlatformImage(data: data) {
            frames.append(AnimatedFrame(image: staticImage, duration: 0))
        }

        return frames
    }


    private static func frameDuration(at index: Int, source: CGImageSource) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            return 0.1 // Default duration
        }

        // Try unclampedDelayTime first, fall back to delayTime
        if let duration = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? TimeInterval,
           duration > 0 {
            return duration
        }

        if let duration = gifProperties[kCGImagePropertyGIFDelayTime as String] as? TimeInterval,
           duration > 0 {
            return duration
        }

        return 0.1 // Default to 100ms if no duration specified
    }
}
