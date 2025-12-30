//
//  MockImageDownloadService.swift
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

/// Mock image download service for SwiftUI previews and testing.
///
/// This service simulates image downloading behavior without making network requests.
/// It returns SF Symbol placeholder images after a simulated delay.
///
/// ## Usage
/// Use this in place of `ImageDownloadService` when:
/// - Running SwiftUI previews
/// - Writing unit tests
/// - Developing UI without network access
///
/// ## Example
/// ```swift
/// // In AppDependencies.mock
/// let imageCacheManager = ImageCacheManager(
///     imageLoadable: MockImageDownloadService(),
///     memoryCache: MemoryImageCache(),
///     diskCache: try! DiskImageCache()
/// )
/// ```
struct MockImageDownloadService {}

// MARK: - ImageLoadable Conformance

extension MockImageDownloadService: ImageLoadable {

    /// Simulates downloading an image without progress tracking.
    ///
    /// - Parameter url: The URL (ignored in mock).
    /// - Returns: A placeholder SF Symbol image.
    /// - Throws: Never throws in the mock implementation.
    func loadImage(from url: URL) async throws -> PlatformImage {
        try await loadImage(from: url, progress: { _ in })
    }


    /// Simulates downloading an image with progress updates.
    ///
    /// This method simulates a ~0.5 second download with 10 progress updates,
    /// then returns a Bitcoin SF Symbol as a placeholder.
    ///
    /// - Parameters:
    ///   - url: The URL (ignored in mock).
    ///   - progress: A closure called with simulated progress (0.0 to 1.0).
    /// - Returns: A placeholder SF Symbol image (bitcoinsign.circle.fill).
    /// - Throws: Never throws in the mock implementation.
    func loadImage(from url: URL, progress: @escaping @Sendable (Double) -> Void) async throws -> PlatformImage {

        // Simulate network delay with progress updates
        let steps = 10
        for step in 0...steps {
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05s per step
            progress(Double(step) / Double(steps))
        }

        // Return placeholder image
#if canImport(UIKit)
        return UIImage(systemName: "bitcoinsign.circle.fill") ?? UIImage()
#elseif canImport(AppKit)
        return NSImage(systemSymbolName: "bitcoinsign.circle.fill", accessibilityDescription: nil) ?? NSImage()
#endif
    }


    /// No-op prefetch implementation.
    ///
    /// The mock doesn't actually prefetch images, so this method does nothing.
    ///
    /// - Parameter urls: The URLs to prefetch (ignored).
    func prefetchImages(urls: [URL]) async {
        // No-op for mock
    }


    /// No-op cancel implementation.
    ///
    /// The mock doesn't track prefetch operations, so this method does nothing.
    ///
    /// - Parameter urls: The URLs to cancel prefetching for (ignored).
    func cancelPrefetch(for urls: [URL]) {
        // No-op for mock
    }
}
