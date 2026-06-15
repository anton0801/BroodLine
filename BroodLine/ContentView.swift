//
//  ContentView.swift
//  BroodLine
//
//  RootView drives the app entry flow: Splash → Onboarding (first launch
//  only) → Main App. There is no auth/welcome/profile gate of any kind.
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var phase: Phase = .main
    
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
    
    enum Phase { case onboarding, main }

    var body: some View {
        ZStack {
            switch phase {
            case .onboarding:
                OnboardingView {
                    hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.5)) { phase = .main }
                }
                .transition(.opacity)

            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .environmentObject(store)
        .environmentObject(theme)
        .preferredColorScheme(theme.colorScheme)
        .accentColor(Palette.primary)
        .onAppear {
            if !hasCompletedOnboarding {
                phase = .onboarding
            } else {
                phase = .main
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(DataStore())
            .environmentObject(ThemeManager())
    }
}
