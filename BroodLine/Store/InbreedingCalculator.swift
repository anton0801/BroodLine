//
//  InbreedingCalculator.swift
//  BroodLine
//
//  Wright's coefficient of inbreeding via the recursive kinship (coancestry)
//  method. F of a prospective offspring of (sire × dam) equals the kinship
//  coefficient f(sire, dam). Memoized; depth ordering keeps the recursion
//  well-founded and cycle-safe.
//

import Foundation

final class InbreedingCalculator {
    private let birds: [UUID: Bird]
    private var kinshipMemo: [String: Double] = [:]
    private var depthMemo: [UUID: Int] = [:]
    private var inbreedMemo: [UUID: Double] = [:]

    init(birds: [UUID: Bird]) {
        self.birds = birds
    }

    convenience init(birds: [Bird]) {
        var dict: [UUID: Bird] = [:]
        for b in birds { dict[b.id] = b }
        self.init(birds: dict)
    }

    /// Generation depth (longest known ancestral path). Used to order recursion.
    func depth(_ id: UUID?) -> Int {
        guard let id = id, let bird = birds[id] else { return 0 }
        if let cached = depthMemo[id] { return cached }
        // Provisional value guards against accidental cycles.
        depthMemo[id] = 0
        let d: Int
        if bird.sireID == nil && bird.damID == nil {
            d = 0
        } else {
            d = 1 + max(depth(bird.sireID), depth(bird.damID))
        }
        depthMemo[id] = d
        return d
    }

    /// Kinship (coancestry) coefficient between two individuals.
    func kinship(_ a: UUID?, _ b: UUID?) -> Double {
        guard let a = a, let b = b else { return 0 }
        guard birds[a] != nil, birds[b] != nil else { return 0 }

        let key = a.uuidString < b.uuidString ? a.uuidString + b.uuidString
                                              : b.uuidString + a.uuidString
        if let cached = kinshipMemo[key] { return cached }

        let result: Double
        if a == b {
            result = 0.5 * (1 + inbreeding(a))
        } else if depth(a) >= depth(b) {
            let bird = birds[a]
            result = 0.5 * (kinship(bird?.sireID, b) + kinship(bird?.damID, b))
        } else {
            let bird = birds[b]
            result = 0.5 * (kinship(a, bird?.sireID) + kinship(a, bird?.damID))
        }
        kinshipMemo[key] = result
        return result
    }

    /// Inbreeding coefficient F of an existing individual.
    func inbreeding(_ id: UUID?) -> Double {
        guard let id = id, let bird = birds[id] else { return 0 }
        if let cached = inbreedMemo[id] { return cached }
        inbreedMemo[id] = 0 // guard against re-entry
        let f = kinship(bird.sireID, bird.damID)
        inbreedMemo[id] = f
        return f
    }

    /// F of a prospective offspring of the given sire and dam.
    func offspringF(sire: UUID?, dam: UUID?) -> Double {
        kinship(sire, dam)
    }

    /// True if `candidate` is `target` or one of its ancestors — used to block
    /// cyclic parent assignment.
    func isAncestorOrSelf(_ candidate: UUID, of target: UUID?) -> Bool {
        guard let target = target else { return false }
        if candidate == target { return true }
        guard let bird = birds[target] else { return false }
        return isAncestorOrSelf(candidate, of: bird.sireID)
            || isAncestorOrSelf(candidate, of: bird.damID)
    }
}
