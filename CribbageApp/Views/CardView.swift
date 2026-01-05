import SwiftUI

struct CardView: View {
    let card: Card
    let isSelected: Bool
    let isPlayable: Bool
    let action: () -> Void
    
    var cardColor: Color {
        card.isRed ? Color.red : Color.black
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: isSelected ? .blue.opacity(0.6) : .gray.opacity(0.3), 
                           radius: isSelected ? 8 : 3,
                           x: 0, y: isSelected ? 3 : 2)
                
                // Selected border
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.4), 
                                 lineWidth: isSelected ? 4 : 1.5)
                
                // Card content
                VStack(spacing: 2) {
                    // Top rank and suit
                    VStack(spacing: 0) {
                        Text(card.rank.rawValue)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(cardColor)
                        
                        Text(card.suit.rawValue)
                            .font(.system(size: 16))
                            .foregroundColor(cardColor)
                    }
                    
                    Spacer()
                    
                    // Center suit symbols
                    Text(card.suit.rawValue)
                        .font(.system(size: 28))
                        .foregroundColor(cardColor.opacity(0.3))
                    
                    Spacer()
                    
                    // Bottom rank and suit (upside down)
                    VStack(spacing: 0) {
                        Text(card.suit.rawValue)
                            .font(.system(size: 16))
                            .foregroundColor(cardColor)
                        
                        Text(card.rank.rawValue)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(cardColor)
                    }
                    .rotationEffect(.degrees(180))
                }
                .padding(6)
            }
            .frame(width: 65, height: 92)
            .opacity(isPlayable ? 1.0 : 0.5)
        }
        .accessibilityLabel(card.name)
        .accessibilityHint(isPlayable ? (isSelected ? "Selected. Tap to deselect" : "Tap to select") : "Not playable")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityValue(isSelected ? "selected" : "not selected")
        .disabled(!isPlayable)
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            CardView(card: Card(rank: .ace, suit: .hearts), isSelected: false, isPlayable: true, action: {})
            CardView(card: Card(rank: .king, suit: .spades), isSelected: true, isPlayable: true, action: {})
            CardView(card: Card(rank: .five, suit: .diamonds), isSelected: false, isPlayable: false, action: {})
        }
        .padding()
    }
}
