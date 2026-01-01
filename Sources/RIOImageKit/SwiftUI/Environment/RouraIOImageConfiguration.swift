//
//  RouraIOImageConfiguration.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/31/25.
//

import SwiftUI

/// Configuration for customizing `RouraIOImage` behavior.
///
/// This configuration is stored in the SwiftUI environment and modified by
/// RouraIOImage modifiers like `.disableCache()`, `.placeholder {}`, etc.
///
/// ## Overview
/// You typically don't create this struct directly. Instead, use the provided
/// view modifiers to customize RouraIOImage behavior:
///
/// ```swift
/// RouraIOImage(source: .remote(url))
///     .disableCache()
///     .showProgress(true)
///     .placeholder {
///         Color.gray.opacity(0.2)
///     }
/// ```
///
/// - SeeAlso: ``RouraIOImage``
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public struct RouraIOImageConfiguration: Equatable, Sendable {

    // MARK: - Cache Configuration

    /// Whether caching is enabled for remote images.
    ///
    /// Defaults to `true`. Set to `false` using `.disableCache()` modifier.
    var cacheEnabled: Bool = true

    /// Custom cache manager to use instead of the environment's cache manager.
    ///
    /// Set using `.cache(manager:)` modifier.
    var customCacheManager: ImageCacheManager? = nil

    // MARK: - Behavior Configuration

    /// Whether to show download progress indicator.
    ///
    /// Defaults to `false`. Set to `true` using `.showProgress()` modifier.
    var showProgress: Bool = false

    /// Whether to animate image appearance with fade-in.
    ///
    /// Defaults to `true`. Controlled by `.animated(duration:)` modifier.
    var animated: Bool = true

    /// Duration of the fade-in animation in seconds.
    ///
    /// Defaults to `0.3`. Set using `.animated(duration:)` modifier.
    var animationDuration: Double = 0.3

    // MARK: - Custom Views

    /// Custom placeholder view to show before image loads.
    ///
    /// Set using `.placeholder { }` modifier.
    ///
    /// - Note: This property uses `nonisolated(unsafe)` because `AnyView` doesn't
    ///         conform to `Sendable`. Environment values are accessed on the main actor,
    ///         ensuring thread safety.
    nonisolated(unsafe) var customPlaceholder: AnyView? = nil

    /// Custom loading view to show while image is loading.
    ///
    /// Receives optional progress value (0.0 to 1.0).
    /// Set using `.onLoading { progress in }` modifier.
    ///
    /// - Note: This property uses `nonisolated(unsafe)` because `AnyView` doesn't
    ///         conform to `Sendable`. Environment values are accessed on the main actor,
    ///         ensuring thread safety.
    nonisolated(unsafe) var customLoadingView: (@Sendable (Double?) -> AnyView)? = nil

    /// Custom error view to show when image fails to load.
    ///
    /// Receives the error that occurred.
    /// Set using `.onError { error in }` modifier.
    ///
    /// - Note: This property uses `nonisolated(unsafe)` because `AnyView` doesn't
    ///         conform to `Sendable`. Environment values are accessed on the main actor,
    ///         ensuring thread safety.
    nonisolated(unsafe) var customErrorView: (@Sendable (any Error) -> AnyView)? = nil

    // MARK: - Equatable

    /// Compares two configurations for equality.
    ///
    /// Note: Custom view closures are not compared for equality.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.cacheEnabled == rhs.cacheEnabled &&
        lhs.showProgress == rhs.showProgress &&
        lhs.animated == rhs.animated &&
        lhs.animationDuration == rhs.animationDuration
        // Skip closure comparisons (customPlaceholder, customLoadingView, customErrorView)
        // Skip customCacheManager comparison as ImageCacheManager is a class
    }
}


// MARK: - Environment Key

/// Environment key for RouraIOImage configuration.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
struct RouraIOImageConfigurationKey: EnvironmentKey {
    static let defaultValue = RouraIOImageConfiguration()
}


// MARK: - Environment Values Extension

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
extension EnvironmentValues {

    /// The current RouraIOImage configuration in the environment.
    ///
    /// Modifiers like `.disableCache()`, `.placeholder {}`, etc. modify this value
    /// to customize RouraIOImage behavior.
    ///
    /// ## Example
    /// ```swift
    /// struct MyView: View {
    ///     @Environment(\.rouraIOImageConfiguration) var config
    ///
    ///     var body: some View {
    ///         Text("Caching enabled: \(config.cacheEnabled)")
    ///     }
    /// }
    /// ```
    var rouraIOImageConfiguration: RouraIOImageConfiguration {
        get { self[RouraIOImageConfigurationKey.self] }
        set { self[RouraIOImageConfigurationKey.self] = newValue }
    }
}
