//
//  RouraIOImageModifiers.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/31/25.
//

import SwiftUI

/// View modifiers for customizing `RouraIOImage` behavior.
///
/// These modifiers allow you to configure caching, progress display, animations,
/// and custom views for different loading states.
///
/// ## Example Usage
/// ```swift
/// RouraIOImage(source: .remote(url))
///     .disableCache()
///     .showProgress(true)
///     .placeholder {
///         Color.gray.opacity(0.2)
///     }
///     .onLoading { progress in
///         if let progress = progress {
///             ProgressView("Loading...", value: progress)
///         } else {
///             ProgressView("Loading...")
///         }
///     }
///     .onError { error in
///         VStack {
///             Image(systemName: "exclamationmark.triangle")
///             Text("Failed to load")
///                 .font(.caption)
///         }
///     }
/// ```
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public extension View {

    // MARK: - Cache Control

    /// Disables caching for remote images.
    ///
    /// When caching is disabled, images are downloaded directly without checking
    /// or storing in the cache. This is useful for sensitive images or images
    /// that change frequently at the same URL.
    ///
    /// ## Example
    /// ```swift
    /// RouraIOImage(source: .remote(privatePhotoURL))
    ///     .disableCache()
    /// ```
    ///
    /// - Note: This only affects remote images. Asset and symbol images are
    ///         always loaded from local sources.
    ///
    /// - Returns: A view with caching disabled.
    func disableCache() -> some View {
        transformEnvironment(\.rouraIOImageConfiguration) { config in
            config.cacheEnabled = false
        }
    }

    /// Uses a custom cache manager for this view.
    ///
    /// Allows you to specify a different cache manager than the one in the
    /// environment. Useful for creating isolated caches with different
    /// configurations or size limits.
    ///
    /// ## Example
    /// ```swift
    /// let ephemeralCache = ImageCacheManager(
    ///     imageLoadable: ImageDownloadService(),
    ///     memoryCache: MemoryImageCache(capacity: 10),
    ///     diskCache: try! DiskImageCache()
    /// )
    ///
    /// RouraIOImage(source: .remote(temporaryURL))
    ///     .cache(manager: ephemeralCache)
    /// ```
    ///
    /// - Parameter manager: The custom cache manager to use.
    /// - Returns: A view using the specified cache manager.
    func cache(manager: ImageCacheManager) -> some View {
        transformEnvironment(\.rouraIOImageConfiguration) { config in
            config.customCacheManager = manager
        }
    }

    // MARK: - Customization

    /// Sets a custom placeholder view to show before the image loads.
    ///
    /// The placeholder is displayed while the image is being loaded or when
    /// the view is in an idle state.
    ///
    /// ## Example
    /// ```swift
    /// RouraIOImage(source: .remote(url))
    ///     .placeholder {
    ///         ZStack {
    ///             Color.gray.opacity(0.2)
    ///             ProgressView()
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameter builder: A view builder that creates the placeholder view.
    /// - Returns: A view with a custom placeholder.
    func placeholder<P: View>(@ViewBuilder _ builder: @escaping () -> P) -> some View {
        transformEnvironment(\.rouraIOImageConfiguration) { config in
            config.customPlaceholder = AnyView(builder())
        }
    }

    /// Sets a custom loading view with progress tracking.
    ///
    /// The loading view is shown while a remote image is being downloaded.
    /// The closure receives the current progress (0.0 to 1.0) if available,
    /// or `nil` if progress tracking is not enabled.
    ///
    /// ## Example
    /// ```swift
    /// RouraIOImage(source: .remote(url))
    ///     .showProgress(true)
    ///     .onLoading { progress in
    ///         if let progress = progress {
    ///             VStack {
    ///                 ProgressView(value: progress)
    ///                 Text("\(Int(progress * 100))%")
    ///                     .font(.caption)
    ///             }
    ///         } else {
    ///             ProgressView()
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameter builder: A view builder that creates the loading view.
    ///                      Receives optional progress (0.0 to 1.0).
    /// - Returns: A view with a custom loading state.
    func onLoading<V: View>(@ViewBuilder _ builder: @escaping (Double?) -> V) -> some View {
        transformEnvironment(\.rouraIOImageConfiguration) { config in
            config.customLoadingView = { progress in AnyView(builder(progress)) }
        }
    }

    /// Sets a custom error view to show when image loading fails.
    ///
    /// The error view is displayed when a remote image fails to download
    /// or cannot be decoded.
    ///
    /// ## Example
    /// ```swift
    /// RouraIOImage(source: .remote(url))
    ///     .onError { error in
    ///         VStack {
    ///             Image(systemName: "exclamationmark.triangle")
    ///                 .foregroundColor(.red)
    ///             Text("Failed to load")
    ///                 .font(.caption)
    ///             Text(error.localizedDescription)
    ///                 .font(.caption2)
    ///                 .foregroundColor(.secondary)
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameter builder: A view builder that creates the error view.
    ///                      Receives the error that occurred.
    /// - Returns: A view with a custom error state.
    func onError<V: View>(@ViewBuilder _ builder: @escaping (any Error) -> V) -> some View {
        transformEnvironment(\.rouraIOImageConfiguration) { config in
            config.customErrorView = { error in AnyView(builder(error)) }
        }
    }

    // MARK: - Behavior

    /// Controls whether to show download progress for remote images.
    ///
    /// When enabled, the image view will track download progress and make it
    /// available to the loading view (via `.onLoading { progress in }` modifier)
    /// or display a default progress view.
    ///
    /// ## Example
    /// ```swift
    /// RouraIOImage(source: .remote(largeImageURL))
    ///     .showProgress(true)
    /// ```
    ///
    /// - Parameter show: Whether to track and display progress. Defaults to `true`.
    /// - Returns: A view with progress tracking enabled or disabled.
    func showProgress(_ show: Bool = true) -> some View {
        transformEnvironment(\.rouraIOImageConfiguration) { config in
            config.showProgress = show
        }
    }

    /// Controls the fade-in animation when the image loads.
    ///
    /// By default, images fade in over 0.3 seconds when loaded. You can customize
    /// the duration or disable the animation entirely by setting duration to 0.
    ///
    /// ## Example
    /// ```swift
    /// // Custom animation duration
    /// RouraIOImage(source: .remote(url))
    ///     .animated(duration: 0.5)
    ///
    /// // Disable animation
    /// RouraIOImage(source: .remote(url))
    ///     .animated(duration: 0)
    /// ```
    ///
    /// - Parameter duration: The fade-in animation duration in seconds.
    ///                       Set to 0 to disable animation. Defaults to 0.3.
    /// - Returns: A view with the specified animation duration.
    func animated(duration: Double = 0.3) -> some View {
        transformEnvironment(\.rouraIOImageConfiguration) { config in
            config.animated = duration > 0
            config.animationDuration = duration
        }
    }
}
