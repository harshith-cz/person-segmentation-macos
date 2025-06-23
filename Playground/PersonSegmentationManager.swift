import SwiftUI
import AVFoundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

@Observable
final class PersonSegmentationManager: NSObject {
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
    
    private var videoInput: AVCaptureDeviceInput?
    private let ciContext = CIContext()
    
    var permissionGranted = false
    var isSessionRunning = false
    var processedImage: NSImage?
    var selectedBackground: BackgroundType = .blur
    var showDebugMask = false
    
    private let personSegmentationRequest: VNGeneratePersonSegmentationRequest = {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        return request
    }()
    
    enum BackgroundType: String, CaseIterable {
        case blur = "Blur"
        case black = "Black"
        case white = "White"
        case gradient = "Gradient"
        case image = "Custom Image"
        
        var displayName: String { rawValue }
    }
    
    func initialize() async {
        await requestPermission()
        if permissionGranted {
            await setupSession()
        }
    }
    
    @MainActor
    private func requestPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            permissionGranted = await AVCaptureDevice.requestAccess(for: .video)
        default:
            permissionGranted = false
        }
    }
    
    private func setupSession() async {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        await setupVideoInput()
        setupVideoOutput()
        
        captureSession.commitConfiguration()
        
        await MainActor.run {
            startSession()
        }
    }
    
    private func setupVideoInput() async {
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                videoInput = input
            }
        } catch {
            print("Error setting up video input: \(error)")
        }
    }
    
    private func setupVideoOutput() {
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true
                }
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }
    }
    
    @MainActor
    private func startSession() {
        Task {
            captureSession.startRunning()
            isSessionRunning = captureSession.isRunning
        }
    }
    
    func stopSession() {
        captureSession.stopRunning()
        isSessionRunning = false
    }
    
    @MainActor
    func changeBackground(to type: BackgroundType) {
        selectedBackground = type
    }
    
    private func processPersonSegmentation(pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([personSegmentationRequest])
            
            guard let maskObservation = personSegmentationRequest.results?.first else { return }
            
            let maskPixelBuffer = maskObservation.pixelBuffer
            let originalImage = CIImage(cvPixelBuffer: pixelBuffer)
            
            let segmentedImage = applyPersonSegmentation(
                originalImage: originalImage,
                maskPixelBuffer: maskPixelBuffer
            )
            
            if let cgImage = ciContext.createCGImage(segmentedImage, from: segmentedImage.extent) {
                let nsImage = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
                
                DispatchQueue.main.async { [weak self] in
                    self?.processedImage = nsImage
                }
            }
        } catch {
            print("Error performing person segmentation: \(error)")
        }
    }
    
    private func applyPersonSegmentation(originalImage: CIImage, maskPixelBuffer: CVPixelBuffer) -> CIImage {
        let maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        
        // Scale mask to match original image size
        let scaleX = originalImage.extent.width / maskImage.extent.width
        let scaleY = originalImage.extent.height / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Uncomment next 3 lines if mask appears inverted (black person, white background)
        // let invertFilter = CIFilter.colorInvert()
        // invertFilter.inputImage = scaledMask
        // let finalMask = invertFilter.outputImage ?? scaledMask
        
        // Debug mode: show just the mask
        if showDebugMask {
            return scaledMask
        }
        
        let backgroundImage = createBackgroundImage(size: originalImage.extent.size)
        
        // Simple blend: person (where mask is white) over background (where mask is black)
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = originalImage      // Show this where mask is WHITE (person)
        blendFilter.backgroundImage = backgroundImage // Show this where mask is BLACK (background)
        blendFilter.maskImage = scaledMask
        
        return blendFilter.outputImage ?? originalImage
    }
    
    private func createBackgroundImage(size: CGSize) -> CIImage {
        switch selectedBackground {
        case .blur:
            return createBlurBackground(size: size)
        case .black:
            return createSolidBackground(color: .black, size: size)
        case .white:
            return createSolidBackground(color: .white, size: size)
        case .gradient:
            return createGradientBackground(size: size)
        case .image:
            return createCustomImageBackground(size: size)
        }
    }
    
    private func createBlurBackground(size: CGSize) -> CIImage {
        let color = CIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0)
        return CIImage(color: color).cropped(to: CGRect(origin: .zero, size: size))
    }
    
    private func createSolidBackground(color: NSColor, size: CGSize) -> CIImage {
        let ciColor = CIColor(color: color) ?? CIColor.black
        return CIImage(color: ciColor).cropped(to: CGRect(origin: .zero, size: size))
    }
    
    private func createGradientBackground(size: CGSize) -> CIImage {
        let gradientFilter = CIFilter.linearGradient()
        gradientFilter.point0 = CGPoint(x: 0, y: 0)
        gradientFilter.point1 = CGPoint(x: 0, y: size.height)
        gradientFilter.color0 = CIColor(red: 0.9, green: 0.3, blue: 0.8, alpha: 1.0)
        gradientFilter.color1 = CIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        
        return gradientFilter.outputImage?.cropped(to: CGRect(origin: .zero, size: size)) ??
               createSolidBackground(color: .blue, size: size)
    }
    
    private func createCustomImageBackground(size: CGSize) -> CIImage {
        guard let image = NSImage(named: "background") else {
            return createGradientBackground(size: size)
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return createGradientBackground(size: size)
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let scaleFilter = CIFilter.lanczosScaleTransform()
        scaleFilter.inputImage = ciImage
        scaleFilter.scale = Float(size.width / ciImage.extent.width)
        
        return scaleFilter.outputImage?.cropped(to: CGRect(origin: .zero, size: size)) ??
               createGradientBackground(size: size)
    }
}

extension PersonSegmentationManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processPersonSegmentation(pixelBuffer: pixelBuffer)
    }
}
