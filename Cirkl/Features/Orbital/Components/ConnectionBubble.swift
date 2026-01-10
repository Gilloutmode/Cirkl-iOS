import SwiftUI

/// Individual connection bubble with glassmorphic design
struct ConnectionBubble: View {
    let connection: Connection
    let isSelected: Bool
    let isHovered: Bool
    var showTrustBadge: Bool = true
    
    @State private var isAnimating = false
    
    // Calculate opacity based on relationship maturity
    private var bubbleOpacity: Double {
        0.3 + (connection.relationshipStrength * 0.7)
    }
    
    // Calculate size based on interaction frequency
    private var bubbleSize: CGFloat {
        60 + (connection.interactionFrequency * 40)
    }
    
    // Determine halo color based on opportunity type
    private var haloColor: Color {
        switch connection.opportunityType {
        case .business:
            return .yellow
        case .romantic:
            return Color(red: 220/255, green: 38/255, blue: 127/255) // Rouge
        case .friendship:
            return .cyan
        case .professional:
            return .orange
        case .creative:
            return .purple
        default:
            return connection.color
        }
    }
    
    var body: some View {
        ZStack {
            // Opportunity halo (if active)
            if connection.hasActiveOpportunity {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                haloColor.opacity(0.6),
                                haloColor.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: bubbleSize * 1.8, height: bubbleSize * 1.8)
                    .blur(radius: 10)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            // Main bubble with glassmorphic effect
            ZStack {
                // Glass background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1 * bubbleOpacity),
                                Color.white.opacity(0.05 * bubbleOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        Circle()
                            .fill(connection.color.opacity(bubbleOpacity * 0.5))
                            .blur(radius: 5)
                    )
                
                // Border
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? 0.5 : 0.2),
                                Color.white.opacity(isHovered ? 0.2 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
                
                // Content
                VStack(spacing: 4) {
                    // Avatar
                    if let avatarURL = connection.avatarURL {
                        AsyncImage(url: avatarURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(width: bubbleSize * 0.6, height: bubbleSize * 0.6)
                        .clipShape(Circle())
                    }
                    
                    // Name (only if hovered or selected)
                    if isHovered || isSelected {
                        Text(connection.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: bubbleSize, height: bubbleSize)
            .scaleEffect(isSelected ? 1.2 : (isHovered ? 1.1 : 1.0))
            .animation(.spring(response: 0.3), value: isSelected)
            .animation(.spring(response: 0.3), value: isHovered)

            // Trust level badge (positioned at bottom-right)
            if showTrustBadge && connection.trustLevel != .pending {
                ConnectionVerificationIcon(
                    trustLevel: connection.trustLevel,
                    showPulse: connection.trustLevel >= .verified
                )
                .offset(x: bubbleSize * 0.35, y: bubbleSize * 0.35)
            }
        }
        .onAppear {
            if connection.hasActiveOpportunity {
                isAnimating = true
            }
        }
    }
}