//
//  MoreView.swift
//  BroodLine
//
//  Hub for the secondary sections that don't live in the tab bar.
//

import SwiftUI

struct MoreView: View {
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        link("Broods", "circle.hexagongrid.fill", Palette.primary) { BroodsView() }
                        link("Rings", "circle.dashed", Palette.copper) { RingsView() }
                        link("Records", "doc.text.fill", Palette.structural) { RecordsView() }
                        link("Recommendations", "lightbulb.fill", Palette.statusWarn) { RecommendationsView() }
                        link("Tasks", "checklist", Palette.primary) { TasksView() }
                        link("Calendar", "calendar", Palette.structural) { CalendarView() }
                        link("Photos", "photo.on.rectangle.angled", Palette.copper) { PhotosView() }
                        link("Reports", "chart.bar.fill", Palette.primaryGlowC) { ReportsView() }
                        link("History", "clock.arrow.circlepath", Palette.structural) { HistoryView() }
                        link("Notifications", "bell.fill", Palette.statusWarn) { NotificationsView() }
                        link("Settings", "gearshape.fill", Palette.textSecondary) { SettingsView() }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    TabBarSpacer()
                }
            }
            .navigationBarTitle("More", displayMode: .large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func link<Destination: View>(_ title: String, _ icon: String, _ color: Color,
                                         @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 12) {
                IconBadge(icon: icon, color: color, size: 44)
                Text(title).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .padding(16)
            .background(Palette.card)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.border, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func newlinK<Destination: View>(_ title: String, _ icon: String, _ color: Color,
                                         @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 12) {
                IconBadge(icon: icon, color: color, size: 44)
                Text(title).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .padding(16)
            .background(Palette.card)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.border, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
