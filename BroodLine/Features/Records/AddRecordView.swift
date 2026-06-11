//
//  AddRecordView.swift
//  BroodLine
//

import SwiftUI
import UIKit

final class AddRecordViewModel: ObservableObject {
    @Published var title = ""
    @Published var subjectKind: SubjectRef.Kind = .bird
    @Published var subjectID: UUID?
    @Published var date = Date()
    @Published var category = "Brood"
    @Published var value = ""
    @Published var comment = ""
    @Published var status = "Open"
    @Published var pickedImage: UIImage?

    private(set) var editingID: UUID?
    private var existingPhoto: String?

    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }
    var isEditing: Bool { editingID != nil }
    var subject: SubjectRef? { subjectID.map { SubjectRef(kind: subjectKind, id: $0) } }

    func load(_ r: BreedingRecord) {
        editingID = r.id
        title = r.title
        if let s = r.subject { subjectKind = s.kind; subjectID = s.id }
        date = r.date
        category = r.category
        value = r.value
        comment = r.comment
        status = r.status
        existingPhoto = r.photoFilename
    }

    func currentPhoto() -> String? { existingPhoto }

    @discardableResult
    func save(into store: DataStore) -> Bool {
        guard isValid else { return false }
        var filename = existingPhoto
        if let image = pickedImage { filename = ImageStorage.save(image) ?? existingPhoto }
        var record = BreedingRecord(title: title.trimmingCharacters(in: .whitespaces),
                                    subject: subject, date: date, category: category,
                                    value: value, comment: comment, photoFilename: filename, status: status)
        if let id = editingID {
            record.id = id
            store.updateRecord(record)
        } else {
            store.addRecord(record)
        }
        return true
    }

    /// Keeps subject/category/date for rapid entry; clears the rest.
    func resetForAnother() {
        title = ""; value = ""; comment = ""; pickedImage = nil; existingPhoto = nil
    }
}

struct AddRecordView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var vm = AddRecordViewModel()
    @State private var showPhotoPicker = false
    @State private var savedPulse = false

    var editing: BreedingRecord?

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        AppTextField(title: "Title", placeholder: "e.g. Spring brood", text: $vm.title, icon: "textformat")

                        HStack { Text("About").font(AppFont.caption()).foregroundColor(Palette.textSecondary); Spacer() }
                        ChipPicker(items: [SubjectRef.Kind.bird, .pair], label: { $0 == .bird ? "Bird" : "Pair" }, selection: $vm.subjectKind)
                        subjectSelector

                        dateField

                        HStack { Text("Category").font(AppFont.caption()).foregroundColor(Palette.textSecondary); Spacer() }
                        ChipPicker(items: store.categories, label: { $0 }, selection: $vm.category)

                        AppTextField(title: "Value", placeholder: "e.g. 6 hatched / 2600 g / 1st place", text: $vm.value, icon: "number")
                        AppTextEditor(title: "Comment", text: $vm.comment)
                        photoField

                        VStack(spacing: 10) {
                            PrimaryButton(title: vm.isEditing ? "Save Changes" : "Save", icon: "checkmark") {
                                if vm.save(into: store) { presentationMode.wrappedValue.dismiss() }
                            }
                            .disabled(!vm.isValid).opacity(vm.isValid ? 1 : 0.5)

                            if !vm.isEditing {
                                SecondaryButton(title: savedPulse ? "Saved ✓" : "Add Another", icon: "plus") {
                                    if vm.save(into: store) {
                                        vm.resetForAnother()
                                        withAnimation { savedPulse = true }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { savedPulse = false }
                                    }
                                }
                                .disabled(!vm.isValid).opacity(vm.isValid ? 1 : 0.5)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
            .navigationBarTitle(vm.isEditing ? "Edit Record" : "Add Record", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .sheet(isPresented: $showPhotoPicker) { PhotoPicker { image in vm.pickedImage = image } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if let editing = editing, !vm.isEditing { vm.load(editing) }
            if vm.category.isEmpty, let first = store.categories.first { vm.category = first }
        }
    }

    private var subjectSelector: some View {
        let options: [(id: UUID, label: String)] = vm.subjectKind == .bird
            ? store.birds.map { ($0.id, "\($0.displayName) · \($0.ringID)") }
            : store.pairs.map { ($0.id, store.pairLabel($0)) }
        return Menu {
            Button("None") { vm.subjectID = nil }
            ForEach(options, id: \.id) { opt in
                Button(opt.label) { vm.subjectID = opt.id }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: vm.subjectKind == .bird ? "bird.fill" : "heart.fill").foregroundColor(Palette.structural)
                Text(vm.subjectID.map { store.subjectName(SubjectRef(kind: vm.subjectKind, id: $0)) } ?? "Select (optional)")
                    .font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 13)).foregroundColor(Palette.textDisabled)
            }
            .padding(14).background(Palette.card).cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
        }
    }

    private var dateField: some View {
        HStack {
            Text("Date").font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
            Spacer()
            DatePicker("", selection: $vm.date, displayedComponents: .date).labelsHidden().accentColor(Palette.primary)
        }
        .padding(14).background(Palette.card).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
    }

    private var photoField: some View {
        Button { showPhotoPicker = true } label: {
            HStack(spacing: 14) {
                if let image = vm.pickedImage {
                    Image(uiImage: image).resizable().scaledToFill().frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    IconBadge(icon: "photo.badge.plus", color: Palette.primary, size: 56)
                }
                Text(vm.pickedImage == nil ? "Add photo (optional)" : "Change photo")
                    .font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Palette.textDisabled)
            }
            .padding(14).background(Palette.card).cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
