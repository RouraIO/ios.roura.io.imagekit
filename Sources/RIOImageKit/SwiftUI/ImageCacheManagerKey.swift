//
//  ImageCacheManagerKey.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

import SwiftUI

/// Environment key for providing an ImageCacheManager to the view hierarchy.
///
/// This allows SwiftUI views to access the shared image cache manager
/// through the environment, enabling dependency injection and testability.
///
/// ## Usage
/// ```swift
/// // Set up in app root
/// @main
/// struct MyApp: App {
///     let cacheManager = ImageCacheManager(
///         imageLoadable: ImageDownloadService(),
///         memoryCache: MemoryImageCache(),
///         diskCache: try! DiskImageCache()
///     )
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .environment(\.imageCacheManager, cacheManager)
///         }
///     }
/// }
///
/// // Access in views
/// struct MyView: View {
///     @Environment(\.imageCacheManager) var cacheManager
///
///     var body: some View {
///         CachedAsyncImage(url: imageURL)
///     }
/// }
/// ```
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
struct ImageCacheManagerKey: EnvironmentKey {

    static let defaultValue: ImageCacheManager = {

        ImageCacheManager(
            imageLoadable: ImageDownloadService(),
            memoryCache: MemoryImageCache(),
            diskCache: try! DiskImageCache()
        )
    }()
}


@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public extension EnvironmentValues {

    /// The image cache manager for this environment.
    ///
    /// Use this to access the shared image caching system in SwiftUI views.
    ///
    /// ## Example
    /// ```swift
    /// struct ContentView: View {
    ///     @Environment(\.imageCacheManager) var cacheManager
    ///
    ///     var body: some View {
    ///         Button("Clear Cache") {
    ///             Task {
    ///                 await cacheManager.clearCache()
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    var imageCacheManager: ImageCacheManager {
        get { self[ImageCacheManagerKey.self] }
        set { self[ImageCacheManagerKey.self] = newValue }
    }
}
