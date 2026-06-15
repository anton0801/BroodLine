import Foundation
import UIKit
import UserNotifications

protocol Toller {
    func ringBell() async -> Bool
    func wireSwarmCall()
}

final class NotificationToller: Toller {
    
    func ringBell() async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let onceBell = SingleChime()
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                if let error = error {
                    print("\(HiveDiction.logBee) Toller error: \(error)")
                }
                DispatchQueue.main.async {
                    guard onceBell.tryChime() else { return }
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func wireSwarmCall() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

final class SingleChime {
    private var chimed = false
    private let lock = NSLock()
    
    func tryChime() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !chimed else { return false }
        chimed = true
        return true
    }
}
