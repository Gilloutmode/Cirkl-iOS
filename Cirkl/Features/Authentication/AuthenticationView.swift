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
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Authentication options
                VStack(spacing: 20) {
                    // QR Code
                    AuthButton(
                        title: "Scanner QR Code",
                        icon: "qrcode",
                        color: .cyan
                    ) {
                        showQRScanner = true
                    }
                    
                    // NFC
                    AuthButton(
                        title: "Connexion NFC",
                        icon: "wave.3.right",
                        color: .purple
                    ) {
                        showNFCReader = true
                    }
                    
                    // Face ID
                    AuthButton(
                        title: "Face ID",
                        icon: "faceid",
                        color: .green
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
                        .foregroundColor(.white.opacity(0.5))
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
            .foregroundColor(.white)
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(color.opacity(0.3))
                                .blur(radius: 10)
                        )
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
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
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("QR Scanner")
                    .foregroundColor(.white)
                
                Button("Authenticate") {
                    appState.authenticate()
                    dismiss()
                }
                .foregroundColor(.cyan)
            }
        }
    }
}

struct NFCReaderView: View {
    let appState: AppStateManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("NFC Reader")
                    .foregroundColor(.white)
                
                Button("Authenticate") {
                    appState.authenticate()
                    dismiss()
                }
                .foregroundColor(.purple)
            }
        }
    }
}