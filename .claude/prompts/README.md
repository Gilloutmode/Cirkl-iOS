# 🎯 Claude Code Prompts Collection for Cirkl

## Feature Development Prompts

### Create New View Component
```
Create a new SwiftUI view for [FEATURE_NAME] following Cirkl's glassmorphic design system.
Requirements:
- Use glassmorphic effects with blur radius 20-30
- Include smooth spring animations
- Follow MVVM pattern with @Observable ViewModel
- Support both light and dark mode (prefer dark)
- Add accessibility labels
- Maximum 300 lines per file
- Include preview with mock data
```

### Implement Physical Verification
```
Implement [QR/NFC/BLE] verification for adding new connections.
Requirements:
- Use [AVFoundation for QR / CoreNFC for NFC / CoreBluetooth for BLE]
- Handle all permission requests gracefully
- Provide fallback options if hardware unavailable
- Add loading states during verification
- Store verification method in Connection model
- Show success animation after verification
```

### Add AI Assistant Feature
```
Implement AI assistant feature for [CONTEXT: post-meeting debrief / opportunity detection / etc].
Requirements:
- Create appropriate AIAssistantState
- Use dynamic color based on state
- Add ripple animation when active
- Integrate with Zep AI for memory persistence
- Handle offline scenarios
- Provide contextual prompts based on user action
```

## Bug Fixing Prompts

### Performance Optimization
```
Optimize [VIEW/FEATURE] for ProMotion 120fps performance.
Current issues: [DESCRIBE ISSUES]
Requirements:
- Profile with Instruments first
- Minimize view redraws
- Use lazy loading where appropriate
- Implement proper state management
- Cache expensive computations
- Target consistent 120fps on iPhone 15 Pro
```

### Memory Leak Fix
```
Fix memory leak in [COMPONENT].
Symptoms: [DESCRIBE SYMPTOMS]
Requirements:
- Check for retain cycles in closures
- Verify proper use of weak/unowned references
- Ensure proper cleanup in onDisappear
- Add proper deinit logging
- Test with Memory Graph Debugger
```

## Refactoring Prompts

### Component Extraction
```
Extract [COMPONENT] from [CURRENT_FILE] into reusable component.
Requirements:
- Create new file in appropriate directory
- Define clear interface with minimal props
- Add comprehensive documentation
- Include unit tests
- Provide usage examples in preview
- Maintain backward compatibility
```

### Architecture Improvement
```
Refactor [FEATURE] to follow Clean Architecture principles.
Current structure: [DESCRIBE CURRENT]
Requirements:
- Separate into layers: Presentation, Domain, Data
- Use dependency injection
- Create proper abstractions/protocols
- Add repository pattern if needed
- Ensure testability
- Document architectural decisions
```

## Testing Prompts

### Unit Test Creation
```
Write comprehensive unit tests for [VIEWMODEL/SERVICE].
Coverage target: 80%
Requirements:
- Test all public methods
- Include edge cases
- Test error scenarios
- Mock external dependencies
- Use XCTest assertions
- Add performance tests where relevant
```

### UI Test Flow
```
Create UI test for [USER_FLOW: onboarding / authentication / connection creation].
Requirements:
- Use XCUITest framework
- Include accessibility identifier checks
- Test both happy path and error states
- Add screenshot capture at key points
- Ensure tests run on multiple device sizes
- Keep tests maintainable and readable
```

## Integration Prompts

### API Integration
```
Integrate [API_ENDPOINT] with the app.
Endpoint: [ENDPOINT_URL]
Method: [GET/POST/PUT/DELETE]
Requirements:
- Use async/await pattern
- Implement proper error handling
- Add retry logic with exponential backoff
- Cache responses when appropriate
- Handle offline scenarios
- Update relevant ViewModels
- Add loading and error states to UI
```

### Third-Party SDK
```
Integrate [SDK_NAME] for [PURPOSE].
Documentation: [LINK]
Requirements:
- Follow SDK best practices
- Wrap in service layer for abstraction
- Handle all error cases
- Add proper logging
- Ensure privacy compliance
- Update Info.plist if needed
- Add to dependency manager
```

## Design Implementation Prompts

### Glassmorphic Component
```
Create glassmorphic [COMPONENT_TYPE: card / button / modal / etc].
Design specs: [PROVIDE SPECS OR SCREENSHOT]
Requirements:
- Background blur effect (20-30 radius)
- Semi-transparent fill (5-10% white)
- Subtle border (20% white, 0.5-1pt)
- Soft shadow for depth
- Support for content overlay
- Smooth hover/tap animations
- Accessible contrast ratios
```

### Animation Creation
```
Create [ANIMATION_TYPE: pulse / orbit / ripple / transition] animation.
Context: [WHERE/WHEN USED]
Requirements:
- Use SwiftUI native animations
- Target 60-120fps performance
- Include easing curves (spring preferred)
- Make duration configurable
- Add preview with controls
- Ensure smooth on all devices
```

## Quick Fixes

### Xcode Build Error
```
Fix Xcode build error: [ERROR_MESSAGE]
File: [FILE_PATH]
Line: [LINE_NUMBER]
Requirements:
- Identify root cause
- Provide minimal fix
- Explain why error occurred
- Suggest prevention for future
- Test fix thoroughly
```

### SwiftUI Layout Issue
```
Fix layout issue in [VIEW_NAME].
Problem: [DESCRIBE VISUAL ISSUE]
Expected: [DESCRIBE EXPECTED BEHAVIOR]
Requirements:
- Use proper SwiftUI layout system
- Avoid hardcoded dimensions where possible
- Test on multiple screen sizes
- Ensure accessibility compliance
- Maintain design consistency
```

---

## Usage Examples

### In Terminal with Claude Code:
```bash
claude-code --prompt "$(cat .claude/prompts/feature.md)" --context .
```

### In Cursor:
1. Open Command Palette (⌘K)
2. Paste the prompt
3. Claude will use .cursorrules for context

### With Custom Variables:
Replace [PLACEHOLDERS] with actual values before using prompts.

---

## Tips for Best Results

1. **Be Specific**: Replace all placeholders with detailed information
2. **Provide Context**: Include relevant code snippets or screenshots
3. **Set Clear Goals**: Define success criteria
4. **Iterate**: Refine prompts based on results
5. **Document**: Save successful prompts for team reuse