import AVFoundation
import Foundation

// MARK: - Pokédex Sound Manager
@MainActor
final class PokedexSoundManager: NSObject {
    static let shared = PokedexSoundManager()

    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var cryPlayer: AVPlayer?

    private override init() {
        super.init()
        configureAudioSession()
        preloadSounds()
    }

    // MARK: - Audio Session
    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Preload bundled sounds
    private func preloadSounds() {
        let soundNames = ["pokedex_open", "pokedex_scan", "pokedex_beep", "pokedex_found"]
        for name in soundNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
                audioPlayers[name] = try? AVAudioPlayer(contentsOf: url)
                audioPlayers[name]?.prepareToPlay()
            }
        }
    }

    // MARK: - Play bundled sounds
    func playSound(_ name: PokedexSound) {
        audioPlayers[name.rawValue]?.stop()
        audioPlayers[name.rawValue]?.currentTime = 0
        audioPlayers[name.rawValue]?.play()

        // Fallback: generate beep if sound file not found
        if audioPlayers[name.rawValue] == nil {
            playGeneratedBeep(for: name)
        }
    }

    // MARK: - Play Pokémon cry from PokeAPI
    func playCry(pokemonId: Int) {
        let urlString = "https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest/\(pokemonId).ogg"
        guard let url = URL(string: urlString) else { return }
        cryPlayer = AVPlayer(url: url)
        cryPlayer?.play()
    }

    // MARK: - Generated beep fallback (synthesized retro sounds)
    private func playGeneratedBeep(for sound: PokedexSound) {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let buffer = generateBeepBuffer(sound: sound, format: format)
        try? engine.start()
        player.scheduleBuffer(buffer, completionHandler: nil)
        player.play()

        // Stop engine after sound finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + sound.duration + 0.1) {
            engine.stop()
        }
    }

    private func generateBeepBuffer(sound: PokedexSound, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sampleRate = Float(format.sampleRate)
        let frameCount = AVAudioFrameCount(sampleRate * Float(sound.duration))
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channelData = buffer.floatChannelData![0]
        let frequency = sound.frequency
        let amplitude: Float = 0.3

        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / sampleRate
            // Apply simple envelope (fade in/out)
            let fadeIn = min(t * 20, 1.0 as Float)
            let remainingTime = Float(sound.duration) - t
            let fadeOut = min(remainingTime * 20, 1.0 as Float)
            let envelope = fadeIn * fadeOut
            channelData[frame] = amplitude * Float(envelope) * sin(2.0 * .pi * frequency * t)
        }

        return buffer
    }
}

// MARK: - Sound Types
enum PokedexSound: String {
    case open    = "pokedex_open"
    case scan    = "pokedex_scan"
    case beep    = "pokedex_beep"
    case found   = "pokedex_found"

    var frequency: Float {
        switch self {
        case .open:  523.25  // C5
        case .scan:  698.46  // F5 (scanning sweep feel)
        case .beep:  880.0   // A5
        case .found: 1046.5  // C6 (success)
        }
    }

    var duration: Double {
        switch self {
        case .open:  0.3
        case .scan:  0.5
        case .beep:  0.15
        case .found: 0.6
        }
    }
}
