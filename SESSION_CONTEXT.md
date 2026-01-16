# Session: Feed Bug Fixes - Janvier 2026

## Date: 16 Janvier 2026

## Résumé
Correction de **tous les bugs critiques du Feed** de l'app CirKL iOS.

### Symptômes corrigés :
- ❌→✅ Filtres ne filtrant pas la liste
- ❌→✅ Tap sur cards non fonctionnel
- ❌→✅ "Tout lire" ne marquant pas les items comme lus
- ❌→✅ "Créer la connexion" sans feedback

---

## Root Causes Identifiées et Corrigées

### ROOT CAUSE #1: @State + @Observable Pattern ✅
| Aspect | Détail |
|--------|--------|
| **Fichier** | `FeedView.swift:9` |
| **Problème** | `@Observable` nécessite `@State` pour que SwiftUI track l'instance |
| **Fix** | `@State private var viewModel = FeedViewModel()` |

### ROOT CAUSE #2: Missing contentShape() sur Cards ✅
| Aspect | Détail |
|--------|--------|
| **Fichiers** | `UpdateCard.swift:66`, `NetworkPulseCard.swift:115` |
| **Problème** | Glass backgrounds transparents empêchent détection des taps |
| **Fix** | `.contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))` |

### ROOT CAUSE #3: Navigation manquante après synergy ✅
| Aspect | Détail |
|--------|--------|
| **Fichier** | `FeedView.swift:145-153` |
| **Problème** | Card disparaît sans feedback après "Créer la connexion" |
| **Fix** | Sauvegarder item avant suppression + afficher sheet de confirmation |

---

## Fichiers Modifiés

```
Cirkl/Features/Feed/
├── FeedView.swift
│   ├── Ligne 9: @State sur viewModel
│   ├── Lignes 145-153: Feedback après synergy creation
│   └── Lignes 488-524: Gestion explicite SynergyCards (connectionId nil)
│
├── FeedViewModel.swift
│   ├── Lignes 66-69: Logs DEBUG enrichis (load)
│   └── Lignes 102-105: Logs DEBUG enrichis (filter change)
│
└── Components/
    ├── UpdateCard.swift
    │   └── Ligne 66: contentShape() ajouté
    │
    └── NetworkPulseCard.swift
        └── Ligne 115: contentShape() ajouté
```

---

## Patterns Techniques Validés

### @Observable + @State (iOS 17+)
```swift
// CORRECT - SwiftUI track l'instance
@State private var viewModel = FeedViewModel()

// INCORRECT - SwiftUI ne détecte pas les changements
private var viewModel = FeedViewModel()
```

### contentShape() pour Glass Backgrounds
```swift
Button(action: onTap) {
    // ... contenu avec glass effect
}
.buttonStyle(.plain)
.contentShape(RoundedRectangle(cornerRadius: radius))  // Zone de tap explicite
```

### Feedback après action destructive
```swift
onCreateConnection: {
    let savedItem = item  // Sauvegarder AVANT suppression
    viewModel.deleteItem(item.id)
    selectedItem = savedItem  // Afficher feedback APRÈS
}
```

---

## Tests de Validation

- [ ] **Filtres**: Tap sur chaque pill filtre correctement
- [ ] **Tap cards**: UpdateCard et NetworkPulseCard ouvrent le detail sheet
- [ ] **Tout lire**: Indicateurs non-lu disparaissent
- [ ] **Créer connexion**: Card disparaît ET sheet s'affiche
- [ ] **Pas maintenant**: Card disparaît silencieusement
- [ ] **Console**: Logs `📰 Filter:`, `📰 Tapped:`, `📰 Marked as read:`

---

## Build Status
✅ BUILD SUCCEEDED (iPhone 17 Pro Simulator, iOS 26)

## Commit Suggéré

```bash
git add -A && git commit -m "$(cat <<'EOF'
fix(feed): resolve all Feed reactivity and interaction bugs

Root causes fixed:
1. @State on viewModel - @Observable needs @State to track instance
2. Add contentShape() to UpdateCard and NetworkPulseCard for tap detection
3. Add navigation feedback after synergy connection creation

Tested: filters, card taps, mark as read, synergy creation

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Notes pour Reprise

- Le `FeedItemDetailSheet` crée un `OrbitalContact` minimal depuis `FeedItem` pour ouvrir `ProfileDetailView`
- Les SynergyCards n'ont pas de `connectionId` unique (2 personnes) → message explicatif dans le sheet
- Les animations sont gérées côté View avec `withAnimation()`, jamais dans le ViewModel

---
---

# Session Précédente: Design Review - Janvier 2026

## Date: 13 Janvier 2026

## Résumé
Session de revue et corrections UX/UI pour l'app Cirkl iOS.

## Corrections Effectuées

### 1. Dynamic Glass Reflection ✅
**Fichier**: `Core/Extensions/DynamicGlassReflection.swift`

**Problème**: Le reflet de lumière sur les bulles ne tournait pas naturellement avec le mouvement du téléphone.

**Solution**: Réécriture complète du modifier pour simuler une source lumineuse fixe dans l'espace:
- Utilisation de `atan2(roll, -pitch)` pour calculer l'angle de rotation
- Application de `.rotationEffect()` sur tout le système de reflet
- Intensité dynamique basée sur l'inclinaison totale

```swift
let lightAngle = atan2(Double(motion.smoothRoll), Double(-motion.smoothPitch))
let rotationDegrees = lightAngle * 180 / .pi
// ZStack avec reflets
.rotationEffect(.degrees(rotationDegrees))
```

### 2. Portrait Mode Lock ✅
**Fichier**: `Info.plist`

**Problème**: L'app passait en mode paysage quand l'utilisateur tournait le téléphone.

**Solution**: Ajout des clés `UISupportedInterfaceOrientations`:
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

### 3. Photos dans ConnectionsListView et ProfileDetailView ✅
**Fichiers**:
- `Features/Orbital/OrbitalView.swift`
- `Features/Connections/ConnectionsListView.swift`
- `Features/Connections/ProfileDetailView.swift`

**Problème**: Les photos étaient visibles dans les bulles orbitales mais pas dans la liste des connexions ni les profils.

**Cause racine**:
- `positionedContacts` (bulles) utilisait `mockPhotoMap` pour récupérer les photoNames
- `baseContactsForCounting` (liste/profils) passait `photoName: nil` pour les contacts Neo4j

**Solution**: Ajout de `mockPhotoMap` dans `baseContactsForCounting`:
```swift
let mockPhotoMap: [String: String] = [
    "denis": "photo_denis",
    "shay": "photo_shay",
    "salomé": "photo_salome",
    "dan": "photo_dan",
    "gilles": "photo_gilles",
    "judith": "photo_judith",
]
let photoName = mockPhotoMap[nameLower]
```

## Composants Clés Impliqués

### MotionManager
- Singleton utilisant CoreMotion
- Fournit `smoothPitch` et `smoothRoll` pour les effets de parallaxe

### ImageSegmentationService
- Utilise Vision Framework (`VNGeneratePersonSegmentationRequest`)
- Supprime le fond des photos de personnes
- Preload des assets: photo_gil, photo_denis, photo_shay, etc.

### SegmentedAsyncImage
- Vue SwiftUI pour charger les images segmentées de manière asynchrone
- Utilisée par GlassBubbleView, ConnectionRowView, ProfileDetailView

## Patterns Découverts

1. **Duplication de logique**: `positionedContacts` et `baseContactsForCounting` font presque la même chose mais avec des différences subtiles (photoName)

2. **Async Image Loading**: Les photos passent par ImageSegmentationService pour le background removal, pas UIImage(named:) directement

## Tests Validés
- ✅ Build réussi sur iPhone 17 Pro Simulator (iOS 26)
- ✅ Reflets tournent naturellement
- ✅ App reste en portrait
- ✅ Photos visibles dans ConnectionsListView
- ✅ Photos visibles dans ProfileDetailView

## Prochaines Étapes (Plan UX Existant)
Voir plan file `eventual-crafting-puffin.md` pour le plan complet:
- Sprint 1: Quick Wins (ConfettiSwiftUI, Kingfisher, Toasts)
- Sprint 2: Onboarding Rebuild avec ConcentricOnboarding
- Sprint 3: Micro-interactions
- Sprint 4: Celebrations
