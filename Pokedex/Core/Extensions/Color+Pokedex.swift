import SwiftUI

extension Color {
    // Pokédex body colors
    static let pokedexRed       = Color(red: 0.85, green: 0.10, blue: 0.10)
    static let pokedexDarkRed   = Color(red: 0.60, green: 0.05, blue: 0.05)
    static let pokedexScreen    = Color(red: 0.55, green: 0.60, blue: 0.55)
    static let pokedexScreenBG  = Color(red: 0.20, green: 0.22, blue: 0.20)
    static let pokedexBlue      = Color(red: 0.15, green: 0.55, blue: 0.90)
    static let pokedexGreen     = Color(red: 0.15, green: 0.75, blue: 0.20)
    static let pokedexYellow    = Color(red: 0.95, green: 0.80, blue: 0.10)
    static let pokedexGray      = Color(red: 0.25, green: 0.25, blue: 0.28)
    static let pokedexTeal      = Color(red: 0.10, green: 0.70, blue: 0.65)
    static let pokedexCream     = Color(red: 0.95, green: 0.93, blue: 0.85)
    static let pokedexScanLine  = Color.green.opacity(0.35)

    // Pokémon type colors
    static func typeColor(_ typeName: String) -> Color {
        switch typeName.lowercased() {
        case "fire":     return Color(red: 1.0, green: 0.42, blue: 0.21)
        case "water":    return Color(red: 0.26, green: 0.55, blue: 0.95)
        case "grass":    return Color(red: 0.30, green: 0.72, blue: 0.35)
        case "electric": return Color(red: 0.98, green: 0.82, blue: 0.09)
        case "psychic":  return Color(red: 0.97, green: 0.28, blue: 0.58)
        case "ice":      return Color(red: 0.60, green: 0.86, blue: 0.97)
        case "dragon":   return Color(red: 0.44, green: 0.22, blue: 0.95)
        case "dark":     return Color(red: 0.44, green: 0.33, blue: 0.25)
        case "fairy":    return Color(red: 0.97, green: 0.62, blue: 0.96)
        case "normal":   return Color(red: 0.65, green: 0.65, blue: 0.55)
        case "fighting": return Color(red: 0.75, green: 0.19, blue: 0.15)
        case "poison":   return Color(red: 0.63, green: 0.25, blue: 0.63)
        case "ground":   return Color(red: 0.88, green: 0.75, blue: 0.42)
        case "flying":   return Color(red: 0.55, green: 0.60, blue: 0.95)
        case "bug":      return Color(red: 0.65, green: 0.75, blue: 0.10)
        case "rock":     return Color(red: 0.72, green: 0.63, blue: 0.30)
        case "ghost":    return Color(red: 0.44, green: 0.33, blue: 0.60)
        case "steel":    return Color(red: 0.72, green: 0.72, blue: 0.81)
        default:         return Color(red: 0.65, green: 0.65, blue: 0.55)
        }
    }
}
