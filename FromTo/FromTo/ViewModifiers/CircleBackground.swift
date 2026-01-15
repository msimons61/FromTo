//
//  CircleBackground.swift
//  FromTo
//
//  Created by Marlon Simons on 14-01-2026.
//

import SwiftUI

struct CircleBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var fgColor: Color
    var font: Font
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .foregroundColor(fgColor)
            .font(font)
            .padding(padding)
            .background(Color(.secondarySystemFill))
            .clipShape(Circle())
    }
}

extension View {
    func circleBackground(
        fgColor: Color,
        font: Font = .caption,
        padding: CGFloat = 2,
    ) -> some View {
        modifier(CircleBackground(
            fgColor: fgColor,
            font: font,
            padding: padding,
        ))
    }
}
