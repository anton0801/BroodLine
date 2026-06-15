import Foundation

struct HiveArchive: Codable {
    let pollens: [String: String]
    let waggles: [String: String]
    let routeURL: String?
    let routeMode: String?
    let unhived: Bool
    let consentDrawn: Bool
    let consentBarred: Bool
    let consentDanceAt: Date?
}

struct Hive {
    var pollens: [String: String] = [:]
    var waggles: [String: String] = [:]
    var routeURL: String? = nil
    var routeMode: String? = nil
    var unhived: Bool = true
    var nested: Bool = false
    var organicForaged: Bool = false
    var consentDrawn: Bool = false
    var consentBarred: Bool = false
    var consentDanceAt: Date? = nil
    
    var pollensReady: Bool { !pollens.isEmpty }
    var organicBee: Bool { pollens["af_status"] == "Organic" }
    
    var consentRipe: Bool {
        guard !consentDrawn && !consentBarred else { return false }
        if let date = consentDanceAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
    
    static func revive(from archive: HiveArchive) -> Hive {
        var h = Hive()
        h.pollens = archive.pollens
        h.waggles = archive.waggles
        h.routeURL = archive.routeURL
        h.routeMode = archive.routeMode
        h.unhived = archive.unhived
        h.consentDrawn = archive.consentDrawn
        h.consentBarred = archive.consentBarred
        h.consentDanceAt = archive.consentDanceAt
        return h
    }
    
    func crystallize() -> HiveArchive {
        HiveArchive(
            pollens: pollens, waggles: waggles,
            routeURL: routeURL, routeMode: routeMode,
            unhived: unhived,
            consentDrawn: consentDrawn, consentBarred: consentBarred,
            consentDanceAt: consentDanceAt
        )
    }
}

enum SwarmOutcome: Equatable {
    case idling
    case askConsent
    case fanOut
    case starved
}

final class SwarmLatch {
    private var dropped: Bool = false
    private let lock = NSLock()
    
    func tryDrop() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !dropped else { return false }
        dropped = true
        return true
    }
    
    var isDropped: Bool {
        lock.lock()
        defer { lock.unlock() }
        return dropped
    }
}
