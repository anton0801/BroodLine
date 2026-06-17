//
//  HistoryView.swift
//  BroodLine
//

import SwiftUI

enum HistoryFilter: String, CaseIterable, Identifiable, Hashable {
    case all, paired, hatched, ringed
    var id: String { rawValue }
    var label: String { self == .all ? "All" : rawValue.capitalized }
    var type: HistoryType? { self == .all ? nil : HistoryType(rawValue: rawValue) }
}

enum HistoryFilterNew: String, CaseIterable, Identifiable, Hashable {
    case all, paired, ringed
    var id: String { rawValue }
    var label: String { self == .all ? "All" : rawValue.capitalized }
    var type: HistoryType? { self == .all ? nil : HistoryType(rawValue: rawValue) }
}

struct HistoryView: View {
    @EnvironmentObject var store: DataStore
    @State private var filter: HistoryFilter = .all

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ChipPicker(items: HistoryFilter.allCases, label: { $0.label }, selection: $filter)

                    let entries = filtered
                    if entries.isEmpty {
                        EmptyStateView(icon: "clock.arrow.circlepath",
                                       title: "No history yet",
                                       message: "Pairings, hatches and ringings will appear here automatically.")
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                HistoryRow(entry: entry, isLast: index == entries.count - 1)
                            }
                        }
                    }
                    TabBarSpacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
        }
        .navigationBarTitle("History", displayMode: .large)
    }

    private var filtered: [HistoryEntry] {
        store.history.filter { filter.type == nil || $0.type == filter.type }
            .sorted { $0.date > $1.date }
    }
}

struct HistoryRow: View {
    @EnvironmentObject var store: DataStore
    let entry: HistoryEntry
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(entry.type.color.opacity(0.18)).frame(width: 38, height: 38)
                    Image(systemName: entry.type.icon).foregroundColor(entry.type.color).font(.system(size: 16))
                }
                if !isLast {
                    Rectangle().fill(Palette.border).frame(width: 2).frame(maxHeight: .infinity)
                }
            }
            destinationLink {
                AppCard(padding: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.text).font(AppFont.medium(14)).foregroundColor(Palette.textPrimary)
                        Text(entry.date, style: .date).font(AppFont.caption(11)).foregroundColor(Palette.textSecondary)
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func destinationLink<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if let id = entry.relatedID, store.pair(id) != nil {
            NavigationLink(destination: PairDetailView(pairID: id)) { content() }
                .buttonStyle(PlainButtonStyle())
        } else if let id = entry.relatedID, store.bird(id) != nil {
            NavigationLink(destination: BirdDetailView(birdID: id)) { content() }
                .buttonStyle(PlainButtonStyle())
        } else {
            content()
        }
    }
}
