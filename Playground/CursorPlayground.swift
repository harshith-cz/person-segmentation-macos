//
//  CursorPlayground.swift
//  Playground
//
//  Created by Harshith on 18/06/25.
//

import SwiftUI

struct CursorPlayground: View {
    @State private var speed = 50.0
    @State private var isEditing = false
    @State private var sliderValue1: Double = 0.5
    @State private var sliderValue2: Double = 0.3
    @State private var sliderValue3: Double = 0.7
    @State private var isActive: Bool = false
    var body: some View {
        VStack {
            VStack(spacing: 30) {
                Slider(
                    value: $speed,
                    in: 0...100,
                    onEditingChanged: { editing in
                        isEditing = editing
                    }
                )
                .controlSize(.extraLarge)
                .tint(.red)
                
                Text("Value: \(sliderValue1, specifier: "%.3f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack {
                    OrangeToggleView(
                        isActive: $isActive,
                        text: "Hello World"
                    )
                    SupavdoSlider(
                        value: $sliderValue1,
                        thumbColor: .black
                    )
                    ButtonStyleView(title: "Reset", isDisabled: false, action: { isActive.toggle() })
                    
                    SliderTextField(
                        value: "50", suffix: "°"
                    )
                }
                .frame(width: 300, alignment: .center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct ButtonStyleView: View {
    private let title: String
    private var isDisabled: Bool
    private let action: () -> Void

    init(title: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .disabled(isDisabled)
        .background(Color.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .buttonStyle(PlainButtonStyle())
        .opacity(isDisabled ? 0.8 : 1)
    }
}
struct OrangeToggleView: View {
    @Binding var isActive: Bool
    var text: String? = nil
    var body: some View {
        Toggle("",isOn: $isActive)
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            .padding()
    }
}

struct SliderTextField: View {
    let value: String
    let suffix: String?

    init(value: String, suffix: String? = nil) {
        self.value = value
        self.suffix = suffix
    }
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            
            Text(value)
                .font(.callout.monospacedDigit())
                .fontWeight(.regular)
                .lineLimit(1)

            if let suffix = suffix {
                Text(suffix)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.36))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .frame(maxWidth: 50, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(.white.opacity(0.36), lineWidth: 2)
        )
    }
}

struct SupavdoSlider: View {
    @Binding var value: Double
    @State private var isDragging = false
    @State private var trackWidth: CGFloat = 0
    private let range: ClosedRange<Double>
    private let trackColor: Color
    private let activeTrackColor: Color
    private let thumbColor: Color
    private let thumbBorderColor: Color
    private let thumbBorderWidth: CGFloat
    private let trackHeight: CGFloat
    private let thumbSize: CGFloat
    
    private var usableWidth: CGFloat {
        max(0, trackWidth - thumbSize)
    }
    
    private var normalizedValue: Double {
        guard range.upperBound != range.lowerBound else { return 0 }
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    private var thumbPosition: CGFloat {
        CGFloat(normalizedValue) * usableWidth
    }
    
    private var activeTrackWidth: CGFloat {
        thumbPosition + thumbSize / 2
    }
    
    init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        trackColor: Color = Color.gray.opacity(0.3),
        activeTrackColor: Color = .blue,
        thumbColor: Color = .blue,
        thumbBorderColor: Color = .blue,
        thumbBorderWidth: CGFloat = 1,
        trackHeight: CGFloat = 4,
        thumbSize: CGFloat = 20
    ) {
        self._value = value
        self.range = range
        self.trackColor = trackColor
        self.activeTrackColor = activeTrackColor
        self.thumbColor = thumbColor
        self.thumbBorderColor = thumbBorderColor
        self.thumbBorderWidth = thumbBorderWidth
        self.trackHeight = trackHeight
        self.thumbSize = thumbSize
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            RoundedRectangle(cornerRadius: trackHeight / 2)
                .fill(trackColor)
                .frame(height: trackHeight)
            
            RoundedRectangle(cornerRadius: trackHeight / 2)
                .fill(activeTrackColor)
                .frame(width: activeTrackWidth, height: trackHeight)
            
            thumbView
                .offset(x: thumbPosition)
        }
        .frame(height: max(thumbSize, trackHeight))
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        trackWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) { _, newWidth in
                        trackWidth = newWidth
                    }
            }
        )
        .contentShape(Rectangle())
        .gesture(sliderGesture)
    }
    
    private var thumbView: some View {
        Circle()
            .fill(thumbColor)
            .background(
                Circle()
                    .fill(Color.black.opacity(1))
            )
            .overlay(
                Circle()
                    .stroke(thumbBorderColor, lineWidth: thumbBorderWidth)
            )
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isDragging)
    }
    
    private var sliderGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                updateValue(from: drag.location.x, animated: !isDragging)
                if !isDragging {
                    isDragging = true
                }
            }
            .onEnded { _ in
                isDragging = false
            }
    }
    
    private func updateValue(from locationX: CGFloat, animated: Bool) {
        guard usableWidth > 0 else { return }
        
        let newPosition = max(0, min(usableWidth, locationX - thumbSize / 2))
        let newValue = range.lowerBound + (Double(newPosition) / Double(usableWidth)) * (range.upperBound - range.lowerBound)
        
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                value = newValue
            }
        } else {
            value = newValue
        }
    }
}

#Preview {
    CursorPlayground()
}
