# CirKL N8N Workflows

Backend d'orchestration IA pour l'application iOS CirKL.

## Structure

```
n8n-workflows/
├── current/                    # Versions actives en production
│   ├── 🧠 Multi-Agents v17.29.json
│   ├── 🔔 Synergy Scanner v1.1.json
│   ├── 🌅 Morning Brief v1.0.json
│   ├── 🤝 Mutual Connection v1.0.json
│   └── 🔔 Acknowledge Synergies Webhook.json
└── archive/                    # Anciennes versions (backup)
```

## Workflows Actifs

| Workflow | Version | Webhook | Description |
|----------|---------|---------|-------------|
| **Multi-Agents** | v17.29 | `/webhook/cirkl-ios` | Orchestration IA principale (texte/audio) |
| **Synergy Scanner** | v1.1 | `/webhook/button-state` | Détection synergies (schedule 6h) |
| **Morning Brief** | v1.0 | `/webhook/morning-brief` | Brief matinal personnalisé |
| **Mutual Connection** | v1.0 | `/webhook/mutual-connection` | Capture connexions IRL bidirectionnelle |
| **Acknowledge** | - | `/webhook/acknowledge-synergies` | Reset button state après vue |

## Architecture

```
iOS App (Cirkl)
    │
    ▼
N8N Webhooks (gilloutmode.app.n8n.cloud)
    │
    ├──► Neo4j (neo4j-production-1adf.up.railway.app)
    │    └── Graph des connexions et synergies
    │
    ├──► Graphiti (graphiti-production-648d.up.railway.app)
    │    └── Mémoire conversationnelle
    │
    ├──► OpenAI GPT-4o
    │    └── Génération texte/analyse
    │
    └──► Google Sheets
         └── Logs et tracking
```

## Endpoints API

### POST /webhook/cirkl-ios (Multi-Agents)

Point d'entrée principal pour toutes les interactions IA.

```json
// Request
{
  "userId": "gil",
  "messageType": "text|audio",
  "content": "string ou base64 pour audio",
  "sessionId": "uuid",
  "deviceInfo": {
    "appVersion": "1.0.0",
    "osVersion": "26.0",
    "deviceModel": "iPhone"
  }
}

// Response
{
  "success": true,
  "response": "Message de l'IA",
  "intent": "new_connection|memory_search|synergy_check|general",
  "buttonState": "idle|synergy|opportunity|new_connection",
  "metadata": {
    "processingTime": 1234,
    "model": "gpt-4o"
  }
}
```

### GET /webhook/button-state (Synergy Scanner)

Polling du state du bouton central iOS.

```json
// Request: ?userId=gil

// Response
{
  "success": true,
  "buttonState": "idle|synergyLow|synergyHigh",
  "synergiesCount": 3,
  "synergies": [
    {
      "id": "syn_xxx",
      "type": "vc_startup|mentor_mentee|collaboration",
      "connectionAName": "Alice",
      "connectionBName": "Bob",
      "score": 75,
      "reason": "Potentiel collaboration sur projet AI"
    }
  ]
}
```

### POST /webhook/morning-brief

Brief matinal personnalisé.

```json
// Request
{ "userId": "gil" }

// Response
{
  "briefText": "Bonjour Gil ! Voici ton brief...",
  "highlights": ["Point 1", "Point 2"],
  "stats": {
    "synchronicityScore": 847,
    "activeConnections": 12,
    "dormantConnections": 23
  },
  "actionItems": ["Relancer Alice", "Préparer meeting Bob"]
}
```

### POST /webhook/mutual-connection

Capture bidirectionnelle lors de rencontres IRL.

```json
// Request (User A scanne)
{
  "meetingId": "mtg_xxx",
  "userId": "gil",
  "userName": "Gil",
  "thoughts": "Super rencontre, expert en AI",
  "context": "Meetup Tech Paris"
}

// Response (en attente)
{ "status": "waiting", "participantNumber": 1 }

// Response (complet - User B a scanné)
{
  "status": "complete",
  "connections": [
    { "name": "Alice", "thoughts": "...", "context": "..." }
  ]
}
```

### POST /webhook/acknowledge-synergies

Reset le button state après que l'utilisateur a vu les synergies.

```json
// Request
{ "userId": "gil" }

// Response
{ "success": true, "newState": "idle" }
```

## Button States iOS

| State | Valeur API | Couleur iOS | Signification |
|-------|------------|-------------|---------------|
| Idle | `idle` | Gris | Aucune notification |
| Synergy Low | `synergyLow` | Jaune | Synergies 50-69% |
| Synergy High | `synergyHigh` | Rouge | Opportunité forte 70%+ |
| New Connection | `new_connection` | Vert | Nouvelle connexion IRL |
| Morning Brief | `morningBrief` | Mint | Brief disponible |

## Synergy Types

```javascript
const SYNERGY_TYPES = {
  'vc_startup': 'VC + Startup founder',
  'mentor_mentee': 'Senior + Junior même domaine',
  'business_partners': 'Rôles complémentaires',
  'same_industry': 'Même industrie, rôles différents',
  'shared_interests': 'Intérêts/hobbies communs',
  'collaboration': 'Potentiel projet commun'
};
```

## Neo4j Schema

```cypher
// Nodes
(:Person {
  userId: String,
  name: String,
  role: String,
  company: String,
  industry: String,
  buttonState: String,
  pendingSynergies: List,
  lastSynergyCheck: DateTime,
  synchronicityScore: Integer,
  deviceToken: String
})

(:Meeting {
  meetingId: String,
  status: String,       // "waiting" | "complete"
  context: String,
  participants: List,
  createdAt: DateTime,
  completedAt: DateTime
})

// Relations
(:Person)-[:CONNECTED_TO {
  context: String,
  thoughts: String,
  meetingId: String,
  createdAt: DateTime,
  source: String        // "qr" | "nfc" | "proximity"
}]->(:Person)
```

## Mise à Jour des Workflows

### Exporter depuis N8N

1. Ouvrir le workflow dans N8N (gilloutmode.app.n8n.cloud)
2. Menu ⋮ → Download
3. Renommer avec le nouveau numéro de version
4. Placer dans `current/`
5. Déplacer l'ancienne version dans `archive/`

### Convention de Nommage

```
[emoji] Nom du Workflow vX.Y.json

Exemples:
🧠 Cirkl - Multi-Agents v17.29.json
🔔 Synergy Scanner v1.1.json
```

## Test des Webhooks

```bash
# Test Multi-Agents
curl -X POST https://gilloutmode.app.n8n.cloud/webhook/cirkl-ios \
  -H "Content-Type: application/json" \
  -d '{"userId": "gil", "messageType": "text", "content": "Hello"}'

# Test Button State
curl "https://gilloutmode.app.n8n.cloud/webhook/button-state?userId=gil"

# Test Morning Brief
curl -X POST https://gilloutmode.app.n8n.cloud/webhook/morning-brief \
  -H "Content-Type: application/json" \
  -d '{"userId": "gil"}'
```

## Liens

- **N8N Cloud**: https://gilloutmode.app.n8n.cloud
- **Neo4j**: https://neo4j-production-1adf.up.railway.app
- **Graphiti**: https://graphiti-production-648d.up.railway.app
- **iOS App**: `/Code/Cirkl-iOS/`
- **API Python**: `/Code/cirkl-graphiti-api/`
