//
//  PairDetailView.swift
//  BroodLine
//

import SwiftUI

struct PairDetailView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.presentationMode) private var presentationMode
    let pairID: UUID
    @State private var showEdit = false
    @State private var showAddBrood = false
    @State private var showDeleteConfirm = false

    private var pair: BreedingPair? { store.pair(pairID) }

    var body: some View {
        ZStack {
            ScreenBackground()
            if let pair = pair {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        hero(pair)
                        inbreedingCard(pair)
                        parentsRow(pair)
                        broodsSection(pair)
                        actions(pair)
                        TabBarSpacer()
                    }
                    .padding(16)
                }
            } else {
                EmptyStateView(icon: "heart", title: "Pair removed", message: "This pair is no longer tracked.")
            }
        }
        .navigationBarTitle("Pair", displayMode: .inline)
        .navigationBarItems(trailing: Group {
            if pair != nil {
                Button { showEdit = true } label: {
                    Image(systemName: "square.and.pencil").foregroundColor(Palette.primary)
                }
            }
        })
        .sheet(isPresented: $showEdit) {
            AddPairView(editing: pair).environmentObject(store).environmentObject(theme)
        }
        .sheet(isPresented: $showAddBrood) {
            AddBroodView(presetPairID: pairID).environmentObject(store).environmentObject(theme)
        }
        .actionSheet(isPresented: $showDeleteConfirm) {
            ActionSheet(title: Text("Delete this pair?"),
                        message: Text("Its broods will also be removed."),
                        buttons: [
                            .destructive(Text("Delete")) {
                                if let pair = pair { store.deletePair(pair) }
                                presentationMode.wrappedValue.dismiss()
                            },
                            .cancel()
                        ])
        }
    }

    private func hero(_ pair: BreedingPair) -> some View {
        AppCard {
            HStack(spacing: 16) {
                PhotoThumb(filename: pair.coverPhotoFilename, size: 76, corner: 18, fallbackIcon: "heart.fill")
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.pairLabel(pair)).font(AppFont.title(20)).foregroundColor(Palette.textPrimary)
                    Text("Line · \(store.pairLine(pair))").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    HStack(spacing: 8) {
                        StatusBadge(text: pair.status.label, color: pair.status.color)
                        StatusBadge(text: "\(store.broodCount(for: pair)) broods", color: Palette.primary)
                    }
                }
                Spacer()
            }
        }
    }

    private func inbreedingCard(_ pair: BreedingPair) -> some View {
        let f = store.inbreedingF(for: pair)
        let band = RiskBand.from(f)
        return AppCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(Palette.bgSoft, lineWidth: 7).frame(width: 64, height: 64)
                    Circle().trim(from: 0, to: CGFloat(min(f * 4, 1)))
                        .stroke(band.color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90)).frame(width: 64, height: 64)
                    Text("\(Int(f * 100))%").font(AppFont.headline(15)).foregroundColor(Palette.textPrimary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inbreeding coefficient").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    Text(band.label).font(AppFont.headline(18)).foregroundColor(band.color)
                    if band >= .moderate {
                        Text("Consider a less-related mate.").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    }
                }
                Spacer()
            }
        }
    }

    private func parentsRow(_ pair: BreedingPair) -> some View {
        HStack(spacing: 12) {
            parentChip("Sire", pair.sireID, Palette.structural)
            parentChip("Dam", pair.damID, Palette.copper)
        }
    }

    @ViewBuilder
    private func parentChip(_ role: String, _ id: UUID?, _ color: Color) -> some View {
        if let id = id {
            NavigationLink(destination: BirdDetailView(birdID: id)) {
                AppCard(padding: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(role).font(AppFont.caption(11)).foregroundColor(color)
                        Text(store.birdName(id)).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            AppCard(padding: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(role).font(AppFont.caption(11)).foregroundColor(color)
                    Text("Unknown").font(AppFont.medium(15)).foregroundColor(Palette.textDisabled)
                }
            }
        }
    }

    private func broodsSection(_ pair: BreedingPair) -> some View {
        let broods = store.broods.filter { $0.pairID == pair.id }.sorted { $0.hatchDate > $1.hatchDate }
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Broods", actionTitle: "Add") { showAddBrood = true }
            if broods.isEmpty {
                AppCard {
                    Text("No broods yet. Register a brood to track hatch results.")
                        .font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
            } else {
                ForEach(broods) { brood in BroodRow(brood: brood) }
            }
        }
    }

    private func actions(_ pair: BreedingPair) -> some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Register Brood", icon: "plus") { showAddBrood = true }
            if pair.status != .closed {
                SecondaryButton(title: "Close pair", icon: "lock") {
                    var p = pair; p.status = .closed; store.updatePair(p)
                }
            } else {
                SecondaryButton(title: "Reactivate pair", icon: "lock.open") {
                    var p = pair; p.status = .active; store.updatePair(p)
                }
            }
            DangerButton(title: "Delete Pair", icon: "trash") { showDeleteConfirm = true }
        }
        .padding(.top, 6)
    }
}
