# Specs: Feed Flat Design Refonte

> **Date**: 16 Janvier 2026
> **Scope**: Feed d'actualité - Refonte visuelle
> **Branche**: feature/dev

## Objectif

Refondre le design des cards du Feed en style **Flat moderne** inspiré Apple Fitness/Wallet :
- Supprimer tous les effets Liquid Glass (`.glassEffect()`, `.ultraThinMaterial`)
- Couleurs solides avec contraste amélioré
- Ombres douces et coins arrondis généreux

## Fichiers à modifier

### 1. CirklDesignTokens.swift
- Ajouter nouveaux tokens pour Flat Design :
  - `cardBackground` : Couleur solide sombre (ex: `Color(hex: "1C1C1E")`)
  - `cardBackgroundElevated` : Légèrement plus clair (ex: `Color(hex: "2C2C2E")`)
- Modifier/supprimer `tokenGlassBackground()` → `tokenCardBackground()`

### 2. FilterPill.swift
- Remplacer `glassEffect()` par fond solide avec opacité
- Style sélectionné : fond `electricBlue`
- Style non sélectionné : fond `cardBackground` avec bordure subtile

### 3. UpdateCard.swift
- Supprimer `glassBackground` ViewBuilder
- Nouveau style : `.background(cardBackground).shadow().cornerRadius(16)`

### 4. SynergyCard.swift
- Supprimer `glassBackground` et `synergyBoxBackground`
- Nouveau style flat avec ombres

### 5. NetworkPulseCard.swift
- Supprimer `glassBackground`
- Nouveau style flat

### 6. FeedItemDetailSheet.swift
- Supprimer `glassBackground`
- Nouveau style flat pour le content container

## Design Tokens à ajouter

```swift
// Dans DesignTokens.Colors
static let cardBackground = Color(hex: "1C1C1E")
static let cardBackgroundElevated = Color(hex: "2C2C2E")
static let cardBorder = Color.white.opacity(0.08)

// Dans DesignTokens.Shadows (utiliser l'existant)
// Shadows.medium déjà défini : black.opacity(0.1), radius: 8, y: 4
```

## Pattern de remplacement

### AVANT (Liquid Glass)
```swift
@ViewBuilder
private var glassBackground: some View {
    if #available(iOS 26.0, *) {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
            .fill(.clear)
            .glassEffect(.regular, in: .rect(cornerRadius: ...))
    } else {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
            .fill(.ultraThinMaterial)
    }
}
```

### APRÈS (Flat Moderne)
```swift
private var cardBackground: some View {
    RoundedRectangle(cornerRadius: DesignTokens.Radius.large) // 16pt
        .fill(DesignTokens.Colors.cardBackground)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
}
```

## Critères d'acceptation

- [ ] Aucun `.glassEffect()` dans les fichiers Feed/Components/
- [ ] Aucun `.ultraThinMaterial` dans les fichiers Feed/Components/
- [ ] Nouveaux tokens `cardBackground`, `cardBackgroundElevated` dans DesignTokens
- [ ] Cards ont des ombres visibles (shadow radius: 8, y: 4)
- [ ] Coins arrondis de 16pt (Radius.large)
- [ ] Bordure unread utilise la couleur d'accent (pas de glass border)
- [ ] Build passe sans erreur
- [ ] Previews Xcode fonctionnent

## Hors scope

- FeedView.swift (structure principale)
- FeedViewModel.swift (logique)
- Autres features de l'app (Orbital, Profile, etc.)
- Light mode (on reste dark mode only)
