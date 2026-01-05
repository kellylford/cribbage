# Cribbage iOS App

A fully accessible native iOS app for playing Cribbage, built with SwiftUI and designed with comprehensive VoiceOver support.

## Features

### Accessibility First
- **Full VoiceOver Support**: Every UI element is properly labeled and navigable
- **Dynamic Type**: Respects user's preferred text size
- **High Contrast**: Clear visual design meeting WCAG standards
- **Haptic Feedback**: Tactile responses for key actions
- **Accessibility Focus Management**: Smart focus handling for screen reader users
- **Live Announcements**: Real-time game updates announced to VoiceOver

### Game Features
- Complete Cribbage game implementation
- Play against computer AI
- Automatic scoring for:
  - Fifteens (2 points)
  - Pairs (2 points each)
  - Runs (1 point per card)
  - Flushes (4-5 points)
  - Nobs (1 point)
  - His Heels (2 points)
- Score tracking to 121 points
- Detailed game log
- Built-in rules reference

## Requirements

- iOS 16.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Project Structure

```
CribbageApp/
├── CribbageApp.swift          # App entry point
├── Models/
│   ├── Card.swift             # Card and Deck models
│   ├── Player.swift           # Player model
│   └── GameState.swift        # Game state enums
├── ViewModels/
│   └── GameViewModel.swift    # Game logic and state management
└── Views/
    ├── ContentView.swift      # Main game view
    ├── CardView.swift         # Individual card display
    ├── ScoreboardView.swift   # Score display
    ├── GameLogView.swift      # Game message log
    └── RulesView.swift        # Rules reference
```

## How to Build

1. Open `CribbageApp.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press `Cmd+R` to build and run

## How to Play

1. **Cut for Deal**: Tap the button to determine who deals first
2. **Discard Phase**: Select 2 cards from your hand to discard to the crib
3. **Play Phase**: Tap cards to play them, maintaining a running count up to 31
4. **Scoring**: Hands are automatically counted at the end of each round
5. **Win**: First player to reach 121 points wins!

## Accessibility Guidelines

### VoiceOver Usage

- **Navigation**: Swipe right/left to move between elements
- **Selection**: Double-tap to activate buttons or select cards
- **Game Log**: Messages are automatically announced as they occur
- **Score Updates**: Score changes are announced immediately

### Visual Features

- **Card Selection**: Selected cards have a blue border and shadow
- **Playability**: Unplayable cards are dimmed (50% opacity)
- **Current Turn**: Clearly indicated with color-coded headers
- **Progress Bars**: Visual representation of scores

## Game Rules

The app includes a comprehensive rules view accessible from the main screen. Key scoring:

- **Fifteens**: Any combination of cards totaling 15 (2 points each)
- **Pairs**: Two cards of the same rank (2 points, 6 for three, 12 for four)
- **Runs**: Three or more consecutive cards (1 point per card)
- **Flush**: Four cards of same suit in hand (4 points, 5 if cut card matches)
- **Nobs**: Jack in hand matching cut card's suit (1 point)
- **His Heels**: Jack as cut card (2 points to dealer)

## Technical Details

### Accessibility Implementation

1. **Semantic Views**: Proper use of SwiftUI accessibility modifiers
2. **Accessibility Labels**: Descriptive labels for all interactive elements
3. **Accessibility Hints**: Contextual help for actions
4. **Accessibility Traits**: Proper traits (button, header, selected, etc.)
5. **Focus State**: @AccessibilityFocusState for programmatic focus
6. **Announcements**: UIAccessibility.post() for live updates

### State Management

- Uses SwiftUI's `@Published` properties for reactive UI updates
- MVVM architecture for clear separation of concerns
- Combine framework for asynchronous operations

## Future Enhancements

- [ ] Multiplayer support (two human players)
- [ ] Game statistics and history
- [ ] Different difficulty levels for AI
- [ ] Sound effects and music
- [ ] Achievements and leaderboards
- [ ] iPad-optimized layout
- [ ] Dark mode support

## License

This project is provided as-is for educational and entertainment purposes.

## Credits

Based on the web-based Accessible Cribbage game, adapted for iOS with enhanced native accessibility features.
