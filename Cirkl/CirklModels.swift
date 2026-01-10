import Foundation
import SwiftUI

// MARK: - STATE MANAGERS

@MainActor
class ConnectionStateManager: ObservableObject {
    @Published var connections: [Connection] = []
    @Published var selectedConnection: Connection?
    @Published var searchText = ""
    
    init() {
        // Créer des connexions d'exemple
        loadMockConnections()
    }
    
    var filteredConnections: [Connection] {
        if searchText.isEmpty {
            return connections
        }
        return connections.filter { connection in
            connection.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func selectConnection(_ connection: Connection) {
        selectedConnection = connection
    }
    
    func deselectConnection() {
        selectedConnection = nil
    }
    
    private func loadMockConnections() {
        connections = [
            Connection(
                name: "Salomé", 
                relationshipStrength: 0.75,
                tags: ["Amie", "Sport"],
                sharedInterests: ["Fitness", "Nutrition"]
            ),
            Connection(
                name: "Shay", 
                relationshipStrength: 0.6,
                tags: ["Université"],
                sharedInterests: ["Musique", "Art"]
            ),
            Connection(
                name: "Dan", 
                relationshipStrength: 0.9,
                tags: ["Famille", "Proche"],
                sharedInterests: ["Voyages", "Cuisine"]
            ),
            Connection(
                name: "Judith", 
                relationshipStrength: 0.7,
                tags: ["Professionnelle"],
                sharedInterests: ["Business", "Innovation"]
            ),
            Connection(
                name: "Gilles", 
                relationshipStrength: 0.5,
                tags: ["Nouvelle rencontre"],
                sharedInterests: ["Tech"]
            ),

        ]
    }
}

@MainActor
class PerformanceManager: ObservableObject {
    @Published private(set) var shouldShowLiquidEffects: Bool = true
    @Published private(set) var animationDuration: Double = 0.6
    @Published private(set) var maxConnections: Int = 12
    
    func initializeOptimizations() async {
        // Déterminer la capacité de l'appareil
        let deviceCapability = await determineDeviceCapability()
        
        switch deviceCapability {
        case .high:
            shouldShowLiquidEffects = true
            animationDuration = 0.6
            maxConnections = 20
        case .medium:
            shouldShowLiquidEffects = true
            animationDuration = 0.4
            maxConnections = 12
        case .low:
            shouldShowLiquidEffects = false
            animationDuration = 0.2
            maxConnections = 8
        }
    }
    
    private func determineDeviceCapability() async -> DeviceCapability {
        // Logique simplifiée pour déterminer les capacités de l'appareil
        let processorCount = ProcessInfo.processInfo.processorCount
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        
        if processorCount >= 6 && physicalMemory > 4_000_000_000 {
            return .high
        } else if processorCount >= 4 && physicalMemory > 2_000_000_000 {
            return .medium
        } else {
            return .low
        }
    }
}

enum DeviceCapability {
    case high, medium, low
}

@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: CirklError?
    @Published var showError = false
    
    func handle(_ error: CirklError) {
        currentError = error
        showError = true
    }
    
    func clearError() {
        currentError = nil
        showError = false
    }
}

struct CirklError: Error, Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let recoveryAction: (() -> Void)?
    
    init(title: String, message: String, recoveryAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.recoveryAction = recoveryAction
    }
}

// MARK: - VIEW EXTENSIONS

extension View {
    func withErrorHandling(_ errorHandler: ErrorHandler) -> some View {
        self.alert(
            errorHandler.currentError?.title ?? "Erreur",
            isPresented: .constant(errorHandler.showError),
            presenting: errorHandler.currentError
        ) { error in
            Button("OK") {
                error.recoveryAction?()
                errorHandler.clearError()
            }
        } message: { error in
            Text(error.message)
        }
    }
}