import Foundation

final class MenuSession {
    var id: UUID
    var userProfileID: UUID
    var restaurantName: String?
    var menuDate: Date
    var menuItems: [MenuItem]
    var recommendations: [MenuItem] // top 6
    var userFeedback: String?
    var itemsOrdered: [String]
    
    init(
        id: UUID = UUID(),
        userProfileID: UUID,
        restaurantName: String? = nil,
        menuDate: Date = Date(),
        menuItems: [MenuItem] = [],
        recommendations: [MenuItem] = [],
        userFeedback: String? = nil,
        itemsOrdered: [String] = []
    ) {
        self.id = id
        self.userProfileID = userProfileID
        self.restaurantName = restaurantName
        self.menuDate = menuDate
        self.menuItems = menuItems
        self.recommendations = recommendations
        self.userFeedback = userFeedback
        self.itemsOrdered = itemsOrdered
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: menuDate)
    }
    
    var displayRestaurantName: String {
        restaurantName ?? "Unknown Restaurant"
    }
    
    var hasRecommendations: Bool {
        !recommendations.isEmpty
    }
    
    var hasUserFeedback: Bool {
        userFeedback != nil && !userFeedback!.isEmpty
    }
}