//
//  ImageFormatDetector+Tests.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation
import Testing

@testable import RIOImageKit

@Suite("ImageFormatDetector Tests")
struct ImageFormatDetectorTests {

    @Test("Detects JPEG format")
    func detectsJPEGFormat() {
        // JPEG magic bytes: FF D8 FF
        var data = Data([0xFF, 0xD8, 0xFF, 0xE0])
        data.append(Data(repeating: 0, count: 100))

        let format = ImageFormatDetector.detect(from: data)
        #expect(format == .jpeg)
    }

    @Test("Detects PNG format")
    func detectsPNGFormat() {
        // PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
        var data = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        data.append(Data(repeating: 0, count: 100))

        let format = ImageFormatDetector.detect(from: data)
        #expect(format == .png)
    }

    @Test("Detects GIF format")
    func detectsGIFFormat() {
        // GIF magic bytes: 47 49 46 38
        var data = Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61])
        data.append(Data(repeating: 0, count: 100))

        let format = ImageFormatDetector.detect(from: data)
        #expect(format == .gif)
    }

    @Test("Detects WebP format")
    func detectsWebPFormat() {
        // WebP magic bytes: RIFF....WEBP
        var data = Data([
            0x52, 0x49, 0x46, 0x46,  // RIFF
            0x00, 0x00, 0x00, 0x00,  // Size (placeholder)
            0x57, 0x45, 0x42, 0x50   // WEBP
        ])
        data.append(Data(repeating: 0, count: 100))

        let format = ImageFormatDetector.detect(from: data)
        #expect(format == .webp)
    }

    @Test("Detects HEIC format")
    func detectsHEICFormat() {
        // HEIC magic bytes: ....ftyp
        var data = Data([
            0x00, 0x00, 0x00, 0x18,  // Size
            0x66, 0x74, 0x79, 0x70,  // ftyp
            0x68, 0x65, 0x69, 0x63   // heic
        ])
        data.append(Data(repeating: 0, count: 100))

        let format = ImageFormatDetector.detect(from: data)
        #expect(format == .heic)
    }

    @Test("Returns unknown for insufficient data")
    func returnsUnknownForInsufficientData() {
        let data = Data([0x00, 0x01])

        let format = ImageFormatDetector.detect(from: data)
        #expect(format == .unknown)
    }

    @Test("Returns unknown for unrecognized format")
    func returnsUnknownForUnrecognizedFormat() {
        var data = Data([0xAA, 0xBB, 0xCC, 0xDD])
        data.append(Data(repeating: 0, count: 100))

        let format = ImageFormatDetector.detect(from: data)
        #expect(format == .unknown)
    }

    @Test("Identifies GIF as animated")
    func identifiesGIFAsAnimated() {
        var data = Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61])
        data.append(Data(repeating: 0, count: 100))

        let isAnimated = ImageFormatDetector.isAnimated(data: data)
        #expect(isAnimated == true)
    }

    @Test("Identifies WebP as potentially animated")
    func identifiesWebPAsPotentiallyAnimated() {
        var data = Data([
            0x52, 0x49, 0x46, 0x46,
            0x00, 0x00, 0x00, 0x00,
            0x57, 0x45, 0x42, 0x50
        ])
        data.append(Data(repeating: 0, count: 100))

        let isAnimated = ImageFormatDetector.isAnimated(data: data)
        #expect(isAnimated == true)
    }

    @Test("Identifies JPEG as not animated")
    func identifiesJPEGAsNotAnimated() {
        var data = Data([0xFF, 0xD8, 0xFF, 0xE0])
        data.append(Data(repeating: 0, count: 100))

        let isAnimated = ImageFormatDetector.isAnimated(data: data)
        #expect(isAnimated == false)
    }
}
