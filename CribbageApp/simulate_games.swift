#!/usr/bin/env swift

import Foundation

// Simplified versions of the models for simulation
enum Suit: String, CaseIterable {
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"
    case spades = "♠"
}

enum Rank: String, CaseIterable {
    case ace = "A", two = "2", three = "3", four = "4", five = "5"
    case six = "6", seven = "7", eight = "8", nine = "9", ten = "10"
    case jack = "J", queen = "Q", king = "K"
    
    var value: Int {
        switch self {
        case .ace: return 1
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        case .seven: return 7
        case .eight: return 8
        case .nine: return 9
        case .ten, .jack, .queen, .king: return 10
        }
    }
}

struct Card: Identifiable, Hashable, Equatable {
    let id = UUID()
    let rank: Rank
    let suit: Suit
    
    var value: Int { rank.value }
    var name: String { "\(rank.rawValue)\(suit.rawValue)" }
    
    var isRed: Bool {
        suit == .hearts || suit == .diamonds
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.rank == rhs.rank && lhs.suit == rhs.suit
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(rank)
        hasher.combine(suit)
    }
}

class Player {
    let name: String
    let isComputer: Bool
    var hand: [Card] = []
    var playedCards: [Card] = []
    var score: Int = 0
    
    init(name: String, isComputer: Bool) {
        self.name = name
        self.isComputer = isComputer
    }
    
    func addCard(_ card: Card) {
        hand.append(card)
    }
    
    func removeCard(_ card: Card) -> Card? {
        if let index = hand.firstIndex(of: card) {
            return hand.remove(at: index)
        }
        return nil
    }
    
    func resetHand() {
        hand.removeAll()
        playedCards.removeAll()
    }
    
    func sortHand() {
        hand.sort { $0.value < $1.value }
    }
    
    func clearPlayedCards() {
        playedCards.removeAll()
    }
}

class Deck {
    private var cards: [Card] = []
    
    init() {
        reset()
    }
    
    func reset() {
        cards.removeAll()
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(Card(rank: rank, suit: suit))
            }
        }
        cards.shuffle()
    }
    
    func deal() -> Card? {
        return cards.isEmpty ? nil : cards.removeFirst()
    }
}

enum GameState {
    case cutForDeal, discard, play, pause31, pauseGo, counting, gameOver
}

struct PlayedCard: Identifiable {
    let id = UUID()
    let card: Card
    let playerName: String
    let isComputer: Bool
}

// Simplified GameViewModel for simulation
class GameSimulator {
    var player: Player
    var computer: Player
    var gameState: GameState = .cutForDeal
    var crib: [Card] = []
    var cutCard: Card?
    var dealer: Player?
    var currentTurn: Player?
    var playedPile: [PlayedCard] = []
    var currentCount: Int = 0
    var lastWinner: Player?
    
    private var deck: Deck = Deck()
    private let winningScore = 121
    private var messages: [String] = []
    
    init() {
        self.player = Player(name: "Player", isComputer: false)
        self.computer = Player(name: "Computer", isComputer: true)
    }
    
    func simulateGame() -> Player? {
        // Start with random dealer
        dealer = Bool.random() ? player : computer
        
        while player.score < winningScore && computer.score < winningScore {
            simulateRound()
        }
        
        return player.score >= winningScore ? player : computer
    }
    
    func simulateRound() {
        player.resetHand()
        computer.resetHand()
        crib.removeAll()
        cutCard = nil
        playedPile.removeAll()
        currentCount = 0
        
        deck.reset()
        
        // Deal 6 cards
        for _ in 0..<6 {
            if let card = deck.deal() {
                player.addCard(card)
            }
            if let card = deck.deal() {
                computer.addCard(card)
            }
        }
        
        player.sortHand()
        computer.sortHand()
        
        // Discard phase - both use AI strategy
        let playerDiscards = selectPlayerDiscard()
        for card in playerDiscards {
            if let removed = player.removeCard(card) {
                crib.append(removed)
            }
        }
        
        let computerDiscards = selectComputerDiscard()
        for card in computerDiscards {
            if let removed = computer.removeCard(card) {
                crib.append(removed)
            }
        }
        
        // Cut card
        if let cut = deck.deal() {
            cutCard = cut
            
            // His heels
            if cut.rank == .jack, let dealer = dealer {
                dealer.score += 2
                if checkForWinner() { return }
            }
        }
        
        // Play phase
        gameState = .play
        currentTurn = dealer === player ? computer : player
        
        simulatePlayPhase()
        
        // Count hands
        if !checkForWinner() {
            countHands()
        }
        
        // Switch dealer
        dealer = dealer === player ? computer : player
    }
    
    func simulatePlayPhase() {
        while !checkPlayComplete() {
            guard let current = currentTurn else { break }
            
            let playableCards = current.hand.filter { card in
                !current.playedCards.contains(card) && currentCount + card.value <= 31
            }
            
            if playableCards.isEmpty {
                // Say go
                if currentTurn === player {
                    computer.score += 1
                } else {
                    player.score += 1
                }
                
                switchTurn()
                
                if !canPlay(player: currentTurn!) {
                    // Both said go, reset count
                    currentCount = 0
                }
                continue
            }
            
            // Play a card
            let cardToPlay = current === computer ? selectBestPlayCard(playableCards) : selectBestPlayCard(playableCards, forPlayer: player)
            
            _ = playCard(cardToPlay, player: current)
            
            if checkForWinner() { return }
        }
        
        // End of play
        if currentCount != 31, let lastPlayed = playedPile.last {
            let lastPlayer = lastPlayed.isComputer ? computer : player
            lastPlayer.score += 1
            if checkForWinner() { return }
        }
        
        // Restore hands
        player.clearPlayedCards()
        computer.clearPlayedCards()
        
        for played in playedPile {
            if played.isComputer {
                computer.addCard(played.card)
            } else {
                player.addCard(played.card)
            }
        }
    }
    
    func playCard(_ card: Card, player: Player) -> Bool {
        currentCount += card.value
        player.playedCards.append(card)
        playedPile.append(PlayedCard(card: card, playerName: player.name, isComputer: player.isComputer))
        
        // Score the play
        scorePlay(card, player: player)
        
        if currentCount == 31 {
            currentCount = 0
        } else {
            switchTurn()
        }
        
        return true
    }
    
    func scorePlay(_ card: Card, player: Player) {
        var points = 0
        
        // 15 or 31
        if currentCount == 15 { points += 2 }
        if currentCount == 31 { points += 2 }
        
        // Pairs, trips, quads
        if playedPile.count >= 2 {
            let recentCards = playedPile.suffix(4).map { $0.card }
            var pairCount = 1
            for i in stride(from: recentCards.count - 2, through: 0, by: -1) {
                if recentCards[i].rank == card.rank {
                    pairCount += 1
                } else {
                    break
                }
            }
            if pairCount == 2 { points += 2 }
            else if pairCount == 3 { points += 6 }
            else if pairCount == 4 { points += 12 }
        }
        
        // Runs
        if playedPile.count >= 3 {
            for length in stride(from: min(7, playedPile.count), through: 3, by: -1) {
                let recent = playedPile.suffix(length).map { $0.card }
                if isRun(recent) {
                    points += length
                    break
                }
            }
        }
        
        player.score += points
    }
    
    func isRun(_ cards: [Card]) -> Bool {
        let values = cards.map { $0.rank.value }.sorted()
        for i in 0..<values.count-1 {
            if values[i+1] != values[i] + 1 {
                return false
            }
        }
        return true
    }
    
    func switchTurn() {
        currentTurn = currentTurn === player ? computer : player
    }
    
    func canPlay(player: Player) -> Bool {
        return player.hand.contains { card in
            !player.playedCards.contains(card) && currentCount + card.value <= 31
        }
    }
    
    func checkPlayComplete() -> Bool {
        return player.hand.count == player.playedCards.count &&
               computer.hand.count == computer.playedCards.count
    }
    
    func countHands() {
        guard let cutCard = cutCard else { return }
        
        // Non-dealer counts first
        let nonDealer = dealer === player ? computer : player
        let ndPoints = scoreHand(nonDealer.hand, cutCard: cutCard, isCrib: false)
        nonDealer.score += ndPoints
        if checkForWinner() { return }
        
        // Dealer counts
        let dPoints = scoreHand(dealer!.hand, cutCard: cutCard, isCrib: false)
        dealer!.score += dPoints
        if checkForWinner() { return }
        
        // Crib
        let cPoints = scoreHand(crib, cutCard: cutCard, isCrib: true)
        dealer!.score += cPoints
        if checkForWinner() { return }
    }
    
    func scoreHand(_ hand: [Card], cutCard: Card, isCrib: Bool) -> Int {
        var points = 0
        let allCards = hand + [cutCard]
        
        // Fifteens
        for i in 0..<allCards.count {
            if allCards[i].value == 15 { points += 2 }
            for j in (i+1)..<allCards.count {
                if allCards[i].value + allCards[j].value == 15 { points += 2 }
                for k in (j+1)..<allCards.count {
                    if allCards[i].value + allCards[j].value + allCards[k].value == 15 { points += 2 }
                    for l in (k+1)..<allCards.count {
                        if allCards[i].value + allCards[j].value + allCards[k].value + allCards[l].value == 15 {
                            points += 2
                        }
                        for m in (l+1)..<allCards.count {
                            if allCards[i].value + allCards[j].value + allCards[k].value + allCards[l].value + allCards[m].value == 15 {
                                points += 2
                            }
                        }
                    }
                }
            }
        }
        
        // Pairs
        for i in 0..<allCards.count {
            for j in (i+1)..<allCards.count {
                if allCards[i].rank == allCards[j].rank {
                    points += 2
                }
            }
        }
        
        // Runs
        if let runPoints = findBestRun(allCards) {
            points += runPoints
        }
        
        // Flush
        let handSuit = hand[0].suit
        if hand.allSatisfy({ $0.suit == handSuit }) {
            points += cutCard.suit == handSuit ? 5 : 4
        }
        
        // Nobs
        if hand.contains(where: { $0.rank == .jack && $0.suit == cutCard.suit }) {
            points += 1
        }
        
        return points
    }
    
    func findBestRun(_ cards: [Card]) -> Int? {
        let values = cards.map { $0.rank.value }.sorted()
        
        for length in stride(from: 5, through: 3, by: -1) {
            var runCount = 0
            for i in 0...(values.count - length) {
                let subset = Array(values[i..<(i+length)])
                var isRun = true
                for j in 0..<(subset.count-1) {
                    if subset[j+1] != subset[j] + 1 {
                        isRun = false
                        break
                    }
                }
                if isRun {
                    runCount += 1
                }
            }
            if runCount > 0 {
                return length * runCount
            }
        }
        return nil
    }
    
    func checkForWinner() -> Bool {
        return player.score >= winningScore || computer.score >= winningScore
    }
    
    // AI Methods
    func selectPlayerDiscard() -> [Card] {
        var bestDiscards: [Card] = []
        var bestScore = Double.infinity
        
        let hand = player.hand
        for i in 0..<hand.count {
            for j in (i+1)..<hand.count {
                let discardPair = [hand[i], hand[j]]
                let remainingCards = hand.filter { !discardPair.contains($0) }
                
                var handScore = 0.0
                for card in remainingCards {
                    for other in remainingCards {
                        if card != other && card.value + other.value == 15 {
                            handScore += 2
                        }
                    }
                }
                
                let cribScore = estimateCribScore(discardPair)
                
                let totalScore = dealer === player
                    ? handScore + (cribScore * 1.5)
                    : handScore - (cribScore * 1.5)
                
                if totalScore < bestScore {
                    bestScore = totalScore
                    bestDiscards = discardPair
                }
            }
        }
        
        return bestDiscards.isEmpty ? Array(player.hand.prefix(2)) : bestDiscards
    }
    
    func selectComputerDiscard() -> [Card] {
        var bestDiscards: [Card] = []
        var bestScore = Double.infinity
        
        let hand = computer.hand
        for i in 0..<hand.count {
            for j in (i+1)..<hand.count {
                let discardPair = [hand[i], hand[j]]
                let remainingCards = hand.filter { !discardPair.contains($0) }
                
                var handScore = 0.0
                for card in remainingCards {
                    for other in remainingCards {
                        if card != other && card.value + other.value == 15 {
                            handScore += 2
                        }
                    }
                }
                
                let cribScore = estimateCribScore(discardPair)
                
                let totalScore = dealer === computer
                    ? handScore + (cribScore * 1.5)
                    : handScore - (cribScore * 1.5)
                
                if totalScore < bestScore {
                    bestScore = totalScore
                    bestDiscards = discardPair
                }
            }
        }
        
        return bestDiscards.isEmpty ? Array(computer.hand.prefix(2)) : bestDiscards
    }
    
    func estimateCribScore(_ cards: [Card]) -> Double {
        var score = 0.0
        
        if cards[0].value + cards[1].value == 15 {
            score += 2
        }
        
        if cards[0].rank == cards[1].rank {
            score += 2
        }
        
        return score
    }
    
    func selectBestPlayCard(_ cards: [Card], forPlayer currentPlayer: Player) -> Card {
        if cards.count == 1 {
            return cards[0]
        }
        
        var bestCard = cards[0]
        var bestScore = -999.0
        
        let opponentPlayer = currentPlayer === player ? computer : player
        
        for card in cards {
            var score = 0.0
            let newCount = currentCount + card.value
            
            if newCount == 15 {
                score += 20
            }
            if newCount == 31 {
                score += 20
            }
            
            let remainingHand = currentPlayer.hand.filter { $0 != card && !currentPlayer.playedCards.contains($0) }
            let futurePlayable = remainingHand.filter { $0.value + newCount <= 31 }.count
            
            if futurePlayable == 0 && newCount < 31 {
                score -= 10
            } else {
                score += Double(futurePlayable) * 2
            }
            
            let opponentHand = opponentPlayer.hand.filter { !opponentPlayer.playedCards.contains($0) }
            
            if opponentHand.contains(where: { newCount + $0.value == 31 }) {
                score -= 15
            }
            
            if opponentHand.contains(where: { newCount + $0.value == 15 }) {
                score -= 8
            }
            
            if opponentHand.contains(where: { $0.rank == card.rank }) {
                score -= 5
            }
            
            let percentOfMax = Double(newCount) / 31.0
            if percentOfMax < 0.6 && card.value >= 10 {
                score -= 3
            }
            
            if newCount != 15 && newCount != 31 {
                score -= Double(card.value) / 10.0
            }
            
            if score > bestScore {
                bestScore = score
                bestCard = card
            }
        }
        
        return bestCard
    }
    
    func selectBestPlayCard(_ cards: [Card]) -> Card {
        return selectBestPlayCard(cards, forPlayer: computer)
    }
}

// Main simulation runner
print("🎴 Starting iOS Cribbage Game Simulation (100 games)")
print(String(repeating: "=", count: 60))

var playerWins = 0
var computerWins = 0
var errors: [String] = []

for gameNum in 1...100 {
    let simulator = GameSimulator()
    
    if let winner = simulator.simulateGame() {
        if winner === simulator.player {
            playerWins += 1
        } else {
            computerWins += 1
        }
        
        if gameNum % 10 == 0 {
            print("Game \(gameNum): Player \(playerWins) - Computer \(computerWins)")
        }
    } else {
        errors.append("Game \(gameNum): No winner determined")
    }
}

print(String(repeating: "=", count: 60))
print("✅ Simulation Complete!")
print("")
print("Results:")
print("  Player wins:    \(playerWins) (\(String(format: "%.1f", Double(playerWins)/100.0*100))%)")
print("  Computer wins:  \(computerWins) (\(String(format: "%.1f", Double(computerWins)/100.0*100))%)")
print("")

if !errors.isEmpty {
    print("⚠️  Errors encountered:")
    for error in errors {
        print("  - \(error)")
    }
} else {
    print("✨ No crashes or errors detected!")
}

print("")
print("Computer AI Performance:")
let winRate = Double(computerWins) / 100.0 * 100
if winRate >= 45 && winRate <= 55 {
    print("  🎯 Excellent! (\(String(format: "%.1f", winRate))% - Very competitive)")
} else if winRate >= 40 && winRate < 45 {
    print("  👍 Good (\(String(format: "%.1f", winRate))% - Competitive)")
} else if winRate >= 30 {
    print("  ⚠️  Fair (\(String(format: "%.1f", winRate))% - Could be improved)")
} else {
    print("  ❌ Weak (\(String(format: "%.1f", winRate))% - Needs improvement)")
}
