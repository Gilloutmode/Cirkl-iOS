//
//  MorningBriefView.swift
//  Cirkl
//
//  Created by Claude on 15/01/2026.
//

import SwiftUI

// MARK: - MorningBriefView

/// Vue du brief matinal avec design Liquid Glass
/// Affiche les highlights, stats et actions du jour
struct MorningBriefView: View {

    // MARK: - Properties

    let brief: MorningBrief
    let onDismiss: () -> Void
    let onActionTap: (MorningBrief.BriefActionItem) -> Void

    // MARK: - State

    @State private var contentOpacity: Double = 0
    @State private var headerScale: CGFloat = 0.9
    @State private var selectedHighlight: MorningBrief.BriefHighlight?
    @State private var showingActionSheet = false

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(
        brief: MorningBrief,
        onDismiss: @escaping () -> Void = {},
        onActionTap: @escaping (MorningBrief.BriefActionItem) -> Void = { _ in }
    ) {
        self.brief = brief
        self.onDismiss = onDismiss
        self.onActionTap = onActionTap
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header avec greeting
                    headerSection
                        .scaleEffect(headerScale)

                    // Stats du réseau
                    statsSection

                    // Highlights du jour
                    highlightsSection

                    // Actions suggérées
                    actionsSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(backgroundGradient)
            .navigationTitle("Brief du matin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        markAsReadAndDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
        .opacity(contentOpacity)
        .onAppear {
            animateEntrance()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.05, blue: 0.15),
                Color(red: 0.02, green: 0.06, blue: 0.12),
                Color(red: 0.04, green: 0.05, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Sun icon avec glow vert menthe
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0, green: 0.78, blue: 0.506).opacity(0.4),
                                Color(red: 0, green: 0.78, blue: 0.506).opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0, green: 0.78, blue: 0.506),
                                Color(red: 0, green: 0.6, blue: 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0, green: 0.78, blue: 0.506).opacity(0.5), radius: 15)
            }

            // Greeting
            Text(greetingText)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Bonjour ! ☀️"
        } else if hour < 18 {
            return "Bon après-midi !"
        } else {
            return "Bonsoir !"
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Score Synchronicity
                StatCard(
                    icon: "sparkles",
                    title: "Score",
                    value: "\(brief.stats.synchronicityScore)",
                    subtitle: brief.stats.scoreChange >= 0 ? "+\(brief.stats.scoreChange)" : "\(brief.stats.scoreChange)",
                    color: .mint
                )

                // Rank
                StatCard(
                    icon: "trophy.fill",
                    title: "Rang",
                    value: brief.stats.rank,
                    subtitle: "",
                    color: .yellow
                )
            }

            HStack(spacing: 12) {
                // Connexions actives
                StatCard(
                    icon: "person.2.fill",
                    title: "Actives",
                    value: "\(brief.stats.activeConnections)",
                    subtitle: "connexions",
                    color: .green
                )

                // Connexions dormantes
                StatCard(
                    icon: "moon.zzz.fill",
                    title: "Dormantes",
                    value: "\(brief.stats.dormantConnections)",
                    subtitle: "à réveiller",
                    color: .orange
                )
            }
        }
    }

    // MARK: - Highlights Section

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            VStack(spacing: 8) {
                ForEach(brief.highlights) { highlight in
                    HighlightRow(highlight: highlight)
                        .onTapGesture {
                            selectedHighlight = highlight
                            CirklHaptics.light()
                        }
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions suggérées")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            VStack(spacing: 8) {
                ForEach(brief.actionItems) { action in
                    ActionRow(action: action) {
                        onActionTap(action)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.4)) {
            contentOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            headerScale = 1.0
        }
    }

    private func markAsReadAndDismiss() {
        MorningBriefManager.shared.markBriefAsRead()
        onDismiss()
        dismiss()
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(color.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - HighlightRow

private struct HighlightRow: View {
    let highlight: MorningBrief.BriefHighlight

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: highlightIcon)
                .font(.title3)
                .foregroundStyle(highlightColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(highlightColor.opacity(0.2))
                )

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(highlight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Text(highlight.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    private var highlightIcon: String {
        switch highlight.type {
        case .jobChange: return "briefcase.fill"
        case .newMutual: return "person.2.fill"
        case .synergy: return "link.circle.fill"
        case .opportunity: return "lightbulb.fill"
        case .anniversary: return "gift.fill"
        case .dormant: return "moon.zzz.fill"
        }
    }

    private var highlightColor: Color {
        switch highlight.type {
        case .jobChange: return .blue
        case .newMutual: return .purple
        case .synergy: return .orange
        case .opportunity: return .yellow
        case .anniversary: return .pink
        case .dormant: return .gray
        }
    }
}

// MARK: - ActionRow

private struct ActionRow: View {
    let action: MorningBrief.BriefActionItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Priority indicator
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)

                    Text(action.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                Text("Agir")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(priorityColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(priorityColor.opacity(0.2))
                    )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(priorityColor.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var priorityColor: Color {
        switch action.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    MorningBriefView(
        brief: MorningBriefManager.shared.createTestBrief()
    )
    .preferredColorScheme(.dark)
}
