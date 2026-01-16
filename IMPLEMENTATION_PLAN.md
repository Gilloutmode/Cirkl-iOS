# Implementation Plan: Feed Flat Design Refonte

> **Scope**: Cross-cutting (7 fichiers) | **Risk**: Balancé | **Validation**: Build + Preview

## Summary

Refonte visuelle du Feed CirKL : exit Liquid Glass (`.glassEffect()`, `.ultraThinMaterial`), entrée design Flat moderne avec couleurs solides, ombres douces, et coins arrondis 16pt. Style inspiré Apple Fitness/Wallet.

## Tasks

- [x] Task 1: Ajouter tokens Flat Design dans CirklDesignTokens.swift - Added `cardBackground` (hex "1C1C1E"), `cardBackgroundElevated` (hex "2C2C2E"), `cardBorder` (white 8%). Added `tokenCardBackground()` and `tokenCardBackgroundWithBorder()` view modifiers.

- [x] Task 2: Refondre FilterPill.swift en Flat - Removed glassEffect/ultraThinMaterial. Solid cardBackground for unselected, electricBlue for selected. Added subtle shadow.

- [x] Task 3: Refondre UpdateCard.swift en Flat - Removed glassBackground ViewBuilder. Solid cardBackground with cardBorder/accent border. Simplified avatar to flat color.

- [x] Task 4: Refondre SynergyCard.swift en Flat - Removed glassBackground and synergyBoxBackground. cardBackgroundElevated for inner box, cardBackground for outer. Simplified avatars.

- [x] Task 5: Refondre NetworkPulseCard.swift en Flat - Removed glassBackground ViewBuilder. Solid cardBackground with status-colored border. Simplified avatar.

- [x] Task 6: Refondre FeedItemDetailSheet.swift en Flat - Removed glassBackground ViewBuilder. cardBackgroundElevated for content section with subtle shadow.

- [x] Task 7: Valider build et vérifier absence de glassEffect - Build passed. Verified: 0 occurrences of glassEffect/ultraThinMaterial in Feed components. Also converted FeedCard.swift (fallback card).

## Commits

| Commit | Description |
|--------|-------------|
| c119a2e | feat(feed): add flat design tokens to CirklDesignTokens |
| c41c332 | refactor(feed): convert FilterPill to flat design |
| aef15d2 | refactor(feed): convert UpdateCard to flat design |
| 039c231 | refactor(feed): convert SynergyCard to flat design |
| 2b50c0e | refactor(feed): convert NetworkPulseCard to flat design |
| 1018696 | refactor(feed): convert FeedItemDetailSheet to flat design |
| c25eae1 | refactor(feed): convert FeedCard to flat design |

## Results

✅ **RALPH_COMPLETE**

- 0 occurrences de `.glassEffect()` dans Feed/Components/
- 0 occurrences de `.ultraThinMaterial` dans Feed/Components/
- Build réussi sur iPhone 17 Pro Simulator
- 7 fichiers convertis en Flat Design
