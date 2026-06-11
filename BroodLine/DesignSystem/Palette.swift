//
//  Palette.swift
//  BroodLine
//
//  Central color palette. Dark values come straight from the brand spec;
//  light values are a tuned counterpart so theme switching is clearly visible.
//

import SwiftUI
import UIKit

enum Palette {
    // MARK: Backgrounds
    static let bg          = Color.dynamic(light: "#F3F6F3", dark: "#0E1512")
    static let bgDeep      = Color.dynamic(light: "#E7EEE9", dark: "#0A0F0C")
    static let bgSoft      = Color.dynamic(light: "#FFFFFF", dark: "#16201B")

    // MARK: Cards
    static let card        = Color.dynamic(light: "#FFFFFF", dark: "#1A2620")
    static let cardHover   = Color.dynamic(light: "#EEF3EF", dark: "#22332B")
    static let border      = Color.dynamic(light: "#D8E2DC", dark: "#2E4238")
    static let hairline    = Color.dynamic(
        light: UIColor.black.withAlphaComponent(0.06),
        dark: UIColor.white.withAlphaComponent(0.05)
    )

    // MARK: Primary accent (line / growth)
    static let primary       = Color(hex: "#10B981")
    static let primaryActive = Color(hex: "#059669")
    static let primaryGlowC  = Color(hex: "#34D399")

    // MARK: Copper accent (breed / award)
    static let copper      = Color(hex: "#D97757")
    static let copperDark  = Color(hex: "#B45309")
    static let copperLight = Color(hex: "#FBBF77")

    // MARK: Structural accent (navigation / sire-dam branches / chart lines)
    static let structural     = Color(hex: "#38BDF8")
    static let structuralSoft = Color(hex: "#7DD3FC")

    // MARK: Status
    static let statusReady    = Color(hex: "#22C55E")
    static let statusProgress = Color(hex: "#38BDF8")
    static let statusWarn     = Color(hex: "#FBBF24")
    static let statusRisk     = Color(hex: "#EF4444")

    // MARK: Charts
    static let chartStrong = Color(hex: "#22C55E")
    static let chartMedium = Color(hex: "#FBBF24")
    static let chartWeak   = Color(hex: "#EF4444")
    static let chartActive = Color(hex: "#D97757")

    // MARK: Text
    static let textPrimary   = Color.dynamic(light: "#0E1512", dark: "#ECFDF5")
    static let textSecondary = Color.dynamic(light: "#466153", dark: "#A7C3B5")
    static let textDisabled  = Color.dynamic(light: "#8AA597", dark: "#5F7A6E")

    // MARK: Button text
    static let onPrimary       = Color(hex: "#0E1512")
    static let secondaryText   = Color.dynamic(light: "#0E5A43", dark: "#D1FAE5")
    static let onDanger        = Color(hex: "#FFFFFF")

    // MARK: Effects
    static let greenGlow  = Color(hex: "#10B981").opacity(0.35)
    static let copperGlow = Color(hex: "#D97757").opacity(0.28)
    static let shadow     = Color.black.opacity(0.6)

    // MARK: Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [primaryGlowC, primary, primaryActive],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var copperGradient: LinearGradient {
        LinearGradient(colors: [copperLight, copper, copperDark],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [bgDeep, bg], startPoint: .top, endPoint: .bottom)
    }
}
