import Foundation

final class UserProfile {
    var id: UUID
    var email: String
    var createdAt: Date
    var spiderChartValues: [String: Double] // 12 dimensions, 0-100 scale
    var dietaryTags: [String] // from list of 30 tags
    var foodPhilosophy: String // 500 char max
    var favoriteCuisines: [String]
    var favoriteDishes: [String]
    var favoriteRestaurants: [String]
    var defaultMenuLanguage: String
    
    init(
        id: UUID = UUID(),
        email: String,
        createdAt: Date = Date(),
        spiderChartValues: [String: Double] = SpiderDimension.defaultValues,
        dietaryTags: [String] = [],
        foodPhilosophy: String = "",
        favoriteCuisines: [String] = [],
        favoriteDishes: [String] = [],
        favoriteRestaurants: [String] = [],
        defaultMenuLanguage: String = "en"
    ) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
        self.spiderChartValues = spiderChartValues
        self.dietaryTags = dietaryTags
        self.foodPhilosophy = foodPhilosophy
        self.favoriteCuisines = favoriteCuisines
        self.favoriteDishes = favoriteDishes
        self.favoriteRestaurants = favoriteRestaurants
        self.defaultMenuLanguage = defaultMenuLanguage
    }
}

enum SpiderDimension: String, CaseIterable {
    case sweetness = "Sweetness"
    case umami = "Savory/Umami"
    case spice = "Spice/Heat Level"
    case acidity = "Acidity/Brightness"
    case richness = "Richness/Fat Content"
    case saltiness = "Saltiness"
    case bitterness = "Bitterness"
    case priceSensitivity = "Price Sensitivity"
    case adventurousness = "Adventurousness"
    case freshness = "Freshness Priority"
    case presentation = "Presentation Importance"
    case portionSize = "Portion Size Preference"
    
    static var defaultValues: [String: Double] {
        Dictionary(uniqueKeysWithValues: SpiderDimension.allCases.map { ($0.rawValue, 50.0) })
    }
    
    var description: String {
        switch self {
        case .sweetness:
            return "Preference for sweet flavors and desserts"
        case .umami:
            return "Preference for savory, rich, umami flavors"
        case .spice:
            return "Tolerance and preference for spicy foods"
        case .acidity:
            return "Preference for bright, acidic, citrusy flavors"
        case .richness:
            return "Preference for rich, creamy, fatty foods"
        case .saltiness:
            return "Preference for salty flavors"
        case .bitterness:
            return "Tolerance for bitter flavors like coffee, dark chocolate"
        case .priceSensitivity:
            return "How much price matters (0=price no object, 100=very budget conscious)"
        case .adventurousness:
            return "Willingness to try new and unusual dishes"
        case .freshness:
            return "Importance of fresh, seasonal ingredients"
        case .presentation:
            return "Importance of visual presentation and plating"
        case .portionSize:
            return "Preference for portion size (0=small, 100=large)"
        }
    }
}

enum DietaryTag: String, CaseIterable {
    // Religious
    case halal = "Halal"
    case kosher = "Kosher"
    case hinduVegetarian = "Hindu Vegetarian"
    case jain = "Jain"
    case buddhistVegetarian = "Buddhist Vegetarian"
    case alcoholFree = "Alcohol-free"
    
    // Restrictions
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case pescatarian = "Pescatarian"
    case glutenFree = "Gluten-free"
    case dairyFree = "Dairy-free"
    case nutFree = "Nut-free"
    case soyFree = "Soy-free"
    case eggFree = "Egg-free"
    case shellfishFree = "Shellfish-free"
    case lowSodium = "Low-sodium"
    case lowSugar = "Low-sugar"
    case keto = "Keto"
    
    // Lifestyle
    case organicOnly = "Organic-only"
    case localSeasonal = "Local/seasonal"
    case sustainable = "Sustainable"
    case rawFoods = "Raw foods"
    case whole30 = "Whole30"
    case paleo = "Paleo"
    
    // Texture
    case crispyPreferred = "Crispy preferred"
    case avoidMushy = "Avoid mushy"
    case rareMeatsOK = "Rare meats OK"
    case wellDoneOnly = "Well-done only"
    case noBones = "No bones"
    case avoidHeavySauce = "Avoid heavy sauce"
    
    static var allTags: [String] {
        DietaryTag.allCases.map { $0.rawValue }
    }
}