//
//  RecordsView.swift
//  BroodLine
//

import SwiftUI

enum RecordStyle {
    static func icon(_ category: String) -> String {
        switch category.lowercased() {
        case "brood": return "circle.hexagongrid.fill"
        case "weight": return "scalemass.fill"
        case "award": return "rosette"
        case "health": return "cross.case.fill"
        case "pedigree": return "arrow.triangle.branch"
        default: return "doc.text.fill"
        }
    }
    static func color(_ category: String) -> Color {
        switch category.lowercased() {
        case "brood": return Palette.primary
        case "weight": return Palette.structural
        case "award": return Palette.copper
        case "health": return Palette.statusReady
        case "pedigree": return Palette.primaryGlowC
        default: return Palette.textSecondary
        }
    }
}

struct RecordRow: View {
    @EnvironmentObject var store: DataStore
    let record: BreedingRecord

    var body: some View {
        AppCard(padding: 12) {
            HStack(spacing: 12) {
                IconBadge(icon: RecordStyle.icon(record.category), color: RecordStyle.color(record.category))
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.title).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary).lineLimit(1)
                    Text("\(record.category) · \(store.subjectName(record.subject))")
                        .font(AppFont.caption()).foregroundColor(Palette.textSecondary).lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if !record.value.isEmpty {
                        Text(record.value).font(AppFont.caption(13)).foregroundColor(RecordStyle.color(record.category)).lineLimit(1)
                    }
                    Text(record.date, style: .date).font(AppFont.caption(10)).foregroundColor(Palette.textSecondary)
                }
            }
        }
    }
}

final class RecordsViewModel: ObservableObject {
    @Published var category: String = "All"

    func categories(_ store: DataStore) -> [String] { ["All"] + store.categories }

    func filtered(_ records: [BreedingRecord]) -> [BreedingRecord] {
        records.filter { category == "All" || $0.category == category }
            .sorted { $0.date > $1.date }
    }
}

struct RecordsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var vm = RecordsViewModel()
    @State private var showAdd = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ChipPicker(items: vm.categories(store), label: { $0 }, selection: $vm.category)

                    let records = vm.filtered(store.records)
                    if records.isEmpty {
                        EmptyStateView(icon: "doc.text",
                                       title: "No records",
                                       message: "Log broods, weights and awards to build a history for each bird and pair.",
                                       actionTitle: "Add Record") { showAdd = true }
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(records) { record in
                                NavigationLink(destination: RecordDetailView(recordID: record.id)) {
                                    RecordRow(record: record)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button { store.duplicateRecord(record) } label: { Label("Duplicate", systemImage: "doc.on.doc") }
                                    Button { store.deleteRecord(record) } label: { Label("Delete", systemImage: "trash") }
                                }
                            }
                        }
                    }
                    TabBarSpacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
        }
        .navigationBarTitle("Records", displayMode: .large)
        .navigationBarItems(trailing: Button { showAdd = true } label: {
            Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundColor(Palette.primary)
        })
        .sheet(isPresented: $showAdd) {
            AddRecordView().environmentObject(store).environmentObject(theme)
        }
    }
}
