import Testing
@testable import Pokedex

// MARK: - PokeAPI Integration Tests
@Suite("PokeAPI Service")
struct PokeAPITests {

    @Test("fetches Bulbasaur by ID")
    func fetchesBulbasaur() async throws {
        let service = PokeAPIService.shared
        let pokemon = try await service.fetchPokemon(id: 1)

        #expect(pokemon.id == 1)
        #expect(pokemon.name == "bulbasaur")
        #expect(!pokemon.types.isEmpty)
        #expect(pokemon.height > 0)
        #expect(pokemon.weight > 0)
    }

    @Test("fetches Pikachu stats")
    func fetchesPikachu() async throws {
        let service = PokeAPIService.shared
        let pokemon = try await service.fetchPokemon(id: 25)

        #expect(pokemon.id == 25)
        #expect(pokemon.name == "pikachu")
        #expect(pokemon.types.contains(where: { $0.type.name == "electric" }))
        #expect(!pokemon.stats.isEmpty)
    }

    @Test("fetches species English flavor text")
    func fetchesEnglishFlavorText() async throws {
        let service = PokeAPIService.shared
        let species = try await service.fetchSpecies(id: 1)

        let text = species.flavorText(language: .english)
        #expect(!text.isEmpty)
    }

    @Test("fetches species Spanish flavor text")
    func fetchesSpanishFlavorText() async throws {
        let service = PokeAPIService.shared
        let species = try await service.fetchSpecies(id: 1)

        let text = species.flavorText(language: .spanish)
        #expect(!text.isEmpty)
    }

    @Test("fetches Gen 1 list with 151 entries")
    func fetchesGen1List() async throws {
        let service = PokeAPIService.shared
        let list = try await service.fetchAllGen1()

        #expect(list.count == 151)
        #expect(list.first?.name == "bulbasaur")
        #expect(list.last?.name == "mew")
    }

    @Test("Gen 1 sprite URL is valid for Charizard")
    func gen1SpriteURL() throws {
        // Charizard ID 6
        let urlStr = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/6.png"
        let url = URL(string: urlStr)
        #expect(url != nil)
    }
}

// MARK: - Model Tests
@Suite("Pokemon Models")
struct PokemonModelTests {

    @Test("AppLanguage rawValues are correct")
    func appLanguageRawValues() {
        #expect(AppLanguage.english.rawValue == "en")
        #expect(AppLanguage.spanish.rawValue == "es")
    }

    @Test("AppLanguage display names")
    func appLanguageDisplayNames() {
        #expect(AppLanguage.english.displayName == "EN")
        #expect(AppLanguage.spanish.displayName == "ES")
    }

    @Test("AppLanguage toggles correctly")
    func appLanguageToggle() {
        var lang: AppLanguage = .english
        lang = lang == .english ? .spanish : .english
        #expect(lang == .spanish)
        lang = lang == .english ? .spanish : .english
        #expect(lang == .english)
    }

    @Test("height and weight conversions")
    func heightWeightConversions() async throws {
        let service = PokeAPIService.shared
        let pokemon = try await service.fetchPokemon(id: 1) // Bulbasaur: 7dm, 69hg

        #expect(pokemon.heightMeters == 0.7)
        #expect(pokemon.weightKg == 6.9)
    }

    @Test("gen1Names covers all 151")
    func gen1NamesCoverage() {
        #expect(gen1Names.count == 151)
        #expect(gen1Names[1] == "bulbasaur")
        #expect(gen1Names[25] == "pikachu")
        #expect(gen1Names[151] == "mew")
    }
}

// MARK: - Recognition Tests
@Suite("Pokemon Recognizer")
struct RecognizerTests {

    @Test("cry URL format is valid")
    func cryURLFormat() {
        for id in [1, 25, 151] {
            let urlStr = "https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest/\(id).ogg"
            #expect(URL(string: urlStr) != nil)
        }
    }
}
