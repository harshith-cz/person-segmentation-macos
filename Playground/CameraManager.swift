//
//  CameraManager.swift
//  Playground
//
//  Created by Harshith on 23/06/25.
//

import SwiftUI
import AVFoundation
import AppKit
import Vision
import CoreImage.CIFilterBuiltins

enum Background {
    case solid, image
}
@Observable
final class CameraManager: NSObject {
    let captureSession: AVCaptureSession = AVCaptureSession()
    private var videoInput: AVCaptureDeviceInput?
    private let videoQueue = DispatchQueue(label: "videoQueue", qos: .default)
    private let videoOutput = AVCaptureVideoDataOutput()
    private let ciContext = CIContext()
    private var selectedBackground: Background = .solid
    
    var isSessionRunning: Bool = false
    var isRecording: Bool = false
    var permissionGranted: Bool = false
    var processedImage: NSImage?
    
    private let personSegmentationRequest: VNGeneratePersonSegmentationRequest = {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        return request
    }()
    
    func initialize() async {
        await requestPermission()
        if permissionGranted {
            await setupCameraSession()
        }
    }
    
    func stopSession() {
        captureSession.stopRunning()
        isSessionRunning = false
    }
    
    @MainActor
    private func requestPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
            case .authorized: permissionGranted = true
            case .notDetermined: permissionGranted = await AVCaptureDevice.requestAccess(for: .video)
            default: permissionGranted = false
        }
    }
    
    private func setupCameraSession() async {
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
            print("Error setting up video \(error)")
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
        
        let scaleX = originalImage.extent.width / maskImage.extent.width
        let scaleY = originalImage.extent.height / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = originalImage
        blendFilter.backgroundImage = createSolidBackground(color: .blue, size: originalImage.extent.size)
        blendFilter.maskImage = scaledMask
        
        return blendFilter.outputImage ?? originalImage
    }
    
    private func createSolidBackground(color: NSColor, size: CGSize) -> CIImage {
        let ciColor = CIColor(color: color) ?? CIColor.black
        return CIImage(color: ciColor).cropped(to: CGRect(origin: .zero, size: size))
    }
    
    private func createCustomImageBackground(size: CGSize) -> CIImage {
        CIImage(color: .yellow) //TODO: yet to implement image background
    }
    
//    @MainActor
//    func changeBackground(to type: BackgroundType) {
//        selectedBackground = type
//    }
}

extension CameraManager : AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processPersonSegmentation(pixelBuffer: pixelBuffer)
    }
}
