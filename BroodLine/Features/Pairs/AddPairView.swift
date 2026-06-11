//
//  AddPairView.swift
//  BroodLine
//

import SwiftUI
import UIKit

final class AddPairViewModel: ObservableObject {
    @Published var sireID: UUID?
    @Published var damID: UUID?
    @Published var label = ""
    @Published var startDate = Date()
    @Published var status: PairStatus = .active
    @Published var notes = ""
    @Published var pickedImage: UIImage?

    private(set) var editingID: UUID?
    private var existingPhoto: String?

    var isValid: Bool { sireID != nil && damID != nil }
    var isEditing: Bool { editingID != nil }

    func load(_ pair: BreedingPair) {
        editingID = pair.id
        sireID = pair.sireID
        damID = pair.damID
        label = pair.label
        startDate = pair.startDate
        status = pair.status
        notes = pair.notes
        existingPhoto = pair.coverPhotoFilename
    }

    func currentPhoto() -> String? { existingPhoto }

    func inbreeding(in store: DataStore) -> Double {
        store.calculator().offspringF(sire: sireID, dam: damID)
    }

    func save(into store: DataStore) {
        var filename = existingPhoto
        if let image = pickedImage { filename = ImageStorage.save(image) ?? existingPhoto }
        var pair = BreedingPair(sireID: sireID, damID: damID, label: label.trimmingCharacters(in: .whitespaces),
                                startDate: startDate, status: status, coverPhotoFilename: filename, notes: notes)
        if let id = editingID {
            pair.id = id
            store.updatePair(pair)
        } else {
            store.addPair(pair)
        }
    }
}

struct AddPairView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var vm = AddPairViewModel()
    @State private var showPhotoPicker = false

    var editing: BreedingPair?

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        coverField
                        selector(title: "Sire (cock)", sex: .male, selection: $vm.sireID, icon: "bird.fill")
                        selector(title: "Dam (hen)", sex: .female, selection: $vm.damID, icon: "bird")
                        inbreedingBanner
                        AppTextField(title: "Pair label (optional)", placeholder: "Auto from names", text: $vm.label, icon: "tag")
                        startDateField
                        if vm.isEditing {
                            HStack { Text("Status").font(AppFont.caption()).foregroundColor(Palette.textSecondary); Spacer() }
                            ChipPicker(items: PairStatus.allCases, label: { $0.label }, selection: $vm.status)
                        }
                        AppTextEditor(title: "Notes", text: $vm.notes)

                        PrimaryButton(title: vm.isEditing ? "Save Changes" : "Save Pair", icon: "checkmark") {
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
            .navigationBarTitle(vm.isEditing ? "Edit Pair" : "Add Pair", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker { image in vm.pickedImage = image }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear { if let editing = editing, !vm.isEditing { vm.load(editing) } }
    }

    private var inbreedingBanner: some View {
        let f = vm.inbreeding(in: store)
        let band = RiskBand.from(f)
        let hasBoth = vm.isValid
        return AppCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: hasBoth ? (band == .none ? "checkmark.shield.fill" : "exclamationmark.shield.fill") : "shield")
                    .font(.system(size: 24))
                    .foregroundColor(hasBoth ? band.color : Palette.textDisabled)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Inbreeding check").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    if hasBoth {
                        Text("F = \(Int(f * 100))% · \(band.label)")
                            .font(AppFont.headline(16)).foregroundColor(band.color)
                    } else {
                        Text("Select sire and dam").font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                    }
                }
                Spacer()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: f)
    }

    private var coverField: some View {
        Button { showPhotoPicker = true } label: {
            HStack(spacing: 14) {
                if let image = vm.pickedImage {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 14))
                } else if let file = vm.currentPhoto(), let image = ImageStorage.load(file) {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    IconBadge(icon: "camera.fill", color: Palette.structural, size: 64)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Cover photo").font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                    Text("Optional").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Palette.textDisabled)
            }
            .padding(14)
            .background(Palette.card)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var startDateField: some View {
        HStack {
            Text("Start date").font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
            Spacer()
            DatePicker("", selection: $vm.startDate, displayedComponents: .date)
                .labelsHidden().accentColor(Palette.primary)
        }
        .padding(14)
        .background(Palette.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
    }

    private func selector(title: String, sex: Sex, selection: Binding<UUID?>, icon: String) -> some View {
        let options = store.birds.filter { $0.sex == sex && $0.status != .archived }
        return Menu {
            Button("None") { selection.wrappedValue = nil }
            ForEach(options) { bird in
                Button("\(bird.displayName) · \(bird.ringID)") { selection.wrappedValue = bird.id }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundColor(sex.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    Text(selection.wrappedValue.map { store.birdName($0) } ?? "Select")
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
}
