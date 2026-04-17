import Foundation
import Observation
import UIKit

enum ScanState {
    case idle
    case scanning
    case found(RecognitionResult)
    case loading
    case error(String)
}

@Observable
@MainActor
final class ScannerViewModel {
    var scanState: ScanState = .idle
    var isDBReady = false
    var dbProgress: Int = 0
    var detectedPokemon: (pokemon: Pokemon, species: PokemonSpecies)?
    var selectedLanguage: AppLanguage = .english
    var showDetail = false

    private let recognizer = PokemonRecognizer.shared
    private let api = PokeAPIService.shared
    private let sound = PokedexSoundManager.shared

    // MARK: - Initialize feature database
    func prepareDatabase() async {
        guard await !recognizer.databaseReady else {
            isDBReady = true
            return
        }

        await recognizer.buildDatabase { built, total in
            Task { @MainActor [weak self] in
                self?.dbProgress = Int(Double(built) / Double(total) * 100)
            }
        }
        isDBReady = await recognizer.databaseReady
    }

    // MARK: - Process live camera frames
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard isDBReady, case .idle = scanState else { return }
        scanState = .scanning

        Task {
            let result = await recognizer.recognize(pixelBuffer: pixelBuffer)
            await handleResult(result)
        }
    }

    // MARK: - Process captured photo
    func processPhoto(_ image: UIImage) {
        guard isDBReady else { return }
        scanState = .scanning
        sound.playSound(.scan)

        Task {
            let result = await recognizer.recognize(image: image)
            await handleResult(result)
        }
    }

    // MARK: - Handle recognition result
    private func handleResult(_ result: RecognitionResult?) async {
        guard let result, result.confidence > 0.3 else {
            scanState = .idle
            return
        }

        scanState = .found(result)
        sound.playSound(.beep)

        // Load full data
        scanState = .loading
        do {
            async let pokemon = api.fetchPokemon(id: result.pokemonId)
            async let species = api.fetchSpecies(id: result.pokemonId)
            let (p, s) = try await (pokemon, species)

            detectedPokemon = (p, s)
            sound.playSound(.found)
            sound.playCry(pokemonId: result.pokemonId)
            showDetail = true
            scanState = .idle
        } catch {
            scanState = .error(error.localizedDescription)
            try? await Task.sleep(for: .seconds(2))
            scanState = .idle
        }
    }

    func resetScan() {
        detectedPokemon = nil
        showDetail = false
        scanState = .idle
    }

    func toggleLanguage() {
        selectedLanguage = selectedLanguage == .english ? .spanish : .english
    }
}
