//
//  SettingsView.swift
//  BroodLine
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var theme: ThemeManager

    @State private var newLine = ""
    @State private var newCategory = ""
    @State private var share: ShareURLItem?
    @State private var showImport = false
    @State private var savedAlert = false
    @State private var resetConfirm = false
    @State private var importResult: String?

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    appearanceSection
                    unitsSection
                    lineTagsSection
                    categoriesSection
                    dataSection
                    PrimaryButton(title: "Save", icon: "checkmark") {
                        store.persist()
                        savedAlert = true
                    }
                    aboutFooter
                    TabBarSpacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
        }
        .navigationBarTitle("Settings", displayMode: .large)
        .sheet(item: $share) { item in ShareSheet(items: [item.url]) }
        .sheet(isPresented: $showImport) {
            DocumentPicker { url in
                importResult = store.importData(from: url) ? "Backup restored successfully." : "Could not read that backup file."
            }
        }
        .alert(isPresented: $savedAlert) {
            Alert(title: Text("Saved"), message: Text("Your settings have been saved."), dismissButton: .default(Text("OK")))
        }
        .actionSheet(isPresented: $resetConfirm) {
            ActionSheet(title: Text("Reset to sample data?"),
                        message: Text("This replaces all current data with the demo flock."),
                        buttons: [.destructive(Text("Reset")) { store.resetToSampleData() }, .cancel()])
        }
    }

    // MARK: sections

    private var appearanceSection: some View {
        sectionCard("Theme", "paintbrush.fill") {
            ChipPicker(items: AppAppearance.allCases, label: { $0.label }, selection: $theme.appearance)
            Text("Light, dark or follow the system. Applied instantly across the app.")
                .font(AppFont.caption()).foregroundColor(Palette.textSecondary)
        }
    }

    private var unitsSection: some View {
        sectionCard("Units", "ruler.fill") {
            ChipPicker(items: UnitSystem.allCases, label: { $0.label }, selection: $theme.units)
            Text("Weights are shown in \(theme.units.weightUnit).")
                .font(AppFont.caption()).foregroundColor(Palette.textSecondary)
        }
    }

    private var lineTagsSection: some View {
        sectionCard("Line tags", "circle.grid.cross.fill") {
            flowTags(store.lineTags) { store.removeLineTag($0) }
            addRow(text: $newLine, placeholder: "Add line (e.g. Sussex)") {
                store.addLineTag(newLine); newLine = ""
            }
        }
    }

    private var categoriesSection: some View {
        sectionCard("Record categories", "tag.fill") {
            flowTags(store.categories) { store.removeCategory($0) }
            addRow(text: $newCategory, placeholder: "Add category") {
                store.addCategory(newCategory); newCategory = ""
            }
        }
    }

    private var dataSection: some View {
        sectionCard("Data", "externaldrive.fill") {
            dataButton("Backup (export JSON)", "arrow.up.doc.fill", Palette.primary) {
                if let url = store.exportFileURL() { share = ShareURLItem(url: url) }
            }
            dataButton("Restore backup", "arrow.down.doc.fill", Palette.structural) { showImport = true }
            dataButton("Export data (CSV)", "tablecells.fill", Palette.copper) {
                if let url = store.exportCSVURL() { share = ShareURLItem(url: url) }
            }
            dataButton("Reset to sample data", "trash.fill", Palette.statusRisk) { resetConfirm = true }
            if let result = importResult {
                Text(result).font(AppFont.caption()).foregroundColor(Palette.textSecondary)
            }
        }
    }

    private var aboutFooter: some View {
        VStack(spacing: 4) {
            Text("Brood Line").font(AppFont.headline(15)).foregroundColor(Palette.textPrimary)
            Text("Smart poultry assistant · v1.0").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: helpers

    private func sectionCard<Content: View>(_ title: String, _ icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(Palette.primary)
                Text(title).font(AppFont.headline(17)).foregroundColor(Palette.textPrimary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.border, lineWidth: 1))
    }

    private func flowTags(_ tags: [String], onRemove: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if tags.isEmpty {
                    Text("None yet").font(AppFont.caption()).foregroundColor(Palette.textDisabled)
                }
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 6) {
                        Text(tag).font(AppFont.caption()).foregroundColor(Palette.textPrimary)
                        Button { onRemove(tag) } label: {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 13)).foregroundColor(Palette.textDisabled)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Palette.bgSoft).clipShape(Capsule())
                    .overlay(Capsule().stroke(Palette.border, lineWidth: 1))
                }
            }
        }
    }

    private func addRow(text: Binding<String>, placeholder: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            TextField(placeholder, text: text)
                .foregroundColor(Palette.textPrimary)
                .padding(12).background(Palette.bgSoft).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.border, lineWidth: 1))
            Button(action: action) {
                Image(systemName: "plus").foregroundColor(Palette.onPrimary)
                    .frame(width: 44, height: 44).background(Palette.primary).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(text.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(text.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
    }

    private func dataButton(_ title: String, _ icon: String, _ color: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundColor(color).frame(width: 24)
                Text(title).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Palette.textDisabled)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
}
