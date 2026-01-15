# CLAUDE.md - Cirkl iOS Project

This file provides guidance to Claude Code and Claude Desktop when working with this iOS project.

## Quick Reference

```bash
# Build
xcodebuild -scheme Cirkl -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run tests
xcodebuild test -scheme Cirkl -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Open in Xcode
open Cirkl.xcodeproj
```

## Project Overview

**Cirkl** is an authentic social network iOS app that guarantees real human connections through physical verification (QR/NFC/BLE). Zero fake profiles, 100% human.

> 📖 **Vision complète**: Voir [`VISION_PRODUIT.md`](./VISION_PRODUIT.md) pour la vision fondateur, mécaniques psychologiques, et features détaillées.

### Core Philosophy
- **Émerveillement en 3 secondes**: L'utilisateur se voit au centre de son univers relationnel
- **Réseau vivant**: Les connexions "respirent" - s'approchent ou s'éloignent selon l'engagement
- **IA compagnon**: Pas un outil, un compagnon relationnel qui donne de la valeur avant de demander

### Key Features (Priority Order)

| Feature | Description | Status |
|---------|-------------|--------|
| 🎙️ **Morning Brief** | Brief vocal quotidien personnalisé (ElevenLabs) | 🔴 P0 |
| 🔮 **Synchronicity Score** | Widget iOS public avec score et niveau | 🔴 P0 |
| 📱 **Memory Import** | Import contacts + LinkedIn pour valeur J1 | 🔴 P0 |
| 🌙 **Night Reflection** | Mode réflexion nocturne avec souvenirs | 🟡 P1 |
| 📊 **Network Pulse** | Dashboard santé du réseau (🟢🟡🔴) | 🟡 P1 |
| ⏱️ **Window of Opportunity** | Urgence éthique 48h sur opportunités | 🟢 P2 |

### UX Principles
1. **< 30 sec to value**: Dopamine dès l'import réseau existant
2. **Pull > Push**: L'utilisateur revient par curiosité, pas par notification
3. **Variable Reward**: Synchronicity Engine génère des surprises imprévisibles
4. **Identité**: "Je suis un architecte de connexions" (pas un networker)

### Magic Numbers
- **25 connexions + 3 CirKLs** = Seuil d'indispensabilité
- **CirKL of 3** = Unité minimale de valeur (triangulation sociale)
- **48h** = Fenêtre d'opportunité avant redistribution

### Tech Stack
- **Swift 6.0** with **SwiftUI** (iOS 26)
- **Min iOS**: 26.0 (Liquid Glass)
- **Architecture**: MVVM-C + Clean Architecture
- **State Management**: `@Observable` for ViewModels, `@MainActor` for UI
- **Persistence**: SwiftData
- **Backend**: N8N webhooks → AI Orchestration
- **On-Device AI**: Foundation Models (iPhone 15 Pro+)

## Project Structure

```
Cirkl/
├── App/                    # App lifecycle (CirklApp.swift)
├── Core/
│   ├── Extensions/         # Swift extensions
│   ├── Models/             # Shared data models
│   ├── Services/           # API services (N8NService, Neo4jService)
│   ├── ViewModels/         # Shared ViewModels
│   └── Views/              # Shared views
├── Features/               # Feature modules (vertical slices)
│   ├── AI/                 # AI assistant (Zep integration)
│   ├── Authentication/     # Login, biometrics
│   ├── Circles/            # Group management
│   ├── Connections/        # Connection profiles, lists
│   ├── Onboarding/         # User onboarding flow
│   ├── Orbital/            # Main orbital interface (flagship feature)
│   └── Professional/       # Professional features
├── Components/             # Reusable UI components
├── Models/                 # Core data models (Connection, User, etc.)
└── Resources/              # Assets, colors, localization
```

## Design System - Liquid Glass (iOS 26)

### Core Visual Rules
1. **Native Glass**: Use `.glassEffect()` instead of manual blur/materials
2. **Interactive Elements**: `.glassEffect(.regular.interactive())` for buttons
3. **Morphing Transitions**: `GlassEffectContainer` with `glassEffectID()`
4. **Dark mode only**: `.preferredColorScheme(.dark)`
5. **Target framerate**: 120fps (ProMotion)

### Brand Colors
- **Cirkl Blue**: `#0A0E27` (dark background)
- **Electric Blue**: `#007AFF` (primary actions)
- **Mint**: `#00C781` (success, verification)

### Liquid Glass Component Patterns
```swift
// Basic glass effect (replaces old manual glassmorphism)
.glassEffect()

// Interactive buttons
Button("Action") { }
    .buttonStyle(.glassProminent)

// Glass card component
VStack {
    content
}
.padding()
.glassEffect(.regular, in: .rect(cornerRadius: 20))

// Morphing transitions
@Namespace private var namespace

GlassEffectContainer(spacing: 16) {
    ForEach(items) { item in
        ItemView(item: item)
            .glassEffect()
            .glassEffectID(item.id, in: namespace)
    }
}
```

### Glass Effect Variants
```swift
.glassEffect()                    // Default: regular, capsule
.glassEffect(.regular)            // Standard translucent
.glassEffect(.clear)              // More transparent
.glassEffect(.identity)           // For morphing transitions
.glassEffect(.regular.interactive()) // Responds to touch
```

## Coding Standards

### Rules
1. **Max 300 lines per file** - Split if larger
2. **Use `// MARK: -`** for section organization
3. **Async/await only** - No completion handlers
4. **Never force unwrap** without certainty
5. **LocalizedStringKey** for all user-facing strings

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Views | `*View.swift` | `OrbitalView.swift` |
| ViewModels | `*ViewModel.swift` | `OrbitalViewModel.swift` |
| Services | `*Service.swift` | `N8NService.swift` |
| Models | Descriptive | `Connection.swift` |

### ViewModel Pattern
```swift
@MainActor
@Observable
final class FeatureViewModel {
    var state: ViewState = .idle

    func load() async {
        state = .loading
        do {
            let data = try await service.fetch()
            state = .loaded(data)
        } catch {
            state = .error(error)
        }
    }
}
```

### Foundation Models Integration (On-Device AI)
```swift
import FoundationModels

// Always check availability first
guard LanguageModelSession.isAvailable else {
    // Provide fallback for non-Pro devices
    return
}

// Simple generation
let session = LanguageModelSession()
let response = try await session.respond(to: prompt)

// Streaming for better UX
for try await chunk in session.streamResponse(to: prompt) {
    output += chunk
}
```
> **Requires**: iPhone 15 Pro+, iPad M1+, Mac M1+

## Key Services

### N8NService (Core/Services/N8NService.swift)
- Webhook: `https://gilloutmode.app.n8n.cloud/webhook/cirkl-ios`
- Handles: AI messages, connection updates, button state polling
- All requests use `@MainActor`, `Sendable` responses

### Neo4jService (Core/Services/Neo4jService.swift)
- Graph database for connection relationships
- Manages spheres, natures, closeness levels

## Key Models

### Connection (Models/Connection.swift)
- `id`, `name`, `avatarURL`
- `relationshipProfile`: spheres, natures, closeness
- `verificationMethod`: QR, NFC, Proximity, Bluetooth

### RelationshipProfile
- `spheres`: [.professional, .personal, .creative, .community, .family]
- `natures`: [.mentor, .collaborator, .friend, ...]
- `closeness`: 1-5 scale

## Orbital Interface (Flagship Feature)

The orbital view displays connections as bubbles orbiting around the user:
- **Center**: User avatar
- **Orbits**: Connections positioned by closeness/interaction
- **Bubbles**: Tappable to view profiles
- **AI Button**: Bottom center, changes state based on context

### Key Files
- `Features/Orbital/OrbitalView.swift` - Main view
- `Features/Orbital/OrbitalViewModel.swift` - Business logic
- `Features/Orbital/Components/ConnectionBubble.swift` - Connection bubble UI

## Common Tasks

### Add a new feature module
```
Features/NewFeature/
├── Views/
│   └── NewFeatureView.swift
├── ViewModels/
│   └── NewFeatureViewModel.swift
└── Components/
    └── FeatureSpecificComponent.swift
```

### Add a new service call
1. Add request/response models to `N8NService.swift`
2. Add method following existing patterns
3. Use `try await` for async operations

### Test on simulator
```bash
xcodebuild -scheme Cirkl -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

## Git Workflow

### Branch naming
- Feature: `feature/add-nfc-verification`
- Fix: `fix/orbital-animation-lag`
- Claude Desktop: `claude/description-XXXXX`

### Commit messages
```
feat(orbital): add connection clustering for 100+ users
fix(auth): resolve biometric prompt not showing
refactor(services): extract N8N response parsing
```

## Current Development Focus

### In Progress
- Physical verification system (NFC/QR/BLE)
- AI assistant integration (Zep memory)
- Connection profile editing

### Technical Debt
- [ ] Refactor OrbitalView into smaller components
- [ ] Add comprehensive error handling
- [ ] Unit tests for ViewModels
- [ ] Memory optimization for 1000+ connections

## Performance Targets

| Metric | Target |
|--------|--------|
| Animation FPS | 60-120 |
| Response time | < 200ms |
| App size | < 50MB |
| Crash rate | < 0.1% |

## Related Documentation

| Document | When to Read | Content |
|----------|--------------|---------|
| @VISION_PRODUIT.md | Adding features, UX decisions, understanding "why" | Vision fondateur, mécaniques psychologiques, features prioritaires |
| `~/.claude/references/liquid-glass/` | Liquid Glass APIs, Foundation Models | Complete iOS 26 API reference |
| `~/.claude/skills/ios/` | iOS development patterns | SwiftUI features, AI integration skills |
| `.claude/context.md` | Deep project context needed | Architecture détaillée, décisions techniques |
| `.serena/memories/` | Resuming after break, context recovery | Session memories, learnings |

> **Note**: Create `CLAUDE.local.md` (gitignored) for personal environment overrides.

## Recommended Swift Packages

### Animation Libraries (À ajouter via Xcode)

| Package | URL | Usage |
|---------|-----|-------|
| **open-swiftui-animations** | `https://github.com/amosgyamfi/open-swiftui-animations` | Loading, spring, fade, spin animations - Updated Jan 2026 |
| **PopupView** | `https://github.com/exyte/PopupView` | Toasts & popups professionnels (4k⭐) |
| **Lottie-iOS** | `https://github.com/airbnb/lottie-ios` | Animations After Effects |
| **AnimateText** | `https://github.com/jasudev/AnimateText` | Animations de texte élégantes |
| **ShuffleIt** | `https://github.com/dscyrescotti/ShuffleIt` | Stack views avec shuffling/swiping |

### Liquid Glass Libraries (iOS 26+)

| Package | URL | Stars | Usage |
|---------|-----|-------|-------|
| **LiquidGlass** | `https://github.com/BarredEwe/LiquidGlass` | 174⭐ | Real-time frosted glass & liquid refraction |
| **LiquidGlasKit** | `https://github.com/rryam/LiquidGlasKit` | 98⭐ | Customizable glass modifiers |
| **LiquidGlassReference** | `https://github.com/conorluddy/LiquidGlassReference` | 76⭐ | Ultimate Liquid Glass reference |

### Design System & Components

| Package | URL | Usage |
|---------|-----|-------|
| **SwiftUI-Design-System-Pro** | `https://github.com/muhittincamdali/SwiftUI-Design-System-Pro` | 200+ reusable components |
| **swiftcn-ui** | `https://github.com/Mobilecn-UI/swiftcn-ui` | shadcn/ui style for SwiftUI (137⭐) |
| **dskit-swiftui** | `https://github.com/imodeveloperlab/dskit-swiftui` | Design system with collection of components |
| **swift-theme-kit** | `https://github.com/Charlyk/swift-theme-kit` | Themeable UI framework |

### Official Resources

| Resource | URL |
|----------|-----|
| **WWDC25: Build a SwiftUI app with new design** | `https://developer.apple.com/videos/play/wwdc2025/323/` |
| **Adopting Liquid Glass** | `https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass` |
| **Liquid Glass Tutorial** | `https://liquidglass.info/` |
| **GlassUI Toolkit** | `https://glassui.dev/` |

### Liquid Glass Quick Reference

```swift
// Core APIs (iOS 26+)
import SwiftUI

// 1. Basic glass effect
.glassEffect()

// 2. Glass container for coordinated elements
GlassEffectContainer {
    CardView().glassEffect()
    ButtonView().glassEffect()
}

// 3. Morphing transitions between states
@Namespace private var animation
.glassEffectID("card", in: animation)

// 4. Native materials (fallback for older iOS)
.background(.ultraThinMaterial)
.background(.regularMaterial)
.background(.thickMaterial)

// 5. Interactive glass buttons
Button("Action") { }
    .buttonStyle(.glassProminent)
    .glassEffect(.regular.interactive())
```

### Usage in Cirkl

```swift
// Connection bubble with glass effect
struct ConnectionBubble: View {
    var body: some View {
        Circle()
            .fill(.clear)
            .frame(width: 60, height: 60)
            .overlay {
                AsyncImage(url: avatarURL)
            }
            .glassEffect(.regular, in: .circle)
    }
}

// Orbital action button
struct OrbitalActionButton: View {
    var body: some View {
        Button(action: handleTap) {
            Image(systemName: "sparkles")
                .font(.title)
        }
        .buttonStyle(.glassProminent)
        .glassEffect(.regular.interactive())
    }
}

// Toast notification
import PopupView

.popup(isPresented: $showToast, type: .toast, position: .top) {
    Text("Connection ajoutée!")
        .padding()
        .glassEffect()
}
```

## AI Assistant Guidelines

### Before Modifying Code - Ask Yourself:
1. **Have I read the file(s)?** - Never edit blind
2. **Does this follow existing patterns?** - Check similar code first
3. **Is this the minimal change?** - Avoid over-engineering
4. **Will this compile/build?** - Test before committing

### Security Guardrails
- **Never commit**: API keys, credentials, tokens, .env files
- **Never expose**: User data, internal URLs in logs
- **Always check**: `.gitignore` before adding sensitive files

### Modification Rules
1. **Read before edit**: Always read a file before modifying it
2. **Follow existing patterns**: Match the style of surrounding code
3. **Small changes**: Prefer targeted edits over large rewrites
4. **Test builds**: Verify changes compile before committing
5. **Use Liquid Glass**: All floating UI must use `.glassEffect()` APIs
