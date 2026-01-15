---
name: ab-test
description: Run A/B design testing across worktrees
---

# A/B Design Testing

Compare multiple design implementations:

```javascript
async function runABTest() {
  const variants = [
    { path: '../cirkl-design-v1', name: 'Variant A' },
    { path: '../cirkl-design-v2', name: 'Variant B' },
    { path: '../cirkl-design-v3', name: 'Variant C' }
  ];
  
  const results = [];
  
  for (const variant of variants) {
    console.log(`Testing ${variant.name}...`);
    
    // Navigate to variant
    process.chdir(variant.path);
    
    // Start server
    const server = await startServer();
    
    // Run visual tests
    const metrics = await captureMetrics();
    
    results.push({
      variant: variant.name,
      metrics,
      screenshots: await captureScreenshots()
    });
    
    // Stop server
    await stopServer(server);
  }
  
  // Generate comparison report
  await generateComparisonReport(results);
}
```