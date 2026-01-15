import SwiftUI

// MARK: - Connection Lines (Grises subtiles - suivent les bulles en temps reel)
struct OrbitalLinesCanvas: View {
    let contacts: [OrbitalContact]
    let centerX: CGFloat
    let centerY: CGFloat
    let width: CGFloat
    let height: CGFloat
    let bubbleOffsets: [Int: CGSize]  // Offsets de drag des bulles
    let searchQuery: String  // Pour filtrer les lignes aussi

    // Rayons des bulles (lignes touchent exactement le bord VISUEL)
    private let centerBubbleRadius: CGFloat = 42
    private let contactBubbleRadius: CGFloat = 32

    // ID unique base sur les offsets ET la recherche pour forcer le redraw du Canvas
    private var canvasId: String {
        let offsetsStr = bubbleOffsets.map { "\($0.key):\($0.value.width),\($0.value.height)" }.joined(separator: "|")
        return "\(offsetsStr)|\(searchQuery)|\(contacts.count)"
    }

    var body: some View {
        Canvas { context, _ in
            for (index, contact) in contacts.enumerated() {
                // Ne pas dessiner les lignes pour les contacts filtres
                guard contact.matches(query: searchQuery) else { continue }
                // Position de base de la bulle
                let baseX = width * contact.xPercent
                let baseY = height * contact.yPercent

                // Ajouter l'offset de drag si present
                let offset = bubbleOffsets[index] ?? .zero
                let bubbleX = baseX + offset.width
                let bubbleY = baseY + offset.height

                // Calculer la direction et distance vers le centre (Gil)
                let dx = bubbleX - centerX
                let dy = bubbleY - centerY
                let distance = sqrt(dx * dx + dy * dy)

                // Eviter division par zero
                guard distance > 0 else { continue }

                // Normaliser la direction
                let dirX = dx / distance
                let dirY = dy / distance

                // Point de depart: exactement au bord de la bulle centrale (Gil)
                let startX = centerX + dirX * centerBubbleRadius
                let startY = centerY + dirY * centerBubbleRadius

                // Point d'arrivee: exactement au bord de la bulle contact
                let endX = bubbleX - dirX * contactBubbleRadius
                let endY = bubbleY - dirY * contactBubbleRadius

                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))

                // === LIGNES CONNEXION (Adaptatif Light/Dark) ===
                context.stroke(
                    path,
                    with: .color(DesignTokens.Colors.orbitalLines),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
            }
        }
        .id(canvasId)  // Force le redraw quand les offsets changent
    }
}

// MARK: - Connection Bubbles Layer
struct OrbitalBubblesLayer: View {
    let contacts: [OrbitalContact]
    let centerX: CGFloat
    let centerY: CGFloat
    let width: CGFloat
    let height: CGFloat
    @Binding var bubbleOffsets: [Int: CGSize]
    let searchQuery: String
    var onContactTap: ((OrbitalContact) -> Void)?  // Callback pour ouvrir le profil

    private let verifiedBubbleSize: CGFloat = 70   // Taille pour connexions verifiees
    private let pendingBubbleSize: CGFloat = 60    // Taille reduite pour connexions en attente

    var body: some View {
        ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
            let posX = width * contact.xPercent
            let posY = height * contact.yPercent
            let isVisible = contact.matches(query: searchQuery)
            let bubbleSize = contact.trustLevel.isConfirmed ? verifiedBubbleSize : pendingBubbleSize

            AnimatedBubbleWrapper(
                contact: contact,
                index: index,
                posX: posX,
                posY: posY,
                centerX: centerX,
                centerY: centerY,
                bubbleSize: bubbleSize,
                isVisible: isVisible,
                isPending: !contact.trustLevel.isConfirmed,
                dragOffset: Binding(
                    get: { bubbleOffsets[index] ?? .zero },
                    set: { bubbleOffsets[index] = $0 }
                ),
                onTap: { onContactTap?(contact) }
            )
        }
    }
}

// MARK: - Animated Bubble Wrapper (Explosion Effect)
struct AnimatedBubbleWrapper: View {
    let contact: OrbitalContact
    let index: Int
    let posX: CGFloat
    let posY: CGFloat
    let centerX: CGFloat
    let centerY: CGFloat
    let bubbleSize: CGFloat
    let isVisible: Bool
    let isPending: Bool  // Determine le style de bulle (ghost ou normal)
    @Binding var dragOffset: CGSize
    var onTap: (() -> Void)?  // Callback pour ouvrir le profil

    // Animation states
    @State private var explosionOffset: CGSize = .zero
    @State private var explosionScale: CGFloat = 1.0
    @State private var explosionOpacity: Double = 1.0
    @State private var explosionRotation: Double = 0

    var body: some View {
        Group {
            if isPending {
                // Bulle fantome pour connexions en attente
                GhostBubbleView(
                    name: contact.name,
                    photoName: contact.photoName,
                    contactPhotoData: contact.contactPhotoData,
                    avatarColor: contact.avatarColor,
                    size: bubbleSize,
                    index: index,
                    dragOffset: $dragOffset,
                    onTap: onTap
                )
            } else {
                // Bulle normale pour connexions verifiees
                GlassBubbleView(
                    name: contact.name,
                    photoName: contact.photoName,
                    avatarColor: contact.avatarColor,
                    size: bubbleSize,
                    index: index,
                    dragOffset: $dragOffset,
                    onTap: onTap
                )
            }
        }
        .scaleEffect(explosionScale)
        .opacity(explosionOpacity)
        .rotationEffect(.degrees(explosionRotation))
        .offset(x: explosionOffset.width, y: explosionOffset.height)
        .position(x: posX, y: posY)
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                // Retour avec animation "pop-in"
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    explosionOffset = .zero
                    explosionScale = 1.0
                    explosionOpacity = 1.0
                    explosionRotation = 0
                }
            } else {
                // Explosion vers l'exterieur
                let dx = posX - centerX
                let dy = posY - centerY
                let angle = atan2(dy, dx)

                // Distance d'explosion basee sur la position
                let distance: CGFloat = 300
                let targetX = cos(angle) * distance
                let targetY = sin(angle) * distance

                // Rotation aleatoire pour effet naturel
                let randomRotation = Double.random(in: -45...45)

                withAnimation(.easeOut(duration: 0.4)) {
                    explosionOffset = CGSize(width: targetX, height: targetY)
                    explosionScale = 0.3
                    explosionOpacity = 0.0
                    explosionRotation = randomRotation
                }
            }
        }
    }
}
