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
    var prominent: Bool = false

    func body(content: Content) -> some View {
        content
            .foregroundColor(prominent ? .primary : fgColor)
            .font(font)
            .padding(padding)
//            .background(prominent ? fgColor : .clear)
            .background(prominent ? fgColor : Color(.secondarySystemFill))
            .clipShape(Circle())
    }
}

extension View {
    func circleBackground(
        fgColor: Color,
        font: Font = .caption,
        padding: CGFloat = 2,
        prominent: Bool = false
    ) -> some View {
        modifier(CircleBackground(
            fgColor: fgColor,
            font: font,
            padding: padding,
            prominent: prominent,
        ))
    }
}

#Preview {
//    let tab = AppTab.investment
//    let tab = AppTab.projection
    let tab = AppTab.difference
//    let tab = AppTab.settings
    
    VStack{
        Image(systemName: "checkmark")
            .circleBackground(fgColor: tab.color(), font: .body, padding: 6)
        Image(systemName: "xmark")
            .circleBackground(fgColor: tab.color(), font: .body, padding: 6)
        Image(systemName: "checkmark")
            .circleBackground(fgColor: tab.color(), font: .body, padding: 6, prominent: true)
        Image(systemName: "xmark")
            .circleBackground(fgColor: tab.color(), font: .body, padding: 6, prominent: true)
    }

}
