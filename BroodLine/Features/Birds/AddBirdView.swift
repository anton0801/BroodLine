//
//  AddBirdView.swift
//  BroodLine
//

import SwiftUI
import UIKit

final class AddBirdViewModel: ObservableObject {
    @Published var ringID = ""
    @Published var name = ""
    @Published var sex: Sex = .male
    @Published var lineTag = ""
    @Published var hasHatchDate = false
    @Published var hatchDate = Date()
    @Published var sireID: UUID?
    @Published var damID: UUID?
    @Published var status: BirdStatus = .active
    @Published var notes = ""
    @Published var pickedImage: UIImage?

    private(set) var editingID: UUID?
    private var createdAt = Date()
    private var existingPhoto: String?

    var isValid: Bool { !ringID.trimmingCharacters(in: .whitespaces).isEmpty }
    var isEditing: Bool { editingID != nil }

    func load(_ bird: Bird) {
        editingID = bird.id
        ringID = bird.ringID
        name = bird.name
        sex = bird.sex
        lineTag = bird.lineTag
        if let d = bird.hatchDate { hasHatchDate = true; hatchDate = d }
        sireID = bird.sireID
        damID = bird.damID
        status = bird.status
        notes = bird.notes
        existingPhoto = bird.photoFilename
        createdAt = bird.createdAt
    }

    func currentPhotoFilename() -> String? { existingPhoto }

    func save(into store: DataStore) {
        var filename = existingPhoto
        if let image = pickedImage {
            filename = ImageStorage.save(image) ?? existingPhoto
        }
        var bird = Bird(
            ringID: ringID.trimmingCharacters(in: .whitespaces),
            name: name.trimmingCharacters(in: .whitespaces),
            sex: sex,
            lineTag: lineTag.trimmingCharacters(in: .whitespaces),
            hatchDate: hasHatchDate ? hatchDate : nil,
            sireID: sireID,
            damID: damID,
            status: status,
            photoFilename: filename,
            notes: notes,
            createdAt: createdAt
        )
        if let id = editingID {
            bird.id = id
            store.updateBird(bird)
        } else {
            store.addBird(bird)
        }
        if !bird.lineTag.isEmpty { store.addLineTag(bird.lineTag) }
    }
}

struct AddBirdView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var vm = AddBirdViewModel()
    @State private var showPhotoPicker = false

    /// Optional bird to edit.
    var editing: Bird?

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        photoField
                        AppTextField(title: "Ring / ID", placeholder: "e.g. BR-052", text: $vm.ringID, icon: "tag.fill")
                        AppTextField(title: "Name (optional)", placeholder: "e.g. Goliath", text: $vm.name, icon: "character.cursor.ibeam")

                        fieldLabel("Sex")
                        ChipPicker(items: Sex.allCases, label: { $0.label }, selection: $vm.sex)

                        lineField
                        hatchField

                        parentField(title: "Sire (father)", sex: .male, selection: $vm.sireID, icon: "bird.fill")
                        parentField(title: "Dam (mother)", sex: .female, selection: $vm.damID, icon: "bird")

                        if vm.isEditing {
                            fieldLabel("Status")
                            ChipPicker(items: BirdStatus.allCases, label: { $0.label }, selection: $vm.status)
                        }

                        AppTextEditor(title: "Notes", text: $vm.notes)

                        PrimaryButton(title: vm.isEditing ? "Save Changes" : "Save Bird", icon: "checkmark") {
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
            .navigationBarTitle(vm.isEditing ? "Edit Bird" : "Add Bird", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker { image in vm.pickedImage = image }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if let editing = editing, !vm.isEditing { vm.load(editing) }
            if vm.lineTag.isEmpty, let first = store.lineTags.first { vm.lineTag = first }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        HStack { Text(text).font(AppFont.caption()).foregroundColor(Palette.textSecondary); Spacer() }
    }

    private var photoField: some View {
        Button { showPhotoPicker = true } label: {
            HStack(spacing: 14) {
                if let image = vm.pickedImage {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 14))
                } else if let file = vm.currentPhotoFilename(), let image = ImageStorage.load(file) {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    IconBadge(icon: "camera.fill", color: Palette.primary, size: 64)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.pickedImage == nil && vm.currentPhotoFilename() == nil ? "Add photo" : "Change photo")
                        .font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                    Text("From your photo library").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
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

    private var lineField: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppTextField(title: "Breed / Line", placeholder: "e.g. Brahma", text: $vm.lineTag, icon: "circle.grid.cross.fill")
            if !store.lineTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.lineTags, id: \.self) { tag in
                            Button { vm.lineTag = tag } label: {
                                Text(tag).font(AppFont.caption())
                                    .foregroundColor(vm.lineTag == tag ? Palette.onPrimary : Palette.textSecondary)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(vm.lineTag == tag ? Palette.primary : Palette.card)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Palette.border, lineWidth: 1))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private var hatchField: some View {
        VStack(spacing: 10) {
            Toggle(isOn: $vm.hasHatchDate.animation()) {
                Text("Hatch date").font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
            }
            .toggleStyle(SwitchToggleStyle(tint: Palette.primary))
            if vm.hasHatchDate {
                DatePicker("", selection: $vm.hatchDate, displayedComponents: .date)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accentColor(Palette.primary)
            }
        }
        .padding(14)
        .background(Palette.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
    }

    private func parentField(title: String, sex: Sex, selection: Binding<UUID?>, icon: String) -> some View {
        let options = store.eligibleParents(sex: sex, excluding: vm.editingID)
        return Menu {
            Button("None") { selection.wrappedValue = nil }
            ForEach(options) { bird in
                Button("\(bird.displayName) · \(bird.ringID)") { selection.wrappedValue = bird.id }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundColor(Palette.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    Text(selection.wrappedValue.map { store.birdName($0) } ?? "None")
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
