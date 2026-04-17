import SwiftUI

// MARK: - Pokémon Detail View (retro style)
struct PokemonDetailView: View {
    let pokemon: Pokemon
    let species: PokemonSpecies
    @Binding var language: AppLanguage
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var animateIn = false

    private var displayName: String { species.localizedName(language: language) }
    private var genus: String { species.genus(language: language) }
    private var description: String { species.flavorText(language: language) }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient using type color
                LinearGradient(
                    colors: [
                        Color.typeColor(pokemon.primaryType.name),
                        Color.pokedexScreenBG
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        spriteSection
                        infoCard
                        statsSection
                        typesSection
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("◀ BACK") {
                        dismiss()
                        onDismiss()
                    }
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    languageToggle
                }
            }
        }
        .onAppear { withAnimation(.spring(duration: 0.5)) { animateIn = true } }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text("No. \(String(format: "%03d", pokemon.id))")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Button(action: {
                    PokedexSoundManager.shared.playCry(pokemonId: pokemon.id)
                }) {
                    Label("CRY", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Text(displayName.uppercased())
                .font(.system(size: 30, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 4)

            if !genus.isEmpty {
                Text(genus)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Retro Gen 1 sprite
    private var spriteSection: some View {
        ZStack {
            // CRT screen background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.pokedexScreenBG)
                .frame(width: 160, height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.pokedexGreen.opacity(0.4), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.4), radius: 8)

            // Scanlines
            VStack(spacing: 3) {
                ForEach(0..<20, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.12))
                        .frame(height: 1)
                    Spacer().frame(height: 3)
                }
            }
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .allowsHitTesting(false)

            // Gen 1 pixel sprite
            AsyncImage(url: pokemon.gen1SpriteURL) { phase in
                switch phase {
                case .success(let img):
                    img
                        .interpolation(.none) // keep pixel art crisp
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .colorMultiply(.pokedexGreen.opacity(0.9)) // retro green tint
                case .failure:
                    // Fallback to official artwork
                    AsyncImage(url: pokemon.sprites.officialArtworkURL) { phase2 in
                        if case .success(let img2) = phase2 {
                            img2.resizable().scaledToFit().frame(width: 120, height: 120)
                        } else {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.pokedexGreen.opacity(0.5))
                        }
                    }
                default:
                    ProgressView().tint(.pokedexGreen)
                }
            }
            .scaleEffect(animateIn ? 1.0 : 0.5)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Info card
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Pokédex entry text
            Text(description)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .lineSpacing(4)

            Divider().background(Color.white.opacity(0.2))

            // Height / Weight
            HStack(spacing: 0) {
                statPill(
                    label: language == .english ? "HEIGHT" : "TALLA",
                    value: String(format: "%.1f m", pokemon.heightMeters)
                )
                Spacer()
                statPill(
                    label: language == .english ? "WEIGHT" : "PESO",
                    value: String(format: "%.1f kg", pokemon.weightKg)
                )
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - Stats section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language == .english ? "BASE STATS" : "ESTADÍSTICAS")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 4)

            ForEach(pokemon.stats, id: \.stat.name) { stat in
                statBar(name: stat.stat.name.uppercased(), value: stat.baseStat, max: 255)
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Types section
    private var typesSection: some View {
        HStack(spacing: 12) {
            ForEach(pokemon.types, id: \.slot) { slot in
                Text(slot.type.name.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.typeColor(slot.type.name))
                    .clipShape(Capsule())
                    .shadow(color: Color.typeColor(slot.type.name).opacity(0.5), radius: 4)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Language toggle
    private var languageToggle: some View {
        Button(action: {
            withAnimation(.spring(duration: 0.2)) {
                language = language == .english ? .spanish : .english
            }
            PokedexSoundManager.shared.playSound(.beep)
        }) {
            HStack(spacing: 4) {
                Text("EN")
                    .opacity(language == .english ? 1 : 0.4)
                Text("/")
                    .opacity(0.5)
                Text("ES")
                    .opacity(language == .spanish ? 1 : 0.4)
            }
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.3))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers
    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }

    private func statBar(name: String, value: Int, max: Int) -> some View {
        HStack(spacing: 8) {
            Text(shortStatName(name))
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 40, alignment: .trailing)
            Text("\(value)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 28, alignment: .trailing)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.3))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(statBarColor(value: value))
                        .frame(width: g.size.width * CGFloat(value) / CGFloat(max))
                }
            }
            .frame(height: 8)
        }
    }

    private func shortStatName(_ name: String) -> String {
        switch name {
        case "HP":              return "HP"
        case "ATTACK":          return "ATK"
        case "DEFENSE":         return "DEF"
        case "SPECIAL-ATTACK":  return "SATK"
        case "SPECIAL-DEFENSE": return "SDEF"
        case "SPEED":           return "SPD"
        default:                return String(name.prefix(4))
        }
    }

    private func statBarColor(value: Int) -> Color {
        switch value {
        case 0..<50:  return .red
        case 50..<80: return .pokedexYellow
        default:      return .pokedexGreen
        }
    }
}
