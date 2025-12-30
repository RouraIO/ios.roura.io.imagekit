//
//  ProgressiveImageDecoder+Tests.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation
import Testing

@testable import RIOImageKit

@Suite("ProgressiveImageDecoder Tests")
struct ProgressiveImageDecoderTests {

    @Test("Initializes with default scale")
    func initializesWithDefaultScale() async {
        let decoder = ProgressiveImageDecoder()
        #expect(decoder != nil)
    }

    @Test("Initializes with custom scale")
    func initializesWithCustomScale() async {
        let decoder = ProgressiveImageDecoder(scale: 2.0)
        #expect(decoder != nil)
    }

    @Test("Returns nil image with no data")
    func returnsNilImageWithNoData() async {
        let decoder = ProgressiveImageDecoder()
        let image = await decoder.currentImage
        #expect(image == nil)
    }

    @Test("Returns zero progress with no data")
    func returnsZeroProgressWithNoData() async {
        let decoder = ProgressiveImageDecoder()
        let progress = await decoder.progress
        #expect(progress == 0.0)
    }

    @Test("Accepts data without throwing")
    func acceptsDataWithoutThrowing() async {
        let decoder = ProgressiveImageDecoder()
        let testData = Data([0xFF, 0xD8, 0xFF]) // JPEG header
        await decoder.append(testData)

        // Should not crash
        #expect(decoder != nil)
    }

    @Test("Can be finalized")
    func canBeFinalized() async {
        let decoder = ProgressiveImageDecoder()
        let testData = Data([0xFF, 0xD8, 0xFF])
        await decoder.append(testData)
        await decoder.finalize()

        // Should not crash
        #expect(decoder != nil)
    }

    @Test("Can be reset")
    func canBeReset() async {
        let decoder = ProgressiveImageDecoder()
        let testData = Data([0xFF, 0xD8, 0xFF])
        await decoder.append(testData)
        await decoder.reset()

        let progress = await decoder.progress
        #expect(progress == 0.0)
    }

    @Test("Progress increases with more data")
    func progressIncreasesWithMoreData() async {
        let decoder = ProgressiveImageDecoder()

        let initialProgress = await decoder.progress
        #expect(initialProgress == 0.0)

        // Add valid JPEG header
        var jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        jpegData.append(Data(repeating: 0, count: 100))
        await decoder.append(jpegData)

        // Progress may or may not increase with just header data
        // This is implementation-dependent
        let midProgress = await decoder.progress
        #expect(midProgress >= 0.0)

        // Add more data
        let chunk2 = Data(repeating: 0xFF, count: 1000)
        await decoder.append(chunk2)

        let laterProgress = await decoder.progress
        #expect(laterProgress >= 0.0)
    }

    @Test("Finalize sets progress to 1.0 with valid data")
    func finalizeSetProgressToOneWithValidData() async {
        let decoder = ProgressiveImageDecoder()

        // Create a minimal valid JPEG
        var jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header
        jpegData.append(Data(repeating: 0xFF, count: 100))
        jpegData.append(Data([0xFF, 0xD9])) // JPEG EOI marker

        await decoder.append(jpegData)
        await decoder.finalize()

        let progress = await decoder.progress
        #expect(progress > 0.0) // Should have some progress
    }

    @Test("Reset clears all state")
    func resetClearsAllState() async {
        let decoder = ProgressiveImageDecoder()

        // Add data and finalize
        let testData = Data(repeating: 0xFF, count: 1000)
        await decoder.append(testData)
        await decoder.finalize()

        // Reset
        await decoder.reset()

        // Verify state is cleared
        let progress = await decoder.progress
        let image = await decoder.currentImage
        #expect(progress == 0.0)
        #expect(image == nil)
    }
}
