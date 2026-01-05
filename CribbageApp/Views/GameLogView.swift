import SwiftUI

struct GameLogView: View {
    let messages: [String]
    @AccessibilityFocusState private var focusedMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Game Log")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                if !messages.isEmpty {
                    Button("Clear") {
                        // This would clear messages - handled by parent
                    }
                    .font(.caption)
                    .accessibilityLabel("Clear game log")
                }
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(messages.enumerated().reversed()), id: \.offset) { index, message in
                            Text(message)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding(.vertical, 2)
                                .id(index)
                                .accessibilityLabel(message)
                                .accessibilityAddTraits(.isStaticText)
                                .accessibilityFocused($focusedMessage, equals: message)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 200)
                .onChange(of: messages.count) { _ in
                    if let lastIndex = messages.indices.last {
                        withAnimation {
                            proxy.scrollTo(lastIndex, anchor: .top)
                        }
                        // Capture the message immediately to avoid announcing wrong message
                        let messageToAnnounce = messages.last
                        
                        // Announce to VoiceOver with slight delay for UI update
                        if let message = messageToAnnounce {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                UIAccessibility.post(notification: .announcement, argument: message)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct GameLogView_Previews: PreviewProvider {
    static var previews: some View {
        GameLogView(messages: [
            "New game started.",
            "You cut: Ace of Hearts",
            "Computer cut: King of Spades",
            "Computer is the dealer.",
            "Deal complete. Select 2 cards to discard to the crib."
        ])
        .padding()
    }
}
