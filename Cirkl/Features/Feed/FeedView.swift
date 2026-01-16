import SwiftUI

// MARK: - Feed View
/// Onglet actualités réseau avec filtres et liste scrollable
/// Style Instagram notifications avec 3 types de cards spécialisées

struct FeedView: View {

    @State private var viewModel = FeedViewModel()
    @State private var selectedConnectionId: String?
    @State private var showConnectionDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignTokens.Colors.background
                    .ignoresSafeArea()

                // Content
                content
            }
            .navigationTitle("Actualités")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.hasUnread {
                        Button {
                            withAnimation(DesignTokens.Animations.fast) {
                                viewModel.markAllAsRead()
                            }
                        } label: {
                            Text("Tout lire")
                                .font(DesignTokens.Typography.buttonSmall)
                                .foregroundStyle(DesignTokens.Colors.electricBlue)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .preferredColorScheme(.dark)
        // Animation globale pour les changements de filtre et items
        .animation(DesignTokens.Animations.fast, value: viewModel.selectedFilter)
        .animation(DesignTokens.Animations.normal, value: viewModel.items.count)
        .animation(DesignTokens.Animations.fast, value: viewModel.unreadCount)
        // Sheet pour le détail connexion
        .sheet(isPresented: $showConnectionDetail) {
            if let connectionId = selectedConnectionId {
                ConnectionDetailSheet(connectionId: connectionId)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.items.isEmpty {
            emptyView
        } else {
            feedList
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)

            Text("Chargement des actualités...")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "newspaper")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            Text("Aucune actualité")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Les actualités de ton réseau apparaîtront ici")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.xl)
    }

    // MARK: - Feed List

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                // Filter pills
                filterHeader
                    .padding(.horizontal, DesignTokens.Spacing.md)

                // Feed items - dispatched by type
                ForEach(viewModel.filteredItems) { item in
                    feedCard(for: item)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.9))
                        ))
                        .id(item.id) // Important pour les animations
                }

                // Bottom spacer
                Spacer()
                    .frame(height: DesignTokens.Spacing.xxl)
            }
            .padding(.top, DesignTokens.Spacing.md)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Card Dispatcher

    @ViewBuilder
    private func feedCard(for item: FeedItem) -> some View {
        switch item.type {
        case .update:
            UpdateCard(item: item) {
                handleItemTap(item)
            }

        case .synergy:
            SynergyCard(
                item: item,
                onCreateConnection: {
                    withAnimation(DesignTokens.Animations.normal) {
                        viewModel.createSynergyConnection(item.id)
                    }
                    CirklHaptics.success()
                },
                onDismiss: {
                    withAnimation(DesignTokens.Animations.normal) {
                        viewModel.dismissSynergy(item.id)
                    }
                }
            )

        case .networkPulse:
            NetworkPulseCard(item: item) {
                handleItemTap(item)
            }
        }
    }

    // MARK: - Filter Header

    private var filterHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(FeedFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        count: countForFilter(filter),
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        withAnimation(DesignTokens.Animations.fast) {
                            viewModel.selectFilter(filter)
                        }
                        CirklHaptics.light()
                    }
                }
            }
            .padding(.vertical, DesignTokens.Spacing.xs)
        }
    }

    // MARK: - Helpers

    private func countForFilter(_ filter: FeedFilter) -> Int? {
        switch filter {
        case .all: return nil
        case .updates: return viewModel.updateCount
        case .synergies: return viewModel.synergyCount
        case .reminders: return viewModel.reminderCount
        }
    }

    private func handleItemTap(_ item: FeedItem) {
        // Mark as read with animation
        withAnimation(DesignTokens.Animations.fast) {
            viewModel.markAsRead(item.id)
        }

        // Haptic feedback
        CirklHaptics.light()

        #if DEBUG
        print("📰 Tapped: \(item.connectionName ?? item.type.displayName)")
        #endif

        // Navigate to connection profile if available
        if let connectionId = item.connectionId {
            selectedConnectionId = connectionId
            showConnectionDetail = true
        }
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let title: String
    let count: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(DesignTokens.Typography.buttonSmall)

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(DesignTokens.Typography.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : DesignTokens.Colors.textTertiary.opacity(0.2))
                        )
                }
            }
            .foregroundStyle(
                isSelected ? Color.white : DesignTokens.Colors.textSecondary
            )
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background { pillBackground }
            .contentShape(Capsule()) // FIX: Zone de tap explicite
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var pillBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(isSelected ? DesignTokens.Colors.electricBlue : .clear)
                .glassEffect(.regular, in: .capsule)
        } else {
            if isSelected {
                Capsule()
                    .fill(DesignTokens.Colors.electricBlue)
            } else {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Connection Detail Sheet (Placeholder)

private struct ConnectionDetailSheet: View {
    let connectionId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(DesignTokens.Colors.electricBlue.opacity(0.5))

                Text("Profil Connexion")
                    .font(DesignTokens.Typography.title2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("ID: \(connectionId)")
                    .font(DesignTokens.Typography.caption1)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)

                Text("Navigation vers ProfileDetailView à implémenter")
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignTokens.Colors.background)
            .navigationTitle("Connexion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    FeedView()
}
