//
//  ImageModifiers.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

import SwiftUI

/// View modifiers for common image styling operations.
///
/// These modifiers provide convenient shortcuts for styling cached images
/// with common patterns like aspect ratios, corner radius, and scaling.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public extension View {

    /// Applies aspect-fill scaling to the image.
    ///
    /// The image will fill its container while maintaining its aspect ratio,
    /// clipping content that doesn't fit.
    ///
    /// ## Example
    /// ```swift
    /// CachedAsyncImage(url: imageURL)
    ///     .aspectFill()
    ///     .frame(width: 200, height: 200)
    ///     .clipped()
    /// ```
    ///
    /// - Returns: A view with aspect-fill scaling applied.
    func aspectFill() -> some View {

        self
            .scaledToFill()
    }


    /// Applies aspect-fit scaling to the image.
    ///
    /// The image will fit within its container while maintaining its aspect ratio,
    /// showing letterboxing if necessary.
    ///
    /// ## Example
    /// ```swift
    /// CachedAsyncImage(url: imageURL)
    ///     .aspectFit()
    ///     .frame(width: 200, height: 200)
    /// ```
    ///
    /// - Returns: A view with aspect-fit scaling applied.
    func aspectFit() -> some View {

        self
            .scaledToFit()
    }


    /// Applies a corner radius to the image.
    ///
    /// ## Example
    /// ```swift
    /// CachedAsyncImage(url: imageURL)
    ///     .roundedCorners(12)
    /// ```
    ///
    /// - Parameter radius: The corner radius to apply.
    /// - Returns: A view with rounded corners.
    func roundedCorners(_ radius: CGFloat) -> some View {

        self
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }


    /// Makes the image circular.
    ///
    /// Perfect for profile pictures and avatars.
    ///
    /// ## Example
    /// ```swift
    /// CachedAsyncImage(url: avatarURL)
    ///     .circular()
    ///     .frame(width: 60, height: 60)
    /// ```
    ///
    /// - Returns: A view with circular clipping applied.
    func circular() -> some View {

        self
            .clipShape(Circle())
    }


    /// Applies a shadow to the image.
    ///
    /// ## Example
    /// ```swift
    /// CachedAsyncImage(url: imageURL)
    ///     .imageShadow(radius: 8, opacity: 0.3)
    /// ```
    ///
    /// - Parameters:
    ///   - color: The shadow color. Defaults to black.
    ///   - radius: The blur radius of the shadow.
    ///   - x: The horizontal offset of the shadow.
    ///   - y: The vertical offset of the shadow.
    ///   - opacity: The opacity of the shadow.
    /// - Returns: A view with a shadow applied.
    func imageShadow(
        color: Color = .black,
        radius: CGFloat = 4,
        x: CGFloat = 0,
        y: CGFloat = 2,
        opacity: Double = 0.2
    ) -> some View {

        self
            .shadow(color: color.opacity(opacity), radius: radius, x: x, y: y)
    }
}


// MARK: - Image-Specific Modifiers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
public extension Image {

    /// Applies common resizable and content mode settings.
    ///
    /// ## Example
    /// ```swift
    /// Image(platformImage: image)
    ///     .resizable(contentMode: .fill)
    ///     .frame(width: 200, height: 200)
    /// ```
    ///
    /// - Parameter contentMode: The content mode to apply.
    /// - Returns: A resizable image with the specified content mode.
    func resizable(contentMode: ContentMode) -> some View {

        self
            .resizable()
            .aspectRatio(contentMode: contentMode)
    }


    /// Applies rendering mode and foreground style in one call.
    ///
    /// Useful for tinting SF Symbols or template images.
    ///
    /// ## Example
    /// ```swift
    /// Image(systemName: "heart.fill")
    ///     .styled(mode: .template, color: .red)
    /// ```
    ///
    /// - Parameters:
    ///   - mode: The rendering mode to apply.
    ///   - color: The foreground color/style to apply.
    /// - Returns: A styled image.
    func styled<S: ShapeStyle>(mode: Image.TemplateRenderingMode, color: S) -> some View {

        self
            .renderingMode(mode)
            .foregroundStyle(color)
    }
}
