import SwiftUI

// MARK: - VerificationBadge
/// Badge affichant le niveau de confiance d'une connexion
struct VerificationBadge: View {

    // MARK: - Properties
    let trustLevel: TrustLevel
    var style: BadgeStyle = .standard

    enum BadgeStyle {
        case standard   // Icon + label
        case compact    // Icon only
        case expanded   // Icon + label + description
    }

    // MARK: - Body
    var body: some View {
        switch style {
        case .standard:
            standardBadge
        case .compact:
            compactBadge
        case .expanded:
            expandedBadge
        }
    }

    // MARK: - Standard Badge
    private var standardBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: trustLevel.icon)
                .font(.caption)
                .foregroundStyle(trustLevel.color)

            Text(trustLevel.displayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(trustLevel.color.opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(trustLevel.color.opacity(0.3), lineWidth: 0.5)
        )
    }

    // MARK: - Compact Badge
    private var compactBadge: some View {
        ZStack {
            Circle()
                .fill(trustLevel.color.opacity(0.2))
                .frame(width: 24, height: 24)

            Image(systemName: trustLevel.icon)
                .font(.system(size: 12))
                .foregroundStyle(trustLevel.color)
        }
    }

    // MARK: - Expanded Badge
    private var expandedBadge: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(trustLevel.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: trustLevel.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(trustLevel.color)
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(trustLevel.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(trustLevel.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(trustLevel.color.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Trust Level Indicator
/// Indicateur visuel simplifié du niveau de confiance (cercles)
struct TrustLevelIndicator: View {
    let trustLevel: TrustLevel

    var body: some View {
        HStack(spacing: 4) {
            ForEach(TrustLevel.allCases, id: \.self) { level in
                Circle()
                    .fill(level <= trustLevel ? trustLevel.color : .white.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Verification Status Tag
/// Tag de statut de vérification pour les listes
struct VerificationStatusTag: View {
    let trustLevel: TrustLevel

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(trustLevel.color)
                .frame(width: 6, height: 6)

            Text(shortLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(trustLevel.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(trustLevel.color.opacity(0.1))
        .clipShape(Capsule())
    }

    private var shortLabel: String {
        switch trustLevel {
        case .invited: return "INVITÉ"
        case .pending: return "EN ATTENTE"
        case .attested: return "ATTESTÉE"
        case .verified: return "VÉRIFIÉE"
        case .superVerified: return "SUPER VÉRIFIÉE"
        }
    }
}

// MARK: - Connection Verification Icon
/// Icône de vérification pour les bulles de connexion dans l'orbital
struct ConnectionVerificationIcon: View {
    let trustLevel: TrustLevel
    var showPulse: Bool = false

    @State private var pulse = false

    var body: some View {
        ZStack {
            // Pulse effect for verified
            if showPulse && trustLevel >= .verified {
                Circle()
                    .fill(trustLevel.color.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .scaleEffect(pulse ? 1.5 : 1.0)
                    .opacity(pulse ? 0 : 1)
            }

            // Icon
            Image(systemName: trustLevel.icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(trustLevel.color)
                .padding(4)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .stroke(trustLevel.color.opacity(0.5), lineWidth: 1)
                )
        }
        .onAppear {
            if showPulse && trustLevel >= .verified {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("All Badge Styles") {
    ZStack {
        Color(red: 0.04, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                // Standard badges
                Text("Standard").font(.headline).foregroundStyle(.white)
                HStack(spacing: 12) {
                    ForEach(TrustLevel.allCases, id: \.self) { level in
                        VerificationBadge(trustLevel: level, style: .standard)
                    }
                }

                // Compact badges
                Text("Compact").font(.headline).foregroundStyle(.white)
                HStack(spacing: 16) {
                    ForEach(TrustLevel.allCases, id: \.self) { level in
                        VerificationBadge(trustLevel: level, style: .compact)
                    }
                }

                // Expanded badges
                Text("Expanded").font(.headline).foregroundStyle(.white)
                VStack(spacing: 12) {
                    ForEach(TrustLevel.allCases, id: \.self) { level in
                        VerificationBadge(trustLevel: level, style: .expanded)
                    }
                }
                .padding(.horizontal)

                // Trust level indicators
                Text("Indicators").font(.headline).foregroundStyle(.white)
                VStack(spacing: 12) {
                    ForEach(TrustLevel.allCases, id: \.self) { level in
                        HStack {
                            Text(level.displayName)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Spacer()
                            TrustLevelIndicator(trustLevel: level)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Status tags
                Text("Status Tags").font(.headline).foregroundStyle(.white)
                HStack(spacing: 8) {
                    ForEach(TrustLevel.allCases, id: \.self) { level in
                        VerificationStatusTag(trustLevel: level)
                    }
                }

                // Connection icons
                Text("Connection Icons").font(.headline).foregroundStyle(.white)
                HStack(spacing: 16) {
                    ForEach(TrustLevel.allCases, id: \.self) { level in
                        ConnectionVerificationIcon(trustLevel: level, showPulse: true)
                    }
                }
            }
            .padding()
        }
    }
}
