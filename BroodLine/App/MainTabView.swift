//
//  MainTabView.swift
//  BroodLine
//
//  Custom themed tab bar with five primary destinations. Secondary sections
//  live under "More".
//

import SwiftUI

enum MainTab: Int, CaseIterable, Identifiable {
    case dashboard, birds, pairs, pedigree, more
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .birds: return "Birds"
        case .pairs: return "Pairs"
        case .pedigree: return "Pedigree"
        case .more: return "More"
        }
    }
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .birds: return "bird.fill"
        case .pairs: return "heart.fill"
        case .pedigree: return "arrow.triangle.branch"
        case .more: return "line.3.horizontal"
        }
    }
}

struct MainTabView: View {
    @State private var tab: MainTab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.bg.ignoresSafeArea()

            Group {
                switch tab {
                case .dashboard: DashboardView()
                case .birds:     BirdsView()
                case .pairs:     PairsView()
                case .pedigree:  PedigreeView()
                case .more:      MoreView()
                }
            }

            CustomTabBar(selection: $tab)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selection: MainTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainTab.allCases) { t in
                TabBarItem(tab: t, isSelected: selection == t) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selection = t }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(tabBarBackground)
    }

    private var tabBarBackground: some View {
        Palette.bgSoft
            .overlay(Rectangle().fill(Palette.hairline).frame(height: 1), alignment: .top)
            .ignoresSafeArea(edges: .bottom)
    }
}

private struct TabBarItem: View {
    let tab: MainTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon).font(.system(size: 19, weight: .semibold))
                Text(tab.title).font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isSelected ? Palette.primary : Palette.textDisabled)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selectionBackground)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder private var selectionBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 14).fill(Palette.primary.opacity(0.14))
        }
    }
}

/// Spacer placed at the end of scrollable content so the tab bar never covers it.
struct TabBarSpacer: View {
    var body: some View { Color.clear.frame(height: 84) }
}
