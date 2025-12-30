//
//  ImageSource.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Represents different sources from which images can be loaded.
///
/// This enum provides a unified way to specify image sources across your application,
/// supporting remote URLs, local assets, and SF Symbols.
///
/// ## Overview
/// `ImageSource` enables consistent image loading regardless of origin:
/// - **Remote**: Downloaded from network (with automatic caching)
/// - **Asset**: Loaded from asset catalog (bundled with app)
/// - **Symbol**: SF Symbols from the system
///
/// ## Design Benefits
/// - **Type safety**: Compile-time checking of source types
/// - **Unified interface**: Single type for all image sources
/// - **SwiftUI integration**: Works seamlessly with custom image views
/// - **Equatable**: Can compare and cache sources efficiently
///
/// ## Example Usage
/// ```swift
/// // Remote image with URL
/// let profileImage = ImageSource.remote(profileURL)
///
/// // Asset catalog image
/// let placeholderImage = ImageSource.asset("placeholder")
///
/// // SF Symbol
/// let iconImage = ImageSource.symbol("person.circle.fill")
///
/// // Conditional source based on availability
/// let userAvatar: ImageSource
/// if let avatarURL = user.avatarURL {
///     userAvatar = .remote(avatarURL)
/// } else {
///     userAvatar = .asset("default-avatar")
/// }
///
/// // Using convenience initializer
/// let maybeImage = ImageSource(urlString: user.profileImageURL)
/// ```
///
/// ## SwiftUI Integration
/// ```swift
/// struct AsyncImageView: View {
///     let source: ImageSource
///
///     var body: some View {
///         switch source {
///         case .remote(let url):
///             CachedAsyncImage(url: url)
///         case .asset(let name):
///             Image(name)
///         case .symbol(let name):
///             Image(systemName: name)
///         }
///     }
/// }
/// ```
///
/// - SeeAlso: ``ImageCacheManager`` for loading remote images with caching.
/// - SeeAlso: ``ImageDownloadService`` for downloading remote images.
public enum ImageSource: Equatable, Sendable {

    /// Remote image from a URL with automatic caching.
    ///
    /// Use this for images downloaded from the internet. The image will be
    /// automatically cached by ``ImageCacheManager`` for improved performance.
    ///
    /// **Performance Characteristics:**
    /// - First load: Network download (~100ms-2s depending on connection)
    /// - Subsequent loads: Memory cache hit (~1ms) or disk cache hit (~10-50ms)
    ///
    /// **Example:**
    /// ```swift
    /// let profilePicture = ImageSource.remote(
    ///     URL(string: "https://example.com/avatar.jpg")!
    /// )
    ///
    /// // Loading the image
    /// let image = try await imageCacheManager.loadImage(from: url)
    /// ```
    ///
    /// - Parameter URL: The remote URL of the image to load.
    case remote(URL)

    /// Local image from the app's asset catalog.
    ///
    /// Use this for images bundled with your application in the asset catalog.
    /// These images load instantly as they're part of your app bundle.
    ///
    /// **Benefits:**
    /// - Instant loading (no network request)
    /// - Automatic @2x/@3x resolution handling
    /// - Dark mode variants support
    /// - Vector PDF support
    ///
    /// **Example:**
    /// ```swift
    /// let placeholderImage = ImageSource.asset("placeholder")
    /// let logo = ImageSource.asset("app-logo")
    ///
    /// // In SwiftUI
    /// Image(assetName) // Automatically selects correct resolution
    /// ```
    ///
    /// - Parameter String: The name of the image in the asset catalog.
    case asset(String)

    /// SF Symbol by name.
    ///
    /// Use this for Apple's built-in SF Symbols, which provide thousands of
    /// vector icons that automatically adapt to font size, weight, and color.
    ///
    /// **Benefits:**
    /// - 5000+ built-in symbols
    /// - Automatic dynamic type scaling
    /// - Multicolor and hierarchical rendering
    /// - Consistent with iOS design language
    ///
    /// **Example:**
    /// ```swift
    /// let personIcon = ImageSource.symbol("person.circle.fill")
    /// let heartIcon = ImageSource.symbol("heart.fill")
    /// let settingsIcon = ImageSource.symbol("gear")
    ///
    /// // In SwiftUI with customization
    /// Image(systemName: symbolName)
    ///     .font(.largeTitle)
    ///     .foregroundStyle(.blue)
    /// ```
    ///
    /// - Parameter String: The name of the SF Symbol.
    /// - Important: Ensure the symbol name exists in the current iOS version.
    ///              Use SF Symbols app to browse available symbols.
    case symbol(String)
}


// MARK: - Convenience Initializers

public extension ImageSource {

    /// Creates a remote image source from an optional URL.
    ///
    /// This failable initializer returns `nil` if the URL is `nil`,
    /// providing a convenient way to handle optional URLs.
    ///
    /// ## Example Usage
    /// ```swift
    /// struct User {
    ///     let avatarURL: URL?
    /// }
    ///
    /// let user = User(avatarURL: nil)
    ///
    /// // Returns nil if URL is nil
    /// if let avatarSource = ImageSource(url: user.avatarURL) {
    ///     // Load avatar
    /// } else {
    ///     // Use default avatar
    /// }
    ///
    /// // Or use nil coalescing
    /// let imageSource = ImageSource(url: user.avatarURL) ?? .asset("default-avatar")
    /// ```
    ///
    /// - Parameter url: An optional URL for the remote image.
    /// - Returns: A `.remote` image source if the URL is non-nil, otherwise `nil`.
    init?(url: URL?) {
        guard let url else { return nil }
        self = .remote(url)
    }


    /// Creates a remote image source from an optional URL string.
    ///
    /// This failable initializer parses a URL string and returns `nil` if:
    /// - The string is `nil`
    /// - The string cannot be parsed as a valid URL
    ///
    /// ## Example Usage
    /// ```swift
    /// struct APIResponse: Decodable {
    ///     let imageURL: String?
    /// }
    ///
    /// let response = try decoder.decode(APIResponse.self, from: data)
    ///
    /// // Safely create image source from API response
    /// if let imageSource = ImageSource(urlString: response.imageURL) {
    ///     // Valid URL, load image
    ///     await loadImage(source: imageSource)
    /// } else {
    ///     // Invalid or nil URL, show placeholder
    ///     showPlaceholder()
    /// }
    ///
    /// // Or use nil coalescing for default
    /// let source = ImageSource(urlString: response.imageURL) ?? .symbol("photo")
    /// ```
    ///
    /// - Parameter urlString: An optional URL string to parse.
    /// - Returns: A `.remote` image source if parsing succeeds, otherwise `nil`.
    init?(urlString: String?) {
        guard let urlString, let url = URL(string: urlString) else { return nil }
        self = .remote(url)
    }
}
