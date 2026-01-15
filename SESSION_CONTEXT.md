# Session: Design Review - Janvier 2026

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
