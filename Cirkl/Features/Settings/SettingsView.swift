import SwiftUI

// MARK: - Settings View
/// Comprehensive settings screen for Cirkl app
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Section
                Section {
                    profileRow
                } header: {
                    Text("Profil")
                }

                // MARK: - Notifications Section
                Section {
                    Toggle("Notifications push", isOn: $viewModel.pushNotificationsEnabled)
                    Toggle("Morning Brief quotidien", isOn: $viewModel.morningBriefEnabled)
                    Toggle("Rappels de connexions", isOn: $viewModel.connectionRemindersEnabled)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Le Morning Brief vous informe chaque matin des actualites de votre reseau.")
                }

                // MARK: - Appearance Section
                Section {
                    HStack {
                        Text("Theme")
                        Spacer()
                        Text("Sombre")
                            .foregroundColor(.secondary)
                    }

                    Picker("Langue", selection: $viewModel.selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                } header: {
                    Text("Apparence")
                } footer: {
                    Text("Cirkl utilise le mode sombre pour une experience optimale.")
                }

                // MARK: - Privacy Section
                Section {
                    Picker("Visibilite du profil", selection: $viewModel.profileVisibility) {
                        ForEach(ProfileVisibility.allCases) { visibility in
                            Text(visibility.displayName).tag(visibility)
                        }
                    }

                    Toggle("Partager les statistiques anonymes", isOn: $viewModel.shareAnalytics)
                } header: {
                    Text("Confidentialite")
                }

                // MARK: - Sync Section
                Section {
                    syncStatusRow(
                        title: "Neo4j",
                        status: viewModel.neo4jSyncStatus,
                        icon: "cylinder.split.1x2"
                    )
                    syncStatusRow(
                        title: "N8N Orchestrator",
                        status: viewModel.n8nSyncStatus,
                        icon: "arrow.triangle.branch"
                    )
                    syncStatusRow(
                        title: "Google Sheets",
                        status: viewModel.googleSheetsSyncStatus,
                        icon: "tablecells"
                    )

                    Button {
                        CirklHaptics.medium()
                        Task {
                            await viewModel.syncNow()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isSyncing {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(viewModel.isSyncing ? "Synchronisation..." : "Synchroniser maintenant")
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isSyncing)
                } header: {
                    Text("Synchronisation")
                } footer: {
                    if let lastSync = viewModel.lastSyncDate {
                        Text("Derniere synchronisation: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                    }
                }

                // MARK: - Export Section (GDPR)
                Section {
                    Button {
                        CirklHaptics.medium()
                        viewModel.exportData()
                    } label: {
                        Label("Exporter mes donnees", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Mes donnees")
                } footer: {
                    Text("Telechargez une copie de toutes vos donnees (RGPD).")
                }

                // MARK: - Account Section
                Section {
                    Button {
                        CirklHaptics.medium()
                        viewModel.showLogoutConfirmation = true
                    } label: {
                        Label("Se deconnecter", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.primary)
                    }

                    Button(role: .destructive) {
                        CirklHaptics.warning()
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        Label("Supprimer mon compte", systemImage: "trash")
                    }
                } header: {
                    Text("Compte")
                }

                // MARK: - About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://cirkl.app/privacy")!) {
                        Label("Politique de confidentialite", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "https://cirkl.app/terms")!) {
                        Label("Conditions d'utilisation", systemImage: "doc.text")
                    }
                } header: {
                    Text("A propos")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Reglages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        CirklHaptics.light()
                        dismiss()
                    }
                }
            }
            .alert("Se deconnecter ?", isPresented: $viewModel.showLogoutConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Se deconnecter", role: .destructive) {
                    viewModel.logout()
                }
            } message: {
                Text("Vous devrez vous reconnecter pour acceder a votre compte.")
            }
            .alert("Supprimer le compte ?", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount()
                    }
                }
            } message: {
                Text("Cette action est irreversible. Toutes vos donnees seront supprimees.")
            }
        }
    }

    // MARK: - Profile Row
    private var profileRow: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Text(viewModel.userName.prefix(1).uppercased())
                        .font(.title2.bold())
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.userName)
                    .font(.headline)

                Text(viewModel.userEmail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if !viewModel.userRole.isEmpty {
                    Text(viewModel.userRole)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.showProfileEditor = true
        }
    }

    // MARK: - Sync Status Row
    private func syncStatusRow(title: String, status: SyncStatus, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)

                Text(status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Settings ViewModel
@MainActor
@Observable
final class SettingsViewModel: ObservableObject {
    // User Profile
    var userName: String = "Gil"
    var userEmail: String = "gil@cirkl.app"
    var userRole: String = "Fondateur"
    var showProfileEditor: Bool = false

    // Notifications
    var pushNotificationsEnabled: Bool = true
    var morningBriefEnabled: Bool = true
    var connectionRemindersEnabled: Bool = true

    // Appearance
    var selectedLanguage: AppLanguage = .french

    // Privacy
    var profileVisibility: ProfileVisibility = .connections
    var shareAnalytics: Bool = true

    // Sync
    var neo4jSyncStatus: SyncStatus = .connected
    var n8nSyncStatus: SyncStatus = .connected
    var googleSheetsSyncStatus: SyncStatus = .disconnected
    var lastSyncDate: Date? = Date()
    var isSyncing: Bool = false

    // Alerts
    var showLogoutConfirmation: Bool = false
    var showDeleteConfirmation: Bool = false

    // App Info
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Actions

    func syncNow() async {
        isSyncing = true
        // Simulate sync
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        lastSyncDate = Date()
        isSyncing = false
    }

    func exportData() {
        // TODO: Implement data export
        print("Exporting user data...")
    }

    func logout() {
        // TODO: Implement logout
        print("Logging out...")
    }

    func deleteAccount() async {
        // TODO: Implement account deletion
        print("Deleting account...")
    }
}

// MARK: - Supporting Types

enum AppLanguage: String, CaseIterable, Identifiable {
    case french = "fr"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .french: return "Francais"
        case .english: return "English"
        }
    }
}

enum ProfileVisibility: String, CaseIterable, Identifiable {
    case everyone = "everyone"
    case connections = "connections"
    case nobody = "nobody"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .everyone: return "Tout le monde"
        case .connections: return "Mes connexions"
        case .nobody: return "Personne"
        }
    }
}

enum SyncStatus {
    case connected
    case syncing
    case disconnected
    case error

    var displayName: String {
        switch self {
        case .connected: return "Connecte"
        case .syncing: return "Synchronisation"
        case .disconnected: return "Deconnecte"
        case .error: return "Erreur"
        }
    }

    var color: Color {
        switch self {
        case .connected: return .green
        case .syncing: return .blue
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
