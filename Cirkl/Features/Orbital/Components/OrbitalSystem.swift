import SwiftUI

/// Orbital system showing connections around the user
struct OrbitalSystem: View {
    let geometry: GeometryProxy
    let connections: [Connection]
    @Binding var selectedConnection: Connection?
    let rotationAngle: Double
    
    @State private var hoveredConnection: Connection?
    
    var body: some View {
        ZStack {
            // Connection lines
            ForEach(connections) { connection in
                ConnectionLine(
                    from: CGPoint(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    ),
                    to: orbitalPosition(for: connection, in: geometry.size),
                    connection: connection,
                    isHovered: hoveredConnection?.id == connection.id
                )
            }
            
            // Connection bubbles
            ForEach(connections) { connection in
                ConnectionBubble(
                    connection: connection,
                    isSelected: selectedConnection?.id == connection.id,
                    isHovered: hoveredConnection?.id == connection.id
                )
                .position(orbitalPosition(for: connection, in: geometry.size))
                .onTapGesture {
                    withAnimation(.spring()) {
                        selectedConnection = connection
                    }
                }
                .onHover { isHovered in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hoveredConnection = isHovered ? connection : nil
                    }
                }
            }
        }
        .rotationEffect(.degrees(rotationAngle))
    }
    
    /// Calculate orbital position for a connection
    private func orbitalPosition(for connection: Connection, in size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Distance based on relationship strength (closer = stronger)
        let minRadius: CGFloat = 120
        let maxRadius: CGFloat = min(size.width, size.height) / 2 - 60
        let distance = minRadius + (maxRadius - minRadius) * (1 - connection.relationshipStrength)
        
        // Angle based on connection index and some randomization
        let angleOffset = Double(connection.id.hashValue % 360)
        let angle = angleOffset * .pi / 180
        
        let x = center.x + cos(angle) * distance
        let y = center.y + sin(angle) * distance
        
        return CGPoint(x: x, y: y)
    }
}

/// Connection line between center and orbital bubble
struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let connection: Connection
    let isHovered: Bool
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(
            LinearGradient(
                colors: [
                    connection.color.opacity(isHovered ? 0.6 : 0.3),
                    connection.color.opacity(isHovered ? 0.3 : 0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            lineWidth: isHovered ? 2 : 1
        )
        .blur(radius: 0.5)
        .animation(.easeInOut(duration: 0.3), value: isHovered)
    }
}