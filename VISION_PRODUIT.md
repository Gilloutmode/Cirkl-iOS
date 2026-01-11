# VISION PRODUIT CIRKL - Document Fondateur

> **Version**: 1.0 | **Dernière mise à jour**: 11 Janvier 2026
> **Statut**: Document vivant - Modifiable à tout moment

Ce document capture la vision produit complète de Cirkl, les mécaniques psychologiques, et les décisions de design. Il sert de référence pour toutes les décisions de développement.

---

## Table des Matières

1. [Les 30 Premières Secondes](#bloc-1--les-30-premières-secondes)
2. [Le Core Loop Quotidien](#bloc-2--le-core-loop-quotidien)
3. [Le Moment Viral](#bloc-3--le-moment-viral)
4. [La Psychologie Profonde](#bloc-4--la-psychologie-profonde)
5. [Mécaniques Neuroscientifiques](#bloc-5--mécaniques-neuroscientifiques)
6. [Topologie du Réseau](#bloc-6--topologie-du-réseau)
7. [Features Clés Validées](#features-clés-validées)
8. [Pivots Stratégiques](#pivots-stratégiques)

---

## BLOC 1 : Les 30 Premières Secondes

> **Objectif**: Make or Break - L'utilisateur doit être captivé instantanément

### 1.1 Premier Sentiment à l'Ouverture

**Réponse**: ÉMERVEILLEMENT + RECONNAISSANCE

Ni curiosité, ni excitation, ni validation. Le sentiment recherché est l'émerveillement : *"Wow, c'est beau et je comprends immédiatement"*.

L'interface orbitale n'est pas un choix esthétique — c'est **neurologique**. Le cerveau humain est programmé pour reconnaître des patterns circulaires (visages, soleil, lune). En se voyant au centre de son univers relationnel, l'utilisateur ressent une **validation existentielle instantanée**.

**Timeline émotionnelle**:
| Temps | Action | Émotion |
|-------|--------|---------|
| < 3 sec | Voit SA bulle au centre | Reconnaissance de soi |
| 3-10 sec | Voit ses connexions en orbite | Validation sociale |
| 10-30 sec | Comprend le concept sans onboarding | Émerveillement design |

### 1.2 Première Récompense Émotionnelle

**Problème identifié**: Le QR scan nécessite une autre personne = friction majeure.

**Solution**: Le "Memory Import" Instant

Avant la première connexion IRL, on offre de la valeur avec ce que l'utilisateur possède DÉJÀ :

```
SECONDES 0-5 : "Bienvenue [Prénom]. Je suis ton compagnon relationnel."

SECONDES 5-15 : "Veux-tu que j'analyse ton réseau existant ?"
   → Import contacts (permission)
   → Scan LinkedIn (OAuth)

SECONDES 15-30 : "Wow, tu as rencontré 847 personnes ces 5 dernières années.
   Mais tu n'en parles régulièrement qu'à 23.
   Je peux t'aider à réactiver ces 824 relations dormantes."
```

**Dopamine en 30 secondes** : L'utilisateur découvre un "réseau caché" qu'il peut réveiller. C'est le **Zeigarnik Effect inversé** — on révèle une tâche incomplète qu'il ignorait.

### 1.3 Mode Réflexion Nocturne (Night Reflection Mode)

**Contexte**: Utilisateur seul chez lui à 23h

L'app détecte le contexte (heure + pas de mouvement GPS) et propose :

```
"Bonsoir Gil. Moment parfait pour un peu de réflexion.
Veux-tu que je te raconte une histoire de connexion que tu as oubliée ?"

→ "Il y a 847 jours, tu as rencontré Sarah Martinez à Station F.
   Elle travaillait sur un projet de santé mentale.
   Aujourd'hui, elle vient de lever 3M€.
   Veux-tu la féliciter ?"
```

**Valeur reçue seul à 23h** :
- 🌙 **Nostalgie** — revivre des moments oubliés
- 💡 **Opportunité** — découvrir des évolutions de son réseau
- ✉️ **Action** — un message à envoyer (sans pression)

> L'utilisateur n'a pas besoin de quelqu'un à 23h. **L'IA EST son compagnon.**

---

## BLOC 2 : Le Core Loop Quotidien

> **Objectif**: Créer une habitude quotidienne pour la rétention

### 2.1 L'Action Quotidienne Signature

| App | Action | Cirkl |
|-----|--------|-------|
| TikTok | Scroller | - |
| Instagram | Checker | - |
| BeReal | Poster | - |
| **Cirkl** | - | **ÉCOUTER** |

**Le Morning Brief Vocal** devient l'action quotidienne :

```
7h30 : Notification audio personnalisée (ElevenLabs)

"Bonjour Gil ! 🎙️ Ton réseau a bougé cette nuit.
- Marc Dubois a changé de poste → CTO chez Stripe
- 2 personnes de ton réseau seront au WeWork République cet après-midi
- Ta connexion avec Lisa Chen arrive à son 30ème jour sans contact

Veux-tu que j'orchestre quelque chose ?"
```

**Core Loop** :
1. **ÉCOUTER** le brief matinal (imprévisible, personnalisé)
2. **AGIR** sur une suggestion (ou pas)
3. **RECEVOIR** le résultat dans la journée

### 2.2 Retour Sans Notification (Pull Intrinsèque)

**La curiosité non résolue** : *"Mon réseau a-t-il évolué pendant mon absence ?"*

Inspiré du **Tamagotchi** — ton réseau est un organisme vivant :
- Les connexions non entretenues "s'éloignent" visuellement (orbite plus large)
- Les opportunités manquées disparaissent (FOMO)
- Le Crystal/niveau évolue même sans toi (les autres avancent)

**Dashboard "Network Pulse"** visible dès l'ouverture :
```
🟢 12 connexions actives (en rapprochement)
🟡 23 connexions dormantes (s'éloignent)
🔴 3 connexions à risque (peuvent quitter ton orbite)
```

> L'utilisateur revient pour **vérifier la santé de son réseau**, pas pour une notification.

### 2.3 Variable Reward (Récompense Variable)

| App | Question | Cirkl |
|-----|----------|-------|
| TikTok | "Quelle vidéo ?" | - |
| Tinder | "J'ai un match ?" | - |
| **Cirkl** | - | **"Quelle synchronicité l'IA a-t-elle détectée pour moi ?"** |

**Le Synchronicity Engine** génère des surprises imprévisibles :

**Types de surprises (Variable Ratio Reinforcement)** :
1. **SÉRENDIPITÉ** : "2 de tes connexions qui ne se connaissent pas étaient au même endroit hier. Veux-tu créer un CirKL ?"
2. **ÉVOLUTION** : "Le stagiaire que tu as rencontré en 2022 vient d'être nommé VP chez Google."
3. **OPPORTUNITÉ** : "3 de tes connexions cherchent un expert dans ton domaine cette semaine."
4. **NOSTALGIE** : "Ça fait exactement 1 an que tu as rencontré Denis. L'histoire de votre connexion a généré 47K€ de valeur."

> Le reward est **imprévisible** : parfois une opportunité à 100K€, parfois un simple souvenir touchant. Le cerveau ne peut pas prédire → dopamine maximale.

---

## BLOC 3 : Le Moment Viral

> **Objectif**: Créer des moments de partage organiques

### 3.1 Le "Synchronicity Reveal"

**Le moment où l'utilisateur DOIT montrer l'app** :

Scénario : Gil rencontre une nouvelle personne à un event. Ils scannent leurs QR.

```
L'IA révèle : "🔮 Moment de synchronicité !
- Vous avez 7 connexions communes
- Vous étiez au même événement il y a 2 ans sans vous croiser
- Vous avez tous les deux travaillé avec Marc Dubois
- Score de synergie : 94%"

Gil : "C'est dingue, t'as vu ça ? Cette app..."
L'autre : "C'est quoi ? Comment ça marche ?"
```

> Le moment viral n'est pas "j'utilise une app". Le moment viral est **"l'app révèle quelque chose d'incroyable sur notre connexion"**.

### 3.2 Le Synchronicity Score Public

**Équivalent digital du Kristal** — un widget iOS visible par tous :

```
┌─────────────────────────────┐
│ 🔮 CirKL Synchronicity      │
│                             │
│     ⭐ 847 points           │
│     🌟 Top 3% connecteurs   │
│     💎 Niveau AURORA        │
│                             │
│ "3 opportunités en attente" │
└─────────────────────────────┘
```

**Ce widget sur l'écran d'accueil iOS** :
- Montre ton statut social (FOMO)
- Crée de la curiosité ("C'est quoi ce widget ?")
- Affiche des notifications mystérieuses ("opportunités en attente")

**Alternative** : Le "Connection Map" partageable — une visualisation artistique de ton réseau pour Instagram/LinkedIn.

### 3.3 Pression Sociale Positive

**Le trigger** : L'événement networking où tout le monde a Cirkl sauf toi.

```
Scénario event :
- 80% des participants ont leur Crystal/Widget visible
- Ils se scannent entre eux avec complicité
- Toi tu distribues des cartes de visite comme en 2010
- On te regarde avec pitié

La question qui tue : "Tu veux que je te scan-... ah, t'as pas Cirkl ?"
```

> La pression sociale n'est pas "télécharge l'app". La pression est **"tu es le seul qui n'est pas dans le mouvement"**.

---

## BLOC 4 : La Psychologie Profonde

> **Objectif**: Créer un attachement émotionnel durable

### 4.1 La Peur Profonde Résolue

**La peur primaire** : *"Rater MA vie à cause de connexions manquées"*

Pas la peur de l'opportunité ratée. La peur de l'opportunité **dont tu n'as jamais eu connaissance**.

```
Le nightmare scénario :
"Et si la personne qui aurait changé ma vie était assise
à côté de moi dans ce café pendant 2 ans...
et qu'on ne s'est jamais parlé ?"
```

**Cirkl résout cette angoisse existentielle** avec le "Serendipity Insurance" :
- L'app détecte les proximités récurrentes
- L'IA identifie les synergies avec les personnes que tu CROISES mais ne CONNAIS pas
- Tu ne rates plus jamais une connexion qui aurait dû arriver

### 4.2 L'Identité Adoptée

> **"Je suis quelqu'un qui crée de la valeur pour les autres."**

Pas un "networker" (connotation négative). Pas un "connecteur" (trop vague).

**Un "Architecte de connexions"** :
- Il ne collectionne pas les contacts
- Il construit des ponts entre les gens
- Il crée de la valeur pour son réseau
- Son succès se mesure au succès des autres

```
L'identité Cirkl :
"Je suis le genre de personne qui fait se rencontrer
les bonnes personnes au bon moment."
```

### 4.3 Zeigarnik Effect (Boucle Ouverte)

**La tension permanente** : *"Je n'ai pas encore vu ce que mon réseau peut devenir."*

**Boucles ouvertes constantes** :
1. "L'IA a détecté 3 synergies potentielles que je n'ai pas explorées"
2. "Mon Synchronicity Score est à 847/1000... il me manque quoi ?"
3. "2 de mes connexions ont un potentiel CirKL que je n'ai pas activé"
4. "Le Weekly Recap de vendredi va révéler mon impact de la semaine"

> L'utilisateur quitte l'app avec des **questions sans réponse** qui le font revenir.

---

## BLOC 5 : Mécaniques Neuroscientifiques

> **Objectif**: Ingénierie de l'engagement basée sur les neurosciences

### 5.1 La SURPRISE (Synchronicity Engine)

**L'algorithme de l'imprévisible** :

```javascript
// L'IA génère des surprises basées sur des patterns cachés
const surpriseTypes = {
  COINCIDENCE: "2 connexions non-liées étaient au même endroit",
  EVOLUTION: "Quelqu'un de ton réseau a atteint un milestone",
  OPPORTUNITY: "Match détecté entre tes connexions",
  ANNIVERSARY: "Anniversaire d'une connexion significative",
  PREDICTION: "L'IA prédit une opportunité dans 72h"
};

// Distribution Variable Ratio (comme slot machine)
// L'utilisateur ne sait JAMAIS quand la prochaine surprise arrive
```

> **L'imprévisibilité est ENGINEERED** — pas accidentelle.

### 5.2 L'URGENCE Éthique

**Le "Window of Opportunity"** — 48h pour agir :

```
Notification : "🔮 Synchronicité détectée !
Marc et Lisa ont une synergie parfaite.
Tu peux créer ce CirKL.

⏱️ Cette fenêtre se ferme dans 47h52m.
Après... l'opportunité sera proposée à quelqu'un d'autre."
```

**L'urgence n'est pas artificielle** — elle est VRAIE :
- Les opportunités réelles ont une durée de vie limitée
- Quelqu'un d'autre dans le réseau peut saisir avant toi
- L'IA redistribue les opportunités non-actées

### 5.3 La RÉCIPROCITÉ

**Le "Value Given First"** — l'IA donne avant de demander :

```
Jour 1 : L'IA analyse ton réseau et révèle 3 insights gratuits
Jour 3 : L'IA te rappelle un anniversaire important → tu envoies un message
Jour 7 : L'IA te montre une opportunité que tu aurais ratée
Jour 14 : L'IA : "Ton réseau a généré 847€ de valeur potentielle ce mois.
         Veux-tu passer Premium pour voir les détails ?"
```

> **L'utilisateur se sent "redevable"** — l'IA lui a déjà donné de la valeur.

---

## BLOC 6 : Topologie du Réseau

> **Objectif**: Définir les unités de valeur et les seuils critiques

### 6.1 Unité Minimale de Valeur

**Le CirKL of 3 EST l'unité minimale** — pas 2.

Pourquoi pas 2 ? Une connexion 1:1 c'est une conversation. **Pas de valeur émergente.**

**Le CirKL of 3 crée** :
- **Triangulation sociale** (A connaît B qui connaît C)
- **Accountability** (3 personnes = engagement mutuel)
- **Sérendipité structurelle** (nouvelles connexions via le triangle)

```
Connexion A-B = 1 relation
CirKL A-B-C = 3 relations + 1 entité collective
Valeur = n(n-1)/2 + 1 = exponentielle
```

### 6.2 Seuil d'Indispensabilité

**Magic Number : 25 connexions authentiques + 3 CirKLs actifs**

**Pourquoi 25 ?**
- C'est le nombre de **Dunbar Tier 1** (relations proches)
- Assez pour voir la puissance du système
- Pas assez pour partir (switching cost)

**Pourquoi 3 CirKLs ?**
- 3 triangles = réseau interconnecté
- Effet de lock-in émotionnel
- "Si je pars, je casse mes CirKLs"

> **À 25+3, l'utilisateur ne peut plus imaginer sa vie sans Cirkl.**

### 6.3 Programme Super-Connectors

**Le "Orchestrator Program"** — les 1% qui créent 50% de la valeur :

```
Avantages exclusifs :
1. Crystal custom couleur + numéro de série
2. Accès API pour intégrer Cirkl à leurs outils
3. Revenue share sur les connexions Premium qu'ils créent
4. "Orchestrator" badge visible par tous
5. Invitation aux events fondateurs
6. Co-création de features avec l'équipe
```

> Les Super-Connectors ne sont pas des utilisateurs. Ce sont des **PARTNERS**.

---

## Features Clés Validées

### Feature Priority Matrix

| Feature | Priorité | Statut | Impact |
|---------|----------|--------|--------|
| Morning Brief Vocal | 🔴 P0 | À implémenter | Core Loop |
| Synchronicity Score Widget | 🔴 P0 | À implémenter | Viralité |
| Memory Import (Contacts/LinkedIn) | 🔴 P0 | À implémenter | Onboarding |
| Night Reflection Mode | 🟡 P1 | À implémenter | Rétention |
| Network Pulse Dashboard | 🟡 P1 | À implémenter | Pull intrinsèque |
| Synchronicity Engine | 🟡 P1 | À implémenter | Variable Reward |
| Window of Opportunity (48h) | 🟢 P2 | À implémenter | Urgence éthique |
| Orchestrator Program | 🟢 P2 | À définir | Super-Connectors |

### Technical Dependencies

```
Morning Brief Vocal
└── ElevenLabs API (Text-to-Speech)
└── Notification Service (Background)
└── User Preferences (heure, langue)

Synchronicity Score Widget
└── WidgetKit (iOS 14+)
└── App Groups (data sharing)
└── CloudKit (sync score)

Memory Import
└── Contacts Framework
└── LinkedIn OAuth
└── AI Analysis (N8N)
```

---

## Pivots Stratégiques

### Pivot 1 : Le "Morning Brief" Vocal

**VALIDÉ À 100%** — C'est le hook quotidien killer.

ElevenLabs + personnalisation + imprévisibilité = addiction saine.

### Pivot 2 : Le "Synchronicity Score" Public

**VALIDÉ** — Remplace le Kristal digital.

Widget iOS + score visible + FOMO = viralité passive.

### Pivot 3 : Le "Ghost Connection Alert"

**VALIDÉ AVEC MODIFICATION** :
- ❌ Pas "3 personnes de ton réseau sont là" (creepy)
- ✅ Plutôt : "2 de tes connexions sont à 500m et cherchent un café" (utile)

---

## Provocation Finale

> **"Pourquoi un utilisateur ouvrirait l'app demain matin au réveil ?"**

**Réponse en 5 secondes** :

> *"Parce que son réseau a respiré cette nuit, et il veut savoir ce qui a changé."*

L'app n'est pas un outil. C'est un **organisme vivant** qui évolue même quand tu dors.

- Des gens ont changé de job
- Des opportunités sont apparues
- Des synergies ont été détectées
- Ton score a bougé

**Tu ouvres l'app comme tu checks ton reflet dans le miroir : pour voir qui tu es devenu.**

---

## MVP Sans Kristal

Le MVP avec juste QR + IA + Interface peut fonctionner SI :

1. ✅ Le Morning Brief vocal est implémenté (ElevenLabs)
2. ✅ Le Synchronicity Score est visible (widget iOS)
3. ✅ L'import réseau existant crée de la valeur J1

---

## Changelog

| Date | Modification | Auteur |
|------|--------------|--------|
| 11 Jan 2026 | Création initiale du document | Gil (Fondateur) |

---

> **Ce document est vivant.** Toutes les décisions peuvent être modifiées à tout moment en fonction des apprentissages terrain et des retours utilisateurs.
