//
//  PairsView.swift
//  BroodLine
//

import SwiftUI

enum PairFilter: String, CaseIterable, Identifiable, Hashable {
    case all, active, paused, closed
    var id: String { rawValue }
    var label: String { self == .all ? "All" : rawValue.capitalized }
    var status: PairStatus? { self == .all ? nil : PairStatus(rawValue: rawValue) }
}

final class PairsViewModel: ObservableObject {
    @Published var filter: PairFilter = .all

    func filtered(_ pairs: [BreedingPair]) -> [BreedingPair] {
        pairs.filter { filter.status == nil || $0.status == filter.status }
            .sorted { $0.startDate > $1.startDate }
    }
}

struct PairsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var vm = PairsViewModel()
    @State private var showAdd = false

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ChipPicker(items: PairFilter.allCases, label: { $0.label }, selection: $vm.filter)

                        let pairs = vm.filtered(store.pairs)
                        if pairs.isEmpty {
                            EmptyStateView(icon: "heart",
                                           title: "No pairs yet",
                                           message: "Create a cock × hen pair to track broods and lineage.",
                                           actionTitle: "Add Pair") { showAdd = true }
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(pairs) { pair in
                                    NavigationLink(destination: PairDetailView(pairID: pair.id)) {
                                        PairRow(pair: pair)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button { store.deletePair(pair) } label: {
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
            .navigationBarTitle("Pairs", displayMode: .large)
            .navigationBarItems(trailing: Button { showAdd = true } label: {
                Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundColor(Palette.primary)
            })
            .sheet(isPresented: $showAdd) {
                AddPairView().environmentObject(store).environmentObject(theme)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct PairRow: View {
    @EnvironmentObject var store: DataStore
    let pair: BreedingPair

    var body: some View {
        let f = store.inbreedingF(for: pair)
        let band = RiskBand.from(f)
        return AppCard(padding: 12) {
            HStack(spacing: 12) {
                PhotoThumb(filename: pair.coverPhotoFilename, size: 52, fallbackIcon: "heart.fill")
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.pairLabel(pair)).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                        .lineLimit(1)
                    Text("\(store.pairLine(pair)) · \(store.broodCount(for: pair)) broods")
                        .font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    HStack(spacing: 6) {
                        StatusBadge(text: pair.status.label, color: pair.status.color)
                        if band >= .moderate {
                            StatusBadge(text: "F \(Int(f * 100))%", color: band.color)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Palette.textDisabled)
            }
        }
    }
}
