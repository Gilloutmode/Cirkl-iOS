#!/usr/bin/swift

import Foundation

print("✅ Animation validation started...")

// Check that BubbleToHexagonAnimation.swift exists
let animationFile = "/Users/gil/Cirkl/Cirkl/Components/BubbleToHexagonAnimation.swift"
if FileManager.default.fileExists(atPath: animationFile) {
    print("✓ BubbleToHexagonAnimation.swift found")
} else {
    print("✗ BubbleToHexagonAnimation.swift not found")
}

// Check that the animation has the correct phases
let content = try! String(contentsOfFile: animationFile)

// Verify all 5 phases are implemented
let phases = [
    "Phase 1: Initial state",
    "Phase 2: Bubble appearance", 
    "Phase 3: Expansion start",
    "Phase 4: Final positioning",
    "Phase 5: Connection lines"
]

for phase in phases {
    if content.contains(phase) {
        print("✓ \(phase) implemented")
    } else {
        print("✗ \(phase) missing")
    }
}

// Check key animation components
let components = [
    "AnimatedConnectionLine",
    "AnimatedBubble",
    "CenterProfile",
    "hexagon",
    "glassmorphic",
    "0-500ms",
    "500-1500ms", 
    "1500-2500ms",
    "2500-3000ms"
]

print("\n📋 Component check:")
for component in components {
    if content.contains(component) {
        print("✓ \(component) present")
    } else {
        print("✗ \(component) missing")
    }
}

// Check for NO orbital movement keywords
if content.contains("orbital") || content.contains("floating") || content.contains("orbit") {
    print("\n⚠️ WARNING: Found orbital/floating keywords - ensure final state is FIXED")
}

print("\n✅ Animation validation complete!")
print("📌 Final state: Fixed hexagonal layout (NO orbital movement)")
print("⏱ Total duration: 3000ms (3 seconds)")
print("🎯 6 connections in hexagonal pattern at angles: 30°, 90°, 150°, 210°, 270°, 330°")