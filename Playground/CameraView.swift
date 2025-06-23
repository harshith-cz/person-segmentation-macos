//
//  CameraView.swift
//  Playground
//
//  Created by Harshith on 23/06/25.
//

import SwiftUI

struct CameraView: View {
    @State private var cameraManager: CameraManager = CameraManager()
    var body: some View {
        VStack {
            CameraPreviewView(session: cameraManager.captureSession)
                .frame(width: 320, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding()
        }
        .task {
            await cameraManager.initialize()
        }
    }
}

#Preview {
    CameraView()
}
