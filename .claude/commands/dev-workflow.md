---
name: dev-workflow
description: Complete development workflow with visual validation
---

# Automated Development Workflow

Execute the complete Cirkl development cycle:

```javascript
async function runDevWorkflow() {
  // 1. Pre-flight checks
  console.log('🔍 Running pre-flight checks...');
  await runLinter();
  await checkTypeScript();
  
  // 2. Launch dev server
  console.log('🚀 Starting development server...');
  await startDevServer();
  
  // 3. Wait for server ready
  await waitForServer('http://localhost:3000');
  
  // 4. Visual regression testing
  console.log('📸 Capturing baseline screenshots...');
  await captureBaseline();
  
  // 5. Run playwright tests
  console.log('🎭 Running Playwright visual tests...');
  await runPlaywrightTests();
  
  // 6. Accessibility audit
  console.log('♿ Running accessibility audit...');
  await runA11yAudit();
  
  // 7. Performance check
  console.log('⚡ Checking performance metrics...');
  await measurePerformance();
  
  // 8. Generate report
  console.log('📊 Generating visual report...');
  await generateReport();
  
  return {
    status: 'complete',
    report: './reports/dev-workflow-report.html'
  };
}
```