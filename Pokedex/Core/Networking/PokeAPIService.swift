import Foundation

// MARK: - PokeAPI Service Protocol
protocol PokeAPIServiceProtocol: Sendable {
    func fetchPokemon(id: Int) async throws -> Pokemon
    func fetchSpecies(id: Int) async throws -> PokemonSpecies
    func fetchAllGen1() async throws -> [PokemonListItem]
}

// MARK: - List Response
struct PokemonListResponse: Codable, Sendable {
    let count: Int
    let results: [PokemonListItem]
}

struct PokemonListItem: Codable, Identifiable, Sendable {
    let name: String
    let url: String

    var id: Int {
        Int(url.components(separatedBy: "/").dropLast().last ?? "0") ?? 0
    }
}

// MARK: - PokeAPI Service
final class PokeAPIService: PokeAPIServiceProtocol {
    static let shared = PokeAPIService()

    private let baseURL = URL(string: "https://pokeapi.co/api/v2")!
    private let client = NetworkClient.shared

    private init() {}

    func fetchPokemon(id: Int) async throws -> Pokemon {
        let url = baseURL.appending(path: "pokemon/\(id)")
        return try await client.fetch(url)
    }

    func fetchSpecies(id: Int) async throws -> PokemonSpecies {
        let url = baseURL.appending(path: "pokemon-species/\(id)")
        return try await client.fetch(url)
    }

    func fetchAllGen1() async throws -> [PokemonListItem] {
        let url = baseURL.appending(path: "pokemon").appending(queryItems: [
            URLQueryItem(name: "limit", value: "151"),
            URLQueryItem(name: "offset", value: "0")
        ])
        let response: PokemonListResponse = try await client.fetch(url)
        return response.results
    }
}

// MARK: - URL extension helper
private extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        components.queryItems = queryItems
        return components.url!
    }
}
