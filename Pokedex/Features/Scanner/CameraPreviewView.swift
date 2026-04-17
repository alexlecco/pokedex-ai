import SwiftUI
import AVFoundation

// MARK: - UIView wrapper for AVFoundation camera preview
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    let onFrame: (CVPixelBuffer) -> Void

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if !cameraManager.isRunning {
            cameraManager.setupSession(previewView: uiView, onFrame: onFrame)
        }
    }

    static func dismantleUIView(_ uiView: CameraPreviewUIView, coordinator: ()) {
        // cleanup handled by CameraManager.stopSession()
    }
}

final class CameraPreviewUIView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.first.map { $0.frame = bounds }
    }
}
