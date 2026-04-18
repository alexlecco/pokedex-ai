import SwiftUI

// MARK: - Main Pokédex View (retro hardware skin)
struct PokedexHomeView: View {
    @State private var viewModel = ScannerViewModel()
    @State private var cameraManager = CameraManager()
    @State private var showCamera = false
    @State private var scanLineOffset: CGFloat = 0
    @State private var screenGlow = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                pokedexBody(geo: geo)
            }
        }
        .task { await viewModel.prepareDatabase() }
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            if let img = newImage {
                viewModel.processPhoto(img)
                cameraManager.capturedImage = nil
            }
        }
        .sheet(isPresented: $viewModel.showDetail) {
            if let data = viewModel.detectedPokemon {
                PokemonDetailView(
                    pokemon: data.pokemon,
                    species: data.species,
                    language: $viewModel.selectedLanguage
                ) {
                    viewModel.resetScan()
                }
            }
        }
        .onAppear {
            PokedexSoundManager.shared.playSound(.open)
        }
    }

    // MARK: - Pokédex hardware body
    private func pokedexBody(geo: GeometryProxy) -> some View {
        let w = min(geo.size.width * 0.92, 380.0)
        let h = w * 1.85

        return ZStack {
            // Body shadow
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.pokedexDarkRed)
                .frame(width: w, height: h)
                .offset(x: 4, y: 6)
                .blur(radius: 8)

            // Main red body
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.pokedexRed, Color.pokedexRed.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: w, height: h)

            // Inner border detail
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.pokedexDarkRed.opacity(0.4), lineWidth: 2)
                .frame(width: w - 6, height: h - 6)

            // Content
            VStack(spacing: 0) {
                topSection(width: w)
                screenSection(width: w)
                bottomSection(width: w)
            }
            .frame(width: w, height: h)
        }
        .frame(width: w, height: h)
        .position(x: geo.size.width / 2, y: geo.size.height / 2)
    }

    // MARK: - Top section: big blue button + indicator dots
    private func topSection(width: CGFloat) -> some View {
        HStack(alignment: .center) {
            // Big blue camera button
            Button(action: openCamera) {
                ZStack {
                    Circle()
                        .fill(Color.pokedexGray.opacity(0.4))
                        .frame(width: width * 0.22)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.pokedexBlue.opacity(0.9), Color.pokedexBlue],
                                center: .topLeading,
                                startRadius: 4,
                                endRadius: width * 0.12
                            )
                        )
                        .frame(width: width * 0.19)
                        .shadow(color: .pokedexBlue.opacity(0.7), radius: 8)
                    Image(systemName: "camera.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: width * 0.07))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Status indicator dots
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    indicatorDot(.pokedexRed.opacity(0.9),    size: 10)
                    indicatorDot(.pokedexYellow,              size: 10)
                    indicatorDot(.pokedexGreen,               size: 10)
                }
                // DB loading indicator
                if !viewModel.isDBReady {
                    Text("INIT \(viewModel.dbProgress)%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Screen section
    private func screenSection(width: CGFloat) -> some View {
        let screenW = width * 0.82
        let screenH = screenW * 0.88

        return ZStack(alignment: .topLeading) {
            // Screen bezel (gray border)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.75, green: 0.78, blue: 0.73))
                .frame(width: screenW + 16, height: screenH + 16)

            // Screen itself
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.pokedexScreenBG)
                    .frame(width: screenW, height: screenH)

                screenContent(width: screenW, height: screenH)

                // Scanline overlay effect
                if showCamera || viewModel.scanState.isScanning {
                    scanlineOverlay(width: screenW, height: screenH)
                }

                // Screen glare
                LinearGradient(
                    colors: [.white.opacity(0.08), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(width: screenW, height: screenH)
                .allowsHitTesting(false)
            }
            .frame(width: screenW, height: screenH)
            .offset(x: 8, y: 8)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Screen content (what's displayed)
    @ViewBuilder
    private func screenContent(width: CGFloat, height: CGFloat) -> some View {
        switch viewModel.scanState {
        case .idle:
            if showCamera {
                cameraLiveView(width: width, height: height)
            } else {
                idleScreen(width: width, height: height)
            }
        case .scanning:
            scanningScreen(width: width, height: height)
        case .found(let result):
            foundScreen(result: result, width: width)
        case .loading:
            loadingScreen(width: width)
        case .error(let msg):
            errorScreen(message: msg, width: width)
        }
    }

    // MARK: - Idle screen
    private func idleScreen(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            Spacer()
            // Retro Pokéball logo
            ZStack {
                Circle()
                    .stroke(Color.pokedexGreen.opacity(0.6), lineWidth: 2)
                    .frame(width: 60, height: 60)
                Image(systemName: "circle.bottomhalf.filled")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.pokedexGreen.opacity(0.7))
            }
            Text("POKÉDEX")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.pokedexGreen)
                .shadow(color: .pokedexGreen.opacity(0.5), radius: 4)
            Text("PRESS CAMERA TO SCAN")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.pokedexGreen.opacity(0.6))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(width: width, height: height)
    }

    // MARK: - Live camera view with overlay
    private func cameraLiveView(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            CameraPreviewView(cameraManager: cameraManager) { buffer in
                viewModel.processFrame(buffer)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Targeting overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.pokedexGreen.opacity(0.8), lineWidth: 2)
                            .frame(width: width * 0.55, height: width * 0.55)
                        // Corner marks
                        cornerMarkers(size: width * 0.55)
                    }
                    Spacer()
                }
                Spacer()
            }

            // Capture button overlay
            VStack {
                Spacer()
                Button(action: capturePhoto) {
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color.pokedexGreen, lineWidth: 3)
                        )
                }
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Scanning screen
    private func scanningScreen(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .tint(.pokedexGreen)
                .scaleEffect(1.5)
            Text("ANALYZING...")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.pokedexGreen)
            Spacer()
        }
        .frame(width: width, height: height)
    }

    // MARK: - Found screen
    private func foundScreen(result: RecognitionResult, width: CGFloat) -> some View {
        VStack(spacing: 6) {
            Spacer()
            Text("POKÉMON DETECTED!")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.pokedexGreen)
            Text(result.pokemonName.uppercased())
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
            Text("MATCH: \(Int(result.confidence * 100))%")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.pokedexGreen.opacity(0.7))
            Spacer()
        }
    }

    // MARK: - Loading screen
    private func loadingScreen(width: CGFloat) -> some View {
        VStack(spacing: 8) {
            Spacer()
            ProgressView()
                .tint(.pokedexGreen)
            Text("LOADING DATA...")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.pokedexGreen)
            Spacer()
        }
    }

    // MARK: - Error screen
    private func errorScreen(message: String, width: CGFloat) -> some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(Color.pokedexYellow)
                .font(.title2)
            Text("ERROR")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.pokedexYellow)
            Text(message)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Spacer()
        }
    }

    // MARK: - Scanline overlay
    private func scanlineOverlay(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Horizontal scanlines
            VStack(spacing: 4) {
                ForEach(0..<Int(height / 6), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .frame(height: 2)
                    Spacer().frame(height: 2)
                }
            }
            .frame(width: width, height: height)

            // Moving scan line
            Rectangle()
                .fill(Color.pokedexScanLine)
                .frame(width: width, height: 3)
                .offset(y: scanLineOffset)
                .blur(radius: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onAppear { animateScanLine(height: height) }
    }

    // MARK: - Bottom section: buttons and D-pad
    private func bottomSection(width: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 0) {
            // Left: round dark button
            VStack {
                Circle()
                    .fill(Color.pokedexGray)
                    .frame(width: width * 0.12, height: width * 0.12)
                    .shadow(radius: 3)
                Spacer()
            }
            .padding(.leading, 20)
            .padding(.top, 8)

            Spacer()

            // Center: two small buttons + green area
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    // Language switch button
                    Button(action: {
                        viewModel.toggleLanguage()
                        PokedexSoundManager.shared.playSound(.beep)
                    }) {
                        Capsule()
                            .fill(Color(red: 0.8, green: 0.2, blue: 0.2))
                            .frame(width: width * 0.12, height: 10)
                    }
                    .buttonStyle(.plain)

                    Capsule()
                        .fill(Color.pokedexTeal)
                        .frame(width: width * 0.14, height: 10)
                }

                // Language indicator
                Text(viewModel.selectedLanguage.displayName)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))

                // Green display area
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pokedexGreen.opacity(0.85))
                        .frame(width: width * 0.30, height: width * 0.12)
                    Text(statusText)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Right: D-pad
            dPad(size: width * 0.22)
                .padding(.trailing, 20)
                .padding(.top, 8)
        }
        .padding(.vertical, 16)
    }

    // MARK: - D-pad
    private func dPad(size: CGFloat) -> some View {
        ZStack {
            // Horizontal bar
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.pokedexGray)
                .frame(width: size, height: size / 3)
            // Vertical bar
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.pokedexGray)
                .frame(width: size / 3, height: size)
            // Center
            Circle()
                .fill(Color.pokedexGray.opacity(0.5))
                .frame(width: size / 3.5, height: size / 3.5)
        }
    }

    // MARK: - Corner markers for targeting overlay
    private func cornerMarkers(size: CGFloat) -> some View {
        let len: CGFloat = 16
        let t: CGFloat = 2
        return ZStack {
            // Top-left
            Path { p in
                p.move(to: CGPoint(x: 0, y: len))
                p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: len, y: 0))
            }.stroke(Color.pokedexGreen, lineWidth: t).offset(x: -size/2 + 4, y: -size/2 + 4)

            // Top-right
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: len, y: 0))
                p.addLine(to: CGPoint(x: len, y: len))
            }.stroke(Color.pokedexGreen, lineWidth: t).offset(x: size/2 - len - 4, y: -size/2 + 4)

            // Bottom-left
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: 0, y: len))
                p.addLine(to: CGPoint(x: len, y: len))
            }.stroke(Color.pokedexGreen, lineWidth: t).offset(x: -size/2 + 4, y: size/2 - len - 4)

            // Bottom-right
            Path { p in
                p.move(to: CGPoint(x: 0, y: len))
                p.addLine(to: CGPoint(x: len, y: len))
                p.addLine(to: CGPoint(x: len, y: 0))
            }.stroke(Color.pokedexGreen, lineWidth: t).offset(x: size/2 - len - 4, y: size/2 - len - 4)
        }
    }

    // MARK: - Indicator dot
    private func indicatorDot(_ color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.8), radius: 3)
    }

    // MARK: - Helpers
    private var statusText: String {
        switch viewModel.scanState {
        case .idle:      return showCamera ? "LIVE" : "READY"
        case .scanning:  return "SCAN"
        case .found:     return "FOUND!"
        case .loading:   return "LOAD"
        case .error:     return "ERROR"
        }
    }

    private func openCamera() {
        PokedexSoundManager.shared.playSound(.beep)
        showCamera = true
    }

    private func capturePhoto() {
        cameraManager.capturePhoto()
        PokedexSoundManager.shared.playSound(.scan)
    }

    private func animateScanLine(height: CGFloat) {
        let half = height / 2
        scanLineOffset = -half
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            scanLineOffset = half
        }
    }
}

// MARK: - ScanState helper
extension ScanState {
    var isScanning: Bool {
        if case .scanning = self { return true }
        return false
    }
}

#Preview {
    PokedexHomeView()
}
