import Foundation

// MARK: - Pokemon (from /pokemon/{id})
struct Pokemon: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let height: Int   // decimeters
    let weight: Int   // hectograms
    let types: [PokemonTypeSlot]
    let sprites: PokemonSprites
    let stats: [PokemonStat]

    var heightMeters: Double { Double(height) / 10.0 }
    var weightKg: Double { Double(weight) / 10.0 }
    var primaryType: PokemonType { types.first?.type ?? PokemonType(name: "normal", url: "") }
}

struct PokemonTypeSlot: Codable, Sendable {
    let slot: Int
    let type: PokemonType
}

struct PokemonType: Codable, Sendable {
    let name: String
    let url: String
}

struct PokemonSprites: Codable, Sendable {
    let frontDefault: String?
    let other: OtherSprites?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
        case other
    }

    // Gen 1 pixel sprite (red/blue)
    var gen1SpriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/\(0).png")
    }

    // Official artwork (fallback)
    var officialArtworkURL: URL? {
        guard let urlStr = other?.officialArtwork.frontDefault else { return nil }
        return URL(string: urlStr)
    }
}

struct OtherSprites: Codable, Sendable {
    let officialArtwork: OfficialArtwork

    enum CodingKeys: String, CodingKey {
        case officialArtwork = "official-artwork"
    }
}

struct OfficialArtwork: Codable, Sendable {
    let frontDefault: String?
    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

struct PokemonStat: Codable, Sendable {
    let baseStat: Int
    let stat: StatInfo

    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case stat
    }
}

struct StatInfo: Codable, Sendable {
    let name: String
    let url: String
}

// MARK: - PokemonSpecies (from /pokemon-species/{id})
struct PokemonSpecies: Codable, Sendable {
    let id: Int
    let name: String
    let flavorTextEntries: [FlavorTextEntry]
    let names: [PokemonName]
    let genera: [Genus]

    enum CodingKeys: String, CodingKey {
        case id, name, genera, names
        case flavorTextEntries = "flavor_text_entries"
    }

    func flavorText(language: AppLanguage, version: String = "red") -> String {
        let langCode = language.rawValue
        // Try to find text for the specified version first, then any version
        let entry = flavorTextEntries.first(where: { $0.language.name == langCode && $0.version.name == version })
            ?? flavorTextEntries.first(where: { $0.language.name == langCode })
        return entry?.flavorText
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\u{000C}", with: " ")
            ?? ""
    }

    func localizedName(language: AppLanguage) -> String {
        names.first(where: { $0.language.name == language.rawValue })?.name ?? name.capitalized
    }

    func genus(language: AppLanguage) -> String {
        genera.first(where: { $0.language.name == language.rawValue })?.genus ?? ""
    }
}

struct FlavorTextEntry: Codable, Sendable {
    let flavorText: String
    let language: LanguageRef
    let version: VersionRef

    enum CodingKeys: String, CodingKey {
        case flavorText = "flavor_text"
        case language, version
    }
}

struct PokemonName: Codable, Sendable {
    let name: String
    let language: LanguageRef
}

struct Genus: Codable, Sendable {
    let genus: String
    let language: LanguageRef
}

struct LanguageRef: Codable, Sendable { let name: String; let url: String }
struct VersionRef: Codable, Sendable { let name: String; let url: String }

// MARK: - App Language
enum AppLanguage: String, CaseIterable {
    case english = "en"
    case spanish = "es"

    var displayName: String {
        switch self {
        case .english: "EN"
        case .spanish: "ES"
        }
    }
}

// MARK: - Gen 1 Sprite URL helper
extension Pokemon {
    var gen1SpriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/\(id).png")
    }

    var cryURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest/\(id).ogg")
    }
}
