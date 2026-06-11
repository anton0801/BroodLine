//
//  AddBroodView.swift
//  BroodLine
//

import SwiftUI

final class AddBroodViewModel: ObservableObject {
    @Published var pairID: UUID?
    @Published var hatchDate = Date()
    @Published var eggCount = 0
    @Published var hatchedCount = 0
    @Published var ringedCount = 0
    @Published var males = 0
    @Published var females = 0
    @Published var status: BroodStatus = .open
    @Published var notes = ""

    private(set) var editingID: UUID?

    var isValid: Bool { pairID != nil }
    var isEditing: Bool { editingID != nil }

    func load(_ brood: Brood) {
        editingID = brood.id
        pairID = brood.pairID
        hatchDate = brood.hatchDate
        eggCount = brood.eggCount
        hatchedCount = brood.hatchedCount
        ringedCount = brood.ringedCount
        males = brood.malesCount
        females = brood.femalesCount
        status = brood.status
        notes = brood.notes
    }

    func save(into store: DataStore) {
        guard let pairID = pairID else { return }
        var brood = Brood(pairID: pairID, hatchDate: hatchDate, eggCount: eggCount,
                          hatchedCount: hatchedCount, ringedCount: ringedCount,
                          malesCount: males, femalesCount: females, status: status, notes: notes)
        if let id = editingID {
            brood.id = id
            store.updateBrood(brood)
        } else {
            store.addBrood(brood)
        }
    }
}

struct AddBroodView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var vm = AddBroodViewModel()

    var editing: Brood?
    var presetPairID: UUID?

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        pairSelector
                        hatchDateField
                        CounterField(title: "Eggs set", value: $vm.eggCount, color: Palette.structural)
                        CounterField(title: "Hatched", value: $vm.hatchedCount, color: Palette.primary)
                        CounterField(title: "Ringed", value: $vm.ringedCount, color: Palette.copper)
                        CounterField(title: "Males ♂", value: $vm.males, color: Palette.structural)
                        CounterField(title: "Females ♀", value: $vm.females, color: Palette.copper)

                        HStack { Text("Status").font(AppFont.caption()).foregroundColor(Palette.textSecondary); Spacer() }
                        ChipPicker(items: BroodStatus.allCases, label: { $0.label }, selection: $vm.status)

                        AppTextEditor(title: "Notes", text: $vm.notes)

                        PrimaryButton(title: vm.isEditing ? "Save Changes" : "Save Brood", icon: "checkmark") {
                            vm.save(into: store)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .disabled(!vm.isValid)
                        .opacity(vm.isValid ? 1 : 0.5)
                        .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
            .navigationBarTitle(vm.isEditing ? "Edit Brood" : "Register Brood", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if let editing = editing, !vm.isEditing { vm.load(editing) }
            else if vm.pairID == nil { vm.pairID = presetPairID ?? store.activePairs.first?.id ?? store.pairs.first?.id }
        }
    }

    private var pairSelector: some View {
        Menu {
            ForEach(store.pairs) { pair in
                Button(store.pairLabel(pair)) { vm.pairID = pair.id }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill").foregroundColor(Palette.structural)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pair").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    Text(vm.pairID.flatMap { store.pair($0) }.map { store.pairLabel($0) } ?? "Select pair")
                        .font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 13)).foregroundColor(Palette.textDisabled)
            }
            .padding(14)
            .background(Palette.card)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
        }
    }

    private var hatchDateField: some View {
        HStack {
            Text("Hatch date").font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
            Spacer()
            DatePicker("", selection: $vm.hatchDate, displayedComponents: .date)
                .labelsHidden().accentColor(Palette.primary)
        }
        .padding(14)
        .background(Palette.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
    }
}

struct CounterField: View {
    let title: String
    @Binding var value: Int
    var color: Color = Palette.primary
    var range: ClosedRange<Int> = 0...200

    var body: some View {
        HStack(spacing: 12) {
            Text(title).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
            Spacer()
            HStack(spacing: 16) {
                stepButton("minus") { if value > range.lowerBound { value -= 1 } }
                Text("\(value)").font(AppFont.headline(18)).foregroundColor(color)
                    .frame(minWidth: 28)
                stepButton("plus") { if value < range.upperBound { value += 1 } }
            }
        }
        .padding(14)
        .background(Palette.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
    }

    private func stepButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.15))
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
