import Foundation
import SwiftUI

/// User model representing the authenticated user
struct User: Identifiable, Codable {
    let id: UUID
    let name: String
    let email: String
    let avatarURL: URL?
    let bio: String?
    let joinedDate: Date
    let isPremium: Bool
    
    // Personalization
    let primaryColor: String? // Hex color
    let sphere: UserSphere
    
    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        avatarURL: URL? = nil,
        bio: String? = nil,
        joinedDate: Date = Date(),
        isPremium: Bool = false,
        primaryColor: String? = nil,
        sphere: UserSphere = .personal
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.bio = bio
        self.joinedDate = joinedDate
        self.isPremium = isPremium
        self.primaryColor = primaryColor
        self.sphere = sphere
    }
}

/// User sphere types
enum UserSphere: String, Codable, CaseIterable {
    case personal = "Personnel"
    case professional = "Professionnel"
    case creative = "Créatif"
    case romantic = "Romantique"
    case business = "Business"
    
    var color: Color {
        switch self {
        case .personal:
            return .blue
        case .professional:
            return .orange
        case .creative:
            return .purple
        case .romantic:
            return Color(red: 220/255, green: 38/255, blue: 127/255)
        case .business:
            return .yellow
        }
    }
    
    var icon: String {
        switch self {
        case .personal:
            return "person.2.fill"
        case .professional:
            return "briefcase.fill"
        case .creative:
            return "paintbrush.fill"
        case .romantic:
            return "heart.fill"
        case .business:
            return "chart.line.uptrend.xyaxis"
        }
    }
}