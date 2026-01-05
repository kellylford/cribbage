import SwiftUI

@main
struct CribbageApp: App {
    @StateObject private var game = GameViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                .preferredColorScheme(.light)
        }
    }
}
