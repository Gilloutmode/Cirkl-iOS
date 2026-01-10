import SwiftUI

// MARK: - ProximityRadar
/// Composant d'animation radar glassmorphique pour la détection de proximité
struct ProximityRadar: View {

    // MARK: - Properties
    let isScanning: Bool
    let detectedCount: Int

    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0

    var size: CGFloat = 200

    // MARK: - Body
    var body: some View {
        ZStack {
            // Concentric circles
            concentricCircles

            // Pulse animation
            if isScanning {
                pulseRing
            }

            // Sweep line
            if isScanning {
                sweepLine
            }

            // Center
            centerPoint

            // Detection indicator
            if detectedCount > 0 {
                detectionBadge
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if isScanning {
                startAnimations()
            }
        }
        .onChange(of: isScanning) { _, newValue in
            if newValue {
                startAnimations()
            } else {
                stopAnimations()
            }
        }
    }

    // MARK: - Concentric Circles
    private var concentricCircles: some View {
        ForEach(1..<5, id: \.self) { index in
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            .mint.opacity(0.3 - Double(index) * 0.06),
                            .blue.opacity(0.2 - Double(index) * 0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(
                    width: size * CGFloat(index) / 4.5,
                    height: size * CGFloat(index) / 4.5
                )
        }
    }

    // MARK: - Pulse Ring
    private var pulseRing: some View {
        Circle()
            .stroke(.mint.opacity(0.5), lineWidth: 2)
            .frame(width: size * 0.9, height: size * 0.9)
            .scaleEffect(pulseScale)
            .opacity(pulseOpacity)
    }

    // MARK: - Sweep Line
    private var sweepLine: some View {
        ZStack {
            // Gradient cone
            AngularGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .mint.opacity(0.05),
                    .mint.opacity(0.15),
                    .mint.opacity(0.3),
                    .clear
                ]),
                center: .center,
                startAngle: .degrees(rotation - 60),
                endAngle: .degrees(rotation)
            )
            .frame(width: size * 0.85, height: size * 0.85)
            .mask(Circle())

            // Line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.mint.opacity(0.8), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 2, height: size * 0.42)
                .offset(y: -size * 0.21)
                .rotationEffect(.degrees(rotation))
        }
    }

    // MARK: - Center Point
    private var centerPoint: some View {
        ZStack {
            // Glow
            Circle()
                .fill(.mint.opacity(0.3))
                .frame(width: 24, height: 24)
                .blur(radius: 8)

            // Point
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, .mint],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 12, height: 12)

            // Inner ring
            Circle()
                .stroke(.white.opacity(0.5), lineWidth: 1)
                .frame(width: 16, height: 16)
        }
    }

    // MARK: - Detection Badge
    private var detectionBadge: some View {
        VStack {
            HStack {
                Spacer()

                ZStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 24, height: 24)

                    Text("\(detectedCount)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
                .offset(x: -10, y: 10)
            }

            Spacer()
        }
        .frame(width: size, height: size)
    }

    // MARK: - Animations
    private func startAnimations() {
        // Rotation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            rotation = 360
        }

        // Pulse
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseScale = 1.2
            pulseOpacity = 0
        }
    }

    private func stopAnimations() {
        rotation = 0
        pulseScale = 1.0
        pulseOpacity = 1.0
    }
}

// MARK: - Mini Radar Variant
/// Version compacte du radar pour les badges et indicateurs
struct MiniProximityRadar: View {
    let isActive: Bool

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Circles
            ForEach(1..<3, id: \.self) { index in
                Circle()
                    .stroke(.mint.opacity(0.3), lineWidth: 0.5)
                    .frame(
                        width: CGFloat(8 + index * 6),
                        height: CGFloat(8 + index * 6)
                    )
            }

            // Sweep
            if isActive {
                Rectangle()
                    .fill(.mint.opacity(0.6))
                    .frame(width: 1, height: 10)
                    .offset(y: -5)
                    .rotationEffect(.degrees(rotation))
            }

            // Center
            Circle()
                .fill(.mint)
                .frame(width: 4, height: 4)
        }
        .frame(width: 24, height: 24)
        .onAppear {
            if isActive {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Scanning") {
    ZStack {
        Color(red: 0.04, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        VStack(spacing: 40) {
            ProximityRadar(isScanning: true, detectedCount: 2)

            HStack(spacing: 20) {
                MiniProximityRadar(isActive: true)
                MiniProximityRadar(isActive: false)
            }
        }
    }
}

#Preview("Idle") {
    ZStack {
        Color(red: 0.04, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        ProximityRadar(isScanning: false, detectedCount: 0)
    }
}
