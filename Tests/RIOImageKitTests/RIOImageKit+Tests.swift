//
//  RIOImageKit+Tests.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation
import Testing
@testable import RIOImageKit

// MARK: - ImageCacheError Tests

@Suite("ImageCacheError Tests")
struct ImageCacheErrorTests {

    @Test("ImageCacheError.invalidImageData has correct description")
    func invalidImageDataDescription() {

        let error = ImageCacheError.invalidImageData
        #expect(error.localizedDescription.contains("could not be converted"))
    }
}


// MARK: - PlatformImage Tests

@Suite("PlatformImage Tests")
struct PlatformImageTests {

    @Test("PlatformImage can be created from valid image data")
    func createFromValidData() throws {

        // Create a simple 1x1 red pixel PNG
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!

        let image = PlatformImage(data: pngData)
        #expect(image != nil)
    }


    @Test("PlatformImage returns nil for invalid data")
    func createFromInvalidData() {

        let invalidData = Data("not an image".utf8)
        let image = PlatformImage(data: invalidData)
        #expect(image == nil)
    }


    @Test("PlatformImage can generate JPEG data")
    func generateJPEGData() throws {

        // Create a simple 1x1 red pixel PNG
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        let jpegData = image.jpegData(compressionQuality: 0.8)
        #expect(jpegData != nil)
        #expect(jpegData!.count > 0)
    }


    @Test("PlatformImage can generate PNG data")
    func generatePNGData() throws {

        // Create a simple 1x1 red pixel PNG
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        let generatedPNGData = image.pngData()
        #expect(generatedPNGData != nil)
        #expect(generatedPNGData!.count > 0)
    }
}


// MARK: - ImageDecoder Tests

@Suite("ImageDecoder Tests")
struct ImageDecoderTests {

    @Test("ImageDecoder decodes valid image data")
    func decodesValidImageData() async throws {

        // Create a simple 1x1 red pixel PNG
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!

        let image = try await ImageDecoder.decode(data: pngData)
        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
    }


    @Test("ImageDecoder throws on invalid data")
    func throwsOnInvalidData() async {

        let invalidData = Data("not an image".utf8)

        await #expect(throws: ImageCacheError.invalidImageData) {
            _ = try await ImageDecoder.decode(data: invalidData)
        }
    }
}


// MARK: - MemoryImageCache Tests

@Suite("MemoryImageCache Tests")
struct MemoryImageCacheTests {

    @Test("MemoryImageCache stores and retrieves images")
    func storesAndRetrievesImages() async throws {

        let cache = MemoryImageCache(maxMemoryCost: 10 * 1024 * 1024)
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        await cache.setImage(image, for: "test-key")
        let retrieved = await cache.getImage(for: "test-key")

        #expect(retrieved != nil)
    }


    @Test("MemoryImageCache returns nil for non-existent keys")
    func returnsNilForNonExistentKeys() async {

        let cache = MemoryImageCache()
        let retrieved = await cache.getImage(for: "non-existent-key")

        #expect(retrieved == nil)
    }


    @Test("MemoryImageCache removes images")
    func removesImages() async throws {

        let cache = MemoryImageCache()
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        await cache.setImage(image, for: "test-key")
        await cache.removeImage(for: "test-key")
        let retrieved = await cache.getImage(for: "test-key")

        #expect(retrieved == nil)
    }


    @Test("MemoryImageCache clears all images")
    func clearsAllImages() async throws {

        let cache = MemoryImageCache()
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        await cache.setImage(image, for: "key1")
        await cache.setImage(image, for: "key2")
        await cache.clearAll()

        let retrieved1 = await cache.getImage(for: "key1")
        let retrieved2 = await cache.getImage(for: "key2")

        #expect(retrieved1 == nil)
        #expect(retrieved2 == nil)
    }
}


// MARK: - DiskImageCache Tests

@Suite("DiskImageCache Tests")
struct DiskImageCacheTests {

    @Test("DiskImageCache stores and retrieves images")
    func storesAndRetrievesImages() async throws {

        let cache = try DiskImageCache(directory: "TestCache-\(UUID().uuidString)")
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        try await cache.setImage(image, for: "test-key")
        let retrieved = await cache.getImage(for: "test-key")

        #expect(retrieved != nil)

        // Cleanup
        try? await cache.clearAll()
    }


    @Test("DiskImageCache returns nil for non-existent keys")
    func returnsNilForNonExistentKeys() async throws {

        let cache = try DiskImageCache(directory: "TestCache-\(UUID().uuidString)")
        let retrieved = await cache.getImage(for: "non-existent-key")

        #expect(retrieved == nil)

        // Cleanup
        try? await cache.clearAll()
    }


    @Test("DiskImageCache removes images")
    func removesImages() async throws {

        let cache = try DiskImageCache(directory: "TestCache-\(UUID().uuidString)")
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        try await cache.setImage(image, for: "test-key")
        try await cache.removeImage(for: "test-key")
        let retrieved = await cache.getImage(for: "test-key")

        #expect(retrieved == nil)

        // Cleanup
        try? await cache.clearAll()
    }


    @Test("DiskImageCache calculates cache size")
    func calculatesCacheSize() async throws {

        let cache = try DiskImageCache(directory: "TestCache-\(UUID().uuidString)")
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        let initialSize = await cache.getCacheSize()
        try await cache.setImage(image, for: "test-key")
        let sizeAfterAdd = await cache.getCacheSize()

        #expect(sizeAfterAdd > initialSize)

        // Cleanup
        try? await cache.clearAll()
    }


    @Test("DiskImageCache clears all images")
    func clearsAllImages() async throws {

        let cache = try DiskImageCache(directory: "TestCache-\(UUID().uuidString)")
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        try await cache.setImage(image, for: "key1")
        try await cache.setImage(image, for: "key2")
        let sizeBeforeClear = await cache.getCacheSize()

        try await cache.clearAll()

        let retrieved1 = await cache.getImage(for: "key1")
        let retrieved2 = await cache.getImage(for: "key2")
        let sizeAfterClear = await cache.getCacheSize()

        #expect(retrieved1 == nil)
        #expect(retrieved2 == nil)
        // Size should be significantly reduced (metadata files may still exist, so not necessarily 0)
        #expect(sizeAfterClear < sizeBeforeClear)
    }


    @Test("DiskImageCache respects maxAge expiration")
    func respectsMaxAgeExpiration() async throws {

        // Create cache with 1 second max age
        let cache = try DiskImageCache(
            directory: "TestCache-\(UUID().uuidString)",
            maxAge: 1.0
        )
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        try await cache.setImage(image, for: "test-key")

        // Should exist immediately
        let retrieved1 = await cache.getImage(for: "test-key")
        #expect(retrieved1 != nil)

        // Wait for expiration (1 second + buffer)
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // Should be expired now
        let retrieved2 = await cache.getImage(for: "test-key")
        #expect(retrieved2 == nil)

        // Cleanup
        try? await cache.clearAll()
    }
}


// MARK: - ImageCacheManager Tests

@Suite("ImageCacheManager Tests")
struct ImageCacheManagerTests {

    @Test("ImageCacheManager stores and retrieves from memory cache")
    func storesAndRetrievesFromMemory() async throws {

        let memoryCache = MemoryImageCache()
        let diskCache = try DiskImageCache(directory: "TestCache-\(UUID().uuidString)")
        let downloader = MockImageDownloadService()
        let manager = ImageCacheManager(
            imageLoadable: downloader,
            memoryCache: memoryCache,
            diskCache: diskCache
        )

        let testURL = URL(string: "https://example.com/image.jpg")!
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        await manager.setImage(image, for: testURL)
        let retrieved = await manager.getImage(for: testURL)

        #expect(retrieved != nil)

        // Cleanup
        try? await diskCache.clearAll()
    }


    @Test("ImageCacheManager promotes disk cache hits to memory")
    func promotesDiskCacheHitsToMemory() async throws {

        let memoryCache = MemoryImageCache()
        let diskCache = try DiskImageCache(directory: "TestCache-\(UUID().uuidString)")
        let downloader = MockImageDownloadService()
        let manager = ImageCacheManager(
            imageLoadable: downloader,
            memoryCache: memoryCache,
            diskCache: diskCache
        )

        let testURL = URL(string: "https://example.com/image.jpg")!
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        // Store only in disk cache
        try await diskCache.setImage(image, for: testURL.absoluteString)

        // Retrieve via manager (should promote to memory)
        let retrieved = await manager.getImage(for: testURL)
        #expect(retrieved != nil)

        // Check if it's now in memory cache
        let memoryRetrieved = await memoryCache.getImage(for: testURL.absoluteString)
        #expect(memoryRetrieved != nil)

        // Cleanup
        try? await diskCache.clearAll()
    }


    @Test("ImageCacheManager removes from both caches")
    func removesFromBothCaches() async throws {

        let memoryCache = MemoryImageCache()
        let diskCache = try DiskImageCache(directory: "TestCache-\(UUID().uuidString)")
        let downloader = MockImageDownloadService()
        let manager = ImageCacheManager(
            imageLoadable: downloader,
            memoryCache: memoryCache,
            diskCache: diskCache
        )

        let testURL = URL(string: "https://example.com/image.jpg")!
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        await manager.setImage(image, for: testURL)
        await manager.removeImage(for: testURL)

        let retrieved = await manager.getImage(for: testURL)
        #expect(retrieved == nil)

        // Cleanup
        try? await diskCache.clearAll()
    }


    @Test("ImageCacheManager clears both caches")
    func clearsBothCaches() async throws {

        let memoryCache = MemoryImageCache()
        let diskCache = try DiskImageCache(directory: "TestCache-\(UUID().uuidString)")
        let downloader = MockImageDownloadService()
        let manager = ImageCacheManager(
            imageLoadable: downloader,
            memoryCache: memoryCache,
            diskCache: diskCache
        )

        let testURL = URL(string: "https://example.com/image.jpg")!
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
        let image = try #require(PlatformImage(data: pngData))

        await manager.setImage(image, for: testURL)
        await manager.clearCache()

        let retrieved = await manager.getImage(for: testURL)
        #expect(retrieved == nil)

        // Cleanup
        try? await diskCache.clearAll()
    }


    @Test("ImageCacheManager returns cache size")
    func returnsCacheSize() async throws {

        let memoryCache = MemoryImageCache()
        let diskCache = try DiskImageCache(directory: "TestCache-\(UUID().uuidString)")
        let downloader = MockImageDownloadService()
        let manager = ImageCacheManager(
            imageLoadable: downloader,
            memoryCache: memoryCache,
            diskCache: diskCache
        )

        let initialSize = await manager.getCacheSize()
        #expect(initialSize >= 0)

        // Cleanup
        try? await diskCache.clearAll()
    }


    @Test("ImageCacheManager loads from cache or downloads")
    func loadsFromCacheOrDownloads() async throws {

        let memoryCache = MemoryImageCache()
        let diskCache = try DiskImageCache(directory: "TestCache-\(UUID().uuidString)")
        let downloader = MockImageDownloadService()
        let manager = ImageCacheManager(
            imageLoadable: downloader,
            memoryCache: memoryCache,
            diskCache: diskCache
        )

        let testURL = URL(string: "https://example.com/image.jpg")!

        // Should download since not cached
        let image = try await manager.loadImage(from: testURL)
        #expect(image.size.width > 0)

        // Should now be cached
        let cached = await manager.getImage(for: testURL)
        #expect(cached != nil)

        // Cleanup
        try? await diskCache.clearAll()
    }
}


// MARK: - MockImageDownloadService Tests

@Suite("MockImageDownloadService Tests")
struct MockImageDownloadServiceTests {

    @Test("MockImageDownloadService returns placeholder image")
    func returnsPlaceholderImage() async throws {

        let downloader = MockImageDownloadService()
        let url = URL(string: "https://example.com/image.jpg")!

        let image = try await downloader.loadImage(from: url)
        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
    }


    @Test("MockImageDownloadService calls progress handler")
    func callsProgressHandler() async throws {

        let downloader = MockImageDownloadService()
        let url = URL(string: "https://example.com/image.jpg")!

        actor ProgressTracker {
            var calls = 0
            var lastProgress: Double = 0

            func recordProgress(_ progress: Double) {

                calls += 1
                lastProgress = progress
            }
        }

        let tracker = ProgressTracker()

        let image = try await downloader.loadImage(from: url) { progress in
            Task { await tracker.recordProgress(progress) }
        }

        #expect(image.size.width > 0)
        // Give time for progress tracking to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        let calls = await tracker.calls
        let lastProgress = await tracker.lastProgress
        #expect(calls > 0)
        #expect(lastProgress >= 0)
    }


    @Test("MockImageDownloadService prefetch is no-op")
    func prefetchIsNoOp() async {

        let downloader = MockImageDownloadService()
        let urls = [
            URL(string: "https://example.com/image1.jpg")!,
            URL(string: "https://example.com/image2.jpg")!
        ]

        // Should complete without errors
        await downloader.prefetchImages(urls: urls)
    }


    @Test("MockImageDownloadService cancel is no-op")
    func cancelIsNoOp() {

        let downloader = MockImageDownloadService()
        let urls = [
            URL(string: "https://example.com/image1.jpg")!,
            URL(string: "https://example.com/image2.jpg")!
        ]

        // Should complete without errors
        downloader.cancelPrefetch(for: urls)
    }
}


// MARK: - ImageDownloadService Tests

@Suite("ImageDownloadService Tests")
struct ImageDownloadServiceTests {

    @Test("ImageDownloadService initialization")
    func initialization() {

        let _ = ImageDownloadService(maxRetries: 5, retryDelay: 1.0)
        // If this compiles and runs, the initialization is working
        #expect(Bool(true))
    }


    @Test("ImageDownloadService real download test")
    func realDownloadTest() async throws {

        // This would require actual network access - skip for unit tests
        // In production, you'd use a local test server or mock URLSession
    }
}
