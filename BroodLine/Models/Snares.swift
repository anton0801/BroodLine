import Foundation

struct HiveSnare: Error, CustomStringConvertible {
    enum Kind {
        case combEmpty
        case waxCracked
        case droneLost
        case swarmOvercrowded
        case waggleTimedOut
        case meadowFenced404
        case combSealed
    }
    
    let kind: Kind
    let stage: String
    let note: String?
    let coolDown: TimeInterval?
    
    init(_ kind: Kind, stage: String, note: String? = nil, coolDown: TimeInterval? = nil) {
        self.kind = kind
        self.stage = stage
        self.note = note
        self.coolDown = coolDown
    }
    
    var description: String {
        let n = note.map { " note=\($0)" } ?? ""
        return "HiveSnare[\(kind)] @ \(stage)\(n)"
    }
    
    var isFenced: Bool {
        switch kind {
        case .meadowFenced404, .combSealed: return true
        default: return false
        }
    }
    
    var isSwarm: Bool {
        if case .swarmOvercrowded = kind { return true }
        return false
    }
}
