import SwiftUI

struct ScoreboardView: View {
    let playerScore: Int
    let computerScore: Int
    let winningScore: Int = 121
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Scoreboard")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            HStack(spacing: 20) {
                // Player Score
                VStack(spacing: 4) {
                    Text("You")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 70, height: 70)
                        
                        Text("\(playerScore)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: min(geometry.size.width * CGFloat(playerScore) / CGFloat(winningScore), geometry.size.width), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Your score: \(playerScore) out of \(winningScore)")
                
                // Computer Score
                VStack(spacing: 4) {
                    Text("Computer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 70, height: 70)
                        
                        Text("\(computerScore)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.red)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: min(geometry.size.width * CGFloat(computerScore) / CGFloat(winningScore), geometry.size.width), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Computer score: \(computerScore) out of \(winningScore)")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ScoreboardView_Previews: PreviewProvider {
    static var previews: some View {
        ScoreboardView(playerScore: 45, computerScore: 38)
            .padding()
    }
}
