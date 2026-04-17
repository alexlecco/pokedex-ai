import Foundation

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:               "Invalid URL"
        case .invalidResponse:          "Invalid server response"
        case .httpError(let code):      "HTTP error \(code)"
        case .decodingError(let e):     "Decoding failed: \(e.localizedDescription)"
        }
    }
}

// MARK: - Network Client (actor for thread safety)
actor NetworkClient {
    static let shared = NetworkClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    // Simple in-memory cache
    private var cache: [URL: (data: Data, timestamp: Date)] = [:]
    private let cacheTTL: TimeInterval = 60 * 60 * 24 // 24 hours

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    func fetch<T: Decodable & Sendable>(_ url: URL) async throws -> T {
        // Check cache
        if let cached = cache[url], Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return try decode(cached.data)
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.httpError(statusCode: http.statusCode)
        }

        cache[url] = (data, Date())
        return try decode(data)
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
