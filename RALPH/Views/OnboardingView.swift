import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var email = ""
    @State private var password = ""
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
    
    private let totalSteps = 6
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: Double(totalSteps - 1))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    LanguageStep(selectedLanguage: $selectedLanguage)
                        .tag(1)
                    
                    DietaryTagsStep(selectedTags: $selectedDietaryTags)
                        .tag(2)
                    
                    SpiderChartStep(values: $spiderChartValues)
                        .tag(3)
                    
                    FoodPhilosophyStep(philosophy: $foodPhilosophy)
                        .tag(4)
                    
                    FavoritesStep(
                        cuisines: $favoriteCuisines,
                        dishes: $favoriteDishes,
                        restaurants: $favoriteRestaurants,
                        newCuisine: $newCuisine,
                        newDish: $newDish,
                        newRestaurant: $newRestaurant
                    )
                    .tag(5)
                    
                    AccountCreationStep(
                        email: $email,
                        password: $password,
                        onComplete: createProfile
                    )
                    .tag(6)
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
                    
                    if currentStep < totalSteps {
                        Button(currentStep == totalSteps - 1 ? "Create Account" : "Next") {
                            withAnimation {
                                if currentStep < totalSteps {
                                    currentStep += 1
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .disabled(!canProceed)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 6: // Account creation
            return !email.isEmpty && !password.isEmpty && password.count >= 6
        default:
            return true
        }
    }
    
    private func createProfile() {
        // TODO: Implement profile creation logic
        print("Profile created for \(email)")
    }
}

struct WelcomeStep: View {
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
                
                FeatureRow(icon: "chart.pie.fill", title: "Taste Mapping", description: "Discover your flavor preferences with our 12-dimension spider chart")
            }
            
            Spacer()
            
            Text("Let's create your taste profile")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct LanguageStep: View {
    @Binding var selectedLanguage: String
    
    private let languages = [
        ("en", "English", "🇺🇸"),
        ("es", "Español", "🇪🇸"),
        ("fr", "Français", "🇫🇷"),
        ("de", "Deutsch", "🇩🇪"),
        ("it", "Italiano", "🇮🇹"),
        ("pt", "Português", "🇵🇹"),
        ("zh", "中文", "🇨🇳"),
        ("ja", "日本語", "🇯🇵"),
        ("ko", "한국어", "🇰🇷")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Default Menu Language")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select your preferred language for menu translations")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                    ForEach(languages, id: \.0) { code, name, flag in
                        Button(action: {
                            selectedLanguage = code
                        }) {
                            VStack(spacing: 8) {
                                Text(flag)
                                    .font(.system(size: 32))
                                
                                Text(name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                selectedLanguage == code ?
                                Color.blue.opacity(0.2) :
                                Color(.systemGray6)
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedLanguage == code ?
                                        Color.blue :
                                        Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .foregroundColor(.primary)
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
    }
}

struct DietaryTagsStep: View {
    @Binding var selectedTags: Set<String>
    
    private let tagCategories = [
        ("Religious", ["Halal", "Kosher", "Hindu Vegetarian", "Jain", "Buddhist Vegetarian", "Alcohol-free"]),
        ("Dietary Restrictions", ["Vegan", "Vegetarian", "Pescatarian", "Gluten-free", "Dairy-free", "Nut-free", "Soy-free", "Egg-free", "Shellfish-free", "Low-sodium", "Low-sugar", "Keto"]),
        ("Lifestyle Choices", ["Organic-only", "Local/seasonal", "Sustainable", "Raw foods", "Whole30", "Paleo"]),
        ("Texture Preferences", ["Crispy preferred", "Avoid mushy", "Rare meats OK", "Well-done only", "No bones", "Avoid heavy sauce"])
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("Dietary Preferences")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select any dietary restrictions, preferences, or requirements that apply to you")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(tagCategories, id: \.0) { category, tags in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category)
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Button(action: {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    }) {
                                        Text(tag)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                selectedTags.contains(tag) ?
                                                Color.blue :
                                                Color(.systemGray6)
                                            )
                                            .foregroundColor(
                                                selectedTags.contains(tag) ?
                                                .white :
                                                .primary
                                            )
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            if !selectedTags.isEmpty {
                Text("Selected: \(selectedTags.count) preferences")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}

struct SpiderChartStep: View {
    @Binding var values: [String: Double]
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("Taste Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Adjust the sliders to reflect your taste preferences. Tap dimension names for explanations.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            InteractiveSpiderChartView(values: $values)
        }
        .padding()
    }
}

struct FoodPhilosophyStep: View {
    @Binding var philosophy: String
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Food Philosophy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Tell us about your relationship with food, dining preferences, or culinary goals (optional)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Examples:")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• \"I prefer simple, fresh ingredients over complex preparations\"")
                    Text("• \"I love trying authentic dishes from different cultures\"")
                    Text("• \"I'm focused on healthy eating while still enjoying flavor\"")
                    Text("• \"I enjoy fine dining experiences and unique flavor combinations\"")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            TextEditor(text: $philosophy)
                .frame(minHeight: 120)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                Spacer()
                Text("\(philosophy.count)/500")
                    .font(.caption)
                    .foregroundColor(philosophy.count > 500 ? .red : .secondary)
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: philosophy) { _, newValue in
            if newValue.count > 500 {
                philosophy = String(newValue.prefix(500))
            }
        }
    }
}

struct FavoritesStep: View {
    @Binding var cuisines: [String]
    @Binding var dishes: [String]
    @Binding var restaurants: [String]
    @Binding var newCuisine: String
    @Binding var newDish: String
    @Binding var newRestaurant: String
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("Favorites")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Add your favorite cuisines, dishes, and restaurants to help us understand your preferences (optional)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Cuisines
                    FavoriteSection(
                        title: "Favorite Cuisines",
                        items: $cuisines,
                        newItem: $newCuisine,
                        placeholder: "e.g., Italian, Thai, Mexican"
                    )
                    
                    // Dishes
                    FavoriteSection(
                        title: "Favorite Dishes",
                        items: $dishes,
                        newItem: $newDish,
                        placeholder: "e.g., Pasta Carbonara, Pad Thai"
                    )
                    
                    // Restaurants
                    FavoriteSection(
                        title: "Favorite Restaurants",
                        items: $restaurants,
                        newItem: $newRestaurant,
                        placeholder: "e.g., Local bistro, chain name"
                    )
                }
                .padding()
            }
        }
        .padding()
    }
}

struct FavoriteSection: View {
    let title: String
    @Binding var items: [String]
    @Binding var newItem: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
            
            // Add new item
            HStack {
                TextField(placeholder, text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Add") {
                    let trimmed = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && !items.contains(trimmed) {
                        items.append(trimmed)
                        newItem = ""
                    }
                }
                .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // Current items
            if !items.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Text(item)
                                .font(.caption)
                            
                            Button(action: {
                                items.removeAll { $0 == item }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                }
            }
        }
    }
}

struct AccountCreationStep: View {
    @Binding var email: String
    @Binding var password: String
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Create your RALPH account to save your taste profile and menu history")
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
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                    
                    SecureField("Enter password (min 6 characters)", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !password.isEmpty && password.count < 6 {
                        Text("Password must be at least 6 characters")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            VStack(spacing: 16) {
                Button(action: onComplete) {
                    Text("Create Account & Finish")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .disabled(email.isEmpty || password.count < 6)
                
                Text("By creating an account, you agree to our terms of service and privacy policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}