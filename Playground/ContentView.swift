//
//  ContentView.swift
//  Playground
//
//  Created by Harshith on 16/06/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isActive: Bool = false
    var body: some View {
        VStack(spacing: 8) {
            SupavdoAccordion(
                title: "Wallpapers",
                isActive: true
            ) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Hello World")
                        Spacer()
                        Text("Hello World")
                    }
                    HStack {
                        Text("Hello World")
                        Spacer()
                        Text("Hello World")
                    }
                    HStack {
                        Text("Hello World")
                        Spacer()
                        Text("Hello World")
                    }
                    HStack {
                        Text("Hello World")
                        Spacer()
                        Text("Hello World")
                    }
                }
            }
            
            SupavdoAccordion(
                title: "Other wallpaper"
            ) {
                VStack {
                    Text("Hello World")
                    Text("Hello World")
                    Text("Hello World")
                    Text("Hello World")
                }
            }
            
            SupavdoAccordion(
                title: "Gradient"
            ) {
                Text("Hello World")
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct SupavdoAccordion<Content: View> : View {
    @State private var isActive: Bool
    let title: String
    let content: () -> Content
    init(title: String, isActive: Bool = false, @ViewBuilder content: @escaping () -> Content) {
            self.title = title
            self._isActive = State(initialValue: isActive)
            self.content = content
        }
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.title2)
                    .fontWeight(.bold)
                    .rotationEffect(.degrees(isActive ? 180 : 0))
                    .animation(.easeInOut, value: isActive)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 21)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isActive.toggle()
                        }
                    }
            }
            if isActive {
                content()
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 35, alignment: .center)
        .background(Color.gray, in: RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .padding(.horizontal)
    }
}

//struct SupavdoAccordion<Content: View>: View {
//    @State private var isActive: Bool
//    let title: String
//    let content: () -> Content
//    
//    init(title: String, isActive: Bool = false, @ViewBuilder content: @escaping () -> Content) {
//        self.title = title
//        self._isActive = State(initialValue: isActive)
//        self.content = content
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            HStack {
//                Text(title)
//                    .font(.callout)
//                    .fontWeight(.semibold)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                
//                Spacer()
//                
//                Image(systemName: "chevron.down")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                    .rotationEffect(.degrees(isActive ? 180 : 0))
//                    .foregroundColor(.white)
//                    .frame(width: 44, height: 21)
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        withAnimation(.easeInOut(duration: 0.3)) {
//                            isActive.toggle()
//                        }
//                    }
//            }
//            .frame(height: 35)
//            .padding(.horizontal, 10)
//            .background(Color.gray, in: RoundedRectangle(cornerRadius: 12))
//            
//            if isActive {
//                VStack(spacing: 0) {
//                    content()
//                        .padding(.horizontal, 10)
//                        .padding(.vertical, 8)
//                }
//                .background(Color.gray.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
//                .padding(.top, 1)
//                .transition(.asymmetric(
//                    insertion: .move(edge: .top).combined(with: .opacity),
//                    removal: .move(edge: .top).combined(with: .opacity)
//                ))
//            }
//        }
//        .padding(.horizontal)
//        .clipped()
//    }
//}


#Preview {
    ContentView()
}
