import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: GameViewModel
    @AccessibilityFocusState private var focusOnNewGame: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Scoreboard
                    ScoreboardView(playerScore: game.player.score, computerScore: game.computer.score)
                        .accessibilityElement(children: .contain)
                    
                    // Game Controls
                    gameControls
                    
                    // Cut Card
                    if let cutCard = game.cutCard {
                        VStack(spacing: 8) {
                            Text("Cut Card")
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            
                            CardView(card: cutCard, isSelected: false, isPlayable: false, action: {})
                                .accessibilityLabel("Cut card: \(cutCard.name)")
                        }
                    }
                    
                    // Current Count
                    if game.gameState == .play || game.gameState == .pause31 || game.gameState == .pauseGo {
                        VStack(spacing: 8) {
                            Text("Current Count")
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text("\(game.currentCount)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.orange.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                )
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Current count: \(game.currentCount)")
                    }
                    
                    // Played Pile
                    if !game.playedPile.isEmpty {
                        VStack(spacing: 8) {
                            Text("Played Cards")
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(game.playedPile) { played in
                                        VStack {
                                            CardView(card: played.card, isSelected: false, isPlayable: false, action: {})
                                            Text(played.playerName)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("\(played.card.name) played by \(played.playerName)")
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Computer Hand (face down)
                    if !game.computer.hand.isEmpty {
                        VStack(spacing: 8) {
                            Text("Computer's Hand")
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            
                            HStack(spacing: -30) {
                                ForEach(0..<game.computer.hand.count, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue)
                                        .frame(width: 60, height: 85)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(Color.white, lineWidth: 1)
                                        )
                                }
                            }
                            .accessibilityLabel("Computer has \(game.computer.hand.count) card\(game.computer.hand.count == 1 ? "" : "s")")
                        }
                    }
                    
                    // Player Hand
                    if !game.player.hand.isEmpty {
                        VStack(spacing: 8) {
                            Text("Your Hand")
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(game.player.hand) { card in
                                        CardView(
                                            card: card,
                                            isSelected: game.selectedForDiscard.contains(card),
                                            isPlayable: isCardPlayable(card),
                                            action: { handleCardTap(card) }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Game Log
                    GameLogView(messages: game.messages)
                }
                .padding()
            }
            .navigationTitle("Cribbage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        game.startNewGame()
                        focusOnNewGame = true
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .accessibilityLabel("New Game")
                    }
                    .accessibilityFocused($focusOnNewGame)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: RulesView()) {
                        Image(systemName: "info.circle")
                            .accessibilityLabel("How to Play")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    @ViewBuilder
    private var gameControls: some View {
        VStack(spacing: 12) {
            switch game.gameState {
            case .cutForDeal:
                Button(action: {
                    game.cutForDeal()
                    UIAccessibility.post(notification: .announcement, argument: "Cutting for deal")
                }) {
                    Text("Cut for Deal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .accessibilityLabel("Cut for Deal")
                .accessibilityHint("Tap to determine who deals first")
                
            case .discard:
                VStack(spacing: 8) {
                    Text("Select 2 cards to discard")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityAddTraits(.isHeader)
                    
                    Button(action: {
                        game.discardToCrib()
                        UIAccessibility.post(notification: .announcement, argument: "Cards discarded to crib")
                    }) {
                        Text("Discard to Crib (\(game.selectedForDiscard.count)/2)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(game.selectedForDiscard.count == 2 ? Color.green : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(game.selectedForDiscard.count != 2)
                    .accessibilityLabel("Discard to Crib")
                    .accessibilityHint("\(game.selectedForDiscard.count) of 2 cards selected")
                    .accessibilityAddTraits(game.selectedForDiscard.count == 2 ? [] : .isButton)
                }
                
            case .play:
                VStack(spacing: 8) {
                    if game.currentTurn === game.player {
                        Text("Your Turn")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .accessibilityAddTraits(.isHeader)
                        
                        Button(action: {
                            game.sayGo()
                            UIAccessibility.post(notification: .announcement, argument: "Go")
                        }) {
                            Text("Say Go")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Say Go")
                        .accessibilityHint("Tap when you cannot play any card")
                    } else {
                        Text("Computer's Turn")
                            .font(.headline)
                            .foregroundColor(.red)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
                
            case .pause31, .pauseGo:
                Button(action: {
                    game.continueAfterPause()
                    UIAccessibility.post(notification: .announcement, argument: "Continuing play")
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)
                }
                .accessibilityLabel("Continue")
                .accessibilityHint("Tap to continue after go or 31")
                
            case .counting:
                Text("Counting Hands...")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                
            case .gameOver:
                Button(action: {
                    game.startNewGame()
                    UIAccessibility.post(notification: .announcement, argument: "Starting new game")
                }) {
                    Text("New Game")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .accessibilityLabel("New Game")
                .accessibilityHint("Tap to start a new game")
            }
        }
        .padding(.horizontal)
    }
    
    private func isCardPlayable(_ card: Card) -> Bool {
        switch game.gameState {
        case .discard:
            return true
        case .play:
            guard game.currentTurn === game.player else { return false }
            guard !game.player.playedCards.contains(card) else { return false }
            return game.currentCount + card.value <= 31
        default:
            return false
        }
    }
    
    private func handleCardTap(_ card: Card) {
        switch game.gameState {
        case .discard:
            game.toggleCardSelection(card)
            // Announcement will be handled by GameLogView or done inline for selection
            if game.selectedForDiscard.contains(card) {
                UIAccessibility.post(notification: .announcement, argument: "\(card.name) selected for discard")
            } else {
                UIAccessibility.post(notification: .announcement, argument: "\(card.name) removed from discard")
            }
            
        case .play:
            guard game.currentTurn === game.player else { return }
            if game.playCard(card, player: game.player) {
                // Announcement will be handled by GameLogView
                
                // Trigger computer play if it's now computer's turn
                if game.currentTurn === game.computer && game.gameState == .play {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        game.computerPlay()
                    }
                }
            }
            
        default:
            break
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GameViewModel())
    }
}
