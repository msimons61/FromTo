//
//  CapsuleBackground.swift
//  FromTo
//
//  Created by Marlon Simons on 15-01-2026.
//

import SwiftUI

struct CapsuleBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var fgColor: Color
    var font: Font
    var hPadding: CGFloat
    var vPadding: CGFloat

    func body(content: Content) -> some View {
        content
            .foregroundColor(fgColor)
            .font(font)
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
            .background(Color(.secondarySystemFill))
            .clipShape(Capsule())
    }
}

extension View {
    func capsuleBackground(
        fgColor: Color,
        font: Font = .caption,
        hPadding: CGFloat,
        vPadding: CGFloat,
    ) -> some View {
        modifier(
            CapsuleBackground(
                fgColor: fgColor,
                font: font,
                hPadding: hPadding,
                vPadding: vPadding,
            )
        )
    }
}
