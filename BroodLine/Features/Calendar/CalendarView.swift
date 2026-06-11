//
//  CalendarView.swift
//  BroodLine
//
//  Custom month grid (no third-party calendar). Shows matings, expected broods
//  and ringing events as colored dots.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var theme: ThemeManager
    @State private var month = Date()
    @State private var selected = Date()
    @State private var showAddEvent = false

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    monthHeader
                    weekdayRow
                    grid
                    selectedEvents
                    TabBarSpacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
        }
        .navigationBarTitle("Calendar", displayMode: .inline)
        .navigationBarItems(trailing: Button { showAddEvent = true } label: {
            Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundColor(Palette.primary)
        })
        .sheet(isPresented: $showAddEvent) {
            AddEventView(presetDate: selected).environmentObject(store)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left").foregroundColor(Palette.primary).padding(8)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(monthTitle).font(AppFont.headline(18)).foregroundColor(Palette.textPrimary)
                Button("Today") { withAnimation { month = Date(); selected = Date() } }
                    .font(AppFont.caption()).foregroundColor(Palette.primary)
            }
            Spacer()
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right").foregroundColor(Palette.primary).padding(8)
            }
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 4) {
            ForEach(weekdaySymbols, id: \.self) { sym in
                Text(sym).font(AppFont.caption(11)).foregroundColor(Palette.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day = day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 46)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = cal.isDate(day, inSameDayAs: selected)
        let isToday = cal.isDateInToday(day)
        let events = store.events(on: day)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selected = day }
        } label: {
            VStack(spacing: 4) {
                Text("\(cal.component(.day, from: day))")
                    .font(AppFont.caption(13))
                    .foregroundColor(isSelected ? Palette.onPrimary : (isToday ? Palette.primary : Palette.textPrimary))
                HStack(spacing: 2) {
                    ForEach(events.prefix(3)) { ev in
                        Circle().fill(isSelected ? Palette.onPrimary : ev.type.color).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(isSelected ? Palette.primary : (isToday ? Palette.primary.opacity(0.12) : Color.clear))
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.9))
    }

    private var selectedEvents: some View {
        let events = store.events(on: selected)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: Self.longDF.string(from: selected))
            if events.isEmpty {
                AppCard {
                    Text("No events. Tap + to add a mating, brood or ringing event.")
                        .font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
            } else {
                ForEach(events) { ev in
                    AppCard(padding: 12) {
                        HStack(spacing: 12) {
                            IconBadge(icon: ev.type.icon, color: ev.type.color)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(ev.title).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                                Text(ev.type.label).font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                            }
                            Spacer()
                            Button { store.deleteEvent(ev) } label: {
                                Image(systemName: "trash").foregroundColor(Palette.textDisabled)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: helpers

    private func shiftMonth(_ delta: Int) {
        if let new = cal.date(byAdding: .month, value: delta, to: month) {
            withAnimation { month = new }
        }
    }

    private var monthTitle: String { Self.monthDF.string(from: month) }

    private var weekdaySymbols: [String] {
        let symbols = cal.shortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var days: [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: month),
              let range = cal.range(of: .day, in: .month, for: month) else { return [] }
        let firstWeekday = cal.component(.weekday, from: interval.start)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: interval.start) {
                cells.append(d)
            }
        }
        return cells
    }

    static let monthDF: DateFormatter = { let f = DateFormatter(); f.dateFormat = "LLLL yyyy"; return f }()
    static let longDF: DateFormatter = { let f = DateFormatter(); f.dateStyle = .full; return f }()
}

struct AddEventView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.presentationMode) private var presentationMode
    var presetDate: Date
    @State private var title = ""
    @State private var date = Date()
    @State private var type: EventType = .custom

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        AppTextField(title: "Title", placeholder: "e.g. Vaccination round", text: $title, icon: "calendar")
                        HStack { Text("Type").font(AppFont.caption()).foregroundColor(Palette.textSecondary); Spacer() }
                        ChipPicker(items: EventType.allCases, label: { $0.label }, selection: $type)
                        HStack {
                            Text("Date").font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                            Spacer()
                            DatePicker("", selection: $date, displayedComponents: .date).labelsHidden().accentColor(Palette.primary)
                        }
                        .padding(14).background(Palette.card).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))

                        PrimaryButton(title: "Add Event", icon: "checkmark") {
                            store.addEvent(CalendarEvent(title: title.trimmingCharacters(in: .whitespaces),
                                                         date: date, type: type, relatedID: nil))
                            presentationMode.wrappedValue.dismiss()
                        }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(16)
                }
            }
            .navigationBarTitle("Add Event", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .onAppear { date = presetDate }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
