import Foundation

class RecommendationEngine {
    static let shared = RecommendationEngine()
    private init() {}
    
    // MARK: - Main Recommendation Logic
    
    func selectTopRecommendations(items: [MenuItem], profile: UserProfile) -> [MenuItem] {
        // Filter by dietary restrictions first
        let filteredItems = filterByDietaryTags(items: items, tags: profile.dietaryTags)
        
        // Calculate match scores for each item
        let scoredItems = filteredItems.map { item in
            ScoredMenuItem(
                item: item,
                score: calculateMatchScore(item: item, profile: profile)
            )
        }
        
        // Sort by score and return top 6
        let sortedItems = scoredItems.sorted { $0.score > $1.score }
        return Array(sortedItems.prefix(6).map { $0.item })
    }
    
    // MARK: - Dietary Filtering
    
    func filterByDietaryTags(items: [MenuItem], tags: [String]) -> [MenuItem] {
        guard !tags.isEmpty else { return items }
        
        return items.filter { item in
            // Check if item is compatible with user's dietary restrictions
            for userTag in tags {
                if !isCompatibleWithDietaryTag(item: item, userTag: userTag) {
                    return false
                }
            }
            return true
        }
    }
    
    private func isCompatibleWithDietaryTag(item: MenuItem, userTag: String) -> Bool {
        let itemTags = item.dietaryTags
        let ingredients = item.ingredients.map { $0.lowercased() }
        let description = item.displayDescription.lowercased()
        
        switch userTag {
        // Vegan restrictions
        case "Vegan":
            return !containsAnimalProducts(ingredients: ingredients, description: description, tags: itemTags)
            
        // Vegetarian restrictions
        case "Vegetarian":
            return !containsMeat(ingredients: ingredients, description: description)
            
        // Religious restrictions
        case "Halal":
            return !containsPork(ingredients: ingredients, description: description) &&
                   !containsAlcohol(ingredients: ingredients, description: description)
            
        case "Kosher":
            return !containsPork(ingredients: ingredients, description: description) &&
                   !containsShellfish(ingredients: ingredients, description: description)
            
        // Allergen restrictions
        case "Gluten-free":
            return !containsGluten(ingredients: ingredients, description: description, tags: itemTags)
            
        case "Dairy-free":
            return !containsDairy(ingredients: ingredients, description: description)
            
        case "Nut-free":
            return !containsNuts(ingredients: ingredients, description: description)
            
        case "Shellfish-free":
            return !containsShellfish(ingredients: ingredients, description: description)
            
        // Diet-specific
        case "Keto":
            return isKetoFriendly(item: item)
            
        case "Paleo":
            return isPaleoFriendly(ingredients: ingredients, description: description)
            
        // If item explicitly has the tag, it's compatible
        default:
            return itemTags.contains(userTag)
        }
    }
    
    // MARK: - Match Score Calculation
    
    func calculateMatchScore(item: MenuItem, profile: UserProfile) -> Double {
        let spiderChartScore = calculateSpiderChartAlignment(item: item, profile: profile)
        let philosophyScore = calculatePhilosophyMatch(item: item, profile: profile)
        let favoritesScore = calculateFavoritesAffinity(item: item, profile: profile)
        
        // Weighted combination: 70% spider chart, 20% philosophy, 10% favorites
        return (spiderChartScore * 0.7) + (philosophyScore * 0.2) + (favoritesScore * 0.1)
    }
    
    func calculateSpiderChartAlignment(item: MenuItem, profile: UserProfile) -> Double {
        let userPreferences = profile.spiderChartValues
        let itemFlavors = item.estimatedFlavors
        
        guard !userPreferences.isEmpty && !itemFlavors.isEmpty else {
            return 0.5 // Neutral score if data is missing
        }
        
        var totalScore = 0.0
        var dimensionCount = 0
        
        for (dimension, userValue) in userPreferences {
            if let itemValue = itemFlavors[dimension] {
                // Calculate similarity (inverse of difference)
                let difference = abs(userValue - itemValue) / 100.0
                let similarity = 1.0 - difference
                totalScore += similarity
                dimensionCount += 1
            }
        }
        
        return dimensionCount > 0 ? totalScore / Double(dimensionCount) : 0.5
    }
    
    private func calculatePhilosophyMatch(item: MenuItem, profile: UserProfile) -> Double {
        guard !profile.foodPhilosophy.isEmpty else {
            return 0.5 // Neutral score if no philosophy provided
        }
        
        let philosophy = profile.foodPhilosophy.lowercased()
        let itemName = item.displayName.lowercased()
        let itemDescription = item.displayDescription.lowercased()
        let ingredients = item.ingredients.joined(separator: " ").lowercased()
        
        var score = 0.5 // Base score
        
        // Keywords that indicate different food philosophies
        let healthKeywords = ["healthy", "fresh", "light", "nutritious", "clean", "organic"]
        let adventurousKeywords = ["unique", "exotic", "authentic", "traditional", "fusion", "creative"]
        let simpleKeywords = ["simple", "classic", "traditional", "homemade", "comfort"]
        let luxuryKeywords = ["fine", "gourmet", "premium", "artisanal", "chef", "signature"]
        
        // Check if user's philosophy matches item characteristics
        if containsKeywords(philosophy, healthKeywords) {
            if containsKeywords(itemDescription + " " + ingredients, ["grilled", "steamed", "fresh", "salad", "lean"]) {
                score += 0.3
            }
            if containsKeywords(itemDescription + " " + ingredients, ["fried", "creamy", "rich", "heavy"]) {
                score -= 0.2
            }
        }
        
        if containsKeywords(philosophy, adventurousKeywords) {
            if containsKeywords(itemName + " " + itemDescription, ["fusion", "unique", "specialty", "traditional"]) {
                score += 0.3
            }
        }
        
        if containsKeywords(philosophy, simpleKeywords) {
            if item.ingredients.count <= 5 && !containsKeywords(itemDescription, ["complex", "fusion"]) {
                score += 0.2
            }
        }
        
        if containsKeywords(philosophy, luxuryKeywords) {
            if item.price > getAveragePrice(profile) * 1.2 {
                score += 0.2
            }
        }
        
        return max(0.0, min(1.0, score))
    }
    
    private func calculateFavoritesAffinity(item: MenuItem, profile: UserProfile) -> Double {
        var score = 0.0
        var matches = 0
        
        let itemText = (item.displayName + " " + item.displayDescription + " " + item.ingredients.joined(separator: " ")).lowercased()
        
        // Check favorite cuisines
        for cuisine in profile.favoriteCuisines {
            if containsKeywords(itemText, [cuisine.lowercased()]) {
                score += 1.0
                matches += 1
            }
        }
        
        // Check favorite dishes
        for dish in profile.favoriteDishes {
            if itemText.contains(dish.lowercased()) {
                score += 1.0
                matches += 1
            }
        }
        
        // Return normalized score
        let maxPossibleMatches = profile.favoriteCuisines.count + profile.favoriteDishes.count
        return maxPossibleMatches > 0 ? score / Double(maxPossibleMatches) : 0.5
    }
    
    // MARK: - Helper Methods
    
    private func containsKeywords(_ text: String, _ keywords: [String]) -> Bool {
        return keywords.contains { text.contains($0) }
    }
    
    private func getAveragePrice(_ profile: UserProfile) -> Double {
        // This would ideally use historical data
        // For now, return a reasonable default
        return 15.0
    }
    
    // MARK: - Dietary Restriction Checks
    
    private func containsAnimalProducts(ingredients: [String], description: String, tags: [String]) -> Bool {
        let animalProducts = ["meat", "beef", "chicken", "pork", "fish", "salmon", "tuna", "shrimp", "egg", "milk", "cheese", "butter", "cream", "yogurt", "honey"]
        let text = (ingredients.joined(separator: " ") + " " + description).lowercased()
        return animalProducts.contains { text.contains($0) } && !tags.contains("Vegan")
    }
    
    private func containsMeat(ingredients: [String], description: String) -> Bool {
        let meatProducts = ["meat", "beef", "chicken", "pork", "lamb", "turkey", "duck", "fish", "salmon", "tuna", "shrimp", "crab", "lobster"]
        let text = (ingredients.joined(separator: " ") + " " + description).lowercased()
        return meatProducts.contains { text.contains($0) }
    }
    
    private func containsPork(ingredients: [String], description: String) -> Bool {
        let porkProducts = ["pork", "bacon", "ham", "sausage", "pepperoni"]
        let text = (ingredients.joined(separator: " ") + " " + description).lowercased()
        return porkProducts.contains { text.contains($0) }
    }
    
    private func containsAlcohol(ingredients: [String], description: String) -> Bool {
        let alcoholProducts = ["wine", "beer", "rum", "vodka", "whiskey", "brandy", "sake", "alcohol"]
        let text = (ingredients.joined(separator: " ") + " " + description).lowercased()
        return alcoholProducts.contains { text.contains($0) }
    }
    
    private func containsGluten(ingredients: [String], description: String, tags: [String]) -> Bool {
        let glutenProducts = ["wheat", "flour", "bread", "pasta", "noodle", "barley", "rye", "oats"]
        let text = (ingredients.joined(separator: " ") + " " + description).lowercased()
        return glutenProducts.contains { text.contains($0) } && !tags.contains("Gluten-free")
    }
    
    private func containsDairy(ingredients: [String], description: String) -> Bool {
        let dairyProducts = ["milk", "cheese", "butter", "cream", "yogurt", "ice cream"]
        let text = (ingredients.joined(separator: " ") + " " + description).lowercased()
        return dairyProducts.contains { text.contains($0) }
    }
    
    private func containsNuts(ingredients: [String], description: String) -> Bool {
        let nutProducts = ["almond", "peanut", "walnut", "cashew", "pecan", "pistachio", "hazelnut"]
        let text = (ingredients.joined(separator: " ") + " " + description).lowercased()
        return nutProducts.contains { text.contains($0) }
    }
    
    private func containsShellfish(ingredients: [String], description: String) -> Bool {
        let shellfishProducts = ["shrimp", "crab", "lobster", "clam", "oyster", "mussel", "scallop"]
        let text = (ingredients.joined(separator: " ") + " " + description).lowercased()
        return shellfishProducts.contains { text.contains($0) }
    }
    
    private func isKetoFriendly(item: MenuItem) -> Bool {
        let highCarbItems = ["rice", "pasta", "bread", "potato", "sugar", "fruit", "dessert"]
        let text = (item.displayName + " " + item.displayDescription + " " + item.ingredients.joined(separator: " ")).lowercased()
        
        // Check if it's likely high in carbs
        return !highCarbItems.contains { text.contains($0) }
    }
    
    private func isPaleoFriendly(ingredients: [String], description: String) -> Bool {
        let nonPaleoItems = ["grain", "wheat", "rice", "bean", "lentil", "dairy", "sugar", "processed"]
        let text = (ingredients.joined(separator: " ") + " " + description).lowercased()
        return !nonPaleoItems.contains { text.contains($0) }
    }
}

// MARK: - Supporting Types

struct ScoredMenuItem {
    let item: MenuItem
    let score: Double
}

// MARK: - Recommendation Explanation

struct RecommendationExplanation {
    let item: MenuItem
    let score: Double
    let reasoning: String
    let matchFactors: [String]
    
    static func generate(for item: MenuItem, score: Double, profile: UserProfile) -> RecommendationExplanation {
        var factors: [String] = []
        var reasoning = "This dish matches your taste profile because:"
        
        // Analyze spider chart alignment
        let spiderScore = RecommendationEngine.shared.calculateSpiderChartAlignment(item: item, profile: profile)
        if spiderScore > 0.7 {
            factors.append("Excellent flavor alignment")
            reasoning += " It aligns well with your flavor preferences."
        }
        
        // Check dietary compatibility
        let filtered = RecommendationEngine.shared.filterByDietaryTags(items: [item], tags: profile.dietaryTags)
        if !filtered.isEmpty {
            factors.append("Meets dietary requirements")
            reasoning += " It meets your dietary restrictions."
        }
        
        // Check favorites
        let itemText = item.displayName.lowercased()
        for cuisine in profile.favoriteCuisines {
            if itemText.contains(cuisine.lowercased()) {
                factors.append("Favorite cuisine: \(cuisine)")
                reasoning += " It's from your favorite \(cuisine) cuisine."
                break
            }
        }
        
        return RecommendationExplanation(
            item: item,
            score: score,
            reasoning: reasoning,
            matchFactors: factors
        )
    }
}

