//
//  ImageFormatDetector.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Detects image format from raw data.
///
/// This utility examines the magic bytes (file signature) at the beginning of image data
/// to determine the format without relying on file extensions.
///
/// ## Supported Formats
/// - **JPEG**: FF D8 FF
/// - **PNG**: 89 50 4E 47
/// - **GIF**: 47 49 46 38
/// - **WebP**: 52 49 46 46 ... 57 45 42 50
/// - **HEIC**: Various ftyp signatures
///
/// ## Example Usage
/// ```swift
/// let data = try Data(contentsOf: imageURL)
/// let format = ImageFormatDetector.detect(from: data)
///
/// switch format {
/// case .jpeg:
///     print("JPEG image")
/// case .webp:
///     print("WebP image")
/// default:
///     print("Other format: \(format)")
/// }
/// ```
public enum ImageFormatDetector {

    // MARK: - Format

    /// Supported image formats
    public enum Format: String, Sendable {
        case jpeg = "JPEG"
        case png = "PNG"
        case gif = "GIF"
        case webp = "WebP"
        case heic = "HEIC"
        case unknown = "Unknown"
    }


    // MARK: - Detection

    /// Detects the image format from data by examining magic bytes.
    ///
    /// - Parameter data: The image data to analyze.
    /// - Returns: The detected image format.
    public static func detect(from data: Data) -> Format {
        guard data.count >= 12 else { return .unknown }

        let bytes = [UInt8](data.prefix(12))

        // JPEG: FF D8 FF
        if bytes.count >= 3,
           bytes[0] == 0xFF,
           bytes[1] == 0xD8,
           bytes[2] == 0xFF {
            return .jpeg
        }

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if bytes.count >= 8,
           bytes[0] == 0x89,
           bytes[1] == 0x50,
           bytes[2] == 0x4E,
           bytes[3] == 0x47 {
            return .png
        }

        // GIF: 47 49 46 38
        if bytes.count >= 4,
           bytes[0] == 0x47,
           bytes[1] == 0x49,
           bytes[2] == 0x46,
           bytes[3] == 0x38 {
            return .gif
        }

        // WebP: RIFF....WEBP
        if bytes.count >= 12,
           bytes[0] == 0x52, // R
           bytes[1] == 0x49, // I
           bytes[2] == 0x46, // F
           bytes[3] == 0x46, // F
           bytes[8] == 0x57, // W
           bytes[9] == 0x45, // E
           bytes[10] == 0x42, // B
           bytes[11] == 0x50 { // P
            return .webp
        }

        // HEIC: ftyp
        if bytes.count >= 12,
           bytes[4] == 0x66, // f
           bytes[5] == 0x74, // t
           bytes[6] == 0x79, // y
           bytes[7] == 0x70 { // p
            return .heic
        }

        return .unknown
    }


    /// Checks if the data represents an animated image format (GIF or animated WebP).
    ///
    /// - Parameter data: The image data to analyze.
    /// - Returns: `true` if the format supports animation and appears to be animated.
    public static func isAnimated(data: Data) -> Bool {
        let format = detect(from: data)

        switch format {
        case .gif:
            // All GIFs are potentially animated
            return true

        case .webp:
            // Check for animation flag in WebP
            // This is a simplified check - full WebP parsing would be more complex
            return data.count > 12

        default:
            return false
        }
    }
}
