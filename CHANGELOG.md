# Changelog

All notable changes to RIOImageKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-30

### Added

- **Two-tier caching system** with memory and disk caches
  - `MemoryImageCache`: Fast, volatile in-memory caching with automatic memory pressure handling
  - `DiskImageCache`: Persistent disk storage with LRU eviction and configurable expiration
  - `ImageCacheManager`: Central coordinator managing both cache tiers with automatic promotion

- **Production-ready image downloading**
  - `ImageDownloadService`: Network downloader with automatic retry and exponential backoff
  - Request deduplication to prevent duplicate concurrent downloads
  - Concurrency limiting (max 6 simultaneous downloads)
  - Real-time progress tracking for downloads
  - Background prefetching with low priority

- **SwiftUI integration**
  - `CachedAsyncImage`: Drop-in replacement for `AsyncImage` with built-in caching
  - `AnimatedImage`: Support for animated images
  - Environment-based cache manager injection
  - Loading state management with progress tracking

- **Image processing capabilities**
  - Resize processor with content mode support
  - Crop processor for image cropping
  - Blur processor for Gaussian blur effects
  - Rounded corners processor
  - Tint/color overlay processor
  - Downsampling options for memory efficiency

- **Testing utilities**
  - `MockImageDownloadService`: Mock implementation for unit testing
  - Protocol-based architecture for easy dependency injection
  - Comprehensive test suite covering core functionality

- **Advanced features**
  - Image format detection (JPEG, PNG, GIF, WebP, HEIC)
  - Progressive image decoding for large images
  - Custom request configuration with headers and authentication
  - Configurable compression quality for disk storage
  - Cache statistics and size monitoring
  - Automatic memory warning handling

- **Cross-platform support**
  - iOS 18.0+
  - macOS 15.0+
  - watchOS 11.0+
  - tvOS 18.0+
  - visionOS 2.0+

- **Developer experience**
  - Comprehensive DocC documentation with code examples
  - Zero external dependencies
  - Built with Swift 6 and modern concurrency
  - Type-safe error handling with `ImageCacheError`

### Fixed

- [RIK-0002] Resolved all compiler warnings for clean builds
- [RIK-0004] Consolidated network errors into unified `ImageCacheError` type
- Made `ImageCacheError` conform to `Equatable` for testing compatibility

### Changed

- [RIK-0003] Restructured SwiftUI components for better organization
- [RIK-0003] Split network configuration into dedicated `RequestConfiguration` type
- [RIK-0005] Made `MockImageDownloadService` public for user testing

### Documentation

- Added comprehensive README.md with installation and usage examples
- Added MIT LICENSE
- Added CHANGELOG.md
- Extensive inline documentation for all public APIs

---

## Version History

- **1.0.0** (2025-12-30) - Initial public release

[1.0.0]: https://github.com/yourusername/RIOImageKit/releases/tag/1.0.0
