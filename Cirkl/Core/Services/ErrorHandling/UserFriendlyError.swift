//
//  UserFriendlyError.swift
//  Cirkl
//
//  Created by Claude on 12/01/2026.
//

import Foundation

// MARK: - User Friendly Error Protocol

/// Protocol for errors that can be presented to users with friendly messages
protocol UserFriendlyErrorConvertible: Error {
    var userFriendlyError: UserFriendlyError { get }
}

// MARK: - User Friendly Error

/// Centralized error handling with user-friendly messages
/// Converts technical errors into messages users can understand and act upon
struct UserFriendlyError: LocalizedError, Equatable {

    // MARK: - Properties

    /// User-facing title (short)
    let title: String

    /// User-facing message (descriptive)
    let message: String

    /// Suggested recovery action
    let recoveryAction: String?

    /// Icon for visual feedback (SF Symbol name)
    let icon: String

    /// Whether the error is recoverable by user action
    let isRecoverable: Bool

    /// Original error for logging (not shown to user)
    let underlyingError: Error?

    // MARK: - LocalizedError Conformance

    var errorDescription: String? { title }
    var failureReason: String? { message }
    var recoverySuggestion: String? { recoveryAction }

    // MARK: - Initialization

    init(
        title: String,
        message: String,
        recoveryAction: String? = nil,
        icon: String = "exclamationmark.triangle",
        isRecoverable: Bool = true,
        underlyingError: Error? = nil
    ) {
        self.title = title
        self.message = message
        self.recoveryAction = recoveryAction
        self.icon = icon
        self.isRecoverable = isRecoverable
        self.underlyingError = underlyingError
    }

    // MARK: - Equatable (ignores underlyingError)

    static func == (lhs: UserFriendlyError, rhs: UserFriendlyError) -> Bool {
        lhs.title == rhs.title &&
        lhs.message == rhs.message &&
        lhs.recoveryAction == rhs.recoveryAction &&
        lhs.icon == rhs.icon &&
        lhs.isRecoverable == rhs.isRecoverable
    }
}

// MARK: - Common Error Cases

extension UserFriendlyError {

    // MARK: - Network Errors

    /// Device is offline
    static var networkOffline: UserFriendlyError {
        UserFriendlyError(
            title: "Pas de connexion",
            message: "Vous semblez être hors ligne. Vérifiez votre connexion Internet et réessayez.",
            recoveryAction: "Réessayer",
            icon: "wifi.slash",
            isRecoverable: true
        )
    }

    /// Request timed out
    static var timeout: UserFriendlyError {
        UserFriendlyError(
            title: "Délai dépassé",
            message: "La connexion a pris trop de temps. Votre réseau est peut-être lent.",
            recoveryAction: "Réessayer",
            icon: "clock.badge.exclamationmark",
            isRecoverable: true
        )
    }

    /// Server returned an error
    static func serverError(code: Int? = nil) -> UserFriendlyError {
        UserFriendlyError(
            title: "Problème serveur",
            message: "Un problème technique est survenu de notre côté. Notre équipe est informée.",
            recoveryAction: "Réessayer plus tard",
            icon: "server.rack",
            isRecoverable: true
        )
    }

    /// Generic network error
    static func networkError(_ error: Error) -> UserFriendlyError {
        // Check for specific URLError cases
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkOffline
            case .timedOut:
                return .timeout
            case .cannotFindHost, .cannotConnectToHost:
                return .serverError()
            default:
                break
            }
        }

        return UserFriendlyError(
            title: "Erreur réseau",
            message: "Impossible de se connecter au serveur. Vérifiez votre connexion.",
            recoveryAction: "Réessayer",
            icon: "network.slash",
            isRecoverable: true,
            underlyingError: error
        )
    }

    // MARK: - Authentication Errors

    /// Session expired
    static var sessionExpired: UserFriendlyError {
        UserFriendlyError(
            title: "Session expirée",
            message: "Votre session a expiré. Veuillez vous reconnecter.",
            recoveryAction: "Se reconnecter",
            icon: "person.badge.clock",
            isRecoverable: true
        )
    }

    /// Invalid credentials
    static var invalidCredentials: UserFriendlyError {
        UserFriendlyError(
            title: "Identifiants incorrects",
            message: "L'email ou le mot de passe est incorrect. Veuillez vérifier et réessayer.",
            recoveryAction: "Réessayer",
            icon: "lock.trianglebadge.exclamationmark",
            isRecoverable: true
        )
    }

    /// Biometric authentication failed
    static var biometricFailed: UserFriendlyError {
        UserFriendlyError(
            title: "Authentification échouée",
            message: "L'authentification biométrique a échoué. Utilisez votre code d'accès.",
            recoveryAction: "Utiliser le code",
            icon: "faceid",
            isRecoverable: true
        )
    }

    // MARK: - Validation Errors

    /// Generic validation failure
    static func validationFailed(field: String, reason: String) -> UserFriendlyError {
        UserFriendlyError(
            title: "Champ invalide",
            message: "\(field) : \(reason)",
            recoveryAction: "Corriger",
            icon: "exclamationmark.circle",
            isRecoverable: true
        )
    }

    /// Email validation
    static var invalidEmail: UserFriendlyError {
        validationFailed(
            field: "Email",
            reason: "Veuillez entrer une adresse email valide."
        )
    }

    /// Phone validation
    static var invalidPhone: UserFriendlyError {
        validationFailed(
            field: "Téléphone",
            reason: "Veuillez entrer un numéro de téléphone valide."
        )
    }

    /// Required field empty
    static func requiredField(_ fieldName: String) -> UserFriendlyError {
        validationFailed(
            field: fieldName,
            reason: "Ce champ est obligatoire."
        )
    }

    // MARK: - Connection/Verification Errors

    /// QR code scan failed
    static var qrScanFailed: UserFriendlyError {
        UserFriendlyError(
            title: "Scan échoué",
            message: "Impossible de lire le QR code. Assurez-vous qu'il est bien visible et réessayez.",
            recoveryAction: "Réessayer",
            icon: "qrcode.viewfinder",
            isRecoverable: true
        )
    }

    /// NFC not available
    static var nfcNotAvailable: UserFriendlyError {
        UserFriendlyError(
            title: "NFC indisponible",
            message: "Votre appareil ne supporte pas le NFC ou il est désactivé.",
            recoveryAction: nil,
            icon: "wave.3.right.circle",
            isRecoverable: false
        )
    }

    /// Verification failed
    static var verificationFailed: UserFriendlyError {
        UserFriendlyError(
            title: "Vérification échouée",
            message: "La vérification n'a pas pu être complétée. Rapprochez-vous de l'autre personne.",
            recoveryAction: "Réessayer",
            icon: "person.2.slash",
            isRecoverable: true
        )
    }

    /// Connection already exists
    static var connectionExists: UserFriendlyError {
        UserFriendlyError(
            title: "Déjà connecté",
            message: "Vous êtes déjà en connexion avec cette personne.",
            recoveryAction: nil,
            icon: "person.2.fill",
            isRecoverable: false
        )
    }

    // MARK: - Data Errors

    /// Failed to save data
    static var saveFailed: UserFriendlyError {
        UserFriendlyError(
            title: "Sauvegarde échouée",
            message: "Impossible d'enregistrer les modifications. Veuillez réessayer.",
            recoveryAction: "Réessayer",
            icon: "externaldrive.badge.exclamationmark",
            isRecoverable: true
        )
    }

    /// Failed to load data
    static var loadFailed: UserFriendlyError {
        UserFriendlyError(
            title: "Chargement échoué",
            message: "Impossible de charger les données. Vérifiez votre connexion.",
            recoveryAction: "Réessayer",
            icon: "arrow.clockwise.icloud",
            isRecoverable: true
        )
    }

    /// Data sync failed
    static var syncFailed: UserFriendlyError {
        UserFriendlyError(
            title: "Synchronisation échouée",
            message: "Vos données n'ont pas pu être synchronisées. Elles seront synchronisées automatiquement plus tard.",
            recoveryAction: "Réessayer maintenant",
            icon: "arrow.triangle.2.circlepath",
            isRecoverable: true
        )
    }

    // MARK: - Permission Errors

    /// Camera permission denied
    static var cameraPermissionDenied: UserFriendlyError {
        UserFriendlyError(
            title: "Accès caméra refusé",
            message: "L'accès à la caméra est nécessaire pour scanner les QR codes.",
            recoveryAction: "Ouvrir les Réglages",
            icon: "camera.badge.ellipsis",
            isRecoverable: true
        )
    }

    /// Contacts permission denied
    static var contactsPermissionDenied: UserFriendlyError {
        UserFriendlyError(
            title: "Accès contacts refusé",
            message: "L'accès aux contacts est nécessaire pour importer votre réseau existant.",
            recoveryAction: "Ouvrir les Réglages",
            icon: "person.crop.circle.badge.exclamationmark",
            isRecoverable: true
        )
    }

    /// Location permission denied
    static var locationPermissionDenied: UserFriendlyError {
        UserFriendlyError(
            title: "Localisation désactivée",
            message: "La localisation permet de découvrir des connexions à proximité.",
            recoveryAction: "Ouvrir les Réglages",
            icon: "location.slash",
            isRecoverable: true
        )
    }

    /// Notification permission denied
    static var notificationPermissionDenied: UserFriendlyError {
        UserFriendlyError(
            title: "Notifications désactivées",
            message: "Activez les notifications pour recevoir votre Morning Brief et les opportunités.",
            recoveryAction: "Ouvrir les Réglages",
            icon: "bell.slash",
            isRecoverable: true
        )
    }

    // MARK: - AI/Chat Errors

    /// AI response failed
    static var aiResponseFailed: UserFriendlyError {
        UserFriendlyError(
            title: "Réponse indisponible",
            message: "Votre compagnon relationnel est temporairement indisponible. Réessayez dans quelques instants.",
            recoveryAction: "Réessayer",
            icon: "sparkles",
            isRecoverable: true
        )
    }

    /// Message send failed
    static var messageSendFailed: UserFriendlyError {
        UserFriendlyError(
            title: "Envoi échoué",
            message: "Votre message n'a pas pu être envoyé. Vérifiez votre connexion.",
            recoveryAction: "Réessayer",
            icon: "paperplane.fill",
            isRecoverable: true
        )
    }

    // MARK: - Generic Errors

    /// Unknown error (fallback)
    static func unknown(_ error: Error? = nil) -> UserFriendlyError {
        UserFriendlyError(
            title: "Erreur inattendue",
            message: "Une erreur inattendue s'est produite. Veuillez réessayer.",
            recoveryAction: "Réessayer",
            icon: "exclamationmark.triangle",
            isRecoverable: true,
            underlyingError: error
        )
    }
}

// MARK: - Error Conversion Extension

extension Error {

    /// Converts any error to a user-friendly error
    var userFriendly: UserFriendlyError {
        // If already a UserFriendlyError, return it
        if let friendly = self as? UserFriendlyError {
            return friendly
        }

        // If conforms to UserFriendlyErrorConvertible, use that
        if let convertible = self as? UserFriendlyErrorConvertible {
            return convertible.userFriendlyError
        }

        // Check for common error types
        if let urlError = self as? URLError {
            return .networkError(urlError)
        }

        // Default to unknown error
        return .unknown(self)
    }
}

// MARK: - Error Logging

extension UserFriendlyError {

    /// Log the error for debugging (not shown to user)
    func log(file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("⚠️ [\(fileName):\(line)] \(function)")
        print("   Title: \(title)")
        print("   Message: \(message)")
        if let underlying = underlyingError {
            print("   Underlying: \(underlying)")
        }
        #endif
    }
}

// MARK: - HTTP Status Code Extension

extension UserFriendlyError {

    /// Creates appropriate error from HTTP status code
    static func fromHTTPStatus(_ statusCode: Int, data: Data? = nil) -> UserFriendlyError {
        switch statusCode {
        case 400:
            return UserFriendlyError(
                title: "Requête invalide",
                message: "Les informations envoyées sont incorrectes.",
                recoveryAction: "Vérifier et réessayer",
                icon: "exclamationmark.circle"
            )
        case 401:
            return .sessionExpired
        case 403:
            return UserFriendlyError(
                title: "Accès refusé",
                message: "Vous n'avez pas les permissions nécessaires pour cette action.",
                icon: "lock.fill",
                isRecoverable: false
            )
        case 404:
            return UserFriendlyError(
                title: "Non trouvé",
                message: "L'élément demandé n'existe plus ou a été déplacé.",
                icon: "questionmark.folder",
                isRecoverable: false
            )
        case 409:
            return .connectionExists
        case 429:
            return UserFriendlyError(
                title: "Trop de requêtes",
                message: "Veuillez patienter quelques instants avant de réessayer.",
                recoveryAction: "Réessayer plus tard",
                icon: "clock.arrow.circlepath"
            )
        case 500...599:
            return .serverError(code: statusCode)
        default:
            return .unknown()
        }
    }
}
