# Accessible Cribbage

A fully accessible web-based Cribbage game built with HTML, CSS, and JavaScript.

## Play Online

Simply open `index.html` in any modern web browser to play!

## Features

- **Fully Accessible**: Designed with WCAG accessibility standards
- **Screen Reader Support**: Complete ARIA labels and live announcements
- **Keyboard Navigation**:
  - **Tab**: Navigate between game controls and card areas
  - **Arrow Keys**: Navigate cards in your hand and game log messages
  - **Space/Enter**: Select cards for discard or play
- **Visual Design**: Beautiful card graphics with proper color contrast
- **Responsive**: Works on desktop, tablet, and mobile devices
- **No Installation Required**: Pure HTML/CSS/JavaScript - works offline

## How to Play

1. Open `index.html` in your browser
2. Click "Cut for Deal" to start
3. **Discard Phase**: Select 2 cards to discard to the crib
4. **Play Phase**: Play cards alternately with the computer
5. **Scoring**: Hands are counted automatically
6. First to 121 points wins!

For complete rules, click "How to Play Cribbage" at the top of the game.

## Files

- `index.html` - Main game page
- `game.js` - Complete game logic and UI
- `styles.css` - Responsive styling
- `rules.html` - Comprehensive cribbage rules

## Accessibility Features

- Semantic HTML with proper table structure for scores
- ARIA labels and roles throughout
- Live regions for screen reader announcements
- Keyboard-navigable game log with arrow key support
- Selected card state announced programmatically
- High contrast colors meeting WCAG standards
- Focus indicators on all interactive elements
