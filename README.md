# RIOImageKit

A modern, lightweight, and production-ready Swift image caching library with two-tier caching, automatic retry logic, and seamless SwiftUI integration.

[![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20visionOS-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Features

- ✅ **Two-Tier Caching**: Fast memory cache + persistent disk cache with LRU eviction
- ✅ **SwiftUI Native**: Drop-in replacement for `AsyncImage` with caching
- ✅ **Automatic Retry**: Exponential backoff for transient network failures
- ✅ **Progress Tracking**: Real-time download progress updates
- ✅ **Request Deduplication**: Multiple requests for the same image share one download
- ✅ **Concurrency Limiting**: Prevents overwhelming the network with too many simultaneous downloads
- ✅ **Background Prefetching**: Preload images at low priority for smoother UX
- ✅ **Modern Swift**: Built with Swift 6, async/await, and Actors
- ✅ **Zero Dependencies**: No external dependencies, fully self-contained
- ✅ **Cross-Platform**: iOS 18+, macOS 15+, watchOS 11+, tvOS 18+, visionOS 2+
- ✅ **Testable**: Protocol-based design with mock implementations included
- ✅ **Well-Documented**: Comprehensive DocC documentation with examples

## Requirements

- iOS 18.0+ / macOS 15.0+ / watchOS 11.0+ / tvOS 18.0+ / visionOS 2.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add RIOImageKit to your project through Xcode:

1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/yourusername/RIOImageKit.git`
3. Select the version you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/RIOImageKit.git", from: "1.0.0")
]
```

## Quick Start

### Basic Usage (SwiftUI)

```swift
import RIOImageKit

struct ContentView: View {
    let imageURL = URL(string: "https://example.com/image.jpg")!

    var body: some View {
        CachedAsyncImage(url: imageURL)
            .frame(width: 300, height: 300)
    }
}
```

### With Placeholder and Error Handling

```swift
CachedAsyncImage(url: imageURL) { state in
    switch state {
    case .idle, .loading:
        ProgressView()
    case .success(let image):
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
    case .failure(let error):
        VStack {
            Image(systemName: "photo")
            Text("Failed to load")
                .font(.caption)
        }
    }
}
```

### With Progress Indicator

```swift
CachedAsyncImage(url: imageURL, showProgress: true)
    .frame(width: 300, height: 300)
```

## Usage

### Setting Up the Cache Manager

For most SwiftUI apps, set up the cache manager in your app's entry point:

```swift
import SwiftUI
import RIOImageKit

@main
struct MyApp: App {
    // Create cache manager as a singleton or state object
    @State private var cacheManager: ImageCacheManager = {
        let memoryCache = MemoryImageCache(maxMemoryCost: 50 * 1024 * 1024)  // 50MB
        let diskCache = try! DiskImageCache(
            maxSize: 100 * 1024 * 1024,  // 100MB
            maxAge: 7 * 24 * 60 * 60      // 7 days
        )
        let downloader = ImageDownloadService()

        return ImageCacheManager(
            imageLoadable: downloader,
            memoryCache: memoryCache,
            diskCache: diskCache
        )
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.imageCacheManager, cacheManager)
        }
    }
}
```

### Programmatic Image Loading

```swift
import RIOImageKit

class ImageViewModel {
    let cacheManager: ImageCacheManager

    func loadImage(from url: URL) async throws -> PlatformImage {
        // Check cache first, download if needed
        return try await cacheManager.loadImage(from: url)
    }

    func loadImageWithProgress(from url: URL) async throws -> PlatformImage {
        if let cached = await cacheManager.getImage(for: url) {
            return cached
        }

        // Download with progress tracking
        let image = try await cacheManager.imageLoadable.loadImage(from: url) { progress in
            print("Download progress: \(Int(progress * 100))%")
        }

        // Cache for future use
        await cacheManager.setImage(image, for: url)
        return image
    }
}
```

### Prefetching Images

```swift
// Prefetch images for better UX (e.g., before scrolling to them)
let upcomingURLs = [
    URL(string: "https://example.com/image1.jpg")!,
    URL(string: "https://example.com/image2.jpg")!,
    URL(string: "https://example.com/image3.jpg")!
]

await cacheManager.prefetchImages(urls: upcomingURLs)

// Cancel prefetch if user navigates away
cacheManager.cancelPrefetch(for: upcomingURLs)
```

### Cache Management

```swift
// Get cache size
let cacheSize = await cacheManager.getCacheSize()
print("Cache size: \(cacheSize / 1024 / 1024) MB")

// Remove specific image
await cacheManager.removeImage(for: url)

// Clear all cached images
await cacheManager.clearCache()
```

### Custom Configuration

```swift
// Custom memory cache size
let memoryCache = MemoryImageCache(maxMemoryCost: 100 * 1024 * 1024)  // 100MB

// Custom disk cache with longer expiration
let diskCache = try DiskImageCache(
    directory: "CustomImageCache",
    maxSize: 200 * 1024 * 1024,    // 200MB
    maxAge: 30 * 24 * 60 * 60,     // 30 days
    compressionQuality: 0.85        // Higher quality
)

// Custom download service with more retries
let downloader = ImageDownloadService(
    maxRetries: 5,
    retryDelay: 1.0
)

// Custom request headers
let requestConfig = RequestConfiguration(
    additionalHeaders: ["Authorization": "Bearer token"],
    timeout: 30.0
)
let authenticatedDownloader = ImageDownloadService(requestConfiguration: requestConfig)
```

## Architecture

RIOImageKit uses a clean, layered architecture:

```
┌─────────────────────────────────────────┐
│         SwiftUI Views                   │
│   (CachedAsyncImage, AnimatedImage)     │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│      ImageCacheManager                  │
│   (Coordinates caching & loading)       │
└─────────────────────────────────────────┘
         │                        │
         ▼                        ▼
┌──────────────────┐    ┌──────────────────┐
│  Memory Cache    │    │   Disk Cache     │
│  (Fast, ~1ms)    │    │ (Persistent)     │
└──────────────────┘    └──────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│     ImageDownloadService                │
│  (Network, retry, deduplication)        │
└─────────────────────────────────────────┘
```

### Cache Strategy

1. **Check memory cache** (~1ms) - Fastest
2. **Check disk cache** (~10-50ms) - Fast, persistent
3. **Download from network** (~100ms-2s) - Slowest
4. **Cache in both tiers** - For future access

### Key Components

- **`CachedAsyncImage`**: SwiftUI view for async image loading with caching
- **`ImageCacheManager`**: Central coordinator for two-tier caching
- **`MemoryImageCache`**: Fast, volatile in-memory cache
- **`DiskImageCache`**: Persistent disk cache with LRU eviction
- **`ImageDownloadService`**: Network downloader with retry and progress tracking
- **`ImageProcessor`**: Image transformation utilities (resize, crop, blur, etc.)

## Testing

RIOImageKit includes a `MockImageDownloadService` for easy testing:

```swift
import Testing
@testable import RIOImageKit

@Test
func testImageCaching() async throws {
    let mockDownloader = MockImageDownloadService()
    let memoryCache = MemoryImageCache()
    let diskCache = try DiskImageCache(directory: "TestCache")

    let manager = ImageCacheManager(
        imageLoadable: mockDownloader,
        memoryCache: memoryCache,
        diskCache: diskCache
    )

    let url = URL(string: "https://example.com/test.jpg")!
    let image = try await manager.loadImage(from: url)

    // Verify image was cached
    let cached = await manager.getImage(for: url)
    #expect(cached != nil)
}
```

## Performance

Typical performance characteristics:

- **Memory cache hit**: ~1ms
- **Disk cache hit**: ~10-50ms (I/O bound)
- **Network download**: 100ms-2s (network dependent)
- **Image decoding**: 5-50ms (size dependent, done in background)

Default cache sizes:
- **Memory**: 50 MB (~200-500 images)
- **Disk**: 100 MB (~400-1000 images)
- **Expiration**: 7 days

## Comparison with Alternatives

| Feature | RIOImageKit | SDWebImage | Kingfisher |
|---------|-------------|------------|------------|
| Swift-first | ✅ | ❌ (Obj-C) | ✅ |
| Swift 6 / Concurrency | ✅ | ❌ | Partial |
| Zero Dependencies | ✅ | ❌ | ✅ |
| SwiftUI Native | ✅ | Via wrapper | Via wrapper |
| Two-tier Cache | ✅ | ✅ | ✅ |
| Automatic Retry | ✅ | ✅ | ✅ |
| Request Deduplication | ✅ | ✅ | ✅ |
| Image Processing | Basic | Advanced | Advanced |
| Minimum iOS | 18 | 12 | 13 |

RIOImageKit is ideal if you want a modern, Swift-first solution with no dependencies and native SwiftUI support.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

RIOImageKit is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Author

Christopher J. Roura

## Acknowledgments

Inspired by the excellent work of:
- [SDWebImage](https://github.com/SDWebImage/SDWebImage)
- [Kingfisher](https://github.com/onevcat/Kingfisher)

Built with modern Swift to provide a lightweight, dependency-free alternative.
