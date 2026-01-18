//
//  KeyboardToolBarButton.swift
//  FromTo
//
//  Created by Marlon Simons on 14-01-2026.
//

import SwiftUI

struct KbCircleBackground: ViewModifier {
    var color: Color
    var bgColor: Color
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .padding(padding)
            .background(bgColor)
            .clipShape(Circle())
    }
}

extension View {
    func kbCircleBackground(
        color: Color,
        bgColor: Color = Color.secondary,
        padding: CGFloat = 10,
    ) -> some View {
        modifier(
            KbCircleBackground(
                color: color,
                bgColor: color.opacity(0.4),
                padding: padding
            )
        )
    }

}
