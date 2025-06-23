import SwiftUI

struct BackgroundReplacementView: View {
    @State private var segmentationManager = PersonSegmentationManager()
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            
            cameraPreviewSection
            
            backgroundControlsSection
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.gradient.opacity(0.1))
        .task {
            await segmentationManager.initialize()
        }
        .onDisappear {
            segmentationManager.stopSession()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Virtual Background")
                .font(.title.bold())
                .foregroundColor(.primary)
            
            Text("AI-powered background replacement using person segmentation")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var cameraPreviewSection: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 400, height: 300)
                
                if let processedImage = segmentationManager.processedImage {
                    Image(nsImage: processedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 400, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                } else if segmentationManager.permissionGranted {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)
                        
                        Text("Processing camera feed...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("Camera permission required")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            statusIndicator
        }
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(segmentationManager.isSessionRunning ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text(segmentationManager.isSessionRunning ? "Live" : "Offline")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var backgroundControlsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Background Options")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                Button("Debug Mask") {
                    segmentationManager.showDebugMask.toggle()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if !segmentationManager.showDebugMask {
                backgroundGrid
            } else {
                Text("Debug Mode: Showing person segmentation mask\nWhite = Person, Black = Background")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var backgroundGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(PersonSegmentationManager.BackgroundType.allCases, id: \.self) { backgroundType in
                BackgroundOptionCard(
                    type: backgroundType,
                    isSelected: segmentationManager.selectedBackground == backgroundType
                ) {
                    Task { @MainActor in
                        await segmentationManager.changeBackground(to: backgroundType)
                    }
                }
            }
        }
    }
}

struct BackgroundOptionCard: View {
    let type: PersonSegmentationManager.BackgroundType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundPreview)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                        )
                    
                    backgroundIcon
                }
                
                Text(type.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var backgroundPreview: some ShapeStyle {
        switch type {
        case .blur:
            return AnyShapeStyle(Color.blue.opacity(0.3))
        case .black:
            return AnyShapeStyle(Color.black)
        case .white:
            return AnyShapeStyle(Color.white)
        case .gradient:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.pink, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .image:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.green.opacity(0.8), .blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    private var backgroundIcon: some View {
        Group {
            switch type {
            case .blur:
                Image(systemName: "camera.filters")
            case .black:
                Image(systemName: "circle.fill")
            case .white:
                Image(systemName: "circle")
            case .gradient:
                Image(systemName: "paintbrush.fill")
            case .image:
                Image(systemName: "photo.fill")
            }
        }
        .font(.title2)
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.5), radius: 2)
    }
}

#Preview {
    BackgroundReplacementView()
}
