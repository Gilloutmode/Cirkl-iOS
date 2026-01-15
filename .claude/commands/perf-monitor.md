---
name: perf-monitor
description: Monitor UI performance metrics
---

# Performance Monitoring

Track key performance indicators:

```javascript
async function monitorPerformance() {
  const metrics = {
    fps: [],
    renderTime: [],
    interactionLatency: [],
    memoryUsage: []
  };
  
  // Monitor for 60 seconds
  const duration = 60000;
  const interval = 1000;
  
  const monitor = setInterval(async () => {
    // Capture FPS
    const fps = await page.evaluate(() => {
      return new Promise(resolve => {
        let frames = 0;
        const start = performance.now();
        
        function count() {
          frames++;
          if (performance.now() - start < 1000) {
            requestAnimationFrame(count);
          } else {
            resolve(frames);
          }
        }
        
        requestAnimationFrame(count);
      });
    });
    
    metrics.fps.push(fps);
    
    // Capture render time
    const renderTime = await page.evaluate(() => {
      return performance.getEntriesByType('paint')[0]?.duration || 0;
    });
    
    metrics.renderTime.push(renderTime);
    
    // Log current metrics
    console.log(`FPS: ${fps}, Render: ${renderTime}ms`);
    
  }, interval);
  
  // Stop after duration
  setTimeout(() => {
    clearInterval(monitor);
    generatePerformanceReport(metrics);
  }, duration);
}
```