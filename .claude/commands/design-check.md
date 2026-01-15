---
name: design-check
description: Quick visual check of current UI implementation
---

# Design Check Command

Execute a rapid visual audit:

1. Launch Playwright with iPhone 15 Pro emulation
2. Navigate to localhost:3000 (or active dev server)
3. Take screenshots of:
   - Main feed
   - Profile with orbital connections
   - Connection request flow
   - Chat interface
   - Settings/privacy screen

4. Check for:
   - Console errors
   - Glassmorphic rendering issues
   - Animation jank
   - Touch target sizes
   - Loading states

5. Generate quick report with screenshots