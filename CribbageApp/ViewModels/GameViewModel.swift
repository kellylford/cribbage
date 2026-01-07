import Foundation
import Combine

class GameViewModel: ObservableObject {
    @Published var player: Player
    @Published var computer: Player
    @Published var gameState: GameState = .cutForDeal
    @Published var messages: [String] = []
    @Published var crib: [Card] = []
    @Published var cutCard: Card?
    @Published var dealer: Player?
    @Published var currentTurn: Player?
    @Published var playedPile: [PlayedCard] = []
    @Published var currentCount: Int = 0
    @Published var selectedForDiscard: Set<Card> = []
    @Published var lastWinner: Player?
    
    private var deck: Deck = Deck()
    private let winningScore = 121
    
    init() {
        self.player = Player(name: "Player", isComputer: false)
        self.computer = Player(name: "Computer", isComputer: true)
    }
    
    // MARK: - Game Flow
    
    func startNewGame() {
        player.score = 0
        computer.score = 0
        messages.removeAll()
        
        if let winner = lastWinner {
            dealer = winner
            addMessage("New game started. \(winner.name) won the last game and gets the first crib.")
            startRound()
        } else {
            gameState = .cutForDeal
            addMessage("New game started. Tap Cut for Deal to begin.")
        }
    }
    
    func cutForDeal() {
        guard gameState == .cutForDeal else { return }
        
        let deck1 = Deck()
        let deck2 = Deck()
        
        guard let playerCut = deck1.deal(), let computerCut = deck2.deal() else { return }
        
        addMessage("You cut: \(playerCut.name)")
        addMessage("Computer cut: \(computerCut.name)")
        
        if playerCut.value < computerCut.value {
            dealer = player
            addMessage("You are the dealer!")
        } else if computerCut.value < playerCut.value {
            dealer = computer
            addMessage("Computer is the dealer.")
        } else {
            addMessage("Tie! Cut again.")
            return
        }
        
        startRound()
    }
    
    func startRound() {
        player.resetHand()
        computer.resetHand()
        crib.removeAll()
        cutCard = nil
        playedPile.removeAll()
        currentCount = 0
        selectedForDiscard.removeAll()
        
        deck.reset()
        
        // Deal 6 cards to each player
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
        
        gameState = .discard
        addMessage("Deal complete. Select 2 cards to discard to the crib.")
        addMessage(dealer === player ? "Player's crib." : "Computer's crib.")
    }
    
    func discardToCrib() {
        guard gameState == .discard else { return }
        guard selectedForDiscard.count == 2 else { return }
        
        // Player discards
        for card in selectedForDiscard {
            if let removed = player.removeCard(card) {
                crib.append(removed)
            }
        }
        selectedForDiscard.removeAll()
        
        // Computer discards
        let computerDiscards = selectComputerDiscard()
        for card in computerDiscards {
            if let removed = computer.removeCard(card) {
                crib.append(removed)
            }
        }
        
        // Cut card
        if let cut = deck.deal() {
            cutCard = cut
            addMessage("Cut card: \(cut.name)")
            
            // Check for his heels (Jack cut)
            if cut.rank == .jack, let dealer = dealer {
                dealer.score += 2
                addMessage("\(dealer.name) scores 2 for his heels!")
                if checkForWinner() {
                    return
                }
            }
        }
        
        // Start play phase
        gameState = .play
        currentTurn = dealer === player ? computer : player
        addMessage("\(currentTurn?.name ?? "") plays first.")
        
        // Computer plays first if it's their turn
        if currentTurn === computer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.computerPlay()
            }
        }
    }
    
    func playCard(_ card: Card, player: Player) -> Bool {
        guard gameState == .play else { return false }
        guard currentTurn === player else { return false }
        guard !player.playedCards.contains(card) else { return false }
        guard currentCount + card.value <= 31 else { return false }
        
        _ = player.playCard(card)
        playedPile.append(PlayedCard(card: card, playerName: player.name, isComputer: player.isComputer))
        currentCount += card.value
        
        let points = scorePlay(card: card, player: player)
        
        // Combine play and scoring into one announcement for better VoiceOver experience
        var announcement = "\(player.name) plays \(card.name). Count: \(currentCount)."
        if points > 0 {
            player.score += points
            announcement += " Scores \(points)."
            if checkForWinner() {
                return true
            }
        }
        
        addMessage(announcement)
        
        // If 31, pause
        if currentCount == 31 {
            switchTurn()
            gameState = .pause31
            addMessage("Count of 31 reached. Tap Continue to resume play.")
            return true
        }
        
        switchTurn()
        return true
    }
    
    func sayGo() {
        guard let current = currentTurn else { return }
        guard !canPlay(player: current) else { return }
        
        addMessage("\(current.name) says Go.")
        
        let opponent = current === player ? computer : player
        
        if !canPlay(player: opponent) {
            // Both players can't play - award go point
            if let lastPlayed = playedPile.last {
                let lastPlayer = lastPlayed.isComputer ? computer : player
                lastPlayer.score += 1
                addMessage("\(lastPlayer.name) scores 1 for go.")
                
                if checkForWinner() {
                    return
                }
            }
            
            gameState = .pauseGo
            addMessage("Go scored. Tap Continue to resume play.")
            
            // Player who said go first leads next
            if let lastPlayed = playedPile.last {
                let lastPlayer = lastPlayed.isComputer ? computer : player
                currentTurn = lastPlayer === player ? computer : player
            }
        } else {
            // Opponent can play, switch to them
            currentTurn = opponent
            
            // If opponent is computer, trigger their play
            if opponent === computer {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.computerPlay()
                }
            }
        }
    }
    
    func continueAfterPause() {
        if gameState == .pause31 || gameState == .pauseGo {
            currentCount = 0
            playedPile.removeAll()
            
            if checkPlayComplete() {
                endPlay()
            } else {
                gameState = .play
                addMessage("Count reset to 0.")
                
                if currentTurn === computer {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.computerPlay()
                    }
                }
            }
        }
    }
    
    // MARK: - Computer AI
    
    func computerPlay() {
        guard currentTurn === computer else { return }
        guard gameState == .play else { return }
        
        let playableCards = computer.hand.filter { card in
            !computer.playedCards.contains(card) && currentCount + card.value <= 31
        }
        
        if playableCards.isEmpty {
            sayGo()
            // Note: sayGo will trigger computer play again if needed
            return
        }
        
        // Simple AI: prioritize making 15 or 31, then pairs, then lowest card
        let bestCard = selectBestPlayCard(playableCards)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            _ = self.playCard(bestCard, player: self.computer)
            
            // Continue computer's turn if needed
            if self.currentTurn === self.computer && self.gameState == .play {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.computerPlay()
                }
            }
        }
    }
    
    private func selectBestPlayCard(_ cards: [Card]) -> Card {
        // Enhanced strategy with lookahead thinking for pegging phase
        if cards.count == 1 {
            return cards[0]
        }
        
        var bestCard = cards[0]
        var bestScore = -999.0
        
        for card in cards {
            var score = 0.0
            let newCount = currentCount + card.value
            
            // 1. IMMEDIATE SCORING (make 15 or 31)
            if newCount == 15 {
                score += 20 // Worth 2 points
            }
            if newCount == 31 {
                score += 20 // Worth 2 points
            }
            
            // 2. LOOKAHEAD: Maintain flexibility
            let remainingHand = computer.hand.filter { $0 != card && !computer.playedCards.contains($0) }
            let futurePlayable = remainingHand.filter { $0.value + newCount <= 31 }.count
            
            // Penalize plays that leave us with no follow-up
            if futurePlayable == 0 && newCount < 31 {
                score -= 10 // We'll be forced to say "Go"
            } else {
                score += Double(futurePlayable) * 2 // Reward flexibility
            }
            
            // 3. AVOID SETTING UP OPPONENT
            let opponentHand = player.hand.filter { !player.playedCards.contains($0) }
            
            // Can opponent make 31?
            if opponentHand.contains(where: { newCount + $0.value == 31 }) {
                score -= 15 // Very dangerous
            }
            
            // Can opponent make 15?
            if opponentHand.contains(where: { newCount + $0.value == 15 }) {
                score -= 8 // Dangerous
            }
            
            // Does opponent have pair card?
            if opponentHand.contains(where: { $0.rank == card.rank }) {
                score -= 5 // Moderate danger
            }
            
            // 4. PRESERVE HIGH CARDS FOR LATER
            let percentOfMax = Double(newCount) / 31.0
            if percentOfMax < 0.6 && card.value >= 10 {
                score -= 3 // Wasteful to use high cards early
            }
            
            // 5. PREFER LOWER CARDS WHEN NOT SCORING
            if newCount != 15 && newCount != 31 {
                score -= Double(card.value) / 10.0 // Small tiebreaker
            }
            
            if score > bestScore {
                bestScore = score
                bestCard = card
            }
        }
        
        return bestCard
    }
    
    private func selectComputerDiscard() -> [Card] {
        // Evaluate all possible 2-card discard combinations
        var bestDiscards: [Card] = []
        var bestScore = Double.infinity
        
        let hand = computer.hand
        for i in 0..<hand.count {
            for j in (i+1)..<hand.count {
                let discardPair = [hand[i], hand[j]]
                let remainingCards = hand.filter { !discardPair.contains($0) }
                
                // Score the remaining hand (fifteens and pairs)
                var handScore = 0.0
                for card in remainingCards {
                    for other in remainingCards {
                        if card != other && card.value + other.value == 15 {
                            handScore += 2
                        }
                    }
                }
                
                // Score the crib (fifteens and pairs in discarded cards)
                let cribScore = estimateCribScore(discardPair)
                
                // If computer owns the crib, weight it (it's an advantage)
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
    
    private func estimateCribScore(_ cards: [Card]) -> Double {
        var score = 0.0
        
        // Check for fifteens
        if cards[0].value + cards[1].value == 15 {
            score += 2
        }
        
        // Check for pairs
        if cards[0].rank == cards[1].rank {
            score += 2
        }
        
        return score
    }
    
    private func estimateHandValue(_ cards: [Card]) -> Int {
        var score = 0
        
        // Count 15s
        for i in 0..<cards.count {
            if cards[i].value == 15 { score += 2 }
            for j in (i+1)..<cards.count {
                if cards[i].value + cards[j].value == 15 { score += 2 }
                for k in (j+1)..<cards.count {
                    if cards[i].value + cards[j].value + cards[k].value == 15 { score += 2 }
                    for l in (k+1)..<cards.count {
                        if cards[i].value + cards[j].value + cards[k].value + cards[l].value == 15 {
                            score += 2
                        }
                    }
                }
            }
        }
        
        // Count pairs
        for i in 0..<cards.count {
            for j in (i+1)..<cards.count {
                if cards[i].rank == cards[j].rank {
                    score += 2
                }
            }
        }
        
        return score
    }
    
    // MARK: - Scoring
    
    private func scorePlay(card: Card, player: Player) -> Int {
        var points = 0
        var messages: [String] = []
        
        // 15
        if currentCount == 15 {
            points += 2
            messages.append("15 for 2")
        }
        
        // 31
        if currentCount == 31 {
            points += 2
            messages.append("31 for 2")
        }
        
        // Pairs, three of a kind, four of a kind
        let recentCards = playedPile.suffix(4).map { $0.card }
        if recentCards.count >= 2 {
            var pairCount = 1
            for i in stride(from: recentCards.count - 2, through: 0, by: -1) {
                if recentCards[i].rank == card.rank {
                    pairCount += 1
                } else {
                    break
                }
            }
            
            if pairCount == 2 {
                points += 2
                messages.append("Pair for 2")
            } else if pairCount == 3 {
                points += 6
                messages.append("Three of a kind for 6")
            } else if pairCount == 4 {
                points += 12
                messages.append("Four of a kind for 12")
            }
        }
        
        // Runs (3 or more cards in sequence)
        if recentCards.count >= 3 {
            for len in stride(from: recentCards.count, through: 3, by: -1) {
                let checkCards = Array(recentCards.suffix(len))
                if isRun(checkCards) {
                    points += len
                    messages.append("Run of \(len) for \(len)")
                    break
                }
            }
        }
        
        if !messages.isEmpty {
            // Don't add message here - it will be combined with the play announcement
            // Just return the points
        }
        
        return points
    }
    
    private func isRun(_ cards: [Card]) -> Bool {
        let values = cards.map { $0.rankValue }.sorted()
        
        for i in 1..<values.count {
            if values[i] != values[i - 1] + 1 {
                return false
            }
        }
        return true
    }
    
    func scoreHand(_ hand: [Card], cutCard: Card, isCrib: Bool) -> (points: Int, details: [ScoringDetail]) {
        var points = 0
        var details: [ScoringDetail] = []
        let allCards = hand + [cutCard]
        
        // Fifteens
        let fifteens = countFifteens(allCards)
        if fifteens > 0 {
            points += fifteens * 2
            details.append(ScoringDetail(description: "\(fifteens) fifteen\(fifteens > 1 ? "s" : "")", points: fifteens * 2))
        }
        
        // Pairs
        let pairs = countPairs(allCards)
        if pairs > 0 {
            points += pairs * 2
            details.append(ScoringDetail(description: "\(pairs) pair\(pairs > 1 ? "s" : "")", points: pairs * 2))
        }
        
        // Runs
        if let runScore = longestRun(allCards) {
            points += runScore
            details.append(ScoringDetail(description: "Run", points: runScore))
        }
        
        // Flush
        let flushScore = scoreFlush(hand: hand, cutCard: cutCard, isCrib: isCrib)
        if flushScore > 0 {
            points += flushScore
            details.append(ScoringDetail(description: "Flush", points: flushScore))
        }
        
        // Nobs (Jack of same suit as cut card)
        if hand.contains(where: { $0.rank == .jack && $0.suit == cutCard.suit }) {
            points += 1
            details.append(ScoringDetail(description: "Nobs", points: 1))
        }
        
        return (points, details)
    }
    
    private func countFifteens(_ cards: [Card]) -> Int {
        var count = 0
        
        // Check all combinations
        for i in 0..<cards.count {
            if cards[i].value == 15 { count += 1 }
            for j in (i+1)..<cards.count {
                if cards[i].value + cards[j].value == 15 { count += 1 }
                for k in (j+1)..<cards.count {
                    if cards[i].value + cards[j].value + cards[k].value == 15 { count += 1 }
                    for l in (k+1)..<cards.count {
                        if cards[i].value + cards[j].value + cards[k].value + cards[l].value == 15 {
                            count += 1
                        }
                        for m in (l+1)..<cards.count {
                            if cards[i].value + cards[j].value + cards[k].value + cards[l].value + cards[m].value == 15 {
                                count += 1
                            }
                        }
                    }
                }
            }
        }
        
        return count
    }
    
    private func countPairs(_ cards: [Card]) -> Int {
        var count = 0
        for i in 0..<cards.count {
            for j in (i+1)..<cards.count {
                if cards[i].rank == cards[j].rank {
                    count += 1
                }
            }
        }
        return count
    }
    
    private func longestRun(_ cards: [Card]) -> Int? {
        // Check for runs of 5, 4, then 3
        for length in stride(from: 5, through: 3, by: -1) {
            if let runScore = findRuns(cards, length: length) {
                return runScore
            }
        }
        return nil
    }
    
    private func findRuns(_ cards: [Card], length: Int) -> Int? {
        guard length <= cards.count else { return nil }
        
        var runCount = 0
        let indices = Array(0..<cards.count)
        
        func combinations(_ arr: [Int], _ k: Int) -> [[Int]] {
            guard k > 0 else { return [[]] }
            guard !arr.isEmpty else { return [] }
            
            let head = arr[0]
            let tail = Array(arr.dropFirst())
            
            let withHead = combinations(tail, k - 1).map { [head] + $0 }
            let withoutHead = combinations(tail, k)
            
            return withHead + withoutHead
        }
        
        for combo in combinations(indices, length) {
            let subset = combo.map { cards[$0] }
            let ranks = subset.map { $0.rankValue }.sorted()
            
            var isRun = true
            for i in 1..<ranks.count {
                if ranks[i] != ranks[i-1] + 1 {
                    isRun = false
                    break
                }
            }
            
            if isRun {
                runCount += 1
            }
        }
        
        return runCount > 0 ? runCount * length : nil
    }
    
    private func scoreFlush(hand: [Card], cutCard: Card, isCrib: Bool) -> Int {
        let handSuit = hand[0].suit
        let allSameSuit = hand.allSatisfy { $0.suit == handSuit }
        
        if !allSameSuit {
            return 0
        }
        
        // In crib, all 5 cards must be same suit
        if isCrib {
            return cutCard.suit == handSuit ? 5 : 0
        }
        
        // In hand, 4 cards get 4 points, all 5 get 5 points
        return cutCard.suit == handSuit ? 5 : 4
    }
    
    func countHands() {
        guard let cutCard = cutCard else { return }
        
        gameState = .counting
        
        // Non-dealer counts first
        let nonDealer = dealer === player ? computer : player
        let (ndPoints, ndDetails) = scoreHand(nonDealer.hand, cutCard: cutCard, isCrib: false)
        
        addMessage("\n\(nonDealer.name)'s hand:")
        for detail in ndDetails {
            addMessage("  \(detail.description): \(detail.points)")
        }
        addMessage("Total: \(ndPoints)")
        
        nonDealer.score += ndPoints
        if checkForWinner() { return }
        
        // Dealer counts
        let (dPoints, dDetails) = scoreHand(dealer!.hand, cutCard: cutCard, isCrib: false)
        
        addMessage("\n\(dealer!.name)'s hand:")
        for detail in dDetails {
            addMessage("  \(detail.description): \(detail.points)")
        }
        addMessage("Total: \(dPoints)")
        
        dealer!.score += dPoints
        if checkForWinner() { return }
        
        // Crib
        let (cPoints, cDetails) = scoreHand(crib, cutCard: cutCard, isCrib: true)
        
        addMessage("\n\(dealer!.name)'s crib:")
        for detail in cDetails {
            addMessage("  \(detail.description): \(detail.points)")
        }
        addMessage("Total: \(cPoints)")
        
        dealer!.score += cPoints
        if checkForWinner() { return }
        
        // Next round
        dealer = dealer === player ? computer : player
        addMessage("\nNext round - \(dealer!.name) is dealer")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startRound()
        }
    }
    
    // MARK: - Helper Methods
    
    private func switchTurn() {
        currentTurn = currentTurn === player ? computer : player
    }
    
    private func canPlay(player: Player) -> Bool {
        return player.hand.contains { card in
            !player.playedCards.contains(card) && currentCount + card.value <= 31
        }
    }
    
    private func checkPlayComplete() -> Bool {
        // Each player should have played all 4 cards (6 dealt - 2 discarded to crib)
        return player.playedCards.count == 4 &&
               computer.playedCards.count == 4
    }
    
    private func endPlay() {
        // Award last card point if not already at 31
        if currentCount != 31, let lastPlayed = playedPile.last {
            let lastPlayer = lastPlayed.isComputer ? computer : player
            lastPlayer.score += 1
            addMessage("\(lastPlayer.name) scores 1 for last card.")
            
            if checkForWinner() {
                return
            }
        }
        
        // Move to counting
        player.clearPlayedCards()
        computer.clearPlayedCards()
        
        // Restore hands from played pile
        for played in playedPile {
            if played.isComputer {
                computer.addCard(played.card)
            } else {
                player.addCard(played.card)
            }
        }
        
        countHands()
    }
    
    private func checkForWinner() -> Bool {
        if player.score >= winningScore {
            gameState = .gameOver
            lastWinner = player
            addMessage("\n🎉 You win! Final score: \(player.score) to \(computer.score)")
            return true
        } else if computer.score >= winningScore {
            gameState = .gameOver
            lastWinner = computer
            addMessage("\n💻 Computer wins! Final score: \(computer.score) to \(player.score)")
            return true
        }
        return false
    }
    
    private func addMessage(_ message: String) {
        messages.append(message)
    }
    
    func toggleCardSelection(_ card: Card) {
        if selectedForDiscard.contains(card) {
            selectedForDiscard.remove(card)
        } else if selectedForDiscard.count < 2 {
            selectedForDiscard.insert(card)
        }
    }
}
