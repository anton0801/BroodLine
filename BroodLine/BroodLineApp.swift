//
//  BroodLineApp.swift
//  BroodLine
//
//  App entry point. Wires the shared DataStore + ThemeManager into the
//  environment and applies the chosen color scheme app-wide.
//

import SwiftUI
import UIKit

@main
struct BroodLineApp: App {
    @StateObject private var store = DataStore()
    @StateObject private var theme = ThemeManager()

    init() {
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        let titleColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "#ECFDF5") : UIColor(hex: "#0E1512")
        }
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(hex: "#10B981")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)
                .accentColor(Palette.primary)
        }
    }
}
