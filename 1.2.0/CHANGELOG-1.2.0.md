## [1.2.0] - 2026-01-01

**Unified Image API** 🎨

### Added

- **`RouraIOImage`**: New unified SwiftUI view for all image sources
  - Single API for remote URLs, local assets, and SF Symbols
  - Type-safe `ImageSource` enum (`.remote(URL)`, `.asset(String)`, `.symbol(String)`)
  - Intelligent routing based on source type
  - Default caching for remote images with opt-out support

- **Modifier-based customization API**
  - `.placeholder { }` - Custom placeholder view
  - `.onLoading { progress in }` - Custom loading view with progress tracking
  - `.onError { error in }` - Custom error view
  - `.disableCache()` - Disable caching for sensitive images
  - `.cache(manager:)` - Use custom cache manager per-view
  - `.showProgress(_ show: Bool)` - Toggle progress tracking
  - `.animated(duration:)` - Control fade-in animation duration

- **`RouraIOImageConfiguration`**: Environment-based configuration system
  - Automatic propagation through view hierarchy
  - Support for custom view builders via type-erased closures
  - Sendable-compliant for Swift 6 concurrency safety

### Changed

- **Deprecated `CachedAsyncImage`** in favor of `RouraIOImage`
  - Existing code continues to work with deprecation warnings
  - Migration guide added to README.md
  - Comprehensive migration examples provided

### Documentation

- Updated README.md with `RouraIOImage` as primary API
- Added examples for all image source types (remote, asset, symbol)
- Added cache configuration examples
- Added migration guide from `CachedAsyncImage` to `RouraIOImage`
- Updated architecture diagram to show unified API flow
- Updated key components section with new APIs

### Developer Experience

- Cleaner, more SwiftUI-native API with modifier-based customization
- Single view component for all image loading needs
- Better discoverability through type-safe `ImageSource` enum
- Consistent API across remote and local images

---
