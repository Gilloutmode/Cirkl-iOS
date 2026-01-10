import Foundation
import SwiftUI

/// Connection model representing a relationship
struct Connection: Identifiable, Codable {
    let id: UUID
    var name: String
    var avatarURL: URL?
    let connectionDate: Date  // Date auto-générée à la création (non modifiable)
    var lastInteraction: Date

    // Meeting context (Contexte de rencontre)
    var meetingPlace: String?           // Lieu de rencontre
    var selfiePhotoData: Data?          // Photo selfie prise lors de la rencontre (optionnel)
    var connectionType: ConnectionType  // Type de connexion (Pro, Perso, etc.)

    // Professional info
    var role: String?                   // Rôle professionnel
    var company: String?                // Entreprise
    var industry: String?               // Secteur d'activité

    // Physical verification
    let verificationMethod: VerificationMethod
    var verificationLocation: String?
    var trustLevel: TrustLevel

    // Relationship metrics
    var relationshipStrength: CGFloat // 0.0 to 1.0
    var interactionFrequency: CGFloat // 0.0 to 1.0
    var maturityLevel: MaturityLevel

    // Opportunity detection
    var hasActiveOpportunity: Bool
    var opportunityType: OpportunityType?
    var opportunityMessage: String?

    // Visual properties
    var color: Color {
        Color(
            hue: Double(id.hashValue % 360) / 360.0,
            saturation: 0.6,
            brightness: 0.8
        )
    }

    // Context and notes
    var tags: [String]
    var notes: String?
    var sharedInterests: [String]
    
    init(
        id: UUID = UUID(),
        name: String,
        avatarURL: URL? = nil,
        connectionDate: Date = Date(),  // Auto-timestamp
        lastInteraction: Date = Date(),
        meetingPlace: String? = nil,
        selfiePhotoData: Data? = nil,
        connectionType: ConnectionType = .personnel,
        role: String? = nil,
        company: String? = nil,
        industry: String? = nil,
        verificationMethod: VerificationMethod = .qrCode,
        verificationLocation: String? = nil,
        trustLevel: TrustLevel = .pending,
        relationshipStrength: CGFloat = 0.3,
        interactionFrequency: CGFloat = 0.5,
        maturityLevel: MaturityLevel = .new,
        hasActiveOpportunity: Bool = false,
        opportunityType: OpportunityType? = nil,
        opportunityMessage: String? = nil,
        tags: [String] = [],
        notes: String? = nil,
        sharedInterests: [String] = []
    ) {
        self.id = id
        self.name = name
        self.avatarURL = avatarURL
        self.connectionDate = connectionDate
        self.lastInteraction = lastInteraction
        self.meetingPlace = meetingPlace
        self.selfiePhotoData = selfiePhotoData
        self.connectionType = connectionType
        self.role = role
        self.company = company
        self.industry = industry
        self.verificationMethod = verificationMethod
        self.verificationLocation = verificationLocation
        self.trustLevel = trustLevel
        self.relationshipStrength = relationshipStrength
        self.interactionFrequency = interactionFrequency
        self.maturityLevel = maturityLevel
        self.hasActiveOpportunity = hasActiveOpportunity
        self.opportunityType = opportunityType
        self.opportunityMessage = opportunityMessage
        self.tags = tags
        self.notes = notes
        self.sharedInterests = sharedInterests
    }

    /// Date de connexion formatée
    var formattedConnectionDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: connectionDate)
    }
}

/// Physical verification methods
enum VerificationMethod: String, Codable {
    case qrCode = "QR Code"
    case nfc = "NFC"
    case bluetooth = "Bluetooth"
    case manual = "Manual"
    case proximity = "Proximity"  // MultipeerConnectivity + NearbyInteraction
}

/// Relationship maturity levels
enum MaturityLevel: Int, Codable {
    case new = 0           // Transparent bubble
    case developing = 1    // Gaining opacity
    case established = 2   // Full opacity
    case strong = 3        // Glowing
    case intimate = 4      // Pulsing glow
}

/// Opportunity types
enum OpportunityType: String, Codable, CaseIterable {
    case business = "Business"
    case romantic = "Romantic"
    case friendship = "Friendship"
    case professional = "Professional"
    case creative = "Creative"
    case mentorship = "Mentorship"
    case collaboration = "Collaboration"
}

// MARK: - Connection Type (Type de relation)
/// Type de connexion selon le contexte de la rencontre
enum ConnectionType: String, Codable, CaseIterable, Identifiable {
    case professionnel = "Professionnel"
    case personnel = "Personnel"
    case evenement = "Événement"
    case famille = "Famille"
    case amiDami = "Ami d'ami"
    case communaute = "Communauté"
    case networking = "Networking"
    case etudes = "Études"
    case voyage = "Voyage"
    case sport = "Sport/Loisir"

    var id: String { rawValue }

    /// Icône SF Symbol pour ce type
    var icon: String {
        switch self {
        case .professionnel: return "briefcase.fill"
        case .personnel: return "heart.fill"
        case .evenement: return "calendar.badge.plus"
        case .famille: return "house.fill"
        case .amiDami: return "person.2.fill"
        case .communaute: return "person.3.fill"
        case .networking: return "network"
        case .etudes: return "graduationcap.fill"
        case .voyage: return "airplane"
        case .sport: return "figure.run"
        }
    }

    /// Couleur associée à ce type
    var color: Color {
        switch self {
        case .professionnel: return Color(red: 0.3, green: 0.5, blue: 0.8)
        case .personnel: return Color(red: 0.9, green: 0.4, blue: 0.5)
        case .evenement: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .famille: return Color(red: 0.9, green: 0.6, blue: 0.3)
        case .amiDami: return Color(red: 0.4, green: 0.7, blue: 0.6)
        case .communaute: return Color(red: 0.5, green: 0.6, blue: 0.9)
        case .networking: return Color(red: 0.3, green: 0.7, blue: 0.8)
        case .etudes: return Color(red: 0.8, green: 0.5, blue: 0.3)
        case .voyage: return Color(red: 0.4, green: 0.8, blue: 0.6)
        case .sport: return Color(red: 0.8, green: 0.3, blue: 0.4)
        }
    }
}

// MARK: - Connection Extensions for Orbital Display
extension Connection {
    /// Perfect orbital positioning - 6 connections equally spaced
    var orbitalAngle: Double {
        let baseAngles: [Double] = [0, 60, 120, 180, 240, 300] // Perfect 60-degree spacing
        let index = abs(id.hashValue) % baseAngles.count
        return baseAngles[index]
    }
    
    var orbitalDistance: CGFloat {
        return 160.0 // Increased distance for better visual separation
    }
    
    var profileImageName: String {
        // Real profile photo names - you can replace these with actual image names
        let profileImages = ["profile_denis", "profile_shay", "profile_dan", "profile_judith", "profile_gilles", "profile_salome"]
        let index = abs(id.hashValue) % profileImages.count
        return profileImages[index]
    }
    
    var fallbackSystemImage: String {
        return "person.crop.circle.fill"
    }
}