//
//  CirklDesignTokens.swift
//  Cirkl
//
//  Created by Claude on 11/01/2026.
//

import SwiftUI

// MARK: - Design Tokens

/// Centralized design tokens for the Cirkl app design system
/// These tokens provide consistent styling across the entire application
enum DesignTokens {

    // MARK: - Colors

    /// Semantic colors that adapt to light/dark mode via Assets.xcassets
    enum Colors {
        // MARK: Primary

        /// Primary brand color - Electric Blue
        static let primary = Color("CirklPrimary")

        /// Secondary accent color
        static let secondary = Color("CirklSecondary")

        // MARK: Background

        /// Main background
        static let background = Color("Background")

        /// Elevated surface background
        static let surface = Color("Surface")

        /// Secondary surface for cards
        static let surfaceSecondary = Color("SurfaceSecondary")

        // MARK: Text

        /// Primary text color
        static let textPrimary = Color("TextPrimary")

        /// Secondary/muted text color
        static let textSecondary = Color("TextSecondary")

        /// Tertiary/disabled text color
        static let textTertiary = Color("TextTertiary")

        // MARK: Semantic

        /// Success color - Mint
        static let success = Color("CirklMint")

        /// Warning color
        static let warning = Color("Warning")

        /// Error/destructive color
        static let error = Color("Error")

        /// Info color
        static let info = Color("Info")

        // MARK: Orbital UI (Adaptive)

        /// Text color for bubble labels - adapts to light/dark
        static let bubbleText = Color("BubbleText")

        /// Background color for bubble badges - adapts to light/dark
        static let bubbleBackground = Color("BubbleBackground")

        /// Color for orbital connection lines - adapts to light/dark
        static let orbitalLines = Color("OrbitalLines")

        // MARK: Glass Effects

        /// Glass background tint (light mode)
        static let glassBackgroundLight = Color.black.opacity(0.05)

        /// Glass background tint (dark mode)
        static let glassBackgroundDark = Color.white.opacity(0.1)

        /// Glass border color
        static let glassBorder = Color.white.opacity(0.2)

        // MARK: Brand Specific (hardcoded fallbacks)

        /// Cirkl Deep Blue background
        static let deepBlue = Color(hex: "0A0E27")

        /// Electric Blue accent
        static let electricBlue = Color(hex: "007AFF")

        /// Mint accent
        static let mint = Color(hex: "00C781")

        /// Purple accent for special features
        static let purple = Color(hex: "8B5CF6")

        /// Pink accent for connections
        static let pink = Color(hex: "EC4899")
    }

    // MARK: - Typography

    /// Typography scale following iOS Human Interface Guidelines
    /// All fonts support Dynamic Type for accessibility
    enum Typography {
        // MARK: Display (Dynamic Type enabled)

        /// Large display title - scales with accessibility settings
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)

        /// Title 1 - scales with accessibility settings
        static let title1 = Font.system(.title, design: .rounded).weight(.bold)

        /// Title 2 - scales with accessibility settings
        static let title2 = Font.system(.title2, design: .rounded).weight(.bold)

        /// Title 3 - scales with accessibility settings
        static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)

        // MARK: Headlines (Dynamic Type enabled)

        /// Headline - scales with accessibility settings
        static let headline = Font.headline.weight(.semibold)

        /// Subheadline - scales with accessibility settings
        static let subheadline = Font.subheadline

        // MARK: Body (Dynamic Type enabled)

        /// Body - scales with accessibility settings
        static let body = Font.body

        /// Body Bold - scales with accessibility settings
        static let bodyBold = Font.body.weight(.semibold)

        /// Callout - scales with accessibility settings
        static let callout = Font.callout

        // MARK: Captions (Dynamic Type enabled)

        /// Footnote - scales with accessibility settings
        static let footnote = Font.footnote

        /// Caption 1 - scales with accessibility settings
        static let caption1 = Font.caption

        /// Caption 2 - scales with accessibility settings
        static let caption2 = Font.caption2

        // MARK: Special (Dynamic Type enabled)

        /// Button text - scales with accessibility settings
        static let button = Font.body.weight(.semibold)

        /// Small button text - scales with accessibility settings
        static let buttonSmall = Font.subheadline.weight(.medium)

        /// Tab bar label - scales with accessibility settings
        static let tabLabel = Font.caption2.weight(.medium)
    }

    // MARK: - Spacing

    /// Consistent spacing scale
    enum Spacing {
        /// Extra small - 4pt
        static let xs: CGFloat = 4

        /// Small - 8pt
        static let sm: CGFloat = 8

        /// Medium - 16pt (base unit)
        static let md: CGFloat = 16

        /// Large - 24pt
        static let lg: CGFloat = 24

        /// Extra large - 32pt
        static let xl: CGFloat = 32

        /// 2x Extra large - 48pt
        static let xxl: CGFloat = 48

        /// 3x Extra large - 64pt
        static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radius

    /// Consistent corner radius scale
    enum Radius {
        /// Small - 8pt (buttons, small cards)
        static let small: CGFloat = 8

        /// Medium - 12pt (cards, inputs)
        static let medium: CGFloat = 12

        /// Large - 16pt (modals, large cards)
        static let large: CGFloat = 16

        /// Extra large - 20pt (sheets)
        static let xl: CGFloat = 20

        /// Pill/Capsule - 100pt
        static let pill: CGFloat = 100

        /// Circle (full round)
        static let circle: CGFloat = .infinity
    }

    // MARK: - Shadows

    /// Shadow styles for elevation
    enum Shadows {
        /// Subtle shadow for cards
        static let subtle = ShadowStyle(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

        /// Medium shadow for elevated elements
        static let medium = ShadowStyle(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

        /// Strong shadow for modals/popovers
        static let strong = ShadowStyle(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)

        /// Glow effect for interactive elements
        static let glow = ShadowStyle(color: Colors.electricBlue.opacity(0.3), radius: 12, x: 0, y: 0)
    }

    /// Shadow style configuration
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Animations

    /// Consistent animation curves and durations
    /// All animations should respect Reduce Motion accessibility setting
    enum Animations {
        /// Fast animation - 0.2s (micro-interactions)
        static let fast = Animation.easeInOut(duration: 0.2)

        /// Normal animation - 0.3s (standard transitions)
        static let normal = Animation.easeInOut(duration: 0.3)

        /// Slow animation - 0.5s (emphasis)
        static let slow = Animation.easeInOut(duration: 0.5)

        /// Spring animation (bouncy feedback)
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)

        /// Gentle spring (smooth)
        static let gentleSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)

        /// Interactive spring (responsive)
        static let interactiveSpring = Animation.interactiveSpring(response: 0.3, dampingFraction: 0.6)

        // MARK: - Reduce Motion Aware Variants

        /// Returns animation or nil if Reduce Motion is enabled
        static func optional(_ animation: Animation, reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : animation
        }

        /// Returns simplified fade animation when Reduce Motion is enabled
        static func adaptive(_ animation: Animation, reduceMotion: Bool) -> Animation {
            reduceMotion ? .linear(duration: 0.15) : animation
        }

        /// Returns no repeating animation when Reduce Motion is enabled
        static func repeating(_ animation: Animation, reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : animation
        }
    }

    // MARK: - Sizes

    /// Standard component sizes
    enum Sizes {
        // MARK: Touch Targets (minimum 44pt for accessibility)

        /// Minimum touch target - 44pt
        static let touchTargetMin: CGFloat = 44

        /// Standard touch target - 48pt
        static let touchTarget: CGFloat = 48

        // MARK: Buttons

        /// Small button height - 36pt
        static let buttonSmall: CGFloat = 36

        /// Medium button height - 44pt
        static let buttonMedium: CGFloat = 44

        /// Large button height - 52pt
        static let buttonLarge: CGFloat = 52

        // MARK: Icons

        /// Small icon - 16pt
        static let iconSmall: CGFloat = 16

        /// Medium icon - 20pt
        static let iconMedium: CGFloat = 20

        /// Large icon - 24pt
        static let iconLarge: CGFloat = 24

        /// Extra large icon - 32pt
        static let iconXL: CGFloat = 32

        // MARK: Avatars

        /// Extra small avatar - 24pt
        static let avatarXS: CGFloat = 24

        /// Small avatar - 32pt
        static let avatarSm: CGFloat = 32

        /// Medium avatar - 40pt
        static let avatarMd: CGFloat = 40

        /// Large avatar - 56pt
        static let avatarLg: CGFloat = 56

        /// Extra large avatar - 80pt
        static let avatarXL: CGFloat = 80
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply design token shadow style
    func tokenShadow(_ shadow: DesignTokens.ShadowStyle) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    /// Apply glass background effect with design tokens
    @ViewBuilder
    func tokenGlassBackground(cornerRadius: CGFloat = DesignTokens.Radius.medium) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

// MARK: - Type Aliases for Convenience

/// Quick access to design token colors
typealias TokenColors = DesignTokens.Colors

/// Quick access to design token typography
typealias TokenTypography = DesignTokens.Typography

/// Quick access to design token spacing
typealias TokenSpacing = DesignTokens.Spacing

/// Quick access to design token radius
typealias TokenRadius = DesignTokens.Radius

/// Quick access to design token shadows
typealias TokenShadows = DesignTokens.Shadows

/// Quick access to design token animations
typealias TokenAnimations = DesignTokens.Animations

/// Quick access to design token sizes
typealias TokenSizes = DesignTokens.Sizes
