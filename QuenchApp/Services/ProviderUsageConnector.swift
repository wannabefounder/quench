import Foundation
import QuenchEngine

protocol ProviderUsageConnector {
    var provider: UsageProvider { get }
    func fetchPage(startingAt: Date, page: String?) async throws -> ProviderUsagePage
}

enum ProviderConnectorError: LocalizedError {
    case invalidURL
    case rejected(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Quench could not construct the provider usage URL."
        case .rejected(let statusCode): "The provider rejected the request (HTTP \(statusCode))."
        }
    }
}

protocol HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionTransport: HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ProviderConnectorError.rejected(statusCode: 0)
        }
        return (data, http)
    }
}

struct OpenAIUsageConnector: ProviderUsageConnector {
    let provider: UsageProvider = .openAI
    private let credential: String
    private let transport: HTTPTransport

    init(credential: String, transport: HTTPTransport = URLSessionTransport()) {
        self.credential = credential
        self.transport = transport
    }

    func fetchPage(startingAt: Date, page: String?) async throws -> ProviderUsagePage {
        var components = URLComponents(string: "https://api.openai.com/v1/organization/usage/completions")
        components?.queryItems = [
            URLQueryItem(name: "start_time", value: String(Int(startingAt.timeIntervalSince1970))),
            URLQueryItem(name: "bucket_width", value: "1h"),
            URLQueryItem(name: "group_by", value: "model"),
            URLQueryItem(name: "limit", value: "168")
        ]
        if let page { components?.queryItems?.append(URLQueryItem(name: "page", value: page)) }
        guard let url = components?.url else { throw ProviderConnectorError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        let (data, response) = try await transport.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            throw ProviderConnectorError.rejected(statusCode: response.statusCode)
        }
        return try ProviderUsageParser.openAI(data)
    }
}

struct AnthropicUsageConnector: ProviderUsageConnector {
    let provider: UsageProvider = .anthropic
    private let credential: String
    private let transport: HTTPTransport

    init(credential: String, transport: HTTPTransport = URLSessionTransport()) {
        self.credential = credential
        self.transport = transport
    }

    func fetchPage(startingAt: Date, page: String?) async throws -> ProviderUsagePage {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        var components = URLComponents(string: "https://api.anthropic.com/v1/organizations/usage_report/messages")
        components?.queryItems = [
            URLQueryItem(name: "starting_at", value: formatter.string(from: startingAt)),
            URLQueryItem(name: "group_by[]", value: "model"),
            URLQueryItem(name: "limit", value: "31")
        ]
        if let page { components?.queryItems?.append(URLQueryItem(name: "page", value: page)) }
        guard let url = components?.url else { throw ProviderConnectorError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue(credential, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        let (data, response) = try await transport.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            throw ProviderConnectorError.rejected(statusCode: response.statusCode)
        }
        return try ProviderUsageParser.anthropic(data)
    }
}
