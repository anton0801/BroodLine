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
    @State private var phase: Phase = .splash

    enum Phase { case splash, onboarding, main }

    var body: some View {
        ZStack {
            switch phase {
            case .splash:
                LaunchView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        phase = hasCompletedOnboarding ? .main : .onboarding
                    }
                }
                .transition(.opacity)

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
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(DataStore())
            .environmentObject(ThemeManager())
    }
}
