//
//  Models.swift
//  BroodLine
//
//  Codable value types. All references between entities are by UUID.
//

import Foundation

struct Bird: Identifiable, Codable, Hashable {
    var id = UUID()
    var ringID: String
    var name: String = ""
    var sex: Sex = .unknown
    var lineTag: String = ""
    var hatchDate: Date?
    var sireID: UUID?
    var damID: UUID?
    var status: BirdStatus = .active
    var photoFilename: String?
    var notes: String = ""
    var createdAt: Date = Date()

    /// Human label: name if present, otherwise the ring/ID.
    var displayName: String { name.isEmpty ? ringID : name }
}

struct BreedingPair: Identifiable, Codable, Hashable {
    var id = UUID()
    var sireID: UUID?
    var damID: UUID?
    var label: String = ""
    var startDate: Date = Date()
    var status: PairStatus = .active
    var coverPhotoFilename: String?
    var notes: String = ""
}

struct Brood: Identifiable, Codable, Hashable {
    var id = UUID()
    var pairID: UUID
    var hatchDate: Date = Date()
    var eggCount: Int = 0
    var hatchedCount: Int = 0
    var ringedCount: Int = 0
    var malesCount: Int = 0
    var femalesCount: Int = 0
    var status: BroodStatus = .open
    var notes: String = ""

    var hatchRatio: Double {
        eggCount > 0 ? Double(hatchedCount) / Double(eggCount) : 0
    }
}

struct Ring: Identifiable, Codable, Hashable {
    var id = UUID()
    var code: String
    var assignedBirdID: UUID?
    var status: RingStatus = .available
    var date: Date = Date()
}

struct BreedingRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var subject: SubjectRef?
    var date: Date = Date()
    var category: String = "Brood"
    var value: String = ""
    var comment: String = ""
    var photoFilename: String?
    var status: String = "Open"
}

struct TaskItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var dueDate: Date?
    var isDone: Bool = false
    var note: String = ""
    var createdAt: Date = Date()
}

struct CalendarEvent: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var date: Date
    var type: EventType
    var relatedID: UUID?
}

struct PhotoItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var filename: String
    var category: PhotoCategory
    var relatedID: UUID?
    var date: Date = Date()
    var caption: String = ""
}

struct HistoryEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var type: HistoryType
    var date: Date = Date()
    var text: String
    var relatedID: UUID?
}

/// Generated advice — not persisted as such; dismissal/save tracked by `key`.
struct Recommendation: Identifiable, Hashable {
    enum Kind { case avoidPair, strengthenLine, check }
    var id = UUID()
    var key: String
    var kind: Kind
    var title: String
    var detail: String
    var severity: RiskBand
    var relatedID: UUID?

    var icon: String {
        switch kind {
        case .avoidPair: return "exclamationmark.triangle.fill"
        case .strengthenLine: return "chart.line.uptrend.xyaxis"
        case .check: return "checklist"
        }
    }
}

/// Single-file persistence container (also used for backup/export/import).
struct AppData: Codable {
    var birds: [Bird] = []
    var pairs: [BreedingPair] = []
    var broods: [Brood] = []
    var rings: [Ring] = []
    var records: [BreedingRecord] = []
    var tasks: [TaskItem] = []
    var events: [CalendarEvent] = []
    var photos: [PhotoItem] = []
    var history: [HistoryEntry] = []
    var lineTags: [String] = []
    var categories: [String] = []
    var dismissedRecKeys: [String] = []
    var savedRecKeys: [String] = []
    var seeded: Bool = false
}
