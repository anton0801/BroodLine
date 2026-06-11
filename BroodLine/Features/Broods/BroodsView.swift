//
//  BroodsView.swift
//  BroodLine
//

import SwiftUI

enum BroodFilter: String, CaseIterable, Identifiable, Hashable {
    case all, open, closed
    var id: String { rawValue }
    var label: String { self == .all ? "All" : rawValue.capitalized }
    var status: BroodStatus? { self == .all ? nil : BroodStatus(rawValue: rawValue) }
}

final class BroodsViewModel: ObservableObject {
    @Published var filter: BroodFilter = .all
    func filtered(_ broods: [Brood]) -> [Brood] {
        broods.filter { filter.status == nil || $0.status == filter.status }
            .sorted { $0.hatchDate > $1.hatchDate }
    }
}

struct BroodsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var vm = BroodsViewModel()
    @State private var showAdd = false
    @State private var editingBrood: Brood?

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ChipPicker(items: BroodFilter.allCases, label: { $0.label }, selection: $vm.filter)

                    let broods = vm.filtered(store.broods)
                    if broods.isEmpty {
                        EmptyStateView(icon: "circle.hexagongrid",
                                       title: "No broods yet",
                                       message: "Register a brood from a pair to track hatch results and rings.",
                                       actionTitle: "Register Brood") { showAdd = true }
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(broods) { brood in
                                Button { editingBrood = brood } label: { BroodRow(brood: brood) }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button { store.deleteBrood(brood) } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    TabBarSpacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
        }
        .navigationBarTitle("Broods", displayMode: .large)
        .navigationBarItems(trailing: Button { showAdd = true } label: {
            Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundColor(Palette.primary)
        })
        .sheet(isPresented: $showAdd) {
            AddBroodView().environmentObject(store).environmentObject(theme)
        }
        .sheet(item: $editingBrood) { brood in
            AddBroodView(editing: brood).environmentObject(store).environmentObject(theme)
        }
    }
}

struct BroodRow: View {
    @EnvironmentObject var store: DataStore
    let brood: Brood

    var body: some View {
        AppCard(padding: 12) {
            HStack(spacing: 12) {
                IconBadge(icon: "circle.hexagongrid.fill", color: brood.status.color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.broodTitle(brood)).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary).lineLimit(1)
                    Text("\(brood.hatchedCount)/\(brood.eggCount) hatched · \(brood.ringedCount) ringed · ♂\(brood.malesCount) ♀\(brood.femalesCount)")
                        .font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(text: brood.status.label, color: brood.status.color)
                    Text(brood.hatchDate, style: .date).font(AppFont.caption(10)).foregroundColor(Palette.textSecondary)
                }
            }
        }
    }
}
