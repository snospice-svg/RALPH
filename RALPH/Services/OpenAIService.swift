import Foundation
import UIKit

class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    private let baseURL = "https://api.openai.com/v1"
    private let keychainManager = KeychainManager.shared
    
    @Published var dailyCostUsed: Double = 0.0
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let maxDailyCost: Double = 10.0 // $10 daily limit
    private let maxRetries = 3
    
    private init() {
        loadDailyCostFromUserDefaults()
    }
    
    // MARK: - API Key Management
    
    var hasAPIKey: Bool {
        keychainManager.hasOpenAIAPIKey
    }
    
    func setAPIKey(_ apiKey: String) throws {
        let formattedKey = keychainManager.formatOpenAIAPIKey(apiKey)
        
        guard keychainManager.validateOpenAIAPIKey(formattedKey) else {
            throw OpenAIError.invalidAPIKey
        }
        
        try keychainManager.saveOpenAIAPIKey(formattedKey)
    }
    
    private func getAPIKey() throws -> String {
        return try keychainManager.getOpenAIAPIKey()
    }
    
    // MARK: - Cost Management
    
    private func loadDailyCostFromUserDefaults() {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: "cost_tracking_date") as? Date
        
        if let savedDate = savedDate, Calendar.current.isDate(savedDate, equalTo: today, toGranularity: .day) {
            dailyCostUsed = UserDefaults.standard.double(forKey: "daily_cost_used")
        } else {
            // New day, reset cost
            dailyCostUsed = 0.0
            UserDefaults.standard.set(today, forKey: "cost_tracking_date")
            UserDefaults.standard.set(0.0, forKey: "daily_cost_used")
        }
    }
    
    private func addToDailyCost(_ cost: Double) {
        dailyCostUsed += cost
        UserDefaults.standard.set(dailyCostUsed, forKey: "daily_cost_used")
    }
    
    private func checkDailyCostLimit() throws {
        guard dailyCostUsed < maxDailyCost else {
            throw OpenAIError.dailyCostLimitExceeded
        }
    }
    
    // MARK: - Menu Analysis
    
    func analyzeMenuImage(_ image: UIImage) async throws -> [MenuItem] {
        try checkDailyCostLimit()
        
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        defer {
            Task {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw OpenAIError.imageProcessingFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let messages: [[String: Any]] = [
            [
                "role": "system",
                "content": MenuAnalysisPrompts.systemPrompt
            ],
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": MenuAnalysisPrompts.userPrompt
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)"
                        ]
                    ]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 2000,
            "temperature": 0.1
        ]
        
        return try await performAPIRequest(
            endpoint: "/chat/completions",
            body: requestBody,
            retryCount: 0
        ) { data in
            let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            
            // Track cost
            let cost = self.calculateCost(response.usage)
            await MainActor.run {
                self.addToDailyCost(cost)
            }
            
            guard let content = response.choices.first?.message.content else {
                throw OpenAIError.invalidResponse
            }
            
            return try self.parseMenuItemsFromJSON(content)
        }
    }
    
    // MARK: - Recommendation Generation
    
    func generateRecommendations(menuItems: [MenuItem], profile: UserProfile) async throws -> [MenuItem] {
        try checkDailyCostLimit()
        
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        defer {
            Task {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
        
        let menuItemsJSON = try JSONEncoder().encode(menuItems.map { item in
            MenuItemForAPI(
                id: item.id.uuidString,
                name: item.displayName,
                description: item.displayDescription,
                price: item.price,
                category: item.categoryType,
                ingredients: item.ingredients,
                dietaryTags: item.dietaryTags,
                estimatedFlavors: item.estimatedFlavors
            )
        })
        
        let profileJSON = try JSONEncoder().encode(ProfileForAPI(
            spiderChartValues: profile.spiderChartValues,
            dietaryTags: profile.dietaryTags,
            foodPhilosophy: profile.foodPhilosophy,
            favoriteCuisines: profile.favoriteCuisines,
            favoriteDishes: profile.favoriteDishes
        ))
        
        let messages: [[String: Any]] = [
            [
                "role": "system",
                "content": RecommendationPrompts.systemPrompt
            ],
            [
                "role": "user",
                "content": RecommendationPrompts.userPrompt(
                    menuItems: String(data: menuItemsJSON, encoding: .utf8) ?? "",
                    profile: String(data: profileJSON, encoding: .utf8) ?? ""
                )
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 1000,
            "temperature": 0.2
        ]
        
        return try await performAPIRequest(
            endpoint: "/chat/completions",
            body: requestBody,
            retryCount: 0
        ) { data in
            let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            
            // Track cost
            let cost = self.calculateCost(response.usage)
            await MainActor.run {
                self.addToDailyCost(cost)
            }
            
            guard let content = response.choices.first?.message.content else {
                throw OpenAIError.invalidResponse
            }
            
            return try self.parseRecommendationsFromJSON(content, menuItems: menuItems)
        }
    }
    
    // MARK: - Feedback Analysis
    
    func analyzeFeedback(sessions: [MenuSession]) async throws -> [String: Any] {
        // Implementation for analyzing user feedback patterns
        // This would analyze past sessions to improve future recommendations
        
        try checkDailyCostLimit()
        
        // For now, return empty dictionary
        // In full implementation, this would analyze feedback patterns
        return [:]
    }
    
    // MARK: - Private Helper Methods
    
    private func performAPIRequest<T>(
        endpoint: String,
        body: [String: Any],
        retryCount: Int,
        parser: @escaping (Data) async throws -> T
    ) async throws -> T {
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let apiKey = try getAPIKey()
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try await parser(data)
                
            case 401:
                throw OpenAIError.invalidAPIKey
                
            case 429:
                // Rate limited - implement exponential backoff
                if retryCount < maxRetries {
                    let delay = pow(2.0, Double(retryCount))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await performAPIRequest(
                        endpoint: endpoint,
                        body: body,
                        retryCount: retryCount + 1,
                        parser: parser
                    )
                } else {
                    throw OpenAIError.rateLimited
                }
                
            case 500...599:
                // Server error - retry with backoff
                if retryCount < maxRetries {
                    let delay = pow(2.0, Double(retryCount))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await performAPIRequest(
                        endpoint: endpoint,
                        body: body,
                        retryCount: retryCount + 1,
                        parser: parser
                    )
                } else {
                    throw OpenAIError.serverError
                }
                
            default:
                throw OpenAIError.unknown(httpResponse.statusCode)
            }
            
        } catch {
            if retryCount < maxRetries && (error as? OpenAIError) != .invalidAPIKey {
                let delay = pow(2.0, Double(retryCount))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await performAPIRequest(
                    endpoint: endpoint,
                    body: body,
                    retryCount: retryCount + 1,
                    parser: parser
                )
            } else {
                throw error
            }
        }
    }
    
    private func parseMenuItemsFromJSON(_ jsonString: String) throws -> [MenuItem] {
        // Extract JSON from response (handle potential markdown formatting)
        let cleanedJSON = extractJSONFromResponse(jsonString)
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        let menuItemsData = try JSONDecoder().decode(MenuAnalysisResponse.self, from: data)
        
        return menuItemsData.menu_items.map { item in
            MenuItem(
                nameOriginal: item.name_original ?? item.name_translated,
                nameTranslated: item.name_translated,
                descriptionOriginal: item.description_original ?? item.description_translated,
                descriptionTranslated: item.description_translated,
                price: item.price,
                currency: item.currency ?? "USD",
                ingredients: item.ingredients ?? [],
                preparationMethods: item.preparation_methods ?? [],
                dietaryTags: item.dietary_tags ?? [],
                estimatedFlavors: item.estimated_flavors ?? [:]
            )
        }
    }
    
    private func parseRecommendationsFromJSON(_ jsonString: String, menuItems: [MenuItem]) throws -> [MenuItem] {
        let cleanedJSON = extractJSONFromResponse(jsonString)
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        let recommendations = try JSONDecoder().decode(RecommendationResponse.self, from: data)
        
        // Match recommendation IDs with actual menu items
        var recommendedItems: [MenuItem] = []
        
        for rec in recommendations.recommendations {
            if let item = menuItems.first(where: { $0.id.uuidString == rec.item_id }) {
                recommendedItems.append(item)
            }
        }
        
        return Array(recommendedItems.prefix(6)) // Return top 6
    }
    
    private func extractJSONFromResponse(_ response: String) -> String {
        // Remove markdown formatting if present
        let lines = response.components(separatedBy: .newlines)
        var jsonLines: [String] = []
        var inCodeBlock = false
        
        for line in lines {
            if line.hasPrefix("```") {
                inCodeBlock.toggle()
                continue
            }
            
            if inCodeBlock || (!line.hasPrefix("```") && (line.hasPrefix("{") || jsonLines.count > 0)) {
                jsonLines.append(line)
            }
        }
        
        let jsonString = jsonLines.joined(separator: "\n")
        return jsonString.isEmpty ? response : jsonString
    }
    
    private func calculateCost(_ usage: Usage) -> Double {
        // GPT-4o pricing (as of 2024)
        let inputCostPer1K = 0.005  // $0.005 per 1K input tokens
        let outputCostPer1K = 0.015 // $0.015 per 1K output tokens
        
        let inputCost = (Double(usage.prompt_tokens) / 1000.0) * inputCostPer1K
        let outputCost = (Double(usage.completion_tokens) / 1000.0) * outputCostPer1K
        
        return inputCost + outputCost
    }
}

// MARK: - Error Types

enum OpenAIError: Error, LocalizedError, Equatable {
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case imageProcessingFailed
    case rateLimited
    case serverError
    case dailyCostLimitExceeded
    case unknown(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid OpenAI API key. Please check your API key and try again."
        case .invalidURL:
            return "Invalid URL configuration."
        case .invalidResponse:
            return "Invalid response from OpenAI API."
        case .imageProcessingFailed:
            return "Failed to process the image. Please try a different image."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverError:
            return "OpenAI server error. Please try again later."
        case .dailyCostLimitExceeded:
            return "Daily cost limit of $10 exceeded. Try again tomorrow."
        case .unknown(let code):
            return "Unknown error occurred (Code: \(code))."
        }
    }
}

// MARK: - API Response Types

struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    let usage: Usage
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String?
}

struct Usage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

struct MenuAnalysisResponse: Codable {
    let menu_items: [MenuItemResponse]
}

struct MenuItemResponse: Codable {
    let name_original: String?
    let name_translated: String
    let description_original: String?
    let description_translated: String
    let price: Double
    let currency: String?
    let category: String
    let ingredients: [String]?
    let preparation_methods: [String]?
    let dietary_tags: [String]?
    let estimated_flavors: [String: Double]?
}

struct RecommendationResponse: Codable {
    let recommendations: [RecommendationItem]
}

struct RecommendationItem: Codable {
    let item_id: String
    let match_score: Double
    let reasoning: String
    let drink_pairing: String?
}

// MARK: - API Request Types

struct MenuItemForAPI: Codable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let category: String
    let ingredients: [String]
    let dietaryTags: [String]
    let estimatedFlavors: [String: Double]
}

struct ProfileForAPI: Codable {
    let spiderChartValues: [String: Double]
    let dietaryTags: [String]
    let foodPhilosophy: String
    let favoriteCuisines: [String]
    let favoriteDishes: [String]
}

// MARK: - Prompts

struct MenuAnalysisPrompts {
    static let systemPrompt = """
    You are a menu analysis expert. Extract all menu items from images and estimate flavor profiles.
    
    Return JSON in this exact format:
    {
      "menu_items": [
        {
          "name_original": "Original name if visible",
          "name_translated": "English translation",
          "description_original": "Original description if visible",
          "description_translated": "English description",
          "price": 12.99,
          "currency": "USD",
          "category": "appetizer|main|dessert|drink|other",
          "ingredients": ["ingredient1", "ingredient2"],
          "preparation_methods": ["grilled", "steamed"],
          "dietary_tags": ["vegan", "gluten-free"],
          "estimated_flavors": {
            "Sweetness": 30,
            "Savory/Umami": 70,
            "Spice/Heat Level": 20,
            "Acidity/Brightness": 40,
            "Richness/Fat Content": 60,
            "Saltiness": 50,
            "Bitterness": 10
          }
        }
      ]
    }
    
    Estimate all 7 flavor dimensions on 0-100 scale. Be accurate with prices and translations.
    """
    
    static let userPrompt = "Analyze this menu image and extract all items with translations, prices, and flavor profiles. Return only valid JSON."
}

struct RecommendationPrompts {
    static let systemPrompt = """
    You are a food recommendation expert. Given a user's taste profile and menu items, recommend the top 6 dishes that best match their preferences.
    
    Use this scoring logic:
    - 70% weight on spider chart flavor alignment
    - 20% weight on food philosophy match
    - 10% weight on favorites affinity
    
    Return JSON in this format:
    {
      "recommendations": [
        {
          "item_id": "uuid-from-menu-items",
          "match_score": 0.85,
          "reasoning": "Why this matches their taste profile",
          "drink_pairing": "Optional drink suggestion"
        }
      ]
    }
    """
    
    static func userPrompt(menuItems: String, profile: String) -> String {
        return """
        Menu Items: \(menuItems)
        
        User Profile: \(profile)
        
        Recommend the top 6 dishes that best match this user's taste profile. Return only valid JSON.
        """
    }
}