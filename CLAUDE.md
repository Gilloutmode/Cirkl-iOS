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

### Tech Stack
- **Swift 6.0** with **SwiftUI 5**
- **Min iOS**: 17.0
- **Architecture**: MVVM-C + Clean Architecture
- **State Management**: `@Observable` for ViewModels (iOS 17+), `@MainActor` for UI
- **Persistence**: SwiftData
- **Backend**: N8N webhooks → AI Orchestration

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

## Design System - Glassmorphic VisionOS Style

### Core Visual Rules
1. **Background blur**: 20-30 radius
2. **Glass tint**: `Color.white.opacity(0.05)` to `0.1`
3. **Border**: 0.5pt white @ 20% opacity
4. **Dark mode only**: `.preferredColorScheme(.dark)`
5. **Target framerate**: 120fps (ProMotion)

### Brand Colors
- **Cirkl Blue**: `#0A0E27` (dark background)
- **Electric Blue**: `#007AFF` (primary actions)
- **Mint**: `#00C781` (success, verification)

### Glassmorphic Component Pattern
```swift
RoundedRectangle(cornerRadius: 20)
    .fill(Color.white.opacity(0.08))
    .background(.ultraThinMaterial)
    .overlay(
        RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
    )
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

- `.claude/context.md` - Detailed project context
- `.claude/context/design-principles.md` - Design guidelines
- `.claude/context/style-guide.md` - UI style guide
- `.serena/memories/` - Session memories and learnings

## Claude Usage Rules

1. **Read before edit**: Always read a file before modifying it
2. **Follow existing patterns**: Match the style of surrounding code
3. **Small changes**: Prefer targeted edits over large rewrites
4. **Test builds**: Verify changes compile before committing
5. **Preserve glassmorphism**: All UI must follow the glass design system
