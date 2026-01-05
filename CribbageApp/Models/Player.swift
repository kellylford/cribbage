import Foundation

class Player: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    let isComputer: Bool
    
    @Published var hand: [Card] = []
    @Published var playedCards: [Card] = []
    @Published var score: Int = 0
    
    init(name: String, isComputer: Bool = false) {
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
    
    func playCard(_ card: Card) -> Card? {
        if let removed = removeCard(card) {
            playedCards.append(removed)
            return removed
        }
        return nil
    }
    
    func clearPlayedCards() {
        playedCards.removeAll()
    }
    
    func resetHand() {
        hand.removeAll()
        playedCards.removeAll()
    }
    
    func sortHand() {
        hand.sort { $0.rankValue < $1.rankValue }
    }
}
