# Implementation Plan: Feed Flat Design Refonte

> **Scope**: Cross-cutting (6 fichiers) | **Risk**: Balancé | **Validation**: Build + Preview

## Summary

Refonte visuelle du Feed CirKL : exit Liquid Glass (`.glassEffect()`, `.ultraThinMaterial`), entrée design Flat moderne avec couleurs solides, ombres douces, et coins arrondis 16pt. Style inspiré Apple Fitness/Wallet.

## Tasks

- [ ] Task 1: Ajouter tokens Flat Design dans CirklDesignTokens.swift - Ajouter `cardBackground` (Color hex "1C1C1E"), `cardBackgroundElevated` (Color hex "2C2C2E"), `cardBorder` (white opacity 0.08). Modifier `tokenGlassBackground()` en `tokenCardBackground()` sans glassEffect.

- [ ] Task 2: Refondre FilterPill.swift en Flat - Supprimer le `@ViewBuilder pillBackground` avec glassEffect/ultraThinMaterial. Remplacer par fond solide : sélectionné = `electricBlue`, non sélectionné = `cardBackground` avec bordure `cardBorder`. Ajouter shadow subtile.

- [ ] Task 3: Refondre UpdateCard.swift en Flat - Supprimer le `@ViewBuilder glassBackground`. Remplacer `.background { glassBackground }` par `.background(cardBackground).tokenShadow(.medium)`. Utiliser `Radius.large` (16pt). Garder la bordure colorée pour items non lus.

- [ ] Task 4: Refondre SynergyCard.swift en Flat - Supprimer `glassBackground` et `synergyBoxBackground` ViewBuilders. Remplacer par fonds solides avec ombres. synergyBox interne : `cardBackgroundElevated`, card externe : `cardBackground` + shadow.

- [ ] Task 5: Refondre NetworkPulseCard.swift en Flat - Supprimer `glassBackground` ViewBuilder. Appliquer même pattern que UpdateCard : fond solide `cardBackground`, shadow medium, cornerRadius 16pt, bordure colorée si non lu.

- [ ] Task 6: Refondre FeedItemDetailSheet.swift en Flat - Supprimer `glassBackground` ViewBuilder. Remplacer `.background(glassBackground)` du contentSection par fond solide `cardBackgroundElevated` + shadow subtle.

- [ ] Task 7: Valider build et tester previews - Build sur iPhone 17 Pro Simulator. Vérifier previews Xcode des 5 composants modifiés. S'assurer que les ombres sont visibles et le contraste amélioré.
