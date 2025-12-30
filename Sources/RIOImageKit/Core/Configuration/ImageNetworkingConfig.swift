//
//  ImageNetworkingConfig.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/30/25.
//

import Foundation

/// Global configuration constants for networking operations.
///
/// This enum provides centralized configuration for network client behavior,
/// retry logic, timeouts, and caching strategies across the application.
///
/// ## Overview
/// Configuration is organized into logical groups:
/// - **API**: Request behavior (timeout, retries, backoff)
/// - **URLCache**: Memory and disk cache sizes for HTTP responses
///
/// ## Design Philosophy
/// Default values are chosen for optimal balance between:
/// - **Performance**: Fast response times with reasonable caching
/// - **Reliability**: Multiple retries with exponential backoff
/// - **Resource usage**: Conservative memory/disk allocation
///
/// ## Customization
/// While these are static defaults, you can override them when initializing components:
/// ```swift
/// // Using custom timeout and retry configuration
/// let client = NetworkClient(
///     maxRetries: 5,              // Override default 3
///     retryDelay: 1.0,            // Override default 0.5s
///     timeout: 60                 // Override default 30s
/// )
///
/// // Using custom cache configuration
/// let config = URLSessionConfiguration.default
/// config.urlCache = URLCache(
///     memoryCapacity: 20 * 1024 * 1024,  // 20MB instead of default 10MB
///     diskCapacity: 100 * 1024 * 1024    // 100MB instead of default 50MB
/// )
/// ```
///
/// ## Performance Tuning
/// Adjust these values based on your app's needs:
/// - **Low memory devices**: Reduce cache capacities
/// - **High latency networks**: Increase timeout and retry delay
/// - **Mission-critical operations**: Increase max retries
/// - **Background operations**: Use longer timeouts
///
/// - Note: Changes to these values require recompilation. For runtime configuration,
///         pass custom values to initializers.
/// - SeeAlso: ``NetworkClient`` for using these configuration values.
public enum ImageNetworkingConfig {

    /// Configuration for API request behavior and retry logic.
    ///
    /// These settings control how the ``NetworkClient`` handles network requests,
    /// including timeouts, retry attempts, and backoff strategies.
    ///
    /// ## Default Values
    /// - **Timeout**: 30 seconds (balances user patience with slow networks)
    /// - **Max Retries**: 3 attempts (reduces failure rate without excessive delays)
    /// - **Retry Delay**: 0.5 seconds initial (doubles each retry for exponential backoff)
    ///
    /// ## Retry Timeline Example
    /// With default settings, a failing request will retry:
    /// 1. Initial attempt: 0s
    /// 2. First retry: +0.5s (total: 0.5s)
    /// 3. Second retry: +1.0s (total: 1.5s)
    /// 4. Third retry: +2.0s (total: 3.5s)
    /// 5. Give up: Total time ~3.5s (excluding request durations)
    ///
    /// ## Usage Example
    /// ```swift
    /// // Using default configuration
    /// let client = NetworkClient(
    ///     maxRetries: NetworkingConfig.API.maxRetries,
    ///     retryDelay: NetworkingConfig.API.retryDelay,
    ///     timeout: NetworkingConfig.API.timeout
    /// )
    ///
    /// // Or simply use the defaults
    /// let client = NetworkClient() // Uses these values implicitly
    /// ```
    public enum API {

        /// Maximum time (in seconds) to wait for a request to complete.
        ///
        /// Requests exceeding this duration will fail with a timeout error.
        /// Default: **30 seconds**
        ///
        /// - Note: This applies to individual request attempts, not including retries.
        public static let timeout: TimeInterval = 30


        /// Maximum number of retry attempts for failed requests.
        ///
        /// Requests will be retried up to this many times for transient failures
        /// (network errors, timeouts, 5xx server errors, 408/429 status codes).
        /// Default: **3 retries**
        ///
        /// - Note: Client errors (4xx except 408/429) are not retried as they indicate
        ///         permanent failures that won't be resolved by retrying.
        public static let maxRetries = 3


        /// Initial delay (in seconds) between retry attempts.
        ///
        /// Uses exponential backoff: each retry doubles the delay.
        /// Default: **0.5 seconds**
        ///
        /// With default settings:
        /// - 1st retry: 0.5s delay
        /// - 2nd retry: 1.0s delay
        /// - 3rd retry: 2.0s delay
        ///
        /// - Note: Exponential backoff reduces server load and improves success rates
        ///         for rate-limited or temporarily overloaded services.
        public static let retryDelay: TimeInterval = 0.5
    }


    /// Configuration for HTTP response caching.
    ///
    /// These settings control the size of the in-memory and on-disk caches used
    /// by `URLSession` for storing HTTP responses. Proper caching improves
    /// performance and reduces network usage.
    ///
    /// ## Cache Strategy
    /// - **Memory cache**: Fast access, volatile (cleared on app termination)
    /// - **Disk cache**: Persistent across launches, slower than memory
    ///
    /// ## Default Values
    /// - **Memory**: 10 MB (stores ~50-100 typical API responses)
    /// - **Disk**: 50 MB (stores ~250-500 typical API responses)
    ///
    /// ## Cache Behavior
    /// Caching respects HTTP headers (`Cache-Control`, `Expires`, `ETag`).
    /// Responses are cached only if the server permits it via headers.
    ///
    /// ## Usage Example
    /// ```swift
    /// // Using default cache configuration
    /// let config = URLSessionConfiguration.default
    /// config.urlCache = URLCache(
    ///     memoryCapacity: NetworkingConfig.URLCache.memoryCapacity,
    ///     diskCapacity: NetworkingConfig.URLCache.diskCapacity
    /// )
    ///
    /// // Custom cache for high-traffic apps
    /// let largeCache = URLCache(
    ///     memoryCapacity: 50 * 1024 * 1024,  // 50MB
    ///     diskCapacity: 200 * 1024 * 1024    // 200MB
    /// )
    /// ```
    ///
    /// - Important: Cache sizes are in bytes. Use multiplications for clarity
    ///              (e.g., `10 * 1024 * 1024` for 10MB).
    public enum URLCache {

        /// Maximum memory (in bytes) for caching HTTP responses.
        ///
        /// Memory cache provides fastest access but is cleared when the app terminates.
        /// Default: **10 MB** (10,485,760 bytes)
        ///
        /// ## Tuning Guidelines
        /// - iOS devices with 2GB+ RAM: 10-20 MB safe
        /// - Memory-constrained devices: 5 MB or less
        /// - High-traffic apps: 20-50 MB
        ///
        /// - Note: iOS may purge memory cache under memory pressure.
        public static let memoryCapacity = 10 * 1024 * 1024 // 10MB


        /// Maximum disk space (in bytes) for caching HTTP responses.
        ///
        /// Disk cache persists across app launches but is slower to access than memory.
        /// Default: **50 MB** (52,428,800 bytes)
        ///
        /// ## Tuning Guidelines
        /// - Most apps: 50-100 MB safe
        /// - Media-heavy apps: 100-500 MB
        /// - Limited storage devices: 25 MB or less
        ///
        /// - Note: iOS may purge disk cache when storage is low.
        public static let diskCapacity = 50 * 1024 * 1024   // 50MB
    }
}
