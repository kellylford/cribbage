# Cribbage Game - WPF Edition

A fully accessible Windows desktop cribbage game built with WPF (Windows Presentation Foundation) and C#.

## Requirements

- .NET 8.0 SDK or later
- Windows 10/11

## Building and Running

1. **Build the project**:
   ```bash
   dotnet build
   ```

2. **Run the game**:
   ```bash
   dotnet run
   ```

3. **Publish a standalone executable** (optional):
   ```bash
   dotnet publish -c Release -r win-x64 --self-contained
   ```

## Features

- **Full Cribbage Gameplay**: Complete implementation of cribbage rules including:
  - Cut for deal
  - Discard to crib
  - Play phase with counting (15s, pairs, runs, 31)
  - Hand counting (15s, pairs, runs, flushes, nobs)
  - Score tracking to 121 points

- **Full Keyboard Accessibility**:
  - **Tab**: Navigate between game controls and your hand
  - **Arrow Keys**: Navigate between cards in your hand (Left/Right)
  - **Home/End**: Jump to first/last card
  - **Space/Enter**: Select or play the current card
  - **Alt+C**: Cut for Deal
  - **Alt+G**: Say Go
  - **Alt+N**: Continue / New Game
  - **Ctrl+N**: Start New Game

- **Screen Reader Support**:
  - All UI elements have proper AutomationProperties names
  - Live region announcements for game events
  - Descriptive card names (e.g., "Ace of Hearts, card 1 of 4")
  - Game log with full history

## How to Play

1. Click "Cut for Deal" or press Alt+C to determine who deals first
2. Select 2 cards to discard to the crib, then click "Continue" or press Alt+N
3. Play cards during the play phase by clicking them or using arrow keys + Space/Enter
4. Click "Go" (Alt+G) if you cannot play
5. Continue through scoring phases
6. First to 121 points wins!

## Accessibility Notes

- The player hand panel is a single tab stop for efficiency
- Use Left/Right arrow keys to navigate between cards
- All cards announce their full name when focused
- Game events are announced via a live region for screen readers
- High contrast compatible
- Full keyboard navigation - no mouse required

## Project Structure

- `Cribbage.csproj` - Project file
- `App.xaml` / `App.xaml.cs` - Application entry point and global styles
- `MainWindow.xaml` / `MainWindow.xaml.cs` - Main game window and UI logic
- `GameModel.cs` - Game logic (Card, Deck, Player, CribbageGame classes)

## Web Version

The web version of this game is still available:
- `index.html` - Main game page
- `game.js` - Complete game logic and UI
- `styles.css` - Responsive styling
- `rules.html` - Comprehensive cribbage rules
