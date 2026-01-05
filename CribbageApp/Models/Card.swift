import Foundation

enum Suit: String, CaseIterable, Codable {
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"
    case spades = "♠"
    
    var name: String {
        switch self {
        case .hearts: return "Hearts"
        case .diamonds: return "Diamonds"
        case .clubs: return "Clubs"
        case .spades: return "Spades"
        }
    }
    
    var isRed: Bool {
        self == .hearts || self == .diamonds
    }
}

enum Rank: String, CaseIterable, Codable {
    case ace = "A"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case ten = "10"
    case jack = "J"
    case queen = "Q"
    case king = "K"
    
    var name: String {
        switch self {
        case .ace: return "Ace"
        case .two: return "Two"
        case .three: return "Three"
        case .four: return "Four"
        case .five: return "Five"
        case .six: return "Six"
        case .seven: return "Seven"
        case .eight: return "Eight"
        case .nine: return "Nine"
        case .ten: return "Ten"
        case .jack: return "Jack"
        case .queen: return "Queen"
        case .king: return "King"
        }
    }
    
    // Value for counting (Ace=1, face cards=10)
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
    
    // Rank value for ordering (Ace=1, King=13)
    var rankValue: Int {
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
        case .ten: return 10
        case .jack: return 11
        case .queen: return 12
        case .king: return 13
        }
    }
}

struct Card: Identifiable, Equatable, Codable, Hashable {
    let id = UUID()
    let rank: Rank
    let suit: Suit
    
    var value: Int { rank.value }
    var rankValue: Int { rank.rankValue }
    
    var name: String {
        "\(rank.name) of \(suit.name)"
    }
    
    var displayString: String {
        "\(rank.rawValue)\(suit.rawValue)"
    }
    
    var isRed: Bool { suit.isRed }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.rank == rhs.rank && lhs.suit == rhs.suit
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(rank)
        hasher.combine(suit)
    }
}

class Deck {
    private var cards: [Card] = []
    
    init() {
        reset()
    }
    
    func reset() {
        cards = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(Card(rank: rank, suit: suit))
            }
        }
        shuffle()
    }
    
    func shuffle() {
        cards.shuffle()
    }
    
    func deal() -> Card? {
        cards.popLast()
    }
    
    var count: Int { cards.count }
}
