//
//  ShareSheet.swift
//  Cirkl
//
//  Created by Claude on 16/01/2026.
//

import SwiftUI
import UIKit

// MARK: - ShareSheet

/// SwiftUI wrapper pour UIActivityViewController (share sheet iOS)
/// Utilisé pour partager du texte, des liens, des images, etc.
struct ShareSheet: UIViewControllerRepresentable {

    /// Items à partager (texte, URL, image, etc.)
    let items: [Any]

    /// Applications à exclure du share sheet (optionnel)
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    /// Callback appelé quand l'utilisateur termine l'action
    var completionHandler: ((Bool) -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        controller.excludedActivityTypes = excludedActivityTypes

        controller.completionWithItemsHandler = { _, completed, _, _ in
            completionHandler?(completed)
        }

        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {
        // Pas de mise à jour nécessaire
    }
}

// MARK: - Preview

#Preview {
    ShareSheet(items: ["Hello World! This is a test message."])
}
