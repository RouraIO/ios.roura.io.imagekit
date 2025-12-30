//
//  PlatformImage.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

#if canImport(AppKit)
import AppKit
/// Platform-specific image type (NSImage on macOS)
public typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
/// Platform-specific image type (UIImage on iOS/tvOS/watchOS/visionOS)
public typealias PlatformImage = UIImage
#endif

import Foundation


// MARK: - Cross-Platform Image Extensions

#if canImport(AppKit) && !canImport(UIKit)
extension NSImage {
    // NSImage already has init?(data:), so we don't need to add it


    /// Returns JPEG representation of the image.
    ///
    /// Provides UIKit-compatible API on macOS for seamless cross-platform usage.
    ///
    /// - Parameter compressionQuality: Quality of JPEG compression (0.0-1.0).
    /// - Returns: JPEG data, or nil if conversion fails.
    public func jpegData(compressionQuality: CGFloat) -> Data? {

        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmapImage.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        )
    }


    /// Returns PNG representation of the image.
    ///
    /// Provides UIKit-compatible API on macOS for seamless cross-platform usage.
    ///
    /// - Returns: PNG data, or nil if conversion fails.
    public func pngData() -> Data? {

        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmapImage.representation(using: .png, properties: [:])
    }
}
#endif
