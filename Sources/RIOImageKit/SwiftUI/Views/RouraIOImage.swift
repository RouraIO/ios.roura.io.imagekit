//
//  RouraIOImage.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/31/25.
//

import SwiftUI

/// A unified SwiftUI view for displaying images from any source.
///
/// `RouraIOImage` provides a single, consistent API for loading images from
/// remote URLs, local assets, or SF Symbols, with intelligent caching and
/// extensive customization via modifiers.
///
/// ## Basic Usage
///
/// ### Remote Images (with automatic caching)
/// ```swift
/// RouraIOImage(source: .remote(url))
/// ```
///
/// ### Local Assets
/// ```swift
/// RouraIOImage(source: .asset("logo"))
/// ```
///
/// ### SF Symbols
/// ```swift
/// RouraIOImage(source: .symbol("heart.fill"))
/// ```
///
/// ## Customization with Modifiers
///
/// ```swift
/// RouraIOImage(source: .remote(url))
///     .placeholder {
///         Color.gray.opacity(0.2)
///     }
///     .onLoading { progress in
///         if let progress = progress {
///             ProgressView(value: progress)
///         } else {
///             ProgressView()
///         }
///     }
///     .onError { error in
///         VStack {
///             Image(systemName: "exclamationmark.triangle")
///             Text("Failed to load")
///         }
///     }
///     .showProgress(true)
///     .aspectFill()
///     .frame(width: 300, height: 200)
///     .roundedCorners(12)
/// ```
///
/// ## Cache Configuration
///
/// ```swift
/// // Disable caching for sensitive images
/// RouraIOImage(source: .remote(privateURL))
///     .disableCache()
///
/// // Use custom cache manager
/// let customCache = ImageCacheManager(...)
/// RouraIOImage(source: .remote(url))
///     .cache(manager: customCache)
/// ```
///
/// ## Features
/// - Unified API for all image sources
/// - Automatic two-tier caching (memory + disk) for remote images
/// - Modifier-based customization
/// - Progress tracking for downloads
/// - Fade-in animation
/// - Error handling
/// - Cancellation on view disappear
///
/// - SeeAlso: ``ImageSource``
/// - SeeAlso: ``ImageCacheManager``
/// - SeeAlso: ``CachedAsyncImage``
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public struct RouraIOImage<Content: View, Placeholder: View>: View {

    // MARK: - Properties

    /// The source of the image to display.
    private let source: ImageSource

    /// Content builder for custom rendering based on loading state.
    private let content: (ImageLoadingState) -> Content

    /// Placeholder builder for the view shown before image loads.
    private let placeholder: () -> Placeholder

    // MARK: - Environment

    /// The image cache manager from environment.
    @Environment(\.imageCacheManager) private var cacheManager

    /// The configuration for customizing behavior via modifiers.
    @Environment(\.rouraIOImageConfiguration) private var configuration

    // MARK: - State

    /// Current loading state (only used for remote images).
    @State private var loadingState: ImageLoadingState = .idle

    /// Loading task (only used for remote images).
    @State private var loadingTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Creates a RouraIOImage with full customization.
    ///
    /// - Parameters:
    ///   - source: The source of the image (remote URL, asset, or symbol).
    ///   - content: A view builder that creates the view based on loading state.
    ///   - placeholder: A view builder for the placeholder shown before loading.
    public init(
        source: ImageSource,
        @ViewBuilder content: @escaping (ImageLoadingState) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.source = source
        self.content = content
        self.placeholder = placeholder
    }

    // MARK: - Body

    public var body: some View {
        Group {
            switch source {
            case .remote(let url):
                remoteImageView(url: url)
            case .asset(let name):
                assetImageView(name: name)
            case .symbol(let name):
                symbolImageView(name: name)
            }
        }
    }

    // MARK: - Private View Builders

    /// View for remote images with caching and loading states.
    @ViewBuilder
    private func remoteImageView(url: URL) -> some View {
        Group {
            switch loadingState {
            case .idle:
                placeholderView()
                    .transition(.opacity)

            case .loading(let progress):
                if let image = loadingState.image {
                    imageView(for: image)
                } else {
                    placeholderView()
                }
                if configuration.showProgress, let progress = progress {
                    loadingView(progress: progress)
                }

            case .success(let image):
                imageView(for: image)

            case .failure(let error):
                errorView(for: error)
                    .transition(.opacity)
            }
        }
        .onAppear {
            loadImage(from: url)
        }
        .onDisappear {
            cancelLoading()
        }
    }

    /// View for local asset images.
    @ViewBuilder
    private func assetImageView(name: String) -> some View {
        Image(name)
            .resizable()
    }

    /// View for SF Symbol images.
    @ViewBuilder
    private func symbolImageView(name: String) -> some View {
        Image(systemName: name)
            .resizable()
    }

    // MARK: - Helper View Builders

    /// Returns the placeholder view (custom or default).
    @ViewBuilder
    private func placeholderView() -> some View {
        if let customPlaceholder = configuration.customPlaceholder {
            customPlaceholder
        } else {
            placeholder()
        }
    }

    /// Returns the loading view with progress (custom or default).
    @ViewBuilder
    private func loadingView(progress: Double) -> some View {
        if let customLoadingView = configuration.customLoadingView {
            customLoadingView(progress)
        } else {
            ProgressView(value: progress)
        }
    }

    /// Returns the error view (custom or default).
    @ViewBuilder
    private func errorView(for error: any Error) -> some View {
        if let customErrorView = configuration.customErrorView {
            customErrorView(error)
        } else {
            content(.failure(error: error))
        }
    }

    /// Returns the success image view with animation.
    private func imageView(for platformImage: PlatformImage) -> some View {
        content(.success(image: platformImage))
            .transition(
                configuration.animated
                    ? .opacity.animation(.easeInOut(duration: configuration.animationDuration))
                    : .identity
            )
    }

    // MARK: - Private Methods

    /// The effective cache manager (custom or environment).
    private var effectiveCacheManager: ImageCacheManager {
        configuration.customCacheManager ?? cacheManager
    }

    /// Loads the image from the remote URL.
    private func loadImage(from url: URL) {
        loadingTask = Task {
            // If caching is disabled, bypass cache and download directly
            if !configuration.cacheEnabled {
                await loadImageWithoutCache(from: url)
                return
            }

            // Check cache first
            if let cachedImage = await effectiveCacheManager.getImage(for: url) {
                loadingState = .success(image: cachedImage)
                return
            }

            // Start loading
            loadingState = .loading(progress: configuration.showProgress ? 0.0 : nil)

            do {
                let image: PlatformImage
                if configuration.showProgress {
                    image = try await effectiveCacheManager.imageLoadable.loadImage(from: url) { progress in
                        Task { @MainActor in
                            if case .loading = loadingState {
                                loadingState = .loading(progress: progress)
                            }
                        }
                    }
                } else {
                    image = try await effectiveCacheManager.imageLoadable.loadImage(from: url)
                }

                // Cache the image
                await effectiveCacheManager.setImage(image, for: url)

                // Update state
                loadingState = .success(image: image)

            } catch {
                loadingState = .failure(error: error)
            }
        }
    }

    /// Loads the image without caching.
    private func loadImageWithoutCache(from url: URL) async {
        loadingState = .loading(progress: configuration.showProgress ? 0.0 : nil)

        do {
            let image: PlatformImage
            if configuration.showProgress {
                image = try await effectiveCacheManager.imageLoadable.loadImage(from: url) { progress in
                    Task { @MainActor in
                        if case .loading = loadingState {
                            loadingState = .loading(progress: progress)
                        }
                    }
                }
            } else {
                image = try await effectiveCacheManager.imageLoadable.loadImage(from: url)
            }

            // Update state (don't cache)
            loadingState = .success(image: image)

        } catch {
            loadingState = .failure(error: error)
        }
    }

    /// Cancels the loading task.
    private func cancelLoading() {
        loadingTask?.cancel()
        loadingTask = nil
    }
}


// MARK: - Convenience Initializers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public extension RouraIOImage where Content == _ConditionalContent<Image, EmptyView>, Placeholder == Color {

    /// Creates a RouraIOImage with default rendering.
    ///
    /// Displays the image when loaded, a gray placeholder while loading,
    /// and shows nothing on error.
    ///
    /// ## Example
    /// ```swift
    /// RouraIOImage(source: .remote(url))
    /// RouraIOImage(source: .asset("logo"))
    /// RouraIOImage(source: .symbol("heart.fill"))
    /// ```
    ///
    /// - Parameter source: The source of the image to display.
    init(source: ImageSource) {
        self.init(
            source: source,
            content: { state in
                if let image = state.image {
                    #if canImport(UIKit)
                    Image(uiImage: image)
                        .resizable()
                    #elseif canImport(AppKit)
                    Image(nsImage: image)
                        .resizable()
                    #endif
                } else {
                    EmptyView()
                }
            },
            placeholder: {
                Color.gray.opacity(0.2)
            }
        )
    }
}


@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public extension RouraIOImage where Placeholder == Color {

    /// Creates a RouraIOImage with custom content rendering.
    ///
    /// ## Example
    /// ```swift
    /// RouraIOImage(source: .remote(url)) { state in
    ///     switch state {
    ///     case .success(let image):
    ///         Image(platformImage: image)
    ///             .resizable()
    ///             .aspectRatio(contentMode: .fill)
    ///     case .failure:
    ///         Image(systemName: "xmark.circle")
    ///             .foregroundColor(.red)
    ///     default:
    ///         ProgressView()
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - source: The source of the image to display.
    ///   - content: A view builder for rendering based on loading state.
    init(
        source: ImageSource,
        @ViewBuilder content: @escaping (ImageLoadingState) -> Content
    ) {
        self.init(
            source: source,
            content: content,
            placeholder: {
                Color.gray.opacity(0.2)
            }
        )
    }
}
