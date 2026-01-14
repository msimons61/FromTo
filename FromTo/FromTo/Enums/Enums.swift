//
//  Enums.swift
//  FromTo
//
//  Created by Marlon Simons on 13-01-2026.
//

import Foundation
import SwiftUI


enum KeyboardToolbarButtonType: Shape {
    
    func path(in rect: CGRect) -> Path {
        return Path.init()
    }
    
    case circle, capsule
    
    func shape() -> any Shape {
        switch self {
        case .circle:
            return Circle()
        case .capsule:
            return Capsule()
        }
    }
}
