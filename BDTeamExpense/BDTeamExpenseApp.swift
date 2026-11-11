import SwiftUI

@main
struct BDTeamExpenseApp: App {
    var body: some Scene {
        WindowGroup {
            WebScreen()
                .ignoresSafeArea()
                .background(Color(red: 11 / 255, green: 93 / 255, blue: 75 / 255).ignoresSafeArea())
        }
    }
}
