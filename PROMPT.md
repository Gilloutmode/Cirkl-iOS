# Ralph Build Mode

Implement ONE task from the plan, validate, commit, exit.

## Tools

- **Parallel subagents**: Up to 500 for searches/reads
- **Opus subagents**: Complex reasoning during implementation

## Phase 0: Orient

Read:
- @CLAUDE.md (project rules)
- @IMPLEMENTATION_PLAN.md (current state)
- @specs/feed-fixes.md (requirements)

### Check for completion

Run:
```bash
grep -c "^\- \[ \]" IMPLEMENTATION_PLAN.md || echo 0
```

- If 0: Run validation → commit → output **RALPH_COMPLETE** → exit
- If > 0: Continue to Phase 1

## Phase 1: Implement

1. **Search first** — Use parallel subagents to verify the behavior doesn't already exist
2. **Implement** — ONE task only (use Opus subagents for complex reasoning)
3. **Validate** — Run build command, must pass:

```bash
xcodebuild -scheme Cirkl -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -50
```

## Phase 2: Update Plan

In `IMPLEMENTATION_PLAN.md`:
- Mark task `- [x] Completed`
- Add discovered tasks if any

## Phase 3: Commit & Exit

```bash
git add -A && git commit -m "fix(feed): [description]

Co-Authored-By: Claude <claude@anthropic.com>"
```

Run completion check again:
```bash
grep -c "^\- \[ \]" IMPLEMENTATION_PLAN.md || echo 0
```

- If > 0: Say "X tasks remaining" and EXIT
- If = 0: Output **RALPH_COMPLETE**

## Guardrails

- ONE task per iteration
- Search before implementing
- Validation MUST pass
- Never output RALPH_COMPLETE if tasks remain

## Project Context

### Key Files
- `Cirkl/Features/Feed/FeedView.swift` - Main Feed view
- `Cirkl/Features/Feed/FeedViewModel.swift` - Feed business logic
- `Cirkl/Features/Feed/Models/FeedItem.swift` - Data model
- `Cirkl/Features/Feed/Components/*.swift` - Card components
- `Cirkl/Core/Services/N8NService.swift` - Backend service

### Patterns to Follow
- `@MainActor @Observable` for ViewModels
- `async/await` for all network calls
- `withAnimation` for UI state changes
- Logs format: `print("[Feed] Action: description")`

### N8N Endpoints
- Base: `https://gilloutmode.app.n8n.cloud`
- Synergies: `/webhook/acknowledge-synergies`
- Messages: `/webhook/cirkl-ios`
