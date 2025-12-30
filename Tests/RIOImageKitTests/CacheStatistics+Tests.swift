//
//  CacheStatistics+Tests.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation
import Testing

@testable import RIOImageKit

@Suite("CacheStatistics Tests")
struct CacheStatisticsTests {

    @Test("Initializes with default values")
    func initializesWithDefaultValues() {
        let stats = CacheStatistics()

        #expect(stats.hits == 0)
        #expect(stats.misses == 0)
        #expect(stats.totalRequests == 0)
        #expect(stats.hitRate == 0.0)
        #expect(stats.missRate == 0.0)
    }

    @Test("Initializes with custom values")
    func initializesWithCustomValues() {
        let stats = CacheStatistics(hits: 10, misses: 5)

        #expect(stats.hits == 10)
        #expect(stats.misses == 5)
        #expect(stats.totalRequests == 15)
    }

    @Test("Calculates total requests correctly")
    func calculatesTotalRequestsCorrectly() {
        let stats = CacheStatistics(hits: 7, misses: 3)

        #expect(stats.totalRequests == 10)
    }

    @Test("Calculates hit rate correctly")
    func calculatesHitRateCorrectly() {
        let stats = CacheStatistics(hits: 80, misses: 20)

        #expect(stats.hitRate == 0.8)
    }

    @Test("Calculates miss rate correctly")
    func calculatesMissRateCorrectly() {
        let stats = CacheStatistics(hits: 75, misses: 25)

        #expect(stats.missRate == 0.25)
    }

    @Test("Returns zero rates for no requests")
    func returnsZeroRatesForNoRequests() {
        let stats = CacheStatistics()

        #expect(stats.hitRate == 0.0)
        #expect(stats.missRate == 0.0)
    }

    @Test("Records hit correctly")
    func recordsHitCorrectly() {
        let stats = CacheStatistics(hits: 5, misses: 3)
        let updated = stats.recordHit()

        #expect(updated.hits == 6)
        #expect(updated.misses == 3)
        #expect(updated.totalRequests == 9)
    }

    @Test("Records miss correctly")
    func recordsMissCorrectly() {
        let stats = CacheStatistics(hits: 5, misses: 3)
        let updated = stats.recordMiss()

        #expect(updated.hits == 5)
        #expect(updated.misses == 4)
        #expect(updated.totalRequests == 9)
    }

    @Test("Reset creates new statistics")
    func resetCreatesNewStatistics() {
        let stats = CacheStatistics(hits: 100, misses: 50)
        let reset = stats.reset()

        #expect(reset.hits == 0)
        #expect(reset.misses == 0)
        #expect(reset.totalRequests == 0)
    }

    @Test("Elapsed time is non-negative")
    func elapsedTimeIsNonNegative() {
        let stats = CacheStatistics()
        let elapsed = stats.elapsedTime

        #expect(elapsed >= 0)
    }

    @Test("Description contains key metrics")
    func descriptionContainsKeyMetrics() {
        let stats = CacheStatistics(hits: 80, misses: 20)
        let description = stats.description

        #expect(description.contains("Hits"))
        #expect(description.contains("Misses"))
        #expect(description.contains("Total Requests"))
        #expect(description.contains("Hit Rate"))
        #expect(description.contains("Miss Rate"))
    }

    @Test("Perfect hit rate is 100%")
    func perfectHitRateIs100Percent() {
        let stats = CacheStatistics(hits: 100, misses: 0)

        #expect(stats.hitRate == 1.0)
        #expect(stats.missRate == 0.0)
    }

    @Test("Perfect miss rate is 100%")
    func perfectMissRateIs100Percent() {
        let stats = CacheStatistics(hits: 0, misses: 100)

        #expect(stats.hitRate == 0.0)
        #expect(stats.missRate == 1.0)
    }
}
