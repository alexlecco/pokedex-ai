# Pokédex AI

A native iOS Pokédex app that uses your iPhone camera to scan and identify Generation 1 Pokémon — just like in the animated series.

## Features

- **Camera Scanner** — Point at any Pokémon toy, card, or image and tap scan
- **AI Recognition** — Uses Apple's Vision framework feature matching against all 151 Gen 1 Pokémon sprites (no server required)
- **Official Data** — Powered by [PokéAPI](https://pokeapi.co) with official Pokédex entries
- **Bilingual** — Toggle between English and Spanish with a single tap
- **Retro UI** — Faithful recreation of the classic red Pokédex hardware
- **Gen 1 Sprites** — Original pixel art sprites with retro green-screen tint
- **Pokémon Cries** — Authentic cries from PokéAPI's audio archive
- **Classic Sounds** — Pokédex beeps and scan sounds on every interaction

## Requirements

- iOS 17.0+
- iPhone (tested on iPhone 16)
- Xcode 16+
- Internet connection (for PokéAPI data, sprite loading, and cry audio)

## Setup

```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate Xcode project
cd pokedex-ai
xcodegen generate

# Open in Xcode
open Pokedex.xcodeproj
```

Then select your iPhone as the run target and press ▶.

## How Recognition Works

The app uses `VNGenerateImageFeaturePrintRequest` — Apple's on-device image feature extraction — to compare your camera frame against pre-computed feature vectors for all 151 Gen 1 Pokémon sprites downloaded from PokéAPI. No custom ML model or server needed.

On first launch, the app builds the feature database by downloading and processing sprites (~151 requests). This takes 30–60 seconds on a good connection and is cached for the session.

## Architecture

```
Pokedex/
├── App/               Entry point
├── Features/
│   ├── Home/          Retro Pokédex UI shell
│   ├── Scanner/       Camera + Vision recognition
│   └── Detail/        Pokémon info card
└── Core/
    ├── Networking/    PokeAPI (URLSession + actor)
    ├── Models/        Pokemon, PokemonSpecies
    ├── Recognition/   Vision feature matching
    └── Audio/         Sounds + Pokémon cries
```

## API

Data from [PokéAPI](https://pokeapi.co) — free, no API key required.  
Sprites from [PokeAPI/sprites](https://github.com/PokeAPI/sprites).  
Cries from [PokeAPI/cries](https://github.com/PokeAPI/cries).
