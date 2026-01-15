---
name: mobile-test
description: Test responsive design across iOS devices
---

# Mobile Responsive Test

Test UI across all iOS viewports:

```javascript
const devices = [
  { name: 'iPhone SE', width: 375, height: 667 },
  { name: 'iPhone 15', width: 393, height: 852 },
  { name: 'iPhone 15 Pro Max', width: 430, height: 932 },
  { name: 'iPad Pro 11"', width: 834, height: 1194 }
];

for (const device of devices) {
  // Set viewport
  await page.setViewportSize(device);
  
  // Take screenshots
  await page.screenshot({
    path: `screenshots/${device.name}-home.png`
  });
  
  // Check for layout issues
  // Verify touch targets
  // Test gestures
}
```

Generate responsive report with all screenshots.