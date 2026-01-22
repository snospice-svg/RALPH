import Foundation
import Combine

@MainActor
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()

    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var hasCompletedOnboarding = false

    private let keychainManager = KeychainManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkAuthenticationStatus()
    }

    private func checkAuthenticationStatus() {
        // Check if user has saved credentials
        isAuthenticated = keychainManager.hasUserCredentials

        if isAuthenticated {
            // Load user profile if available
            loadUserProfile()
        }

        // Check if onboarding was completed
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboarding_completed")
    }

    func signIn(email: String, password: String) async throws {
        // In a real app, this would authenticate with a server
        // For now, just validate basic requirements and store locally

        guard !email.isEmpty, password.count >= 6 else {
            throw AuthError.invalidCredentials
        }

        // Store credentials
        try keychainManager.saveUserCredentials(email: email, password: password)

        // Create user profile
        let profile = UserProfile(email: email)
        currentUser = profile

        // Save profile to UserDefaults (in a real app, this would be server-side)
        try saveUserProfile(profile)

        isAuthenticated = true
    }

    func signUp(email: String, password: String, profile: UserProfile) async throws {
        // In a real app, this would create account on server
        // For now, just validate and store locally

        guard !email.isEmpty, password.count >= 6 else {
            throw AuthError.invalidCredentials
        }

        // Store credentials
        try keychainManager.saveUserCredentials(email: email, password: password)

        // Update profile with email
        let updatedProfile = UserProfile(
            id: profile.id,
            email: email,
            createdAt: profile.createdAt,
            spiderChartValues: profile.spiderChartValues,
            dietaryTags: profile.dietaryTags,
            foodPhilosophy: profile.foodPhilosophy,
            favoriteCuisines: profile.favoriteCuisines,
            favoriteDishes: profile.favoriteDishes,
            favoriteRestaurants: profile.favoriteRestaurants,
            defaultMenuLanguage: profile.defaultMenuLanguage
        )
        currentUser = updatedProfile

        // Save profile
        try saveUserProfile(updatedProfile)

        isAuthenticated = true
    }

    func signOut() throws {
        try keychainManager.deleteUserCredentials()
        currentUser = nil
        isAuthenticated = false
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
    }

    func skipAccountCreation() {
        // Mark onboarding as complete without authentication
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
    }

    private func loadUserProfile() {
        // Load from UserDefaults (in a real app, this would be from server)
        if let data = UserDefaults.standard.data(forKey: "user_profile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = profile
        }
    }

    private func saveUserProfile(_ profile: UserProfile) throws {
        let data = try JSONEncoder().encode(profile)
        UserDefaults.standard.set(data, forKey: "user_profile")
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error. Please try again."
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

// Make UserProfile Codable
extension UserProfile: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, email, createdAt, spiderChartValues, dietaryTags, foodPhilosophy
        case favoriteCuisines, favoriteDishes, favoriteRestaurants, defaultMenuLanguage
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(spiderChartValues, forKey: .spiderChartValues)
        try container.encode(dietaryTags, forKey: .dietaryTags)
        try container.encode(foodPhilosophy, forKey: .foodPhilosophy)
        try container.encode(favoriteCuisines, forKey: .favoriteCuisines)
        try container.encode(favoriteDishes, forKey: .favoriteDishes)
        try container.encode(favoriteRestaurants, forKey: .favoriteRestaurants)
        try container.encode(defaultMenuLanguage, forKey: .defaultMenuLanguage)
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let email = try container.decode(String.self, forKey: .email)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let spiderChartValues = try container.decode([String: Double].self, forKey: .spiderChartValues)
        let dietaryTags = try container.decode([String].self, forKey: .dietaryTags)
        let foodPhilosophy = try container.decode(String.self, forKey: .foodPhilosophy)
        let favoriteCuisines = try container.decode([String].self, forKey: .favoriteCuisines)
        let favoriteDishes = try container.decode([String].self, forKey: .favoriteDishes)
        let favoriteRestaurants = try container.decode([String].self, forKey: .favoriteRestaurants)
        let defaultMenuLanguage = try container.decode(String.self, forKey: .defaultMenuLanguage)

        self.init(
            id: id,
            email: email,
            createdAt: createdAt,
            spiderChartValues: spiderChartValues,
            dietaryTags: dietaryTags,
            foodPhilosophy: foodPhilosophy,
            favoriteCuisines: favoriteCuisines,
            favoriteDishes: favoriteDishes,
            favoriteRestaurants: favoriteRestaurants,
            defaultMenuLanguage: defaultMenuLanguage
        )
    }
}