//
//  RecordDetailView.swift
//  BroodLine
//

import SwiftUI

struct RecordDetailView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.presentationMode) private var presentationMode
    let recordID: UUID
    @State private var showEdit = false
    @State private var taskCreated = false

    private var record: BreedingRecord? { store.records.first { $0.id == recordID } }

    var body: some View {
        ZStack {
            ScreenBackground()
            if let record = record {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header(record)
                        if let file = record.photoFilename, let image = ImageStorage.load(file) {
                            Image(uiImage: image).resizable().scaledToFill()
                                .frame(maxWidth: .infinity).frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.border, lineWidth: 1))
                        }
                        detailsCard(record)
                        if !record.comment.isEmpty {
                            AppCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes").font(AppFont.headline(16)).foregroundColor(Palette.textPrimary)
                                    Text(record.comment).font(AppFont.body(14)).foregroundColor(Palette.textSecondary)
                                }
                            }
                        }
                        actions(record)
                        TabBarSpacer()
                    }
                    .padding(16)
                }
            } else {
                EmptyStateView(icon: "doc.text", title: "Record removed", message: "This record no longer exists.")
            }
        }
        .navigationBarTitle("Record", displayMode: .inline)
        .sheet(isPresented: $showEdit) {
            AddRecordView(editing: record).environmentObject(store).environmentObject(theme)
        }
        .alert(isPresented: $taskCreated) {
            Alert(title: Text("Task created"),
                  message: Text("A follow-up task was added to your task list."),
                  dismissButton: .default(Text("OK")))
        }
    }

    private func header(_ record: BreedingRecord) -> some View {
        AppCard {
            HStack(spacing: 14) {
                IconBadge(icon: RecordStyle.icon(record.category), color: RecordStyle.color(record.category), size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.title).font(AppFont.title(20)).foregroundColor(Palette.textPrimary)
                    Text(record.category).font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
                Spacer()
            }
        }
    }

    private func detailsCard(_ record: BreedingRecord) -> some View {
        AppCard {
            VStack(spacing: 12) {
                detailRow("About", store.subjectName(record.subject), "link")
                Divider().background(Palette.border)
                detailRow("Date", Self.df.string(from: record.date), "calendar")
                if !record.value.isEmpty {
                    Divider().background(Palette.border)
                    detailRow("Value", record.value, "number")
                }
                Divider().background(Palette.border)
                detailRow("Status", record.status, "flag")
            }
        }
    }

    private func detailRow(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(Palette.primary).frame(width: 22)
            Text(label).font(AppFont.medium(15)).foregroundColor(Palette.textSecondary)
            Spacer()
            Text(value).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func actions(_ record: BreedingRecord) -> some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Edit", icon: "square.and.pencil") { showEdit = true }
            HStack(spacing: 10) {
                SecondaryButton(title: "Duplicate", icon: "doc.on.doc") {
                    store.duplicateRecord(record)
                    presentationMode.wrappedValue.dismiss()
                }
                SecondaryButton(title: "Create Task", icon: "checklist") {
                    store.addTask(TaskItem(title: "Follow up: \(record.title)", dueDate: nil))
                    taskCreated = true
                }
            }
            DangerButton(title: "Delete", icon: "trash") {
                store.deleteRecord(record)
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding(.top, 6)
    }

    static let df: DateFormatter = { let f = DateFormatter(); f.dateStyle = .medium; return f }()
}
