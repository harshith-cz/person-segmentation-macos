//
//  MetalCIImageView.swift
//  Playground
//
//  Created by Harshith on 24/06/25.
//

import SwiftUI
import MetalKit
import CoreImage

struct CIImageView: NSViewRepresentable {
    let ciImage: CIImage?

    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.ciImage = ciImage
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var ciImage: CIImage?
        private var ciContext: CIContext?
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard
                let drawable = view.currentDrawable,
                let image = ciImage,
                let device = view.device
            else { return }

            if ciContext == nil {
                ciContext = CIContext(mtlDevice: device)
            }

            let drawableSize = view.drawableSize
            let scaleX = drawableSize.width / image.extent.width
            let scaleY = drawableSize.height / image.extent.height
            let scale = min(scaleX, scaleY)

            let scaled = image.transformed(by: .init(scaleX: scale, y: scale))
            let centered = scaled.transformed(by: .init(
                translationX: (drawableSize.width - scaled.extent.width) / 2,
                y: (drawableSize.height - scaled.extent.height) / 2
            ))

            ciContext?.render(
                centered,
                to: drawable.texture,
                commandBuffer: nil,
                bounds: CGRect(origin: .zero, size: drawableSize),
                colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
            )

            drawable.present()
        }
    }
}
