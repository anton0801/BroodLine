//
//  Enums.swift
//  BroodLine
//
//  Shared enumerations with their display metadata (label, icon, color).
//

import SwiftUI

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male, female, unknown
    var id: String { rawValue }

    var label: String {
        switch self {
        case .male: return "Cock"
        case .female: return "Hen"
        case .unknown: return "Unknown"
        }
    }
    var short: String {
        switch self {
        case .male: return "♂"
        case .female: return "♀"
        case .unknown: return "?"
        }
    }
    var icon: String {
        switch self {
        case .male: return "bird.fill"
        case .female: return "bird"
        case .unknown: return "questionmark.circle"
        }
    }
    var color: Color {
        switch self {
        case .male: return Palette.structural
        case .female: return Palette.copper
        case .unknown: return Palette.textDisabled
        }
    }
}

enum BirdStatus: String, Codable, CaseIterable, Identifiable {
    case active, breeding, archived, sold, deceased
    var id: String { rawValue }

    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .active: return Palette.statusReady
        case .breeding: return Palette.statusProgress
        case .archived: return Palette.textDisabled
        case .sold: return Palette.copper
        case .deceased: return Palette.statusRisk
        }
    }
}

enum PairStatus: String, Codable, CaseIterable, Identifiable {
    case active, paused, closed
    var id: String { rawValue }

    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .active: return Palette.statusProgress
        case .paused: return Palette.statusWarn
        case .closed: return Palette.textDisabled
        }
    }
}

enum BroodStatus: String, Codable, CaseIterable, Identifiable {
    case open, closed
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color { self == .open ? Palette.statusProgress : Palette.textDisabled }
}

enum RingStatus: String, Codable, CaseIterable, Identifiable {
    case available, assigned, lost
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .available: return Palette.statusReady
        case .assigned: return Palette.statusProgress
        case .lost: return Palette.statusRisk
        }
    }
}

enum PhotoCategory: String, Codable, CaseIterable, Identifiable {
    case sire, dam, brood, award
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .sire: return Palette.structural
        case .dam: return Palette.copper
        case .brood: return Palette.primary
        case .award: return Palette.copperLight
        }
    }
}

enum HistoryType: String, Codable, CaseIterable, Identifiable {
    case paired, hatched, ringed
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .paired: return "heart.circle.fill"
        case .hatched: return "circle.hexagongrid.fill"
        case .ringed: return "circle.dashed"
        }
    }
    var color: Color {
        switch self {
        case .paired: return Palette.structural
        case .hatched: return Palette.primary
        case .ringed: return Palette.copper
        }
    }
}

enum EventType: String, Codable, CaseIterable, Identifiable {
    case mating, broodDue, ringing, custom
    var id: String { rawValue }
    var label: String {
        switch self {
        case .mating: return "Mating"
        case .broodDue: return "Brood due"
        case .ringing: return "Ringing"
        case .custom: return "Event"
        }
    }
    var icon: String {
        switch self {
        case .mating: return "heart.fill"
        case .broodDue: return "timer"
        case .ringing: return "circle.dashed"
        case .custom: return "calendar"
        }
    }
    var color: Color {
        switch self {
        case .mating: return Palette.structural
        case .broodDue: return Palette.primary
        case .ringing: return Palette.copper
        case .custom: return Palette.statusWarn
        }
    }
}

/// Inbreeding risk classification for a coefficient F.
enum RiskBand: Int, Comparable {
    case none, low, moderate, high

    static func < (lhs: RiskBand, rhs: RiskBand) -> Bool { lhs.rawValue < rhs.rawValue }

    static func from(_ f: Double) -> RiskBand {
        if f <= 0.0001 { return .none }
        if f < 0.0625 { return .low }
        if f < 0.125 { return .moderate }
        return .high
    }

    var label: String {
        switch self {
        case .none: return "No risk"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High risk"
        }
    }
    var color: Color {
        switch self {
        case .none: return Palette.statusReady
        case .low: return Palette.statusProgress
        case .moderate: return Palette.statusWarn
        case .high: return Palette.statusRisk
        }
    }
}

/// Reference from a record/task to either a bird or a pair.
struct SubjectRef: Codable, Hashable {
    enum Kind: String, Codable { case bird, pair }
    var kind: Kind
    var id: UUID
}
