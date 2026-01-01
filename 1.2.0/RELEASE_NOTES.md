# RIOImageKit 1.2.0 - Unified Image API 🎨

We're excited to announce RIOImageKit 1.2.0, featuring a completely redesigned API that unifies image loading from all sources!

## 🎯 What's New

### RouraIOImage - One View for All Your Images

Say goodbye to managing different views for different image sources. `RouraIOImage` provides a single, consistent API for:

- 🌐 **Remote URLs** (with automatic caching)
- 📦 **Local Assets** (from asset catalog)
- 🔣 **SF Symbols** (system icons)

```swift
// Remote image (cached by default)
RouraIOImage(source: .remote(url))

// Local asset
RouraIOImage(source: .asset("logo"))

// SF Symbol
RouraIOImage(source: .symbol("heart.fill"))
```

### Modifier-Based Customization

Customize your images with a clean, SwiftUI-native modifier API:

```swift
RouraIOImage(source: .remote(url))
    .placeholder {
        Color.gray.opacity(0.2)
    }
    .onLoading { progress in
        ProgressView(value: progress)
    }
    .onError { error in
        Image(systemName: "exclamationmark.triangle")
    }
    .showProgress(true)
    .disableCache()  // For sensitive images
```

### Fine-Grained Cache Control

Control caching behavior per-view:

```swift
// Disable caching for sensitive images
RouraIOImage(source: .remote(privatePhotoURL))
    .disableCache()

// Use custom cache manager
RouraIOImage(source: .remote(url))
    .cache(manager: customCacheManager)

// Control animation
RouraIOImage(source: .remote(url))
    .animated(duration: 0.5)
```

## 📦 What's Included

### New Components

- **`RouraIOImage`** - Unified image view for all sources
- **`RouraIOImageConfiguration`** - Environment-based configuration system
- **Modifier API** - `.placeholder {}`, `.onLoading {}`, `.onError {}`, `.disableCache()`, `.cache(manager:)`, `.showProgress()`, `.animated(duration:)`

### Migration from CachedAsyncImage

`CachedAsyncImage` is now deprecated but continues to work. Migration is straightforward:

```swift
// Old:
CachedAsyncImage(url: imageURL)

// New:
RouraIOImage(source: .remote(imageURL))
```

See the [README](https://github.com/RouraIO/ios.roura.io.imagekit#migration-from-cachedasyncimage) for complete migration examples.

## 🔧 Breaking Changes

None! This is a backward-compatible release. `CachedAsyncImage` continues to work with deprecation warnings.

## 📚 Documentation

- Updated README with RouraIOImage examples
- Comprehensive migration guide
- Updated architecture diagram
- Inline documentation for all new APIs

## 🙏 Acknowledgments

Built with ❤️ using Swift 6 and modern concurrency patterns.

---

**Full Changelog**: https://github.com/RouraIO/ios.roura.io.imagekit/compare/1.1.0...1.2.0

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/RouraIO/ios.roura.io.imagekit.git", from: "1.2.0")
]
```

## Requirements

- iOS 18.0+ / macOS 15.0+ / watchOS 11.0+ / tvOS 18.0+ / visionOS 2.0+
- Swift 6.0+
- Xcode 16.0+
