import AVFoundation
import UIKit
import Foundation
import Observation

// MARK: - Camera Manager
@Observable
@MainActor
final class CameraManager: NSObject {
    var isAuthorized = false
    var capturedImage: UIImage?
    var isRunning = false

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private var onFrame: ((CVPixelBuffer) -> Void)?
    private var frameThrottle = 0
    private let frameInterval = 10 // process every Nth frame

    override init() {
        super.init()
        Task { await checkAuthorization() }
    }

    // MARK: - Authorization
    func checkAuthorization() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isAuthorized = false
        }
    }

    // MARK: - Setup
    func setupSession(previewView: UIView, onFrame: @escaping (CVPixelBuffer) -> Void) {
        self.onFrame = onFrame
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        captureSession = session

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) { session.addInput(input) }

        // Photo capture
        let photo = AVCapturePhotoOutput()
        if session.canAddOutput(photo) {
            session.addOutput(photo)
            photoOutput = photo
        }

        // Live frames for recognition
        let video = AVCaptureVideoDataOutput()
        video.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        video.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frames", qos: .userInitiated))
        video.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(video) {
            session.addOutput(video)
            videoOutput = video
        }

        // Preview
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = previewView.bounds
        previewView.layer.insertSublayer(preview, at: 0)
        previewLayer = preview

        Task.detached { [weak session] in
            session?.startRunning()
            await MainActor.run { [weak self] in self?.isRunning = true }
        }
    }

    // MARK: - Capture photo
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Stop
    func stopSession() {
        Task.detached { [weak captureSession] in
            captureSession?.stopRunning()
            await MainActor.run { [weak self] in self?.isRunning = false }
        }
    }

    func updatePreviewFrame(_ frame: CGRect) {
        previewLayer?.frame = frame
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Throttle frames
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.frameThrottle += 1
            guard self.frameThrottle % self.frameInterval == 0 else { return }
            self.onFrame?(pixelBuffer)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        Task { @MainActor [weak self] in
            self?.capturedImage = image
        }
    }
}
