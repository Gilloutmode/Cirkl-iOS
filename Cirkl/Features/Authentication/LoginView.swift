import SwiftUI

// MARK: - LoginView
/// Écran de connexion - Design Dark Mode avec Liquid Glass
/// Layout adaptatif avec gestion du clavier
struct LoginView: View {
    @ObservedObject var appState: AppStateManager
    @ObservedObject private var supabaseService = SupabaseService.shared

    @State private var email = ""
    @State private var isLoading = false
    @State private var showMagicLinkSent = false
    @State private var errorMessage: String?
    @FocusState private var isEmailFocused: Bool

    // Animation states
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // === ADAPTIVE BACKGROUND - Changes with theme ===
                DesignTokens.Colors.background
                    .ignoresSafeArea()

                // Subtle decorative circles
                decorativeBackground
                    .ignoresSafeArea()

                // Main content
                VStack(spacing: 0) {
                    // Logo section - Compresses when keyboard appears
                    logoSection
                        .opacity(logoOpacity)
                        .scaleEffect(logoScale)
                        .frame(height: isEmailFocused ? 100 : 180)
                        .animation(.easeInOut(duration: 0.3), value: isEmailFocused)

                    Spacer()
                        .frame(height: isEmailFocused ? 16 : 32)

                    // Login form
                    loginFormSection
                        .opacity(contentOpacity)
                        .padding(.horizontal, 24)

                    Spacer()
                        .frame(minHeight: 16)

                    // Social login section
                    if !isEmailFocused {
                        socialLoginSection
                            .opacity(contentOpacity)
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer()
                        .frame(minHeight: 12)

                    // Footer
                    footerSection
                        .opacity(contentOpacity)
                        .padding(.bottom, isEmailFocused ? 8 : 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.3), value: isEmailFocused)
            }
        }
        .onTapGesture {
            isEmailFocused = false
        }
        .alert("Lien envoyé !", isPresented: $showMagicLinkSent) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Vérifie ta boîte mail \(email) et clique sur le lien magique pour te connecter.")
        }
        .alert("Erreur", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
        .onChange(of: supabaseService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                appState.authenticate()
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Decorative Background
    private var decorativeBackground: some View {
        ZStack {
            // Top-right soft circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.0, green: 0.78, blue: 0.51).opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 120, y: -200)

            // Bottom-left soft circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 120
                    )
                )
                .frame(width: 250, height: 250)
                .offset(x: -100, y: 300)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: isEmailFocused ? 8 : 12) {
            // Logo
            ZStack {
                // Soft shadow
                Circle()
                    .fill(Color(red: 0.0, green: 0.78, blue: 0.51).opacity(0.15))
                    .frame(width: isEmailFocused ? 50 : 72, height: isEmailFocused ? 50 : 72)
                    .blur(radius: 15)

                // Logo background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.78, blue: 0.51),
                                Color(red: 0.0, green: 0.48, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isEmailFocused ? 48 : 64, height: isEmailFocused ? 48 : 64)

                // Icon
                Image(systemName: "circle.hexagongrid.circle.fill")
                    .font(.system(size: isEmailFocused ? 24 : 32))
                    .foregroundColor(.white)
            }
            .animation(.easeInOut(duration: 0.3), value: isEmailFocused)

            if !isEmailFocused {
                // App name - ADAPTIVE
                Text("Cirkl")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                // Tagline - ADAPTIVE
                Text("Connexions authentiques")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(.top, isEmailFocused ? 20 : 40)
    }

    // MARK: - Login Form Section
    private var loginFormSection: some View {
        VStack(spacing: 14) {
            // Email field - ADAPTIVE GLASS
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)

                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isEmailFocused ? DesignTokens.Colors.success : DesignTokens.Colors.textSecondary)

                    TextField("", text: $email, prompt: Text("ton@email.com").foregroundColor(DesignTokens.Colors.textTertiary))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .tint(DesignTokens.Colors.success)
                        .focused($isEmailFocused)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isEmailFocused ? DesignTokens.Colors.success : DesignTokens.Colors.textTertiary.opacity(0.3),
                            lineWidth: isEmailFocused ? 2 : 1
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isEmailFocused)
            }

            // Magic Link Button
            Button(action: sendMagicLink) {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Text(isLoading ? "Envoi en cours..." : "Recevoir le lien magique")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(buttonFillStyle)
                )
                .shadow(
                    color: email.isEmpty ? .clear : DesignTokens.Colors.success.opacity(0.3),
                    radius: 12,
                    y: 4
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(email.isEmpty || isLoading)
            .animation(.easeInOut(duration: 0.2), value: email.isEmpty)
        }
    }

    // MARK: - Social Login Section - ADAPTIVE
    private var socialLoginSection: some View {
        VStack(spacing: 14) {
            // Divider with text - ADAPTIVE
            HStack {
                Rectangle()
                    .fill(DesignTokens.Colors.textTertiary.opacity(0.3))
                    .frame(height: 1)

                Text("ou continuer avec")
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .padding(.horizontal, 12)

                Rectangle()
                    .fill(DesignTokens.Colors.textTertiary.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 8)

            // Social buttons row - ADAPTIVE GLASS
            HStack(spacing: 12) {
                // Apple
                SocialLoginButton(
                    icon: "apple.logo",
                    text: "Apple",
                    backgroundColor: DesignTokens.Colors.textPrimary,
                    textColor: DesignTokens.Colors.background
                ) {
                    // TODO: Implement Apple Sign In
                    print("Apple login tapped")
                }

                // Google
                SocialLoginButton(
                    icon: "g.circle.fill",
                    text: "Google",
                    backgroundColor: .clear,
                    textColor: DesignTokens.Colors.textPrimary.opacity(0.9),
                    borderColor: DesignTokens.Colors.textTertiary.opacity(0.3),
                    useGlass: true
                ) {
                    // TODO: Implement Google Sign In
                    print("Google login tapped")
                }

                // Facebook
                SocialLoginButton(
                    icon: "f.circle.fill",
                    text: "Facebook",
                    backgroundColor: Color(red: 0.23, green: 0.35, blue: 0.60),
                    textColor: .white
                ) {
                    // TODO: Implement Facebook Sign In
                    print("Facebook login tapped")
                }
            }
        }
    }

    // MARK: - Footer Section - ADAPTIVE
    private var footerSection: some View {
        VStack(spacing: 10) {
            #if DEBUG
            Button(action: {
                appState.authenticate()
            }) {
                Text("Skip (Dev)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.Colors.success)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial.opacity(0.5))
                    )
                    .overlay(
                        Capsule()
                            .stroke(DesignTokens.Colors.success.opacity(0.3), lineWidth: 1)
                    )
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            #endif

            Text("En continuant, tu acceptes nos conditions d'utilisation")
                .font(.caption2)
                .foregroundColor(DesignTokens.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Computed Properties - ADAPTIVE
    private var buttonFillStyle: AnyShapeStyle {
        if email.isEmpty || isLoading {
            // Disabled state - subtle glass (adaptive)
            return AnyShapeStyle(DesignTokens.Colors.textTertiary.opacity(0.2))
        } else {
            // Active state - Cirkl gradient (brand colors stay the same)
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.success,
                        DesignTokens.Colors.electricBlue
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }

    // MARK: - Animations
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            contentOpacity = 1.0
        }
    }

    // MARK: - Actions
    private func sendMagicLink() {
        guard !email.isEmpty else { return }
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Merci d'entrer une adresse email valide"
            return
        }

        isEmailFocused = false
        isLoading = true

        Task {
            do {
                try await supabaseService.signInWithMagicLink(email: email)
                await MainActor.run {
                    isLoading = false
                    showMagicLinkSent = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Impossible d'envoyer le lien : \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Social Login Button Component - ADAPTIVE
struct SocialLoginButton: View {
    let icon: String
    let text: String
    let backgroundColor: Color
    let textColor: Color
    var borderColor: Color? = nil
    var useGlass: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(textColor)

                Text(text)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(useGlass ? AnyShapeStyle(.ultraThinMaterial.opacity(0.5)) : AnyShapeStyle(backgroundColor))
            )
            .overlay(
                Group {
                    if let border = borderColor {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(border, lineWidth: 1)
                    }
                }
            )
            .shadow(color: DesignTokens.Colors.textPrimary.opacity(0.1), radius: 8, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    LoginView(appState: AppStateManager())
}
