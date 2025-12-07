# Accessible Cribbage

A fully functional Cribbage game written in Python with wxPython, designed for accessibility.

## Features

- **Accessibility First**: Designed for screen readers and keyboard navigation.
- **Keyboard Navigation**:
  - **Tab**: Move between Player Hand, Opponent Hand, and Played Cards list.
  - **Left/Right Arrows**: Navigate cards within a hand or list.
  - **Enter/Space**: Select/Play a card.
- **Automatic Announcements**: Game actions, played cards, scores, and counts are spoken aloud.
- **Automatic Pegging**: Scoring is handled automatically.

## Requirements

- Python 3
- `wxPython`
- `pyttsx3`

## How to Run

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
2. Run the game:
   ```bash
   python gui.py
   ```

## How to Play

1. **Deal**: The game starts with a deal.
2. **Discard**: Select 2 cards from your hand to discard to the crib. Navigate with Arrows, press Enter to select.
3. **Play (Pegging)**: Play cards alternately with the computer. Try to make 15, 31, pairs, or runs.
4. **Show**: Hands are scored automatically.
5. **Win**: First to 121 points wins.
