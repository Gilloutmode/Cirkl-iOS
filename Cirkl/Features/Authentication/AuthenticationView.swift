import SwiftUI

/// Authentication view with physical verification
struct AuthenticationView: View {
    @ObservedObject var appState: AppStateManager
    @StateObject private var errorHandler = ErrorHandler()
    @State private var showQRScanner = false
    @State private var showNFCReader = false
    
    var body: some View {
        ZStack {
            // Background
            CirklGlassBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Logo
                VStack(spacing: 16) {
                    Text("Cirkl")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Connexion Authentique")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.8))
                }
                
                // Authentication options
                VStack(spacing: 20) {
                    // QR Code
                    AuthButton(
                        title: "Scanner QR Code",
                        icon: "qrcode",
                        color: DesignTokens.Colors.electricBlue
                    ) {
                        showQRScanner = true
                    }

                    // NFC
                    AuthButton(
                        title: "Connexion NFC",
                        icon: "wave.3.right",
                        color: DesignTokens.Colors.purple
                    ) {
                        showNFCReader = true
                    }

                    // Face ID
                    AuthButton(
                        title: "Face ID",
                        icon: "faceid",
                        color: DesignTokens.Colors.success
                    ) {
                        authenticateWithBiometric()
                    }
                }
                .padding(.horizontal, 40)
                
                // Skip for dev
                #if DEBUG
                Button {
                    appState.authenticate()
                } label: {
                    Text("Skip (Dev)")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                #endif
            }
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerView(appState: appState)
        }
        .sheet(isPresented: $showNFCReader) {
            NFCReaderView(appState: appState)
        }
    }
    
    private func authenticateWithBiometric() {
        Task {
            do {
                // Simulation de l'authentification biométrique
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
                await MainActor.run {
                    appState.authenticate()
                }
            } catch {
                await MainActor.run {
                    errorHandler.handle(CirklError(
                        title: "Erreur d'authentification",
                        message: error.localizedDescription
                    ))
                }
            }
        }
    }
}

struct AuthButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))

                Text(title)
                    .font(.headline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(DesignTokens.Colors.textPrimary)
            .padding()
            .background(
                ZStack {
                    // Colored glow behind
                    RoundedRectangle(cornerRadius: 20)
                        .fill(color.opacity(0.25))
                        .blur(radius: 8)

                    // Glass fill
                    RoundedRectangle(cornerRadius: 20)
                        .fill(color.opacity(0.1))
                }
            )
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.textPrimary.opacity(0.3),
                                DesignTokens.Colors.textPrimary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Placeholder views
struct QRScannerView: View {
    let appState: AppStateManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            
            VStack {
                Text("QR Scanner")
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Button("Authenticate") {
                    appState.authenticate()
                    dismiss()
                }
                .foregroundColor(DesignTokens.Colors.electricBlue)
            }
        }
    }
}

struct NFCReaderView: View {
    let appState: AppStateManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            
            VStack {
                Text("NFC Reader")
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Button("Authenticate") {
                    appState.authenticate()
                    dismiss()
                }
                .foregroundColor(DesignTokens.Colors.purple)
            }
        }
    }
}