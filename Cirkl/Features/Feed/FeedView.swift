import SwiftUI

// MARK: - Feed View
/// Onglet actualités réseau avec filtres et liste scrollable
/// Style Instagram notifications avec 3 types de cards spécialisées

struct FeedView: View {

    @StateObject private var viewModel = FeedViewModel()
    @State private var selectedFeedItem: FeedItem?

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
        .sheet(item: $selectedFeedItem) { item in
            FeedItemDetailSheet(item: item) { updatedContact in
                viewModel.updateConnectionInFeed(updatedContact)
            }
        }
        // Alert pour afficher les erreurs
        .alert("Erreur", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.error ?? "Une erreur est survenue")
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
                        // Animate isRead changes (unread indicator visibility)
                        .animation(DesignTokens.Animations.fast, value: item.isRead)
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
                isLoading: viewModel.isItemLoading(item.id),
                onCreateConnection: {
                    // Sauvegarder les noms AVANT suppression pour le toast
                    let person1 = item.synergyPerson1Name ?? "Contact 1"
                    let person2 = item.synergyPerson2Name ?? "Contact 2"
                    CirklHaptics.medium()

                    Task {
                        await viewModel.createSynergyConnection(item.id)

                        await MainActor.run {
                            withAnimation(DesignTokens.Animations.normal) {
                                // L'item est déjà supprimé dans le ViewModel si succès
                            }

                            // Toast feedback based on result
                            if let error = viewModel.error {
                                // Erreur réseau ou backend
                                ToastManager.shared.error("Échec : \(error)")
                                CirklHaptics.error()
                            } else {
                                // Succès
                                ToastManager.shared.success("Connexion \(person1) ↔ \(person2) créée !")
                                CirklHaptics.success()
                            }
                        }
                    }
                },
                onDismiss: {
                    withAnimation(DesignTokens.Animations.normal) {
                        viewModel.dismissSynergy(item.id)
                    }
                    ToastManager.shared.info("Synergie ignorée")
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
        print("[Feed] Tapped: \(item.connectionName ?? item.type.displayName)")
        #endif

        // Open detail sheet for this item
        selectedFeedItem = item
    }
}

// MARK: - Preview

#Preview {
    FeedView()
}
