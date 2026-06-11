//
//  BirdDetailView.swift
//  BroodLine
//

import SwiftUI

struct BirdDetailView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.presentationMode) private var presentationMode
    let birdID: UUID
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var bird: Bird? { store.bird(birdID) }

    var body: some View {
        ZStack {
            ScreenBackground()
            if let bird = bird {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        hero(bird)
                        statsRow(bird)
                        parentsSection(bird)
                        offspringSection(bird)
                        recordsSection(bird)
                        actions(bird)
                        TabBarSpacer()
                    }
                    .padding(16)
                }
            } else {
                EmptyStateView(icon: "bird", title: "Bird removed", message: "This bird is no longer in your flock.")
            }
        }
        .navigationBarTitle(bird?.displayName ?? "Bird", displayMode: .inline)
        .navigationBarItems(trailing: Group {
            if bird != nil {
                Button { showEdit = true } label: {
                    Image(systemName: "square.and.pencil").foregroundColor(Palette.primary)
                }
            }
        })
        .sheet(isPresented: $showEdit) {
            AddBirdView(editing: bird).environmentObject(store).environmentObject(theme)
        }
        .actionSheet(isPresented: $showDeleteConfirm) {
            ActionSheet(title: Text("Delete this bird?"),
                        message: Text("This also clears it from any pedigree links."),
                        buttons: [
                            .destructive(Text("Delete")) {
                                if let bird = bird { store.deleteBird(bird) }
                                presentationMode.wrappedValue.dismiss()
                            },
                            .cancel()
                        ])
        }
    }

    private func hero(_ bird: Bird) -> some View {
        AppCard {
            HStack(spacing: 16) {
                PhotoThumb(filename: bird.photoFilename, size: 80, corner: 18, fallbackIcon: bird.sex.icon)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(bird.displayName).font(AppFont.title(22)).foregroundColor(Palette.textPrimary)
                        Text(bird.sex.short).font(AppFont.headline(18)).foregroundColor(bird.sex.color)
                    }
                    Text(bird.ringID).font(AppFont.mono(14)).foregroundColor(Palette.textSecondary)
                    HStack(spacing: 8) {
                        StatusBadge(text: bird.lineTag.isEmpty ? "No line" : bird.lineTag, color: Palette.copper)
                        StatusBadge(text: bird.status.label, color: bird.status.color)
                    }
                }
                Spacer()
            }
        }
    }

    private func statsRow(_ bird: Bird) -> some View {
        let f = store.calculator().inbreeding(bird.id)
        let band = RiskBand.from(f)
        return HStack(spacing: 12) {
            infoTile("Inbreeding", "\(Int(f * 100))%", band.color, "drop.triangle")
            infoTile("Hatched", bird.hatchDate.map { Self.df.string(from: $0) } ?? "—", Palette.structural, "calendar")
            NavigationLink(destination: PedigreeView(initialFocus: bird.id, embedInNavigation: false)) {
                infoTile("Pedigree", "View", Palette.primary, "arrow.triangle.branch")
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func infoTile(_ title: String, _ value: String, _ color: Color, _ icon: String) -> some View {
        AppCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundColor(color)
                Text(value).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
                Text(title).font(AppFont.caption(11)).foregroundColor(Palette.textSecondary)
            }
        }
    }

    private func parentsSection(_ bird: Bird) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Parents")
            HStack(spacing: 12) {
                parentCard("Sire", bird.sireID, Palette.structural)
                parentCard("Dam", bird.damID, Palette.copper)
            }
        }
    }

    @ViewBuilder
    private func parentCard(_ role: String, _ id: UUID?, _ color: Color) -> some View {
        if let id = id, let parent = store.bird(id) {
            NavigationLink(destination: BirdDetailView(birdID: id)) {
                AppCard(padding: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(role).font(AppFont.caption(11)).foregroundColor(color)
                        Text(parent.displayName).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                        Text(parent.ringID).font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            AppCard(padding: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(role).font(AppFont.caption(11)).foregroundColor(color)
                    Text("Unknown").font(AppFont.medium(15)).foregroundColor(Palette.textDisabled)
                    Text("—").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func offspringSection(_ bird: Bird) -> some View {
        let offspring = store.birds.filter { $0.sireID == bird.id || $0.damID == bird.id }
        if !offspring.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Offspring (\(offspring.count))")
                ForEach(offspring) { child in
                    NavigationLink(destination: BirdDetailView(birdID: child.id)) {
                        BirdRow(bird: child)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private func recordsSection(_ bird: Bird) -> some View {
        let records = store.records.filter { $0.subject == SubjectRef(kind: .bird, id: bird.id) }
        if !records.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Records")
                ForEach(records) { record in
                    NavigationLink(destination: RecordDetailView(recordID: record.id)) {
                        RecordRow(record: record)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func actions(_ bird: Bird) -> some View {
        VStack(spacing: 10) {
            if bird.status != .archived {
                SecondaryButton(title: "Archive", icon: "archivebox") {
                    store.archiveBird(bird)
                }
            } else {
                SecondaryButton(title: "Restore to active", icon: "arrow.uturn.backward") {
                    var b = bird; b.status = .active; store.updateBird(b)
                }
            }
            DangerButton(title: "Delete Bird", icon: "trash") { showDeleteConfirm = true }
        }
        .padding(.top, 6)
    }

    static let df: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()
}
