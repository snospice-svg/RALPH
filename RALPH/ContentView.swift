import SwiftUI

struct ContentView: View {
    @State private var showingOnboarding = true

    var body: some View {
        Group {
            if showingOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}

#Preview {
    ContentView()
}