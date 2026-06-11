//
//  BirdsView.swift
//  BroodLine
//

import SwiftUI

enum BirdFilter: String, CaseIterable, Identifiable, Hashable {
    case all, active, breeding, archived, sold, deceased
    var id: String { rawValue }
    var label: String { self == .all ? "All" : rawValue.capitalized }
    var status: BirdStatus? { self == .all ? nil : BirdStatus(rawValue: rawValue) }
}

final class BirdsViewModel: ObservableObject {
    @Published var search = ""
    @Published var filter: BirdFilter = .all

    func filtered(_ birds: [Bird]) -> [Bird] {
        birds.filter { bird in
            if let status = filter.status, bird.status != status { return false }
            if !search.isEmpty {
                let q = search.lowercased()
                return bird.ringID.lowercased().contains(q)
                    || bird.name.lowercased().contains(q)
                    || bird.lineTag.lowercased().contains(q)
            }
            return true
        }
        .sorted { $0.createdAt > $1.createdAt }
    }
}

struct BirdsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var vm = BirdsViewModel()
    @State private var showAdd = false

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        SearchBar(text: $vm.search, placeholder: "Search ring, name or line")
                        ChipPicker(items: BirdFilter.allCases, label: { $0.label }, selection: $vm.filter)

                        let birds = vm.filtered(store.birds)
                        if birds.isEmpty {
                            EmptyStateView(icon: "bird",
                                           title: "No birds yet",
                                           message: "Add your breeders to start building lines and pedigrees.",
                                           actionTitle: "Add Bird") { showAdd = true }
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(birds) { bird in
                                    NavigationLink(destination: BirdDetailView(birdID: bird.id)) {
                                        BirdRow(bird: bird)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        if bird.status != .archived {
                                            Button { store.archiveBird(bird) } label: {
                                                Label("Archive", systemImage: "archivebox")
                                            }
                                        }
                                        Button { store.deleteBird(bird) } label: {
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
            .navigationBarTitle("Birds", displayMode: .large)
            .navigationBarItems(trailing: Button { showAdd = true } label: {
                Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundColor(Palette.primary)
            })
            .sheet(isPresented: $showAdd) {
                AddBirdView().environmentObject(store).environmentObject(theme)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct BirdRow: View {
    @EnvironmentObject var store: DataStore
    let bird: Bird

    var body: some View {
        AppCard(padding: 12) {
            HStack(spacing: 12) {
                PhotoThumb(filename: bird.photoFilename, size: 52, fallbackIcon: bird.sex.icon)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(bird.displayName).font(AppFont.medium(16)).foregroundColor(Palette.textPrimary)
                        Text(bird.sex.short).font(AppFont.headline(15)).foregroundColor(bird.sex.color)
                    }
                    Text("\(bird.ringID) · \(bird.lineTag.isEmpty ? "No line" : bird.lineTag)")
                        .font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
                Spacer()
                StatusBadge(text: bird.status.label, color: bird.status.color)
            }
        }
    }
}
