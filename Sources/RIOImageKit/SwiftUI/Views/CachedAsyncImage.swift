//
//  CachedAsyncImage.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import SwiftUI

/// A SwiftUI view that asynchronously loads and caches images from a URL.
///
/// `CachedAsyncImage` provides a drop-in replacement for SwiftUI's `AsyncImage`
/// with built-in two-tier caching (memory + disk), progress tracking, and
/// extensive customization options.
///
/// ## Basic Usage
/// ```swift
/// CachedAsyncImage(url: imageURL)
/// ```
///
/// ## With Placeholder
/// ```swift
/// CachedAsyncImage(url: imageURL) { phase in
///     switch phase {
///     case .idle, .loading:
///         ProgressView()
///     case .success(let image):
///         image.resizable().aspectRatio(contentMode: .fit)
///     case .failure:
///         Image(systemName: "photo")
///     }
/// }
/// ```
///
/// ## With Progress
/// ```swift
/// CachedAsyncImage(url: imageURL, showProgress: true)
/// ```
///
/// ## Features
/// - Two-tier caching (memory + disk)
/// - Automatic retry on failure
/// - Progress tracking
/// - Fade-in animation
/// - Placeholder support
/// - Error handling
/// - Cancellation on view disappear
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public struct CachedAsyncImage<Content: View, Placeholder: View>: View {

    // MARK: - Properties

    /// The URL of the image to load
    private let url: URL?


    /// The image cache manager
    @Environment(\.imageCacheManager) private var cacheManager


    /// Whether to show download progress
    private let showProgress: Bool


    /// Whether to animate the image appearance
    private let animated: Bool


    /// Animation duration
    private let animationDuration: Double


    /// Content builder for custom rendering
    private let content: (ImageLoadingState) -> Content


    /// Placeholder builder
    private let placeholder: () -> Placeholder


    /// Current loading state
    @State private var loadingState: ImageLoadingState = .idle


    /// Loading task
    @State private var loadingTask: Task<Void, Never>?


    // MARK: - Initialization

    /// Creates a cached async image with full customization.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - showProgress: Whether to track and display download progress.
    ///   - animated: Whether to fade in the image when loaded.
    ///   - animationDuration: Duration of the fade-in animation.
    ///   - content: A view builder that creates the view based on loading state.
    ///   - placeholder: A view builder for the placeholder.
    public init(
        url: URL?,
        showProgress: Bool = false,
        animated: Bool = true,
        animationDuration: Double = 0.3,
        @ViewBuilder content: @escaping (ImageLoadingState) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.showProgress = showProgress
        self.animated = animated
        self.animationDuration = animationDuration
        self.content = content
        self.placeholder = placeholder
    }


    // MARK: - Body

    public var body: some View {

        Group {
            switch loadingState {
            case .idle:
                placeholder()
                    .transition(.opacity)

            case .loading(let progress):
                if let image = loadingState.image {
                    imageView(for: image)
                } else {
                    placeholder()
                }
                if showProgress, let progress = progress {
                    ProgressView(value: progress)
                }

            case .success(let image):
                imageView(for: image)

            case .failure:
                content(loadingState)
                    .transition(.opacity)
            }
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            cancelLoading()
        }
    }


    // MARK: - Private Methods

    private func imageView(for platformImage: PlatformImage) -> some View {

        content(.success(image: platformImage))
            .transition(
                animated
                    ? .opacity.animation(.easeInOut(duration: animationDuration))
                    : .identity
            )
    }


    private func loadImage() {

        guard let url = url else {
            loadingState = .idle
            return
        }

        loadingTask = Task {
            // Check cache first
            if let cachedImage = await cacheManager.getImage(for: url) {
                loadingState = .success(image: cachedImage)
                return
            }

            // Start loading
            loadingState = .loading(progress: showProgress ? 0.0 : nil)

            do {
                let image: PlatformImage
                if showProgress {
                    image = try await cacheManager.imageLoadable.loadImage(from: url) { progress in
                        Task { @MainActor in
                            if case .loading = loadingState {
                                loadingState = .loading(progress: progress)
                            }
                        }
                    }
                } else {
                    image = try await cacheManager.imageLoadable.loadImage(from: url)
                }

                // Cache the image
                await cacheManager.setImage(image, for: url)

                // Update state
                loadingState = .success(image: image)

            } catch {
                loadingState = .failure(error: error)
            }
        }
    }


    private func cancelLoading() {

        loadingTask?.cancel()
        loadingTask = nil
    }
}


// MARK: - Convenience Initializers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public extension CachedAsyncImage where Content == _ConditionalContent<Image, EmptyView>, Placeholder == Color {

    /// Creates a cached async image with default rendering.
    ///
    /// Displays the image when loaded, a gray placeholder while loading,
    /// and shows nothing on error.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - showProgress: Whether to show download progress.
    ///   - animated: Whether to fade in the image.
    init(
        url: URL?,
        showProgress: Bool = false,
        animated: Bool = true
    ) {
        self.init(
            url: url,
            showProgress: showProgress,
            animated: animated,
            animationDuration: 0.3,
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
public extension CachedAsyncImage where Placeholder == Color {

    /// Creates a cached async image with custom content rendering.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - showProgress: Whether to show download progress.
    ///   - animated: Whether to fade in the image.
    ///   - content: A view builder for rendering based on loading state.
    init(
        url: URL?,
        showProgress: Bool = false,
        animated: Bool = true,
        @ViewBuilder content: @escaping (ImageLoadingState) -> Content
    ) {
        self.init(
            url: url,
            showProgress: showProgress,
            animated: animated,
            animationDuration: 0.3,
            content: content,
            placeholder: {
                Color.gray.opacity(0.2)
            }
        )
    }
}
