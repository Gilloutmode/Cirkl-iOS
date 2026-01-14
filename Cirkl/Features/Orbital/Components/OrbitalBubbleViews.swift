import SwiftUI

// MARK: - Glass Bubble Overlay (Effet bulle transparent reutilisable)
struct GlassBubbleOverlay: View {
    let size: CGFloat
    let tintColor: Color

    var body: some View {
        ZStack {
            // === BORDURE EPAISSE IRIDESCENTE (style reference) ===
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.8),
                            tintColor.opacity(0.4),
                            Color(red: 0.85, green: 0.7, blue: 0.95).opacity(0.7),
                            Color(red: 1.0, green: 0.75, blue: 0.85).opacity(0.6),
                            Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.8)
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    lineWidth: 3.5
                )
                .frame(width: size, height: size)

            // === HIGHLIGHT PRINCIPAL HAUT-GAUCHE (grand arc) ===
            Circle()
                .trim(from: 0.6, to: 0.9)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.95),
                            Color.white.opacity(1.0),
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size * 0.92, height: size * 0.92)
                .rotationEffect(.degrees(-20))

            // === REFLET COURBE HAUT-GAUCHE ===
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.4, height: size * 0.15)
                .rotationEffect(.degrees(-40))
                .offset(x: -size * 0.12, y: -size * 0.32)

            // === REFLET BAS SUBTIL ===
            Circle()
                .trim(from: 0.05, to: 0.20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: size * 0.85, height: size * 0.85)

            // === POINT SPARKLE ===
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.06, height: size * 0.06)
                .offset(x: -size * 0.25, y: -size * 0.28)
                .blur(radius: 0.3)
        }
    }
}

// MARK: - Glass Bubble View (VRAIE BULLE TRANSPARENTE style soap/glass)
struct GlassBubbleView: View {
    let name: String
    let photoName: String?
    let avatarColor: Color
    let size: CGFloat
    let index: Int
    @Binding var dragOffset: CGSize
    var onTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // PERFORMANCE FIX: Removed breathingPhase animation
    @State private var isDragging: Bool = false
    @State private var isBouncing: Bool = false
    @State private var dragStartLocation: CGPoint = .zero

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // === FOND LIQUID GLASS NATIF iOS 26 ===
                Circle()
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: size, height: size)
                    .glassEffect(.regular.interactive(), in: .circle)

                // === CONTENU: PHOTO DETOUREE OU PLACEHOLDER ===
                if let photoName = photoName, UIImage(named: photoName) != nil {
                    SegmentedAsyncImage(
                        imageName: photoName,
                        size: CGSize(width: size - 10, height: size - 10),
                        placeholderColor: avatarColor
                    )
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.38, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    avatarColor,
                                    avatarColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: avatarColor.opacity(0.5), radius: 8)
                }

                // === BORDURE SUBTILE IRIDESCENTE ===
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                avatarColor.opacity(0.6),
                                avatarColor.opacity(0.3),
                                avatarColor.opacity(0.5),
                                avatarColor.opacity(0.4),
                                avatarColor.opacity(0.6)
                            ],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: size - 2, height: size - 2)
            }
            .dynamicGlassReflection(intensity: 0.7)
            // PERFORMANCE FIX: Removed breathing animation
            .scaleEffect(isBouncing ? 1.15 : 1.0)
            .scaleEffect(isDragging ? 1.08 : 1.0)
            .shadow(color: avatarColor.opacity(isDragging ? 0.5 : 0.3), radius: isDragging ? 15 : 10, x: 0, y: isDragging ? 8 : 5)

            // === BADGE NOM ===
            Text(name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(DesignTokens.Colors.bubbleText)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(DesignTokens.Colors.bubbleBackground)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            Capsule()
                                .stroke(DesignTokens.Colors.bubbleBackground, lineWidth: 0.5)
                        )
                )
                .shadow(color: avatarColor.opacity(0.3), radius: 4, y: 2)
        }
        .offset(x: dragOffset.width, y: dragOffset.height)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging && !isBouncing {
                        dragStartLocation = value.startLocation

                        let impact = UIImpactFeedbackGenerator(style: .soft)
                        impact.impactOccurred()

                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5, blendDuration: 0)) {
                            isBouncing = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                                isBouncing = false
                            }
                        }
                    }

                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let dragDistance = sqrt(
                        pow(value.translation.width, 2) +
                        pow(value.translation.height, 2)
                    )

                    if dragDistance < 10 {
                        onTap?()
                    }

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        isDragging = false
                        dragOffset = .zero
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
        )
        // PERFORMANCE FIX: Removed breathing animation from onAppear
    }
}

// MARK: - Ghost Bubble View (Pour connexions invitees/en attente)
// PERFORMANCE FIX: Removed pulse animation
struct GhostBubbleView: View {
    let name: String
    let photoName: String?
    let contactPhotoData: Data?
    let avatarColor: Color
    let size: CGFloat
    let index: Int
    @Binding var dragOffset: CGSize
    var onTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // PERFORMANCE FIX: Removed pulsePhase
    @State private var isDragging: Bool = false
    @State private var isBouncing: Bool = false
    @State private var dragStartLocation: CGPoint = .zero

    private let ghostOpacity: Double = 0.65

    private var contactImage: UIImage? {
        guard let data = contactPhotoData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // === FOND LIQUID GLASS iOS 26 (style fantome) ===
                Circle()
                    .fill(avatarColor.opacity(0.08 * ghostOpacity))
                    .frame(width: size, height: size)
                    .glassEffect(.regular, in: .circle)
                    .opacity(ghostOpacity)
                    .dynamicGlassReflectionSubtle()

                // === CONTENU FANTOME ===
                if let uiImage = contactImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size - 8, height: size - 8)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.clear,
                                            Color.black.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .saturation(0.7)
                        .opacity(ghostOpacity)
                } else if let photoName = photoName, UIImage(named: photoName) != nil {
                    SegmentedAsyncImage(
                        imageName: photoName,
                        size: CGSize(width: size - 6, height: size - 6),
                        placeholderColor: avatarColor
                    )
                    .opacity(ghostOpacity)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.35, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    avatarColor.opacity(0.6 * ghostOpacity),
                                    avatarColor.opacity(0.4 * ghostOpacity)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // === BORDURE EN POINTILLES (style en attente) ===
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.gray.opacity(0.4),
                                avatarColor.opacity(0.3),
                                Color.gray.opacity(0.4)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
                    .frame(width: size, height: size)

                // === ICONE D'INVITATION (petit badge) ===
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.7))
                            )
                            .offset(x: 5, y: -5)
                    }
                    Spacer()
                }
                .frame(width: size, height: size)
            }
            // PERFORMANCE FIX: Removed pulse animation
            .scaleEffect(isBouncing ? 1.12 : 1.0)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .shadow(color: Color.gray.opacity(isDragging ? 0.3 : 0.15), radius: isDragging ? 10 : 6, x: 0, y: isDragging ? 6 : 3)

            // === BADGE NOM ===
            Text(name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DesignTokens.Colors.bubbleBackground)
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                )
        }
        .offset(x: dragOffset.width, y: dragOffset.height)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging && !isBouncing {
                        dragStartLocation = value.startLocation

                        let impact = UIImpactFeedbackGenerator(style: .soft)
                        impact.impactOccurred()

                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5, blendDuration: 0)) {
                            isBouncing = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                                isBouncing = false
                            }
                        }
                    }

                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let dragDistance = sqrt(
                        pow(value.translation.width, 2) +
                        pow(value.translation.height, 2)
                    )

                    if dragDistance < 10 {
                        onTap?()
                    }

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        isDragging = false
                        dragOffset = .zero
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
        )
        // PERFORMANCE FIX: Removed pulse animation from onAppear
    }
}

// MARK: - Center User Bubble (Gil - Style Glass Transparent)
// PERFORMANCE FIX: Reduced from 2 animations to 1 (rainbow rotation only)
struct CenterUserBubble: View {
    private let size: CGFloat = 95

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var rainbowRotation: Double = 0

    private let gilColor = Color(red: 0.95, green: 0.45, blue: 0.50)

    var body: some View {
        ZStack {
            // === HALO GLOW EXTERNE === PERFORMANCE FIX: Static (no breathing)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            gilColor.opacity(0.4),
                            gilColor.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.4,
                        endRadius: size * 0.85
                    )
                )
                .frame(width: size * 1.6, height: size * 1.6)
                .blur(radius: 15)

            // === BULLE PRINCIPALE AVEC LIQUID GLASS ===
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(gilColor.opacity(0.2))
                        .frame(width: size, height: size)
                        .glassEffect(.regular, in: .circle)
                        .dynamicGlassReflectionProminent()

                    if UIImage(named: "photo_gil") != nil {
                        SegmentedAsyncImage(
                            imageName: "photo_gil",
                            size: CGSize(width: size - 12, height: size - 12),
                            placeholderColor: gilColor
                        )
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.42, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        gilColor,
                                        gilColor.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: gilColor.opacity(0.6), radius: 10)
                    }

                    // === BORDURE ARC-EN-CIEL ANIMEE ===
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color.red.opacity(0.7),
                                    Color.orange.opacity(0.7),
                                    Color.yellow.opacity(0.7),
                                    Color.green.opacity(0.7),
                                    Color.blue.opacity(0.7),
                                    Color.purple.opacity(0.7),
                                    Color.pink.opacity(0.7),
                                    Color.red.opacity(0.7)
                                ],
                                center: .center,
                                startAngle: .degrees(rainbowRotation),
                                endAngle: .degrees(rainbowRotation + 360)
                            ),
                            lineWidth: 3
                        )
                        .frame(width: size - 2, height: size - 2)
                }
                .shadow(color: gilColor.opacity(0.5), radius: 20, x: 0, y: 8)
            }

            // === BADGE NOM "Gil" ===
            VStack {
                Spacer()
                    .frame(height: size * 0.95)

                Text("Gil")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.Colors.bubbleText)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(DesignTokens.Colors.bubbleBackground)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [gilColor.opacity(0.5), Color.white.opacity(0.3)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: gilColor.opacity(0.4), radius: 6, y: 3)
            }
        }
        .onAppear {
            // PERFORMANCE FIX: Only 1 animation (rainbow) - removed breathing
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                rainbowRotation = 360
            }
        }
    }
}

// MARK: - Mic Button (Style Liquid Glass transparent)
// PERFORMANCE FIX: Removed pulse animation
struct OrbitalMicButtonView: View {
    let onTap: () -> Void
    let onAudioRecorded: (Data) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var audioService = AudioRecorderService.shared

    @State private var isPressed = false
    // PERFORMANCE FIX: Removed pulsePhase
    @State private var isLongPressing = false
    @State private var longPressStartTime: Date?

    private let buttonSize: CGFloat = 70
    private let micColor = Color(red: 0.5, green: 0.3, blue: 0.8)
    private let recordingColor = Color.red

    private let longPressThreshold: TimeInterval = 0.3

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            currentColor.opacity(0.15),
                            currentColor.opacity(0.25),
                            currentColor.opacity(0.10)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: buttonSize * 0.5
                    )
                )
                .frame(width: buttonSize - 4, height: buttonSize - 4)

            Image(systemName: audioService.state.isRecording ? "waveform.circle.fill" : "mic.fill")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            currentColor.opacity(0.9),
                            currentColor.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .symbolEffect(.pulse, isActive: audioService.state.isRecording)

            GlassBubbleOverlay(size: buttonSize, tintColor: currentColor)

            if audioService.state.isRecording {
                Circle()
                    .stroke(recordingColor.opacity(0.8), lineWidth: 3)
                    .frame(width: buttonSize + 8, height: buttonSize + 8)
                    .scaleEffect(1.0 + CGFloat(audioService.audioLevel) * 0.15)
                    .animation(.easeOut(duration: 0.1), value: audioService.audioLevel)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        // PERFORMANCE FIX: Removed pulse animation
        .shadow(color: currentColor.opacity(0.3), radius: 12, x: 0, y: 6)
        // PERFORMANCE FIX: minimumDistance 5 reduces gesture events without affecting UX
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { _ in
                    if !isLongPressing {
                        isLongPressing = true
                        longPressStartTime = Date()

                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()

                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            isPressed = true
                        }

                        Task {
                            try? await Task.sleep(for: .milliseconds(Int(longPressThreshold * 1000)))

                            if isLongPressing {
                                let impact = UIImpactFeedbackGenerator(style: .heavy)
                                impact.impactOccurred()

                                do {
                                    try await audioService.startRecording()
                                    print("Recording started via long press")
                                } catch {
                                    print("Failed to start recording: \(error)")
                                }
                            }
                        }
                    }
                }
                .onEnded { _ in
                    let pressDuration = Date().timeIntervalSince(longPressStartTime ?? Date())

                    withAnimation(.easeOut(duration: 0.2)) {
                        isPressed = false
                    }

                    if audioService.state.isRecording {
                        Task {
                            do {
                                let audioData = try await audioService.stopRecording()
                                print("Recording stopped: \(audioData.count) bytes")
                                onAudioRecorded(audioData)
                            } catch {
                                print("Failed to stop recording: \(error)")
                            }
                        }
                    } else if pressDuration < longPressThreshold {
                        onTap()
                    }

                    isLongPressing = false
                    longPressStartTime = nil
                }
        )
        // PERFORMANCE FIX: Removed pulse animation from onAppear
    }

    private var currentColor: Color {
        audioService.state.isRecording ? recordingColor : micColor
    }
}
