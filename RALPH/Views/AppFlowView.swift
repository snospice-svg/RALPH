import SwiftUI

struct AppFlowView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var currentFlow: AppFlow = .welcome

    enum AppFlow {
        case welcome
        case menuAnalysis
        case profileCreation
        case accountCreation
        case main
    }

    var body: some View {
        Group {
            switch currentFlow {
            case .welcome:
                WelcomeFlowView(onContinue: {
                    currentFlow = .menuAnalysis
                })

            case .menuAnalysis:
                MenuAnalysisFlowView(
                    onRecommendationsGenerated: { _ in
                        currentFlow = .profileCreation
                    }
                )

            case .profileCreation:
                ProfileCreationFlowView(
                    onProfileCreated: { profile in
                        // Store the profile temporarily
                        currentFlow = .accountCreation
                    },
                    onSkip: {
                        authService.skipAccountCreation()
                        currentFlow = .main
                    }
                )

            case .accountCreation:
                AccountCreationFlowView(
                    onAccountCreated: {
                        authService.completeOnboarding()
                        currentFlow = .main
                    },
                    onSkip: {
                        authService.skipAccountCreation()
                        currentFlow = .main
                    }
                )

            case .main:
                MainTabView()
            }
        }
        .onAppear {
            setupInitialFlow()
        }
    }

    private func setupInitialFlow() {
        if authService.hasCompletedOnboarding || authService.isAuthenticated {
            currentFlow = .main
        } else {
            currentFlow = .welcome
        }
    }
}

struct WelcomeFlowView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("RALPH")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)

                Text("Restaurant Analysis & Learning\nProtocol for Hospitality")
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 20) {
                FeatureRow(icon: "camera.fill", title: "Smart Menu Analysis", description: "Upload menu photos and get instant translations and insights")

                FeatureRow(icon: "person.fill", title: "Personalized Recommendations", description: "Get dish suggestions based on your unique taste profile")

                FeatureRow(icon: "chart.pie.fill", title: "Taste Mapping", description: "Discover your flavor preferences with our interactive chart")
            }

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct MenuAnalysisFlowView: View {
    let onRecommendationsGenerated: ([MenuItem]) -> Void
    @State private var showingMenuUpload = true
    @State private var showingRecommendations = false
    @State private var mockRecommendations: [MenuItem] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !showingRecommendations {
                    VStack(spacing: 24) {
                        Text("Upload Your Menu")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Take a photo or select an image of the restaurant menu you'd like analyzed")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        VStack(spacing: 16) {
                            Button(action: {
                                // Simulate menu analysis
                                generateMockRecommendations()
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 32))
                                    Text("Take Photo")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }

                            Button(action: {
                                // Simulate menu analysis
                                generateMockRecommendations()
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 32))
                                    Text("Choose from Library")
                                        .font(.headline)
                                }
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }

                            Button(action: {
                                // Skip to mock recommendations for demo
                                generateMockRecommendations()
                            }) {
                                Text("Use Demo Menu")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                        }
                    }
                } else {
                    RecommendationsView(
                        recommendations: mockRecommendations,
                        onContinue: {
                            onRecommendationsGenerated(mockRecommendations)
                        }
                    )
                }

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }

    private func generateMockRecommendations() {
        // Mock recommendations for demo
        mockRecommendations = [
            MenuItem(
                id: UUID(),
                name: "Margherita Pizza",
                description: "Fresh tomatoes, mozzarella, basil",
                price: "$18.00",
                category: "Pizza",
                dietaryTags: ["Vegetarian"],
                spiceLevel: 1,
                matchScore: 95
            ),
            MenuItem(
                id: UUID(),
                name: "Caesar Salad",
                description: "Romaine lettuce, parmesan, croutons",
                price: "$14.00",
                category: "Salads",
                dietaryTags: ["Vegetarian"],
                spiceLevel: 0,
                matchScore: 87
            ),
            MenuItem(
                id: UUID(),
                name: "Grilled Salmon",
                description: "Atlantic salmon, lemon herbs, seasonal vegetables",
                price: "$26.00",
                category: "Seafood",
                dietaryTags: ["Gluten-free"],
                spiceLevel: 2,
                matchScore: 82
            )
        ]

        withAnimation {
            showingRecommendations = true
        }
    }
}

struct RecommendationsView: View {
    let recommendations: [MenuItem]
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("Your Recommendations")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Based on general preferences, here are some dishes we think you'll enjoy:")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recommendations) { item in
                        RecommendationCard(item: item)
                    }
                }
                .padding()
            }

            VStack(spacing: 12) {
                Text("Want better recommendations?")
                    .font(.headline)
                    .foregroundColor(.blue)

                Text("Create a taste profile to get personalized suggestions tailored just for you!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: onContinue) {
                    Text("Create Taste Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
    }
}

struct RecommendationCard: View {
    let item: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.headline)

                    Text(item.displayDescription)
                        .font(.body)
                        .foregroundColor(.secondary)

                    HStack {
                        Text(item.formattedPrice)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)

                        Spacer()

                        Text("\(item.matchScore)% match")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                    }
                }

                Spacer()

                VStack(spacing: 4) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < item.spiceLevel ? "flame.fill" : "flame")
                            .foregroundColor(star < item.spiceLevel ? .red : .gray.opacity(0.3))
                            .font(.caption)
                    }
                }
            }

            if !item.dietaryTags.isEmpty {
                HStack {
                    ForEach(item.dietaryTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}