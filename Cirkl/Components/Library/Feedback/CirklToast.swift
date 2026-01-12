//
//  CirklToast.swift
//  Cirkl
//
//  Created by Claude on 12/01/2026.
//

import SwiftUI

// MARK: - Toast Type

enum ToastType {
    case success
    case info
    case warning
    case error

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return DesignTokens.Colors.success
        case .info: return DesignTokens.Colors.info
        case .warning: return DesignTokens.Colors.warning
        case .error: return DesignTokens.Colors.error
        }
    }

    var hapticType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success: return .success
        case .info: return .warning
        case .warning: return .warning
        case .error: return .error
        }
    }
}

// MARK: - Toast View

/// A non-blocking toast notification component
struct CirklToast: View {

    // MARK: - Properties

    let type: ToastType
    let message: String
    var duration: TimeInterval = 3.0
    var onDismiss: (() -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var isVisible = false
    @State private var dragOffset: CGFloat = 0

    // MARK: - Body

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Icon
            Image(systemName: type.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(type.color)

            // Message
            Text(message)
                .font(DesignTokens.Typography.bodyBold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .lineLimit(2)

            Spacer(minLength: 0)

            // Dismiss button
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fermer")
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(toastBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.large))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .offset(y: isVisible ? 0 : -100)
        .offset(y: dragOffset)
        .opacity(isVisible ? 1 : 0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        dismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            show()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(typeAccessibilityLabel). \(message)")
        .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Background

    @ViewBuilder
    private var toastBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: .rect(cornerRadius: DesignTokens.Radius.large))
        } else {
            DesignTokens.Colors.surface
                .background(.ultraThinMaterial)
        }
    }

    // MARK: - Helpers

    private var typeAccessibilityLabel: String {
        switch type {
        case .success: return "Succès"
        case .info: return "Information"
        case .warning: return "Avertissement"
        case .error: return "Erreur"
        }
    }

    private func show() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type.hapticType)

        // Animate in
        withAnimation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8)) {
            isVisible = true
        }

        // Auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(reduceMotion ? .none : .easeOut(duration: 0.2)) {
            isVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}

// MARK: - Toast Manager

/// Observable manager for presenting toasts
@MainActor
@Observable
final class ToastManager {

    static let shared = ToastManager()

    private(set) var currentToast: ToastItem?
    private var queue: [ToastItem] = []

    private init() {}

    func show(_ type: ToastType, message: String, duration: TimeInterval = 3.0) {
        let toast = ToastItem(type: type, message: message, duration: duration)

        if currentToast == nil {
            currentToast = toast
        } else {
            queue.append(toast)
        }
    }

    func dismiss() {
        currentToast = nil

        if !queue.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.currentToast = self?.queue.removeFirst()
            }
        }
    }

    // Convenience methods
    func success(_ message: String) { show(.success, message: message) }
    func info(_ message: String) { show(.info, message: message) }
    func warning(_ message: String) { show(.warning, message: message) }
    func error(_ message: String) { show(.error, message: message) }
}

// MARK: - Toast Item

struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let message: String
    let duration: TimeInterval
}

// MARK: - Toast Container View

/// View modifier that adds toast support to a view hierarchy
struct ToastContainerModifier: ViewModifier {

    // Access singleton directly - @Observable tracks changes automatically
    private var toastManager: ToastManager { ToastManager.shared }

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let toast = toastManager.currentToast {
                CirklToast(
                    type: toast.type,
                    message: toast.message,
                    duration: toast.duration,
                    onDismiss: {
                        ToastManager.shared.dismiss()
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
                .padding(.top, 60) // Safe area
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: toast.id)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: toastManager.currentToast?.id)
    }
}

extension View {
    /// Adds toast notification support to the view
    func toastContainer() -> some View {
        modifier(ToastContainerModifier())
    }
}

// MARK: - Previews

#Preview("Success Toast") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()

        VStack {
            Spacer()
        }
    }
    .overlay(alignment: .top) {
        CirklToast(type: .success, message: "Contact ajouté avec succès")
            .padding(.top, 60)
    }
    .preferredColorScheme(.dark)
}

#Preview("Info Toast") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
    }
    .overlay(alignment: .top) {
        CirklToast(type: .info, message: "Votre réseau a été synchronisé")
            .padding(.top, 60)
    }
    .preferredColorScheme(.dark)
}

#Preview("Warning Toast") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
    }
    .overlay(alignment: .top) {
        CirklToast(type: .warning, message: "Connexion instable")
            .padding(.top, 60)
    }
    .preferredColorScheme(.dark)
}

#Preview("Error Toast") {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
    }
    .overlay(alignment: .top) {
        CirklToast(type: .error, message: "Impossible d'envoyer le message")
            .padding(.top, 60)
    }
    .preferredColorScheme(.dark)
}
