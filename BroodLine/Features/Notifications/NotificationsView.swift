//
//  NotificationsView.swift
//  BroodLine
//

import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @EnvironmentObject var store: DataStore

    @AppStorage("notif.broodDue") private var broodDue = true
    @AppStorage("notif.ringing") private var ringing = true
    @AppStorage("notif.inbreeding") private var inbreeding = true
    @AppStorage("notif.broodLead") private var broodLead = 3
    @AppStorage("notif.ringLead") private var ringLead = 5

    @State private var authText = "Not requested"
    @State private var authColor = Palette.textSecondary
    @State private var pending = 0
    @State private var savedAlert = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    statusCard
                    toggleCard("Brood due", "Get notified before a pair is expected to hatch.",
                               "timer", Palette.primary, isOn: $broodDue)
                    if broodDue {
                        CounterField(title: "Days before due", value: $broodLead, color: Palette.primary, range: 0...14)
                    }
                    toggleCard("Ringing reminder", "Remind me to ring chicks after they hatch.",
                               "circle.dashed", Palette.copper, isOn: $ringing)
                    if ringing {
                        CounterField(title: "Days after hatch", value: $ringLead, color: Palette.copper, range: 1...30)
                    }
                    toggleCard("Inbreeding warning", "Alert me about high-risk pairings.",
                               "exclamationmark.triangle.fill", Palette.statusRisk, isOn: $inbreeding)

                    PrimaryButton(title: "Save Notifications", icon: "bell.badge.fill") { save() }
                    TabBarSpacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
        }
        .navigationBarTitle("Notifications", displayMode: .inline)
        .onAppear(perform: refreshStatus)
        .alert(isPresented: $savedAlert) {
            Alert(title: Text("Notifications updated"),
                  message: Text("\(pending) reminder(s) scheduled based on your pairs and broods."),
                  dismissButton: .default(Text("OK")))
        }
    }

    private var statusCard: some View {
        AppCard {
            HStack(spacing: 14) {
                IconBadge(icon: "bell.fill", color: authColor, size: 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Permission").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                    Text(authText).font(AppFont.headline(16)).foregroundColor(authColor)
                    Text("\(pending) scheduled").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
                Spacer()
            }
        }
    }

    private func toggleCard(_ title: String, _ subtitle: String, _ icon: String, _ color: Color, isOn: Binding<Bool>) -> some View {
        AppCard {
            HStack(spacing: 14) {
                IconBadge(icon: icon, color: color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(AppFont.medium(15)).foregroundColor(Palette.textPrimary)
                    Text(subtitle).font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
                Spacer()
                Toggle("", isOn: isOn.animation()).labelsHidden().toggleStyle(SwitchToggleStyle(tint: color))
            }
        }
    }

    private func save() {
        NotificationManager.shared.requestAuthorization { granted in
            if granted {
                NotificationManager.shared.reschedule(
                    broodDue: broodDue, ringing: ringing, inbreeding: inbreeding,
                    broodLeadDays: broodLead, ringLeadDays: ringLead,
                    incubationDays: store.incubationDays, store: store)
            } else {
                NotificationManager.shared.cancelAll()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                refreshStatus()
                savedAlert = true
            }
        }
    }

    private func refreshStatus() {
        NotificationManager.shared.authorizationStatus { status in
            switch status {
            case .authorized, .provisional, .ephemeral: authText = "Allowed"; authColor = Palette.statusReady
            case .denied: authText = "Denied — enable in Settings"; authColor = Palette.statusRisk
            case .notDetermined: authText = "Not requested"; authColor = Palette.textSecondary
            @unknown default: authText = "Unknown"; authColor = Palette.textSecondary
            }
        }
        NotificationManager.shared.pendingCount { pending = $0 }
    }
}
