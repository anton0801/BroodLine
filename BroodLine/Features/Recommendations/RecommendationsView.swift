//
//  RecommendationsView.swift
//  BroodLine
//

import SwiftUI

struct RecommendationsView: View {
    @EnvironmentObject var store: DataStore
    @State private var toast: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    let recs = store.recommendations()
                    if recs.isEmpty {
                        EmptyStateView(icon: "checkmark.seal.fill",
                                       title: "All clear",
                                       message: "No risks or weak lines detected. Keep up the good breeding!")
                    } else {
                        ForEach(recs) { rec in
                            RecommendationCard(rec: rec) { message in
                                showToast(message)
                            }
                        }
                    }
                    TabBarSpacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
            if let toast = toast {
                Text(toast)
                    .font(AppFont.caption()).foregroundColor(Palette.onPrimary)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Palette.primary).clipShape(Capsule())
                    .shadow(color: Palette.greenGlow, radius: 10)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitle("Recommendations", displayMode: .large)
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { toast = nil }
        }
    }
}

struct RecommendationCard: View {
    @EnvironmentObject var store: DataStore
    let rec: Recommendation
    var onAction: (String) -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    IconBadge(icon: rec.icon, color: rec.severity.color)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(rec.title).font(AppFont.headline(16)).foregroundColor(Palette.textPrimary)
                        StatusBadge(text: rec.severity == .none ? "Tip" : rec.severity.label, color: rec.severity.color)
                    }
                    Spacer()
                    if store.isSaved(rec) {
                        Image(systemName: "bookmark.fill").foregroundColor(Palette.copper)
                    }
                }
                Text(rec.detail).font(AppFont.body(14)).foregroundColor(Palette.textSecondary)

                HStack(spacing: 8) {
                    actionButton("Add to Tasks", "checklist", Palette.primary) {
                        store.addTask(TaskItem(title: rec.title, dueDate: nil, note: rec.detail))
                        onAction("Added to tasks")
                    }
                    actionButton("Save", store.isSaved(rec) ? "bookmark.fill" : "bookmark", Palette.copper) {
                        store.saveRecommendation(rec)
                        onAction("Saved")
                    }
                    actionButton("Dismiss", "xmark", Palette.textSecondary) {
                        store.dismissRecommendation(rec)
                    }
                }
            }
        }
    }

    private func actionButton(_ title: String, _ icon: String, _ color: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 12))
                Text(title).font(AppFont.caption(12))
            }
            .foregroundColor(color)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
