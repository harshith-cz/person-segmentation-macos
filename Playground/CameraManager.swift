//
//  CameraManager.swift
//  Playground
//
//  Created by Harshith on 23/06/25.
//

import SwiftUI
import AVFoundation
import AppKit

@Observable
final class CameraManager: NSObject {
    let captureSession: AVCaptureSession = AVCaptureSession()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var videoInput: AVCaptureDeviceInput?
    
    var isSessionRunning: Bool = false
    var isRecording: Bool = false
    var permissionGranted: Bool = false
    var lastRecordingURL: URL?
    
    func initialize() async {
        await requestPermission()
        if permissionGranted {
            await setupCameraSession()
        }
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
        setupMovieOutput()
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
    
    private func setupMovieOutput() {
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
            
            if let connection = movieOutput.connection(with: .video) {
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
}

//struct CameraPreviewView: NSViewRepresentable {
//    let session: AVCaptureSession
//    
//    func makeNSView(context: Context) -> NSView {
//        let view = NSView()
//        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
//        previewLayer.videoGravity = .resizeAspectFill
//        
//        view.layer = previewLayer
//        view.wantsLayer = true
//        return view
//    }
//    
//    func updateNSView(_ nsView: NSView, context: Context) {
//        guard let previewLayer = nsView.layer as? AVCaptureVideoPreviewLayer else {
//            return 
//        }
//        previewLayer.frame = nsView.bounds
//    }
//}
