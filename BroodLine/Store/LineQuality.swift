//
//  LineQuality.swift
//  BroodLine
//
//  Heuristic 0–100 quality score for a breeding line, derived from its broods
//  (hatch ratio + productivity) and awards.
//

import SwiftUI

struct LineScore: Identifiable {
    var id: String { line }
    var line: String
    var score: Double
    var broodCount: Int
    var hatchRatio: Double
    var awards: Int

    var bucket: Bucket { Bucket.from(score) }

    enum Bucket {
        case strong, medium, weak
        static func from(_ score: Double) -> Bucket {
            if score >= 70 { return .strong }
            if score >= 40 { return .medium }
            return .weak
        }
        var label: String {
            switch self {
            case .strong: return "Strong"
            case .medium: return "Average"
            case .weak: return "Weak"
            }
        }
        var color: Color {
            switch self {
            case .strong: return Palette.chartStrong
            case .medium: return Palette.chartMedium
            case .weak: return Palette.chartWeak
            }
        }
    }
}

enum LineQuality {

    /// Computes a score for one line. A pair belongs to a line via its sire's
    /// `lineTag`; awards are counted from records about birds in that line.
    static func score(line: String,
                      birds: [Bird],
                      pairs: [BreedingPair],
                      broods: [Brood],
                      records: [BreedingRecord]) -> LineScore {

        let birdsByID = Dictionary(uniqueKeysWithValues: birds.map { ($0.id, $0) })

        func pairLine(_ pair: BreedingPair) -> String {
            if let sid = pair.sireID, let s = birdsByID[sid], !s.lineTag.isEmpty { return s.lineTag }
            if let did = pair.damID, let d = birdsByID[did] { return d.lineTag }
            return ""
        }

        let linePairIDs = Set(pairs.filter { pairLine($0) == line }.map { $0.id })
        let lineBroods = broods.filter { linePairIDs.contains($0.pairID) }

        let totalEggs = lineBroods.reduce(0) { $0 + $1.eggCount }
        let totalHatched = lineBroods.reduce(0) { $0 + $1.hatchedCount }
        let hatchRatio: Double = totalEggs > 0
            ? Double(totalHatched) / Double(totalEggs)
            : (totalHatched > 0 ? 1 : 0)

        let lineBirdIDs = Set(birds.filter { $0.lineTag == line }.map { $0.id })
        let awards = records.filter {
            $0.category.lowercased() == "award"
            && ($0.subject.map { lineBirdIDs.contains($0.id) } ?? false)
        }.count

        // Weighted: hatch success (60), productivity (25), awards (15).
        let broodFactor = min(Double(lineBroods.count), 5) / 5
        let awardFactor = min(Double(awards), 4) / 4
        let raw = hatchRatio * 60 + broodFactor * 25 + awardFactor * 15
        let score = max(0, min(100, raw))

        return LineScore(line: line,
                         score: score,
                         broodCount: lineBroods.count,
                         hatchRatio: hatchRatio,
                         awards: awards)
    }

    /// Scores for every known line, sorted best-first.
    static func allScores(lineTags: [String],
                          birds: [Bird],
                          pairs: [BreedingPair],
                          broods: [Brood],
                          records: [BreedingRecord]) -> [LineScore] {
        let lines = lineTags.isEmpty
            ? Array(Set(birds.map { $0.lineTag }.filter { !$0.isEmpty }))
            : lineTags
        return lines
            .map { score(line: $0, birds: birds, pairs: pairs, broods: broods, records: records) }
            .sorted { $0.score > $1.score }
    }
}
