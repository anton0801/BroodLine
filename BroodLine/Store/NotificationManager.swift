//
//  NotificationManager.swift
//  BroodLine
//
//  Real local notifications via UNUserNotificationCenter: brood-due, ringing
//  and inbreeding-warning reminders derived from the current data.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    static let df: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func authorizationStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    func pendingCount(_ completion: @escaping (Int) -> Void) {
        center.getPendingNotificationRequests { requests in
            DispatchQueue.main.async { completion(requests.count) }
        }
    }

    /// Cancels and rebuilds all reminders from the toggles + current data.
    func reschedule(broodDue: Bool,
                    ringing: Bool,
                    inbreeding: Bool,
                    broodLeadDays: Int,
                    ringLeadDays: Int,
                    incubationDays: Int,
                    store: DataStore) {
        cancelAll()
        let cal = Calendar.current

        if broodDue {
            for pair in store.pairs where pair.status == .active {
                let due = cal.date(byAdding: .day, value: incubationDays, to: pair.startDate) ?? pair.startDate
                let fire = cal.date(byAdding: .day, value: -broodLeadDays, to: due) ?? due
                schedule(id: "brood-\(pair.id.uuidString)",
                         title: "Brood due soon",
                         body: "\(store.pairLabel(pair)) is expected to hatch around \(Self.df.string(from: due)).",
                         date: fire)
            }
        }

        if ringing {
            for brood in store.broods where brood.status == .open {
                let fire = cal.date(byAdding: .day, value: ringLeadDays, to: brood.hatchDate) ?? brood.hatchDate
                schedule(id: "ring-\(brood.id.uuidString)",
                         title: "Ringing reminder",
                         body: "Time to ring chicks from \(store.broodTitle(brood)).",
                         date: fire)
            }
        }

        if inbreeding {
            let calc = store.calculator()
            for pair in store.pairs where pair.status != .closed {
                let f = calc.offspringF(sire: pair.sireID, dam: pair.damID)
                if RiskBand.from(f) == .high {
                    schedule(id: "inbreed-\(pair.id.uuidString)",
                             title: "Inbreeding warning",
                             body: "\(store.pairLabel(pair)) has high inbreeding risk (F = \(Int(f * 100))%). Consider a different mate.",
                             date: Date().addingTimeInterval(5))
                }
            }
        }
    }

    private func schedule(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let interval = max(date.timeIntervalSinceNow, 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}
