//
//  KbCapsuleBackground.swift
//  FromTo
//
//  Created by Marlon Simons on 14-01-2026.
//

import SwiftUI

struct KbCapsuleBackground: ViewModifier {
    var color: Color
    var bgColor: Color
    var hPadding: CGFloat
    var vPadding: CGFloat
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
            .background(bgColor)
            .clipShape(Capsule())
    }
}

extension View {
    func kbCapsuleBackground(
        color: Color,
        bgColor: Color = Color.secondary,
        hPadding: CGFloat = 10,
        vPadding: CGFloat = 8,
    ) -> some View {
        modifier(
            KbCapsuleBackground(
                color: color,
                bgColor: color.opacity(0.3),
                hPadding: hPadding,
                vPadding: vPadding,
            )
        )
    }
    
}
