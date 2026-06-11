//
//  RingsView.swift
//  BroodLine
//

import SwiftUI

enum RingFilter: String, CaseIterable, Identifiable, Hashable {
    case all, available, assigned, lost
    var id: String { rawValue }
    var label: String { self == .all ? "All" : rawValue.capitalized }
    var status: RingStatus? { self == .all ? nil : RingStatus(rawValue: rawValue) }
}

struct RingsView: View {
    @EnvironmentObject var store: DataStore
    @State private var filter: RingFilter = .all
    @State private var showAdd = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    summary
                    ChipPicker(items: RingFilter.allCases, label: { $0.label }, selection: $filter)

                    let rings = filtered
                    if rings.isEmpty {
                        EmptyStateView(icon: "circle.dashed",
                                       title: "No rings",
                                       message: "Add leg rings to your inventory and assign them to birds.",
                                       actionTitle: "Add Ring") { showAdd = true }
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(rings) { ring in RingRow(ring: ring) }
                        }
                    }
                    TabBarSpacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
        }
        .navigationBarTitle("Rings", displayMode: .large)
        .navigationBarItems(trailing: Button { showAdd = true } label: {
            Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundColor(Palette.primary)
        })
        .sheet(isPresented: $showAdd) { AddRingView().environmentObject(store) }
    }

    private var filtered: [Ring] {
        store.rings.filter { filter.status == nil || $0.status == filter.status }
            .sorted { $0.code < $1.code }
    }

    private var summary: some View {
        HStack(spacing: 12) {
            ringStat("Available", store.rings.filter { $0.status == .available }.count, Palette.statusReady)
            ringStat("Assigned", store.rings.filter { $0.status == .assigned }.count, Palette.statusProgress)
            ringStat("Lost", store.rings.filter { $0.status == .lost }.count, Palette.statusRisk)
        }
    }

    private func ringStat(_ title: String, _ count: Int, _ color: Color) -> some View {
        AppCard(padding: 12) {
            VStack(spacing: 4) {
                Text("\(count)").font(AppFont.title(22)).foregroundColor(color)
                Text(title).font(AppFont.caption(11)).foregroundColor(Palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct RingRow: View {
    @EnvironmentObject var store: DataStore
    let ring: Ring

    var body: some View {
        AppCard(padding: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(ring.status.color, lineWidth: 3).frame(width: 36, height: 36)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(ring.code).font(AppFont.mono(15)).foregroundColor(Palette.textPrimary)
                    Text(ring.assignedBirdID.map { "Assigned to \(store.birdName($0))" } ?? ring.status.label)
                        .font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
                Spacer()
                Menu {
                    Button("Mark available") { markAvailable() }
                    Menu("Assign to bird") {
                        ForEach(store.birds) { bird in
                            Button("\(bird.displayName) · \(bird.ringID)") { store.assignRing(ring, to: bird.id) }
                        }
                    }
                    Button("Mark lost") { markLost() }
                    Button("Delete") { store.deleteRing(ring) }
                } label: {
                    StatusBadge(text: ring.status.label, color: ring.status.color)
                }
            }
        }
    }

    private func markAvailable() {
        var r = ring; r.assignedBirdID = nil; r.status = .available; store.updateRing(r)
    }
    private func markLost() {
        var r = ring; r.assignedBirdID = nil; r.status = .lost; store.updateRing(r)
    }
}

struct AddRingView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var code = ""

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        AppTextField(title: "Ring code", placeholder: "e.g. BR-053", text: $code, icon: "circle.dashed")
                        PrimaryButton(title: "Add Ring", icon: "checkmark") {
                            store.addRing(Ring(code: code.trimmingCharacters(in: .whitespaces), status: .available))
                            presentationMode.wrappedValue.dismiss()
                        }
                        .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(code.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(16)
                }
            }
            .navigationBarTitle("Add Ring", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
