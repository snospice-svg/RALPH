import SwiftUI

struct ProfileCreationFlowView: View {
    let onProfileCreated: (UserProfile) -> Void
    let onSkip: () -> Void

    @State private var currentStep = 0
    @State private var selectedLanguage = "en"
    @State private var selectedDietaryTags: Set<String> = []
    @State private var spiderChartValues = SpiderDimension.defaultValues
    @State private var foodPhilosophy = ""
    @State private var favoriteCuisines: [String] = []
    @State private var favoriteDishes: [String] = []
    @State private var favoriteRestaurants: [String] = []
    @State private var newCuisine = ""
    @State private var newDish = ""
    @State private var newRestaurant = ""

    private let totalSteps = 5

    var body: some View {
        NavigationView {
            VStack {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Button("Skip") {
                            onSkip()
                        }
                        .foregroundColor(.blue)

                        Spacer()

                        Text("Create Profile")
                            .font(.headline)

                        Spacer()

                        Text("\(currentStep + 1) of \(totalSteps)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Progress indicator
                    ProgressView(value: Double(currentStep), total: Double(totalSteps - 1))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
                .padding()

                // Content
                TabView(selection: $currentStep) {
                    LanguageStep(selectedLanguage: $selectedLanguage)
                        .tag(0)

                    DietaryTagsStep(selectedTags: $selectedDietaryTags)
                        .tag(1)

                    SpiderChartStep(values: $spiderChartValues)
                        .tag(2)

                    FoodPhilosophyStep(philosophy: $foodPhilosophy)
                        .tag(3)

                    FavoritesStep(
                        cuisines: $favoriteCuisines,
                        dishes: $favoriteDishes,
                        restaurants: $favoriteRestaurants,
                        newCuisine: $newCuisine,
                        newDish: $newDish,
                        newRestaurant: $newRestaurant
                    )
                    .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    }

                    Spacer()

                    if currentStep < totalSteps - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                    } else {
                        Button("Complete Profile") {
                            createProfile()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }

    private func createProfile() {
        let profile = UserProfile(
            email: "", // Will be set during account creation
            spiderChartValues: spiderChartValues,
            dietaryTags: Array(selectedDietaryTags),
            foodPhilosophy: foodPhilosophy,
            favoriteCuisines: favoriteCuisines,
            favoriteDishes: favoriteDishes,
            favoriteRestaurants: favoriteRestaurants,
            defaultMenuLanguage: selectedLanguage
        )

        onProfileCreated(profile)
    }
}

struct AccountCreationFlowView: View {
    let onAccountCreated: () -> Void
    let onSkip: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @StateObject private var authService = AuthenticationService.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                HStack {
                    Button("Skip") {
                        onSkip()
                    }
                    .foregroundColor(.blue)

                    Spacer()
                }
                .padding()

                Spacer()

                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Save Your Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Create an account to save your taste profile and get recommendations wherever you go")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)

                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(isLoading)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)

                            SecureField("Enter password (min 6 characters)", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(isLoading)

                            if !password.isEmpty && password.count < 6 {
                                Text("Password must be at least 6 characters")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }

                    VStack(spacing: 16) {
                        Button(action: createAccount) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Text("Create Account & Save Profile")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canCreateAccount ? Color.blue : Color.gray)
                            .cornerRadius(12)
                        }
                        .disabled(!canCreateAccount || isLoading)

                        Button("Continue Without Account") {
                            onSkip()
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)

                        Text("By creating an account, you agree to our terms of service and privacy policy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }

    private var canCreateAccount: Bool {
        !email.isEmpty && password.count >= 6
    }

    private func createAccount() {
        guard canCreateAccount else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Create a temporary profile for account creation
                let tempProfile = UserProfile(email: email)
                try await authService.signUp(email: email, password: password, profile: tempProfile)

                await MainActor.run {
                    isLoading = false
                    onAccountCreated()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ProfileCreationFlowView(
        onProfileCreated: { _ in },
        onSkip: { }
    )
}