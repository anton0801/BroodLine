//
//  TasksView.swift
//  BroodLine
//

import SwiftUI

enum TaskFilter: String, CaseIterable, Identifiable, Hashable {
    case all, today, overdue, done
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

final class TasksViewModel: ObservableObject {
    @Published var filter: TaskFilter = .all

    func filtered(_ tasks: [TaskItem]) -> [TaskItem] {
        let cal = Calendar.current
        return tasks.filter { task in
            switch filter {
            case .all: return true
            case .today: return task.dueDate.map { cal.isDateInToday($0) } ?? false
            case .overdue: return !task.isDone && (task.dueDate.map { $0 < cal.startOfDay(for: Date()) } ?? false)
            case .done: return task.isDone
            }
        }
        .sorted { lhs, rhs in
            if lhs.isDone != rhs.isDone { return !lhs.isDone }
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?): return l < r
            case (_?, nil): return true
            case (nil, _?): return false
            default: return lhs.createdAt > rhs.createdAt
            }
        }
    }
}

struct TasksView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var vm = TasksViewModel()
    @State private var showAdd = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ChipPicker(items: TaskFilter.allCases, label: { $0.label }, selection: $vm.filter)

                    let tasks = vm.filtered(store.tasks)
                    if tasks.isEmpty {
                        EmptyStateView(icon: "checklist",
                                       title: "No tasks",
                                       message: "Add a task or turn a recommendation into one to stay on top of your flock.",
                                       actionTitle: "Add Task") { showAdd = true }
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(tasks) { task in
                                TaskRow(task: task) { store.toggleTask(task) }
                                    .contextMenu {
                                        Button { store.deleteTask(task) } label: { Label("Delete", systemImage: "trash") }
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
        .navigationBarTitle("Tasks", displayMode: .large)
        .navigationBarItems(trailing: Button { showAdd = true } label: {
            Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundColor(Palette.primary)
        })
        .sheet(isPresented: $showAdd) {
            AddTaskView().environmentObject(store)
        }
    }
}

struct TaskRow: View {
    let task: TaskItem
    var onToggle: () -> Void

    var body: some View {
        AppCard(padding: 12) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(task.isDone ? Palette.statusReady : Palette.textDisabled)
                }
                .buttonStyle(ScaleButtonStyle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title).font(AppFont.medium(15))
                        .foregroundColor(task.isDone ? Palette.textDisabled : Palette.textPrimary)
                        .strikethrough(task.isDone)
                    if let due = task.dueDate {
                        Text(dueLabel(due)).font(AppFont.caption()).foregroundColor(dueColor(due, done: task.isDone))
                    }
                }
                Spacer()
            }
        }
    }

    private func dueLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Due today" }
        if date < cal.startOfDay(for: Date()) { return "Overdue · \(Self.df.string(from: date))" }
        return "Due \(Self.df.string(from: date))"
    }
    private func dueColor(_ date: Date, done: Bool) -> Color {
        if done { return Palette.textDisabled }
        let cal = Calendar.current
        if date < cal.startOfDay(for: Date()) { return Palette.statusRisk }
        if cal.isDateInToday(date) { return Palette.statusWarn }
        return Palette.textSecondary
    }
    static let df: DateFormatter = { let f = DateFormatter(); f.dateStyle = .medium; return f }()
}

struct AddTaskView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var title = ""
    @State private var hasDue = false
    @State private var due = Date()
    @State private var note = ""

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        AppTextField(title: "Task", placeholder: "e.g. Ring the spring brood", text: $title, icon: "checklist")
                        VStack(spacing: 10) {
                            Toggle(isOn: $hasDue.animation()) {
                                Text("Due date").font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Palette.primary))
                            if hasDue {
                                DatePicker("", selection: $due, displayedComponents: .date).labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading).accentColor(Palette.primary)
                            }
                        }
                        .padding(14).background(Palette.card).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))

                        AppTextEditor(title: "Note", text: $note)

                        PrimaryButton(title: "Add Task", icon: "checkmark") {
                            store.addTask(TaskItem(title: title.trimmingCharacters(in: .whitespaces),
                                                   dueDate: hasDue ? due : nil, note: note))
                            presentationMode.wrappedValue.dismiss()
                        }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(16)
                }
            }
            .navigationBarTitle("Add Task", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
