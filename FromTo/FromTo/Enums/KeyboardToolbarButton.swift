//
//  KeyboardToolbarButton.swift
//  FromTo
//
//  Created by Marlon Simons on 18-01-2026.
//

import SwiftUI

enum KeyboardToolbarButton {
    case clear
    case previous
    case next
    case done(Color)

    var stringValue: String {
        switch self {
        case .clear:
            return "Clear"
        case .previous:
            return "Previous"
        case .next:
            return "Next"
        case .done(_):
            return "Done"
        }
    }

    var color: Color {
        switch self {
        case .clear:
            return .red
        case .previous:
            return .teal
        case .next:
            return .indigo
        case .done(let color):
            return color
        }
    }

    var systemName: String {
        switch self {
        case .clear:
            "trash"
        case .previous:
            "chevron.up"
        case .next:
            "chevron.down"
        case .done:
            "xmark"
        }
    }

    var padding: CGFloat {
        switch self {
        case .clear:
            8
        case .previous, .next:
            14
        case .done:
            10
        }
    }

    var image: some View {
        Image(systemName: systemName)
            .foregroundColor(color)
    }

    /// Creates a standardized keyboard toolbar button
    /// - Parameter action: The action to perform when the button is tapped
    /// - Returns: A configured Button view with consistent styling
    @ViewBuilder
    static func button(
        _ buttonType: KeyboardToolbarButton,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            buttonType.image
                .kbCircleBackground(
                    color: buttonType.color,
                    padding: buttonType.padding
                )
        }
    }
}
