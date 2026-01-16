# Ralph Build Mode

Implement ONE task from the plan, validate, commit, exit.

## Tools

- **Parallel subagents**: Up to 500 for searches/reads
- **Opus subagents**: Complex reasoning during implementation

## Phase 0: Orient

Read:
- @CLAUDE.md (project rules)
- @IMPLEMENTATION_PLAN.md (current state)
- @specs/feed-flat-design.md (requirements)

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
xcodebuild -scheme Cirkl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "error:|BUILD"
```

## Phase 2: Update Plan

In `IMPLEMENTATION_PLAN.md`:
- Mark task `- [x] Completed` with brief description of what was done
- Add discovered tasks if any

## Phase 3: Commit & Exit

```bash
git add -A && git commit -m "feat(feed): [description of change]

Co-Authored-By: Claude <claude@anthropic.com>"
```

Use commit message format:
- `feat(feed): add flat design tokens to DesignTokens`
- `refactor(feed): convert FilterPill to flat design`
- `refactor(feed): convert UpdateCard to flat design`

Run completion check again:
```bash
grep -c "^\- \[ \]" IMPLEMENTATION_PLAN.md || echo 0
```

- If > 0: Say "X tasks remaining" and EXIT
- If = 0: Output **RALPH_COMPLETE**

## Guardrails

- ONE task per iteration
- Search before implementing
- Validation MUST pass (build succeeds)
- Never output RALPH_COMPLETE if tasks remain
- Keep existing functionality (buttons, actions, callbacks)
- Only change visual styling, not logic

## Project Context

### Key Files to Modify
- `Cirkl/Components/Library/Core/CirklDesignTokens.swift` - Design tokens
- `Cirkl/Features/Feed/Components/FilterPill.swift` - Filter pills
- `Cirkl/Features/Feed/Components/UpdateCard.swift` - Update cards
- `Cirkl/Features/Feed/Components/SynergyCard.swift` - Synergy cards
- `Cirkl/Features/Feed/Components/NetworkPulseCard.swift` - Pulse cards
- `Cirkl/Features/Feed/Components/FeedItemDetailSheet.swift` - Detail sheet

### Pattern Replacement

BEFORE (Liquid Glass):
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

AFTER (Flat Design):
```swift
private var cardBackground: some View {
    RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
        .fill(DesignTokens.Colors.cardBackground)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
}
```

### New Design Tokens to Add
```swift
// In DesignTokens.Colors
static let cardBackground = Color(hex: "1C1C1E")
static let cardBackgroundElevated = Color(hex: "2C2C2E")
static let cardBorder = Color.white.opacity(0.08)
```
