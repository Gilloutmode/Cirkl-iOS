import SwiftUI
import Kingfisher
import Shimmer

/// Individual connection bubble with glassmorphic design
struct ConnectionBubble: View {
    let connection: Connection
    let isSelected: Bool
    let isHovered: Bool
    var showTrustBadge: Bool = true

    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            
            // Main bubble with LiquidGlass effect
            ZStack {
                // === LIQUID GLASS BACKGROUND (iOS 26) ===
                Circle()
                    .fill(connection.color.opacity(bubbleOpacity * 0.3))
                    .frame(width: bubbleSize, height: bubbleSize)
                    .glassEffect(.regular.interactive(), in: .circle)

                // === SUBTLE BORDER ===
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                connection.color.opacity(0.5),
                                Color.white.opacity(isHovered ? 0.4 : 0.2),
                                connection.color.opacity(0.3),
                                Color.white.opacity(isHovered ? 0.3 : 0.15),
                                connection.color.opacity(0.5)
                            ],
                            center: .center
                        ),
                        lineWidth: isSelected ? 2.5 : 1.5
                    )
                    .frame(width: bubbleSize - 2, height: bubbleSize - 2)

                // Content
                VStack(spacing: 4) {
                    // Avatar with Kingfisher
                    if let avatarURL = connection.avatarURL {
                        KFImage(avatarURL)
                            .placeholder {
                                // Shimmer placeholder
                                Circle()
                                    .fill(connection.color.opacity(0.2))
                                    .frame(width: bubbleSize * 0.6, height: bubbleSize * 0.6)
                                    .shimmering()
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: bubbleSize * 0.25))
                                            .foregroundColor(connection.color.opacity(0.5))
                                    )
                            }
                            .retry(maxCount: 2, interval: .seconds(2))
                            .fade(duration: 0.3)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: bubbleSize * 0.6, height: bubbleSize * 0.6)
                            .clipShape(Circle())
                    } else {
                        // Fallback: initials or icon
                        Circle()
                            .fill(connection.color.opacity(0.3))
                            .frame(width: bubbleSize * 0.6, height: bubbleSize * 0.6)
                            .overlay(
                                Text(connection.name.prefix(1).uppercased())
                                    .font(.system(size: bubbleSize * 0.25, weight: .bold, design: .rounded))
                                    .foregroundColor(connection.color)
                            )
                    }

                    // Name (only if hovered or selected)
                    if isHovered || isSelected {
                        Text(connection.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: bubbleSize, height: bubbleSize)
            .scaleEffect(isSelected ? 1.2 : (isHovered ? 1.1 : 1.0))
            .shadow(color: connection.color.opacity(isSelected ? 0.4 : 0.2), radius: isSelected ? 12 : 6, y: isSelected ? 6 : 3)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)

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
            // Only animate if Reduce Motion is not enabled
            if connection.hasActiveOpportunity && !reduceMotion {
                isAnimating = true
            }
        }
        // MARK: - Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double-tap pour voir le profil")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(accessibilityValueText)
    }

    // MARK: - Accessibility Helpers

    private var accessibilityLabelText: String {
        var label = connection.name

        // Add role/company if available
        if let role = connection.role, !role.isEmpty {
            label += ", \(role)"
        }
        if let company = connection.company, !company.isEmpty {
            label += " chez \(company)"
        }

        return label
    }

    private var accessibilityValueText: String {
        var values: [String] = []

        // Trust level
        switch connection.trustLevel {
        case .superVerified:
            values.append("Connexion super vérifiée")
        case .verified:
            values.append("Connexion vérifiée")
        case .attested:
            values.append("Connexion attestée")
        case .pending:
            values.append("En attente de vérification")
        case .invited:
            values.append("Invitation envoyée")
        }

        // Active opportunity
        if connection.hasActiveOpportunity {
            values.append("Opportunité active")
        }

        return values.joined(separator: ", ")
    }
}