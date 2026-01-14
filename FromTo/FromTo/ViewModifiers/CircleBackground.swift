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
    var size: CGFloat

    func body(content: Content) -> some View {
        content
            .foregroundColor(fgColor)
            .font(font)
            .padding(size)
            .background(Color(.secondarySystemFill))
            .clipShape(Circle())
    }
}

extension View {
    func circleBackground(
        fgColor: Color,
        font: Font = .caption,
        size: CGFloat = 2,
    ) -> some View {
        modifier(CircleBackground(
            fgColor: fgColor,
            font: font,
            size: size,
        ))
    }
}
