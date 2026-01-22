import Foundation

final class MenuItem: Identifiable {
    var id: UUID
    var categoryType: String // appetizer/main/dessert/drink/other
    var nameOriginal: String
    var nameTranslated: String
    var descriptionOriginal: String
    var descriptionTranslated: String
    var price: Double
    var currency: String
    var ingredients: [String]
    var preparationMethods: [String]
    var dietaryTags: [String]
    var estimatedFlavors: [String: Double] // 12 flavor dimensions

    // Additional properties for recommendations
    var matchScore: Int = 0
    var spiceLevel: Int = 0
    
    init(
        id: UUID = UUID(),
        categoryType: String = "other",
        nameOriginal: String,
        nameTranslated: String = "",
        descriptionOriginal: String = "",
        descriptionTranslated: String = "",
        price: Double = 0.0,
        currency: String = "USD",
        ingredients: [String] = [],
        preparationMethods: [String] = [],
        dietaryTags: [String] = [],
        estimatedFlavors: [String: Double] = [:],
        matchScore: Int = 0,
        spiceLevel: Int = 0
    ) {
        self.id = id
        self.categoryType = categoryType
        self.nameOriginal = nameOriginal
        self.nameTranslated = nameTranslated.isEmpty ? nameOriginal : nameTranslated
        self.descriptionOriginal = descriptionOriginal
        self.descriptionTranslated = descriptionTranslated.isEmpty ? descriptionOriginal : descriptionTranslated
        self.price = price
        self.currency = currency
        self.ingredients = ingredients
        self.preparationMethods = preparationMethods
        self.dietaryTags = dietaryTags
        self.estimatedFlavors = estimatedFlavors
        self.matchScore = matchScore
        self.spiceLevel = spiceLevel
    }
    
    var displayName: String {
        nameTranslated.isEmpty ? nameOriginal : nameTranslated
    }
    
    var displayDescription: String {
        descriptionTranslated.isEmpty ? descriptionOriginal : descriptionTranslated
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }

    // Convenience initializer for recommendations
    convenience init(
        id: UUID = UUID(),
        name: String,
        description: String,
        price: String,
        category: String,
        dietaryTags: [String] = [],
        spiceLevel: Int = 0,
        matchScore: Int = 0
    ) {
        // Parse price string to extract numeric value
        let priceValue = Double(price.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) ?? 0.0

        self.init(
            id: id,
            categoryType: category.lowercased(),
            nameOriginal: name,
            nameTranslated: name,
            descriptionOriginal: description,
            descriptionTranslated: description,
            price: priceValue,
            currency: "USD",
            dietaryTags: dietaryTags,
            matchScore: matchScore,
            spiceLevel: spiceLevel
        )
    }
}

enum MenuCategory: String, CaseIterable {
    case appetizer = "appetizer"
    case main = "main"
    case dessert = "dessert"
    case drink = "drink"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .appetizer:
            return "Appetizers"
        case .main:
            return "Main Courses"
        case .dessert:
            return "Desserts"
        case .drink:
            return "Beverages"
        case .other:
            return "Other"
        }
    }
}