import Foundation

enum GameState {
    case cutForDeal
    case discard
    case play
    case pause31
    case pauseGo
    case counting
    case gameOver
}

struct PlayedCard: Identifiable {
    let id = UUID()
    let card: Card
    let playerName: String
    let isComputer: Bool
}

struct ScoringDetail {
    let description: String
    let points: Int
}
