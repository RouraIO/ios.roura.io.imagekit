//
//  ImageLoadingState.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Represents the current state of an image loading operation.
///
/// This enum provides a clear representation of all possible states during
/// image loading, enabling proper UI state management in SwiftUI views.
///
/// ## States
/// - **`idle`**: No loading has started yet
/// - **`loading(progress:)`**: Image is currently downloading with optional progress
/// - **`success(image:)`**: Image loaded successfully
/// - **`failure(error:)`**: Loading failed with an error
///
/// ## Example Usage
/// ```swift
/// @State private var loadingState: ImageLoadingState = .idle
///
/// switch loadingState {
/// case .idle:
///     Color.gray.opacity(0.2)
/// case .loading(let progress):
///     ProgressView(value: progress)
/// case .success(let image):
///     Image(platformImage: image)
/// case .failure(let error):
///     ErrorView(error: error)
/// }
/// ```
public enum ImageLoadingState: Equatable {

    /// No loading has started
    case idle


    /// Image is currently being downloaded
    ///
    /// - Parameter progress: Optional download progress (0.0 to 1.0)
    case loading(progress: Double?)


    /// Image loaded successfully
    ///
    /// - Parameter image: The loaded platform image
    case success(image: PlatformImage)


    /// Loading failed with an error
    ///
    /// - Parameter error: The error that occurred
    case failure(error: Error)


    // MARK: - Equatable Conformance

    public static func == (lhs: ImageLoadingState, rhs: ImageLoadingState) -> Bool {

        switch (lhs, rhs) {
        case (.idle, .idle): true
        case (.loading(let lProgress), .loading(let rProgress)): lProgress == rProgress
        case (.success(let lImage), .success(let rImage)): lImage === rImage
        case (.failure, .failure): true  // Simplified error comparison
        default: false
        }
    }
}


// MARK: - Convenience Properties

public extension ImageLoadingState {

    /// Whether the image is currently loading
    var isLoading: Bool {

        if case .loading = self {
            return true
        }
        return false
    }


    /// Whether the image loaded successfully
    var isSuccess: Bool {

        if case .success = self {
            return true
        }
        return false
    }


    /// Whether loading failed
    var isFailure: Bool {

        if case .failure = self {
            return true
        }
        return false
    }


    /// The loaded image if available
    var image: PlatformImage? {

        if case .success(let image) = self {
            return image
        }
        return nil
    }


    /// The error if loading failed
    var error: Error? {

        if case .failure(let error) = self {
            return error
        }
        return nil
    }


    /// The current loading progress if available
    var progress: Double? {

        if case .loading(let progress) = self {
            return progress
        }
        return nil
    }
}
