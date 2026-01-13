//
//  KeyboardToolbar.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import SwiftUI

struct KeyboardToolbarModifier: ViewModifier {
    @FocusState.Binding var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                }
            }
    }
}

extension View {
    func keyboardToolbar(isFocused: FocusState<Bool>.Binding) -> some View {
        self.modifier(KeyboardToolbarModifier(isFocused: isFocused))
    }
}
