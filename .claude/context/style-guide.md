# Cirkl Visual Style Guide

## Glassmorphism Recipe
```css
.glass-surface {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 20px;
  box-shadow: 
    0 8px 32px rgba(0, 0, 0, 0.1),
    inset 0 2px 0 rgba(255, 255, 255, 0.2);
}

.glass-dark {
  background: rgba(0, 0, 0, 0.2);
  backdrop-filter: blur(30px);
}
```

## Typography Scale
- Display: 34pt SF Pro Display
- Title 1: 28pt SF Pro Display
- Title 2: 22pt SF Pro Display
- Title 3: 20pt SF Pro Display
- Headline: 17pt SF Pro Text Semibold
- Body: 17pt SF Pro Text
- Callout: 16pt SF Pro Text
- Subhead: 15pt SF Pro Text
- Footnote: 13pt SF Pro Text
- Caption: 12pt SF Pro Text

## Animation Curves
- Spring: tension=180, friction=12
- EaseInOut: cubic-bezier(0.42, 0, 0.58, 1)
- Bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55)

## Component Patterns
- Cards: Glass surface + 16px padding
- Buttons: 50px height, 16px horizontal padding
- Inputs: 48px height, glass background
- Modals: Dark glass overlay + light glass content
- Navigation: Blur tab bar, floating design

## Spacing System
- Base unit: 4px
- Micro: 4px
- Small: 8px
- Medium: 16px
- Large: 24px
- Extra Large: 32px
- Huge: 48px

## Touch Targets
- Minimum: 44x44pt
- Recommended: 48x48pt
- Comfortable: 56x56pt

## Z-Index Layers
- Background: 0
- Content: 10
- Cards: 20
- Navigation: 100
- Modals: 200
- Tooltips: 300
- System: 999