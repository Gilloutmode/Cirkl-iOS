import SwiftUI

// MARK: - Network Pulse View
/// Dashboard santé du réseau avec classification des connexions
/// Accessible depuis le bouton AI via ActionSheet

struct NetworkPulseView: View {

    @State private var viewModel = NetworkPulseViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignTokens.Colors.background
                    .ignoresSafeArea()

                // Content
                content
            }
            .navigationTitle("Network Pulse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
        case .loaded:
            loadedView
        case .error(let message):
            errorView(message: message)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)

            Text("Analyse de ton réseau...")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    // MARK: - Loaded View

    private var loadedView: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                // Stats header
                PulseStatsHeader(
                    activeCount: viewModel.activeCount,
                    dormantCount: viewModel.dormantCount,
                    atRiskCount: viewModel.atRiskCount,
                    totalCount: viewModel.totalCount
                )
                .padding(.horizontal, DesignTokens.Spacing.md)

                // Sections
                if !viewModel.atRiskConnections.isEmpty {
                    connectionSection(
                        title: "Connexions à risque",
                        subtitle: "Plus de 30 jours sans contact",
                        connections: viewModel.atRiskConnections,
                        color: DesignTokens.Colors.error
                    )
                }

                if !viewModel.dormantConnections.isEmpty {
                    connectionSection(
                        title: "Connexions dormantes",
                        subtitle: "7-30 jours sans contact",
                        connections: viewModel.dormantConnections,
                        color: DesignTokens.Colors.warning
                    )
                }

                if !viewModel.activeConnections.isEmpty {
                    connectionSection(
                        title: "Connexions actives",
                        subtitle: "Contactées cette semaine",
                        connections: viewModel.activeConnections,
                        color: DesignTokens.Colors.mint
                    )
                }

                // Bottom spacer
                Spacer()
                    .frame(height: DesignTokens.Spacing.xxl)
            }
            .padding(.top, DesignTokens.Spacing.md)
        }
        .refreshable {
            await viewModel.load()
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.Colors.warning)

            Text("Impossible de charger les données")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(message)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.load()
                }
            } label: {
                Label("Réessayer", systemImage: "arrow.clockwise")
                    .font(DesignTokens.Typography.button)
            }
            .buttonStyle(.borderedProminent)
            .tint(DesignTokens.Colors.electricBlue)
        }
        .padding(DesignTokens.Spacing.xl)
    }

    // MARK: - Connection Section

    private func connectionSection(
        title: String,
        subtitle: String,
        connections: [NetworkPulseViewModel.PulseConnection],
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Section header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(DesignTokens.Typography.title3)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Spacer()

                    Text("\(connections.count)")
                        .font(DesignTokens.Typography.headline)
                        .foregroundStyle(color)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(color.opacity(0.15))
                        )
                }

                Text(subtitle)
                    .font(DesignTokens.Typography.caption1)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)

            // Connection rows
            ForEach(connections) { connection in
                PulseConnectionRow(
                    connection: connection,
                    onRequestSuggestion: {
                        Task {
                            await viewModel.fetchSuggestion(for: connection.id)
                        }
                    },
                    onCopySuggestion: { suggestion in
                        UIPasteboard.general.string = suggestion
                        CirklHaptics.light()
                    },
                    onOpenMessages: { name in
                        openMessages(for: name)
                    },
                    onDismiss: {
                        viewModel.clearSuggestion(for: connection.id)
                    }
                )
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
        }
    }

    // MARK: - Helpers

    private func openMessages(for name: String) {
        // Try to open Messages app
        // In a real app, you'd use Contacts framework to find the phone number
        if let url = URL(string: "sms:") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    NetworkPulseView()
}
