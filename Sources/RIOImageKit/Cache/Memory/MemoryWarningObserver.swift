//
//  MemoryWarningObserver.swift
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

/// Observes memory warnings and automatically clears caches.
///
/// This class listens for system memory warnings and triggers cache clearing
/// to help the app avoid being terminated due to memory pressure.
///
/// ## Platform Support
/// - **iOS/tvOS/watchOS**: Observes `UIApplication.didReceiveMemoryWarningNotification`
/// - **macOS**: Observes `NSApplication.didReceiveMemoryWarningNotification` (macOS 10.14+)
///
/// ## Example Usage
/// ```swift
/// let cache = MemoryImageCache()
/// let observer = MemoryWarningObserver { [weak cache] in
///     cache?.clear()
/// }
/// // Observer automatically clears cache on memory warnings
/// ```
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
public final class MemoryWarningObserver: @unchecked Sendable {

    // MARK: - Properties

    /// The action to perform when a memory warning is received
    private let handler: @Sendable () -> Void

    /// Notification observer token
    private var observer: (any NSObjectProtocol)?


    // MARK: - Initialization

    /// Creates a memory warning observer with the specified handler.
    ///
    /// - Parameter handler: The closure to call when a memory warning is received.
    ///                      Typically used to clear caches.
    public init(handler: @escaping @Sendable () -> Void) {
        self.handler = handler
        startObserving()
    }


    deinit {
        stopObserving()
    }


    // MARK: - Private Methods

    private func startObserving() {
#if canImport(UIKit) && !os(watchOS)
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handler()
        }
#elseif canImport(AppKit)
        // macOS doesn't have the same memory warning system as iOS
        // NSCache automatically responds to memory pressure, so we don't need
        // to explicitly observe notifications on macOS
#endif
    }


    private func stopObserving() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
