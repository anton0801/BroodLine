//
//  Typography.swift
//  BroodLine
//
//  Rounded system-font scale with explicit weights.
//

import SwiftUI

enum AppFont {
    static func display(_ size: CGFloat = 32) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func title(_ size: CGFloat = 24)   -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func headline(_ size: CGFloat = 18) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 16)    -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func medium(_ size: CGFloat = 16)  -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func caption(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func mono(_ size: CGFloat = 15)    -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
}

extension Text {
    func display(_ size: CGFloat = 32) -> Text { font(AppFont.display(size)) }
    func appTitle(_ size: CGFloat = 24) -> Text { font(AppFont.title(size)) }
    func headline(_ size: CGFloat = 18) -> Text { font(AppFont.headline(size)) }
}
