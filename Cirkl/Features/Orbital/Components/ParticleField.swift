import SwiftUI

/// Animated particle field for background ambiance
struct ParticleField: View {
    @State private var particles: [Particle] = []
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .blur(radius: particle.blur)
                }
            }
            .onAppear {
                createInitialParticles(in: geometry.size)
            }
            .onReceive(timer) { _ in
                updateParticles(in: geometry.size)
            }
        }
    }
    
    private func createInitialParticles(in size: CGSize) {
        particles = (0..<30).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.1...0.5),
                blur: CGFloat.random(in: 0...2),
                velocity: CGPoint(
                    x: CGFloat.random(in: -0.5...0.5),
                    y: CGFloat.random(in: -0.5...0.5)
                )
            )
        }
    }
    
    private func updateParticles(in size: CGSize) {
        for i in particles.indices {
            particles[i].position.x += particles[i].velocity.x
            particles[i].position.y += particles[i].velocity.y
            
            // Wrap around edges
            if particles[i].position.x < 0 {
                particles[i].position.x = size.width
            } else if particles[i].position.x > size.width {
                particles[i].position.x = 0
            }
            
            if particles[i].position.y < 0 {
                particles[i].position.y = size.height
            } else if particles[i].position.y > size.height {
                particles[i].position.y = 0
            }
        }
    }
}

/// Individual particle model
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var blur: CGFloat
    var velocity: CGPoint
}