import SwiftUI

struct RulesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("How to Play Cribbage")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                
                ruleSection(title: "Objective", content: "Be the first player to reach 121 points.")
                
                ruleSection(title: "Setup", content: """
                    • Each player is dealt 6 cards
                    • Players discard 2 cards each to the "crib"
                    • The crib belongs to the dealer
                    • A card is cut from the deck as the "starter"
                    """)
                
                ruleSection(title: "The Play", content: """
                    • Players alternate playing cards face-up
                    • Each card adds to a running count
                    • Count cannot exceed 31
                    • Score points for:
                      - Making 15: 2 points
                      - Making 31: 2 points
                      - Pairs: 2 points each
                      - Runs of 3+: 1 point per card
                    • When unable to play, say "Go"
                    • Last player to play gets 1 point
                    """)
                
                ruleSection(title: "The Show", content: """
                    After all cards are played, hands are counted:
                    
                    • Fifteens: 2 points each
                      (Any combination totaling 15)
                    
                    • Pairs: 2 points each
                      (3 of a kind = 6, 4 of a kind = 12)
                    
                    • Runs: 1 point per card
                      (3 or more consecutive ranks)
                    
                    • Flush: 4 or 5 points
                      (All cards same suit)
                    
                    • Nobs: 1 point
                      (Jack matching starter suit)
                    
                    • His Heels: 2 points
                      (Dealer when starter is a Jack)
                    """)
                
                ruleSection(title: "Card Values", content: """
                    • Ace = 1
                    • 2-10 = Face value
                    • Jack, Queen, King = 10
                    """)
                
                ruleSection(title: "Order of Counting", content: """
                    1. Non-dealer's hand
                    2. Dealer's hand
                    3. Dealer's crib
                    """)
                
                Text("Good luck and have fun!")
                    .font(.headline)
                    .padding(.top)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding()
        }
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func ruleSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .bold()
                .accessibilityAddTraits(.isHeader)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct RulesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RulesView()
        }
    }
}
