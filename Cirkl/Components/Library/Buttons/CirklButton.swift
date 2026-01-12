//
//  CirklButton.swift
//  Cirkl
//
//  Created by Claude on 11/01/2026.
//

import SwiftUI

// MARK: - Button Variants

/// Available button style variants
enum CirklButtonVariant {
    case primary      // Solid primary color background
    case secondary    // Outlined with primary color border
    case ghost        // Text only, no background
    case glass        // Liquid Glass effect (iOS 26)
    case destructive  // Red/error color for dangerous actions
}

/// Available button sizes
enum CirklButtonSize {
    case small   // 36pt height
    case medium  // 44pt height (default, meets accessibility)
    case large   // 52pt height

    var height: CGFloat {
        switch self {
        case .small: return DesignTokens.Sizes.buttonSmall
        case .medium: return DesignTokens.Sizes.buttonMedium
        case .large: return DesignTokens.Sizes.buttonLarge
        }
    }

    var font: Font {
        switch self {
        case .small: return DesignTokens.Typography.buttonSmall
        case .medium, .large: return DesignTokens.Typography.button
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return DesignTokens.Spacing.md
        case .medium: return DesignTokens.Spacing.lg
        case .large: return DesignTokens.Spacing.xl
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return DesignTokens.Sizes.iconSmall
        case .medium: return DesignTokens.Sizes.iconMedium
        case .large: return DesignTokens.Sizes.iconLarge
        }
    }
}

// MARK: - CirklButton View

/// A versatile button component following the Cirkl design system
/// Supports multiple variants, sizes, icons, and loading states
struct CirklButton: View {
    // MARK: Properties

    let title: String
    let variant: CirklButtonVariant
    let size: CirklButtonSize
    let icon: String?
    let iconPosition: IconPosition
    let isFullWidth: Bool
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    enum IconPosition {
        case leading, trailing
    }

    // MARK: Initialization

    init(
        _ title: String,
        variant: CirklButtonVariant = .primary,
        size: CirklButtonSize = .medium,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.icon = icon
        self.iconPosition = iconPosition
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    // MARK: Body

    var body: some View {
        Button(action: {
            guard !isLoading && !isDisabled else { return }
            action()
        }) {
            buttonContent
        }
        .buttonStyle(CirklButtonInternalStyle(
            variant: variant,
            size: size,
            isFullWidth: isFullWidth,
            isDisabled: isDisabled || isLoading
        ))
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Chargement en cours" : "")
    }

    // MARK: Content

    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                    .scaleEffect(0.8)
            } else {
                if let icon = icon, iconPosition == .leading {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .medium))
                }

                Text(title)
                    .font(size.font)

                if let icon = icon, iconPosition == .trailing {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .medium))
                }
            }
        }
    }

    // MARK: Colors

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return .white
        case .secondary:
            return DesignTokens.Colors.primary
        case .ghost:
            return DesignTokens.Colors.textPrimary
        case .glass:
            return DesignTokens.Colors.textPrimary
        }
    }
}

// MARK: - Internal Button Style

private struct CirklButtonInternalStyle: ButtonStyle {
    let variant: CirklButtonVariant
    let size: CirklButtonSize
    let isFullWidth: Bool
    let isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: size.height)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, size.horizontalPadding)
            .foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
            .background(backgroundView(isPressed: configuration.isPressed))
            .overlay(overlayView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .opacity(isDisabled ? 0.5 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignTokens.Animations.fast, value: configuration.isPressed)
    }

    // MARK: Style Helpers

    private var cornerRadius: CGFloat {
        switch size {
        case .small: return DesignTokens.Radius.small
        case .medium: return DesignTokens.Radius.medium
        case .large: return DesignTokens.Radius.large
        }
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        let baseColor: Color
        switch variant {
        case .primary, .destructive:
            baseColor = .white
        case .secondary:
            baseColor = DesignTokens.Colors.primary
        case .ghost:
            baseColor = DesignTokens.Colors.textPrimary
        case .glass:
            baseColor = DesignTokens.Colors.textPrimary
        }
        return isPressed ? baseColor.opacity(0.8) : baseColor
    }

    @ViewBuilder
    private func backgroundView(isPressed: Bool) -> some View {
        switch variant {
        case .primary:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.Colors.primary,
                            DesignTokens.Colors.primary.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(isPressed ? 0.9 : 1.0)

        case .secondary:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.clear)

        case .ghost:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(isPressed ? DesignTokens.Colors.textPrimary.opacity(0.1) : Color.clear)

        case .glass:
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.clear)
                    .glassEffect(
                        isPressed ? .regular : .regular.interactive(),
                        in: .rect(cornerRadius: cornerRadius)
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            }

        case .destructive:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(DesignTokens.Colors.error)
                .opacity(isPressed ? 0.9 : 1.0)
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        switch variant {
        case .secondary:
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(DesignTokens.Colors.primary, lineWidth: 1.5)

        case .glass:
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(DesignTokens.Colors.glassBorder, lineWidth: 0.5)

        default:
            EmptyView()
        }
    }
}

// MARK: - Convenience Initializers

extension CirklButton {
    /// Primary button with icon
    static func primary(
        _ title: String,
        icon: String? = nil,
        size: CirklButtonSize = .medium,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) -> CirklButton {
        CirklButton(
            title,
            variant: .primary,
            size: size,
            icon: icon,
            isFullWidth: isFullWidth,
            action: action
        )
    }

    /// Secondary outlined button
    static func secondary(
        _ title: String,
        icon: String? = nil,
        size: CirklButtonSize = .medium,
        action: @escaping () -> Void
    ) -> CirklButton {
        CirklButton(
            title,
            variant: .secondary,
            size: size,
            icon: icon,
            action: action
        )
    }

    /// Glass effect button (iOS 26)
    static func glass(
        _ title: String,
        icon: String? = nil,
        size: CirklButtonSize = .medium,
        action: @escaping () -> Void
    ) -> CirklButton {
        CirklButton(
            title,
            variant: .glass,
            size: size,
            icon: icon,
            action: action
        )
    }

    /// Destructive/danger button
    static func destructive(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> CirklButton {
        CirklButton(
            title,
            variant: .destructive,
            icon: icon,
            action: action
        )
    }
}

// MARK: - Preview

#Preview("Button Variants") {
    VStack(spacing: 20) {
        CirklButton("Primary Button", variant: .primary) {}
        CirklButton("Secondary Button", variant: .secondary) {}
        CirklButton("Ghost Button", variant: .ghost) {}
        CirklButton("Glass Button", variant: .glass) {}
        CirklButton("Destructive", variant: .destructive) {}
    }
    .padding()
    .background(DesignTokens.Colors.background)
}

#Preview("Button Sizes") {
    VStack(spacing: 16) {
        CirklButton("Small", size: .small) {}
        CirklButton("Medium", size: .medium) {}
        CirklButton("Large", size: .large) {}
    }
    .padding()
}

#Preview("Button with Icons") {
    VStack(spacing: 16) {
        CirklButton("Scan QR", icon: "qrcode.viewfinder") {}
        CirklButton("Continue", icon: "arrow.right", iconPosition: .trailing) {}
        CirklButton.glass("Add Connection", icon: "person.badge.plus") {}
    }
    .padding()
}

#Preview("Full Width & Loading") {
    VStack(spacing: 16) {
        CirklButton("Full Width", isFullWidth: true) {}
        CirklButton("Loading...", isLoading: true) {}
        CirklButton("Disabled", isDisabled: true) {}
    }
    .padding()
}
