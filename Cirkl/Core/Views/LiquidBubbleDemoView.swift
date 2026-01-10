import SwiftUI

/// Demo view showcasing all liquid bubble variations and animations
struct LiquidBubbleDemoView: View {
    @State private var searchText = ""
    @State private var isSearchFocused = false
    @State private var selectedBubbleSize: CGFloat = 60
    @State private var isAnimationsActive = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Liquid Bubble Demo")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("Apple Intelligence-inspired liquid motion design")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Controls
                    VStack(spacing: 20) {
                        // Animation toggle
                        Toggle("Animations Active", isOn: $isAnimationsActive)
                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                        
                        // Size slider
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bubble Size: \(Int(selectedBubbleSize))")
                                .font(.headline)
                            
                            Slider(value: $selectedBubbleSize, in: 20...120, step: 10)
                                .tint(.purple)
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Search bar demo
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search Bar Integration")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        LiquidSearchBar(text: $searchText)
                            .frame(width: 300)
                    }
                    
                    // Different bubble sizes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Size Variations")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 8) {
                                LiquidBubbleView(size: 30, isActive: isAnimationsActive)
                                Text("Small")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(spacing: 8) {
                                LiquidBubbleView(size: 60, isActive: isAnimationsActive)
                                Text("Medium")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(spacing: 8) {
                                LiquidBubbleView(size: 90, isActive: isAnimationsActive)
                                Text("Large")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Interactive button
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Interactive Button")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        LiquidBubbleButton(action: {
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }, size: 60, isActive: isAnimationsActive)
                    }
                    
                    // Color variations
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Color Variations")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                            ColorBubbleDemo(
                                colors: [.purple, .pink, .cyan],
                                name: "Purple",
                                isActive: isAnimationsActive
                            )
                            
                            ColorBubbleDemo(
                                colors: [.blue, .cyan, .teal],
                                name: "Blue",
                                isActive: isAnimationsActive
                            )
                            
                            ColorBubbleDemo(
                                colors: [.orange, .yellow, .red],
                                name: "Warm",
                                isActive: isAnimationsActive
                            )
                            
                            ColorBubbleDemo(
                                colors: [.green, .mint, .cyan],
                                name: "Green",
                                isActive: isAnimationsActive
                            )
                            
                            ColorBubbleDemo(
                                colors: [.indigo, .purple, .pink],
                                name: "Indigo",
                                isActive: isAnimationsActive
                            )
                            
                            ColorBubbleDemo(
                                colors: [.red, .pink, .orange],
                                name: "Red",
                                isActive: isAnimationsActive
                            )
                        }
                    }
                    
                    // Animation details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Animation Details")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            AnimationDetailRow(
                                title: "Main Rotation",
                                description: "3-4 seconds per revolution",
                                icon: "arrow.clockwise"
                            )
                            
                            AnimationDetailRow(
                                title: "Breathing",
                                description: "2-3 second cycle (in and out)",
                                icon: "lungs"
                            )
                            
                            AnimationDetailRow(
                                title: "Shimmer",
                                description: "Passes every 2 seconds",
                                icon: "sparkles"
                            )
                            
                            AnimationDetailRow(
                                title: "Multiple Layers",
                                description: "4s, 6s, 8s rotations",
                                icon: "layers"
                            )
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(.black)
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Supporting Views

struct ColorBubbleDemo: View {
    let colors: [Color]
    let name: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            LiquidBubbleView(size: 50, colors: colors, isActive: isActive)
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }
}

struct AnimationDetailRow: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    LiquidBubbleDemoView()
}


