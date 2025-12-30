//
//  RequestConfiguration+Tests.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation
import Testing

@testable import RIOImageKit

@Suite("RequestConfiguration Tests")
struct RequestConfigurationTests {

    @Test("Initializes with default values")
    func initializesWithDefaultValues() {
        let config = RequestConfiguration()

        #expect(config.headers.isEmpty)
        #expect(config.timeoutInterval == 30)
    }

    @Test("Initializes with custom headers")
    func initializesWithCustomHeaders() {
        let headers = ["Authorization": "Bearer token123", "X-API-Key": "abc"]
        let config = RequestConfiguration(headers: headers)

        #expect(config.headers.count == 2)
        #expect(config.headers["Authorization"] == "Bearer token123")
        #expect(config.headers["X-API-Key"] == "abc")
    }

    @Test("Initializes with custom timeout")
    func initializesWithCustomTimeout() {
        let config = RequestConfiguration(timeoutInterval: 60)

        #expect(config.timeoutInterval == 60)
    }

    @Test("Creates bearer token configuration")
    func createsBearerTokenConfiguration() {
        let config = RequestConfiguration.bearerToken("my-token")

        #expect(config.headers.count == 1)
        #expect(config.headers["Authorization"] == "Bearer my-token")
    }

    @Test("Creates API key configuration with default header")
    func createsAPIKeyConfigurationWithDefaultHeader() {
        let config = RequestConfiguration.apiKey("my-api-key")

        #expect(config.headers.count == 1)
        #expect(config.headers["X-API-Key"] == "my-api-key")
    }

    @Test("Creates API key configuration with custom header")
    func createsAPIKeyConfigurationWithCustomHeader() {
        let config = RequestConfiguration.apiKey("my-key", headerName: "Custom-Key")

        #expect(config.headers.count == 1)
        #expect(config.headers["Custom-Key"] == "my-key")
    }

    @Test("Applies headers to URL request")
    func appliesHeadersToURLRequest() {
        let url = URL(string: "https://example.com")!
        var request = URLRequest(url: url)

        let config = RequestConfiguration(headers: [
            "Authorization": "Bearer token",
            "Accept": "application/json"
        ])

        config.apply(to: &request)

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("Applies timeout to URL request")
    func appliesTooltipToURLRequest() {
        let url = URL(string: "https://example.com")!
        var request = URLRequest(url: url)

        let config = RequestConfiguration(timeoutInterval: 45)
        config.apply(to: &request)

        #expect(request.timeoutInterval == 45)
    }

    @Test("Applies both headers and timeout")
    func appliesBothHeadersAndTimeout() {
        let url = URL(string: "https://example.com")!
        var request = URLRequest(url: url)

        let config = RequestConfiguration(
            headers: ["X-Custom": "value"],
            timeoutInterval: 90
        )
        config.apply(to: &request)

        #expect(request.value(forHTTPHeaderField: "X-Custom") == "value")
        #expect(request.timeoutInterval == 90)
    }

    @Test("Overwrites existing headers")
    func overwritesExistingHeaders() {
        let url = URL(string: "https://example.com")!
        var request = URLRequest(url: url)
        request.setValue("old-value", forHTTPHeaderField: "Authorization")

        let config = RequestConfiguration(headers: ["Authorization": "new-value"])
        config.apply(to: &request)

        #expect(request.value(forHTTPHeaderField: "Authorization") == "new-value")
    }
}
