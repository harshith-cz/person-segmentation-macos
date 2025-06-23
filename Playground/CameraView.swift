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
            if let processedImage = cameraManager.processedImage {
                Image(nsImage: processedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 320, height: 240)
                    .clipShape(Circle())
                    .padding()
            }
        }
        .task {
            await cameraManager.initialize()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

#Preview {
    CameraView()
}
