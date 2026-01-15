# 📱 Cirkl Project Context for Claude Code

## Executive Summary
Cirkl is a revolutionary social network that guarantees authentic connections through physical verification. Unlike traditional social networks plagued by bots and fake profiles, Cirkl requires physical presence (QR/NFC/BLE) to establish connections, ensuring 100% real human interactions.

## Vision Statement
**"Connecting Authentically, Growing Intelligently"**

We're building the antithesis of superficial social media - a platform where every connection is verified, meaningful, and has the potential to create real-world opportunities.

## Technical Architecture

### Current Implementation Status
- ✅ Orbital interface design implemented
- ✅ Glassmorphic UI components created
- ✅ Basic animation system working
- ✅ Mock data and ViewModels ready
- 🚧 Physical verification (NFC/QR) in progress
- 🚧 AI assistant integration pending
- 🚧 Backend API development starting

### File Structure
```
Cirkl/
├── Features/
│   ├── Orbital/          # Main interface
│   │   ├── OrbitalView.swift
│   │   ├── OrbitalViewModel.swift
│   │   └── Components/
│   ├── Authentication/   # Login/verification
│   └── Onboarding/      # User onboarding
├── Models/              # Data models
├── Services/            # API/Backend services
└── Resources/           # Assets
```

## Design Philosophy

### The Orbital Interface
Inspired by planetary systems, users are at the center of their social universe with connections orbiting around them. This creates an intuitive, memorable visualization of relationships that evolves over time.

### Visual Language
- **Glassmorphism**: Transparency and blur effects create depth
- **Breathing UI**: Elements pulse and breathe, feeling alive
- **Color Psychology**: Each founder has a signature color
- **Particle Effects**: Subtle animations for engagement moments

### User Experience Principles
1. **Zero Friction**: Physical tap to connect (NFC/QR)
2. **Visual Hierarchy**: Important connections are closer/larger
3. **Emotional Design**: Colors and animations reflect relationship states
4. **Progressive Disclosure**: Complexity revealed as needed

## AI Integration Strategy

### Zep AI Memory System
- Persistent conversation memory across sessions
- Context-aware responses based on user history
- Predictive matching based on interaction patterns
- Opportunity detection from conversation analysis

### Assistant Personality
- **Empathetic**: Understands emotional context
- **Proactive**: Suggests connections and opportunities
- **Adaptive**: Changes tone based on context
- **Trustworthy**: Never shares private information

### Dynamic States
The AI assistant changes color to indicate its current mode:
- Analyzing a recent meeting
- Detecting an opportunity
- Celebrating a successful connection
- Suggesting next steps

## Business Model

### Freemium Tiers
1. **Free**: 150 connections, basic AI
2. **Premium** (€9.99/mo): Unlimited connections, advanced AI
3. **Business** (€29.99/mo): Team features, analytics

### Revenue Projections
- Average LTV: €12,400 per user
- Conversion rate: 67% (from pilot data)
- Viral coefficient: 1.7
- CAC: €18.50

### Market Strategy
1. **Phase 1**: Israel POC (Q1 2025)
2. **Phase 2**: USA expansion (Q3 2025)
3. **Phase 3**: Global scale (2026)

## Technical Decisions Log

### Why SwiftUI over UIKit?
- Modern declarative syntax
- Better performance with iOS 17+
- Built-in animation system
- Faster development cycle

### Why Physical Verification?
- Eliminates fake profiles (100% guarantee)
- Creates meaningful friction
- Legal compliance for identity
- Trust signal for users

### Why Orbital Design?
- Intuitive spatial representation
- Scalable to 1000s of connections
- Memorable and unique
- Natural gesture interactions

## Known Challenges & Solutions

### Challenge: Scaling to 1000+ connections
**Solution**: Dynamic clustering and progressive loading. Only show relevant connections based on context and recent interactions.

### Challenge: Physical verification adoption
**Solution**: Multiple methods (QR/NFC/BLE) and gamification to make it fun rather than friction.

### Challenge: Privacy concerns
**Solution**: End-to-end encryption, privacy by design, transparent data practices, user-controlled sharing.

## Current Development Focus

### Sprint 24 (Current)
- [ ] Implement CoreNFC for tap-to-connect
- [ ] Add AVFoundation QR scanning
- [ ] Integrate Zep AI memory system
- [ ] Optimize animations for 120fps
- [ ] Create onboarding flow

### Technical Debt
- Refactor OrbitalView into smaller components
- Add proper error handling to all services
- Implement proper state management
- Add comprehensive unit tests
- Profile and optimize memory usage

## Code Examples & Patterns

### Creating a Glassmorphic Component
```swift
struct GlassCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.1))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.2))
                    .blur(radius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}
```

### Orbital Position Calculation
```swift
func orbitalPosition(for connection: Connection, in size: CGSize) -> CGPoint {
    let center = CGPoint(x: size.width / 2, y: size.height / 2)
    let distance = 120 + (1 - connection.strength) * 100
    let angle = connection.id.hashValue % 360 * .pi / 180
    
    return CGPoint(
        x: center.x + cos(angle) * distance,
        y: center.y + sin(angle) * distance
    )
}
```

### AI State Management
```swift
@MainActor
class AIAssistantViewModel: ObservableObject {
    @Published var state: AIAssistantState = .idle
    
    func processInteraction(_ interaction: Interaction) {
        switch interaction.type {
        case .meeting:
            state = .contextual
        case .opportunity:
            state = .opportunity
        case .success:
            state = .celebration
        }
    }
}
```

## External Dependencies

### Current
- SwiftUI (Apple)
- Combine (Apple)
- Swift 6.0

### Planned
- Zep AI SDK
- Supabase (backend)
- RevenueCat (subscriptions)
- Sentry (monitoring)
- Mixpanel (analytics)

## Success Metrics

### Technical KPIs
- App crash rate < 0.1%
- 60-120fps animations
- < 200ms response time
- < 50MB app size
- 99.9% uptime

### Business KPIs
- MAU growth: 50% MoM
- Retention D30: 60%
- NPS score: 70+
- Viral coefficient: 1.7+
- LTV:CAC ratio: 3:1

## Team Notes

### Gil (CEO/AI)
"The AI should feel like a trusted friend who remembers everything and always has your back."

### Denis (CFO/VC)
"Every feature must drive either engagement or revenue. No vanity features."

### Gilles (CTO)
"Performance is a feature. If it's not smooth, it's not shipped."

---

## Quick Reference

### Common Tasks
- Add new connection: `ConnectionManager.shared.addConnection()`
- Update AI state: `aiViewModel.updateState(.contextual)`
- Trigger animation: `withAnimation(.spring()) { }`
- Save to CloudKit: `CloudKitManager.save()`

### Debugging
- Performance: Use Instruments Time Profiler
- Memory: Check for retain cycles in closures
- UI: Debug View Hierarchy in Xcode
- Network: Charles Proxy for API calls

### Testing
- Unit tests: XCTest for ViewModels
- UI tests: XCUITest for flows
- Performance: XCTest metrics
- Beta: TestFlight with 100 users

---

Remember: Every decision should reinforce our core promise - authentic human connections in a world of digital noise.