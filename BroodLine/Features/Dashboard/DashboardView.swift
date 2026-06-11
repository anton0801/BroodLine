//
//  DashboardView.swift
//  BroodLine
//

import SwiftUI

final class DashboardViewModel: ObservableObject {
    func tiles(for store: DataStore) -> [DashboardTile] {
        let best = store.bestLine
        return [
            DashboardTile(title: "Active Pairs", value: "\(store.activePairs.count)",
                          icon: "heart.fill", color: Palette.statusProgress, destination: .pairs),
            DashboardTile(title: "Open Broods", value: "\(store.openBroods.count)",
                          icon: "circle.hexagongrid.fill", color: Palette.primary, destination: .broods),
            DashboardTile(title: "Warnings", value: "\(store.inbreedingWarnings.count)",
                          icon: "exclamationmark.triangle.fill", color: Palette.statusRisk, destination: .recommendations),
            DashboardTile(title: "Best Line", value: best.map { $0.line } ?? "—",
                          icon: "rosette", color: Palette.copper, destination: .reports)
        ]
    }
}

struct DashboardTile: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
    let destination: TileDestination
    enum TileDestination { case pairs, broods, recommendations, reports }
}

struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var vm = DashboardViewModel()
    @State private var showAddBird = false
    @State private var showAddPair = false

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        greeting
                        quickActions
                        statGrid
                        attentionSection
                        bestLineCard
                        recentActivity
                        TabBarSpacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                }
            }
            .navigationBarTitle("Dashboard", displayMode: .inline)
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill").foregroundColor(Palette.primary)
            })
            .sheet(isPresented: $showAddBird) {
                AddBirdView().environmentObject(store).environmentObject(theme)
            }
            .sheet(isPresented: $showAddPair) {
                AddPairView().environmentObject(store).environmentObject(theme)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var greeting: some View {
        AppCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Palette.primary.opacity(0.15)).frame(width: 50, height: 50)
                    BranchShape().stroke(Palette.primary, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                        .frame(width: 26, height: 24)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your flock").font(AppFont.title(22)).foregroundColor(Palette.textPrimary)
                    Text("\(store.birds.count) birds · \(store.pairs.count) pairs · \(store.broods.count) broods")
                        .font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
                Spacer()
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            quickButton("Add Bird", "plus.circle.fill", Palette.primary) { showAddBird = true }
            quickButton("New Pair", "heart.circle.fill", Palette.structural) { showAddPair = true }
            NavigationLink(destination: ReportsView()) {
                quickLabel("Report", "chart.bar.fill", Palette.copper)
            }
        }
    }

    private func quickButton(_ title: String, _ icon: String, _ color: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { quickLabel(title, icon, color) }
            .buttonStyle(ScaleButtonStyle())
    }

    private func quickLabel(_ title: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
            Text(title).font(AppFont.caption()).foregroundColor(Palette.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Palette.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(vm.tiles(for: store)) { tile in
                NavigationLink(destination: destinationView(tile.destination)) {
                    StatTile(title: tile.title, value: tile.value, icon: tile.icon, color: tile.color)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func destinationView(_ d: DashboardTile.TileDestination) -> some View {
        switch d {
        case .pairs: PairsView()
        case .broods: BroodsView()
        case .recommendations: RecommendationsView()
        case .reports: ReportsView()
        }
    }

    @ViewBuilder
    private var attentionSection: some View {
        let warnings = store.inbreedingWarnings
        if !warnings.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Needs attention")
                ForEach(warnings) { pair in
                    NavigationLink(destination: PairDetailView(pairID: pair.id)) {
                        warningRow(pair)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func warningRow(_ pair: BreedingPair) -> some View {
        let f = store.inbreedingF(for: pair)
        let band = RiskBand.from(f)
        return AppCard {
            HStack(spacing: 12) {
                IconBadge(icon: "exclamationmark.triangle.fill", color: band.color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.pairLabel(pair)).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                    Text("Inbreeding F = \(Int(f * 100))%").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
                Spacer()
                StatusBadge(text: band.label, color: band.color)
            }
        }
    }

    @ViewBuilder
    private var bestLineCard: some View {
        if let best = store.bestLine, best.broodCount > 0 {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Best line")
                AppCard {
                    HStack(spacing: 14) {
                        IconBadge(icon: "rosette", color: best.bucket.color, size: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(best.line).font(AppFont.headline(17)).foregroundColor(Palette.textPrimary)
                            Text("\(Int(best.hatchRatio * 100))% hatch · \(best.broodCount) broods · \(best.awards) awards")
                                .font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("\(Int(best.score))").font(AppFont.title(24)).foregroundColor(best.bucket.color)
                            Text("score").font(AppFont.caption(10)).foregroundColor(Palette.textSecondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recentActivity: some View {
        if !store.history.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Recent activity", actionTitle: "See all")
                ForEach(store.history.prefix(4)) { entry in
                    AppCard(padding: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: entry.type.icon).foregroundColor(entry.type.color)
                            Text(entry.text).font(AppFont.caption(13)).foregroundColor(Palette.textPrimary)
                            Spacer()
                            Text(entry.date, style: .date).font(AppFont.caption(11)).foregroundColor(Palette.textSecondary)
                        }
                    }
                }
            }
        }
    }
}
