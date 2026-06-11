//
//  PedigreeView.swift
//  BroodLine
//
//  The hero screen: a focus bird's ancestry rendered as a generation-column
//  binary tree, with live inbreeding coefficient + line-quality score.
//

import SwiftUI

struct PedigreeView: View {
    @EnvironmentObject var store: DataStore
    var initialFocus: UUID?
    var embedInNavigation: Bool = true

    @State private var focusID: UUID?
    @State private var depth: Int = 3
    @State private var showCheck = false
    @State private var snapshotAlert = false

    var body: some View {
        main.onAppear(perform: setupFocus)
    }

    @ViewBuilder
    private var main: some View {
        if embedInNavigation {
            NavigationView { content }
                .navigationViewStyle(StackNavigationViewStyle())
        } else {
            content
        }
    }

    private func setupFocus() {
        if focusID == nil {
            focusID = initialFocus
                ?? store.birds.first(where: { $0.sireID != nil || $0.damID != nil })?.id
                ?? store.birds.first?.id
        }
    }

    private var content: some View {
        ZStack {
            ScreenBackground()
            innerBody
        }
        .navigationBarTitle("Pedigree", displayMode: .inline)
        .sheet(isPresented: $showCheck) { checkSheet }
        .alert(isPresented: $snapshotAlert) {
            Alert(title: Text("Snapshot saved"),
                  message: Text("A pedigree snapshot record was added to your records and history."),
                  dismissButton: .default(Text("OK")))
        }
    }

    @ViewBuilder
    private var innerBody: some View {
        if store.birds.isEmpty {
            EmptyStateView(icon: "arrow.triangle.branch",
                           title: "No birds to chart",
                           message: "Add birds with parents to build a pedigree tree.")
        } else {
            VStack(spacing: 14) {
                controls
                headerStats
                treeCard
                actionButtons
                TabBarSpacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
        }
    }

    private var focusBird: Bird? { store.bird(focusID) }

    private var controls: some View {
        VStack(spacing: 10) {
            Menu {
                ForEach(store.birds) { bird in
                    Button("\(bird.displayName) · \(bird.ringID)") { focusID = bird.id }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "scope").foregroundColor(Palette.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focus bird").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                        Text(focusBird?.displayName ?? "Select").font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 13)).foregroundColor(Palette.textDisabled)
                }
                .padding(14)
                .background(Palette.card)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
            }

            HStack {
                Text("Generations").font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                Spacer()
                HStack(spacing: 16) {
                    stepBtn("minus") { if depth > 2 { withAnimation { depth -= 1 } } }
                    Text("\(depth)").font(AppFont.headline(18)).foregroundColor(Palette.primary).frame(minWidth: 22)
                    stepBtn("plus") { if depth < 4 { withAnimation { depth += 1 } } }
                }
            }
            .padding(14)
            .background(Palette.card)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
        }
    }

    private var headerStats: some View {
        let f = store.calculator().inbreeding(focusID)
        let band = RiskBand.from(f)
        let line = focusBird?.lineTag ?? ""
        let score = store.lineScores().first(where: { $0.line == line })
        let qualityLabel: String = score?.bucket.label ?? (line.isEmpty ? "No line" : "No data")
        return HStack(spacing: 12) {
            AppCard(padding: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Inbreeding").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    Text("\(Int(f * 100))%").font(AppFont.title(22)).foregroundColor(band.color)
                    StatusBadge(text: band.label, color: band.color)
                }
            }
            AppCard(padding: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Line quality").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    Text(score.map { "\(Int($0.score))" } ?? "—").font(AppFont.title(22))
                        .foregroundColor(score?.bucket.color ?? Palette.textDisabled)
                    StatusBadge(text: qualityLabel, color: score?.bucket.color ?? Palette.textDisabled)
                }
            }
        }
    }

    private var treeCard: some View {
        AppCard(padding: 10) {
            PedigreeTreeView(focusID: focusID, depth: depth)
                .frame(height: 320)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SecondaryButton(title: depth < 4 ? "Expand Tree" : "Collapse", icon: "arrow.up.left.and.arrow.down.right") {
                    withAnimation { depth = depth < 4 ? 4 : 3 }
                }
                SecondaryButton(title: "Check", icon: "shield.lefthalf.filled") { showCheck = true }
            }
            PrimaryButton(title: "Save Snapshot", icon: "camera.viewfinder") { saveSnapshot() }
        }
    }

    private func saveSnapshot() {
        guard let bird = focusBird else { return }
        let f = store.calculator().inbreeding(bird.id)
        let record = BreedingRecord(
            title: "Pedigree snapshot — \(bird.displayName)",
            subject: SubjectRef(kind: .bird, id: bird.id),
            date: Date(),
            category: "Pedigree",
            value: "F = \(Int(f * 100))%, \(depth) generations",
            comment: "Snapshot of \(bird.displayName)'s pedigree (\(depth) generations).",
            status: "Saved")
        store.addRecord(record)
        snapshotAlert = true
    }

    private var checkSheet: some View {
        let bird = focusBird
        let f = store.calculator().inbreeding(focusID)
        let band = RiskBand.from(f)
        return NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().stroke(Palette.bgSoft, lineWidth: 12).frame(width: 130, height: 130)
                            Circle().trim(from: 0, to: CGFloat(min(f * 4, 1)))
                                .stroke(band.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90)).frame(width: 130, height: 130)
                            VStack {
                                Text("\(Int(f * 100))%").font(AppFont.display(30)).foregroundColor(Palette.textPrimary)
                                Text("F").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                            }
                        }
                        .padding(.top, 16)
                        StatusBadge(text: band.label, color: band.color)
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("What this means").font(AppFont.headline(16)).foregroundColor(Palette.textPrimary)
                                Text(interpretation(band))
                                    .font(AppFont.body(14)).foregroundColor(Palette.textSecondary)
                            }
                        }
                        if let bird = bird {
                            AppCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Parents of \(bird.displayName)").font(AppFont.headline(16)).foregroundColor(Palette.textPrimary)
                                    Text("Sire: \(store.birdName(bird.sireID))").font(AppFont.body(14)).foregroundColor(Palette.textSecondary)
                                    Text("Dam: \(store.birdName(bird.damID))").font(AppFont.body(14)).foregroundColor(Palette.textSecondary)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationBarTitle("Inbreeding check", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") { showCheck = false })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func interpretation(_ band: RiskBand) -> String {
        switch band {
        case .none: return "No detectable inbreeding from the recorded pedigree. Genetic diversity is healthy."
        case .low: return "Slight relatedness between ancestors. Generally safe, but keep tracking future pairings."
        case .moderate: return "Noticeable common ancestry. Watch for reduced vigor and hatchability; diversify when possible."
        case .high: return "High inbreeding. Expect higher risk of defects and lower fertility — introduce unrelated bloodline."
        }
    }

    private func stepBtn(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundColor(Palette.primary)
                .frame(width: 30, height: 30).background(Palette.primary.opacity(0.15)).clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Tree

struct PedigreeTreeView: View {
    @EnvironmentObject var store: DataStore
    let focusID: UUID?
    let depth: Int

    private let nodeW: CGFloat = 132
    private let nodeH: CGFloat = 56
    private let colStride: CGFloat = 152
    private let slotH: CGFloat = 72
    private let leftPad: CGFloat = 8

    private var canvasHeight: CGFloat { CGFloat(1 << depth) * slotH }
    private var canvasWidth: CGFloat { CGFloat(depth) * colStride + nodeW + leftPad * 2 }

    private func centerX(_ col: Int) -> CGFloat { leftPad + nodeW / 2 + CGFloat(col) * colStride }
    private func centerY(col: Int, index: Int) -> CGFloat {
        canvasHeight * (CGFloat(index) + 0.5) / CGFloat(1 << col)
    }

    private func birdAt(col: Int, index: Int) -> UUID? {
        if col == 0 { return focusID }
        let parent = birdAt(col: col - 1, index: index / 2)
        guard let p = store.bird(parent) else { return nil }
        return index % 2 == 0 ? p.sireID : p.damID
    }

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                connectors
                ForEach(0...depth, id: \.self) { col in
                    ForEach(0..<(1 << col), id: \.self) { idx in
                        nodeCard(col: col, index: idx)
                            .frame(width: nodeW, height: nodeH)
                            .position(x: centerX(col), y: centerY(col: col, index: idx))
                    }
                }
            }
            .frame(width: canvasWidth, height: max(canvasHeight, 280))
            .padding(.bottom, 16)
        }
    }

    private var connectors: some View {
        Path { path in
            guard depth >= 1 else { return }
            for col in 0..<depth {
                for idx in 0..<(1 << col) {
                    let px = centerX(col) + nodeW / 2
                    let py = centerY(col: col, index: idx)
                    for child in 0...1 {
                        let cidx = idx * 2 + child
                        let cx = centerX(col + 1) - nodeW / 2
                        let cy = centerY(col: col + 1, index: cidx)
                        let midX = (px + cx) / 2
                        path.move(to: CGPoint(x: px, y: py))
                        path.addLine(to: CGPoint(x: midX, y: py))
                        path.addLine(to: CGPoint(x: midX, y: cy))
                        path.addLine(to: CGPoint(x: cx, y: cy))
                    }
                }
            }
        }
        .stroke(Palette.border, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        .frame(width: canvasWidth, height: max(canvasHeight, 280))
    }

    @ViewBuilder
    private func nodeCard(col: Int, index: Int) -> some View {
        let id = birdAt(col: col, index: index)
        let color = nodeColor(col: col, index: index)
        if let id = id, let bird = store.bird(id) {
            NavigationLink(destination: BirdDetailView(birdID: id)) {
                nodeContent(bird: bird, color: color)
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            nodeUnknown(color: color)
        }
    }

    private func nodeColor(col: Int, index: Int) -> Color {
        if col == 0 { return Palette.primary }
        return index < (1 << (col - 1)) ? Palette.structural : Palette.copper
    }

    private func nodeContent(bird: Bird, color: Color) -> some View {
        HStack(spacing: 8) {
            Rectangle().fill(color).frame(width: 4).cornerRadius(2)
            VStack(alignment: .leading, spacing: 2) {
                Text(bird.displayName).font(AppFont.caption(13)).foregroundColor(Palette.textPrimary).lineLimit(1)
                Text(bird.ringID).font(AppFont.caption(10)).foregroundColor(Palette.textSecondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(bird.sex.short).font(AppFont.caption(12)).foregroundColor(bird.sex.color)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Palette.bgSoft)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.5), lineWidth: 1))
    }

    private func nodeUnknown(color: Color) -> some View {
        HStack(spacing: 8) {
            Rectangle().fill(color.opacity(0.3)).frame(width: 4).cornerRadius(2)
            Text("Unknown").font(AppFont.caption(12)).foregroundColor(Palette.textDisabled)
            Spacer(minLength: 0)
            Image(systemName: "questionmark").font(.system(size: 11)).foregroundColor(Palette.textDisabled)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Palette.bgSoft.opacity(0.5))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.border, style: StrokeStyle(lineWidth: 1, dash: [4])))
    }
}
