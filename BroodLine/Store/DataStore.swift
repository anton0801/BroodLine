//
//  DataStore.swift
//  BroodLine
//
//  Single source of truth. Holds every entity as @Published state, exposes
//  CRUD + derived analytics, and persists everything to one JSON file.
//

import SwiftUI
import Combine

struct PairBroodCount: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

final class DataStore: ObservableObject {
    @Published var birds: [Bird] = []
    @Published var pairs: [BreedingPair] = []
    @Published var broods: [Brood] = []
    @Published var rings: [Ring] = []
    @Published var records: [BreedingRecord] = []
    @Published var tasks: [TaskItem] = []
    @Published var events: [CalendarEvent] = []
    @Published var photos: [PhotoItem] = []
    @Published var history: [HistoryEntry] = []
    @Published var lineTags: [String] = []
    @Published var categories: [String] = []
    @Published var dismissedRecKeys: Set<String> = []
    @Published var savedRecKeys: Set<String> = []

    let incubationDays = 21
    private var seeded = false

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("broodline.json")
    }

    init() {
        load()
        if !seeded {
            SampleData.populate(self)
            seeded = true
            persist()
        }
    }

    // MARK: - Lookups

    var birdsByID: [UUID: Bird] { Dictionary(birds.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }) }

    func bird(_ id: UUID?) -> Bird? {
        guard let id = id else { return nil }
        return birds.first { $0.id == id }
    }
    func pair(_ id: UUID?) -> BreedingPair? {
        guard let id = id else { return nil }
        return pairs.first { $0.id == id }
    }
    func birdName(_ id: UUID?) -> String { bird(id)?.displayName ?? "—" }

    func calculator() -> InbreedingCalculator { InbreedingCalculator(birds: birds) }

    func pairLabel(_ pair: BreedingPair) -> String {
        if !pair.label.isEmpty { return pair.label }
        return "\(birdName(pair.sireID)) × \(birdName(pair.damID))"
    }
    func pairLine(_ pair: BreedingPair) -> String {
        if let s = bird(pair.sireID), !s.lineTag.isEmpty { return s.lineTag }
        if let d = bird(pair.damID) { return d.lineTag }
        return "—"
    }
    func broodCount(for pair: BreedingPair) -> Int { broods.filter { $0.pairID == pair.id }.count }
    func broodTitle(_ brood: Brood) -> String {
        if let p = pair(brood.pairID) { return pairLabel(p) }
        return "Brood"
    }
    func inbreedingF(for pair: BreedingPair) -> Double {
        calculator().offspringF(sire: pair.sireID, dam: pair.damID)
    }
    func males() -> [Bird] { birds.filter { $0.sex == .male && $0.status != .archived } }
    func females() -> [Bird] { birds.filter { $0.sex == .female && $0.status != .archived } }

    func subjectName(_ ref: SubjectRef?) -> String {
        guard let ref = ref else { return "—" }
        switch ref.kind {
        case .bird: return birdName(ref.id)
        case .pair: return pair(ref.id).map { pairLabel($0) } ?? "—"
        }
    }

    // MARK: - Derived analytics

    var activePairs: [BreedingPair] { pairs.filter { $0.status == .active } }
    var openBroods: [Brood] { broods.filter { $0.status == .open } }

    var inbreedingWarnings: [BreedingPair] {
        let calc = calculator()
        return pairs.filter {
            $0.status != .closed &&
            RiskBand.from(calc.offspringF(sire: $0.sireID, dam: $0.damID)) >= .moderate
        }
    }

    func lineScores() -> [LineScore] {
        LineQuality.allScores(lineTags: lineTags, birds: birds, pairs: pairs, broods: broods, records: records)
    }
    var bestLine: LineScore? { lineScores().first { $0.broodCount > 0 } ?? lineScores().first }

    func broodsByPair() -> [PairBroodCount] {
        pairs.map { PairBroodCount(label: pairLabel($0), count: broodCount(for: $0)) }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
    }

    func sexRatio() -> (males: Int, females: Int) {
        let m = broods.reduce(0) { $0 + $1.malesCount }
        let f = broods.reduce(0) { $0 + $1.femalesCount }
        return (m, f)
    }

    // MARK: - History (internal, persisted by caller)

    private func log(_ type: HistoryType, _ text: String, related: UUID?) {
        history.insert(HistoryEntry(type: type, text: text, relatedID: related), at: 0)
    }

    // MARK: - Birds

    func addBird(_ bird: Bird) { birds.append(bird); persist() }

    func updateBird(_ bird: Bird) {
        if let i = birds.firstIndex(where: { $0.id == bird.id }) { birds[i] = bird; persist() }
    }

    func archiveBird(_ bird: Bird) {
        var b = bird; b.status = .archived; updateBird(b)
    }

    func deleteBird(_ bird: Bird) {
        ImageStorage.delete(bird.photoFilename)
        birds.removeAll { $0.id == bird.id }
        for i in birds.indices {
            if birds[i].sireID == bird.id { birds[i].sireID = nil }
            if birds[i].damID == bird.id { birds[i].damID = nil }
        }
        for i in rings.indices where rings[i].assignedBirdID == bird.id {
            rings[i].assignedBirdID = nil; rings[i].status = .available
        }
        persist()
    }

    /// Birds that can serve as a parent for `target` without creating a cycle.
    func eligibleParents(sex: Sex, excluding target: UUID?) -> [Bird] {
        birds.filter { candidate in
            guard candidate.sex == sex else { return false }
            if let target = target {
                if candidate.id == target { return false }
                if isDescendant(candidate.id, of: target) { return false }
            }
            return true
        }
    }

    /// True if `candidate` has `ancestor` somewhere below it (i.e. candidate is a descendant of ancestor).
    func isDescendant(_ candidate: UUID, of ancestor: UUID) -> Bool {
        calculator().isAncestorOrSelf(ancestor, of: candidate) && candidate != ancestor
    }

    // MARK: - Pairs

    func addPair(_ pair: BreedingPair) {
        pairs.append(pair)
        log(.paired, "Paired \(pairLabel(pair))", related: pair.id)
        events.append(CalendarEvent(title: "Mating · \(pairLabel(pair))",
                                    date: pair.startDate, type: .mating, relatedID: pair.id))
        let due = Calendar.current.date(byAdding: .day, value: incubationDays, to: pair.startDate) ?? pair.startDate
        events.append(CalendarEvent(title: "Brood due · \(pairLabel(pair))",
                                    date: due, type: .broodDue, relatedID: pair.id))
        persist()
    }

    func updatePair(_ pair: BreedingPair) {
        if let i = pairs.firstIndex(where: { $0.id == pair.id }) { pairs[i] = pair; persist() }
    }

    func deletePair(_ pair: BreedingPair) {
        ImageStorage.delete(pair.coverPhotoFilename)
        pairs.removeAll { $0.id == pair.id }
        broods.removeAll { $0.pairID == pair.id }
        events.removeAll { $0.relatedID == pair.id }
        persist()
    }

    // MARK: - Broods

    func addBrood(_ brood: Brood) {
        broods.append(brood)
        if let p = pair(brood.pairID) {
            log(.hatched, "Hatched \(brood.hatchedCount) chick(s) from \(pairLabel(p))", related: brood.id)
            let ringDate = Calendar.current.date(byAdding: .day, value: 5, to: brood.hatchDate) ?? brood.hatchDate
            events.append(CalendarEvent(title: "Ringing · \(pairLabel(p))",
                                        date: ringDate, type: .ringing, relatedID: brood.id))
        }
        persist()
    }

    func updateBrood(_ brood: Brood) {
        if let i = broods.firstIndex(where: { $0.id == brood.id }) { broods[i] = brood; persist() }
    }

    func deleteBrood(_ brood: Brood) {
        broods.removeAll { $0.id == brood.id }
        events.removeAll { $0.relatedID == brood.id }
        persist()
    }

    // MARK: - Rings

    func addRing(_ ring: Ring) { rings.append(ring); persist() }

    func updateRing(_ ring: Ring) {
        if let i = rings.firstIndex(where: { $0.id == ring.id }) { rings[i] = ring; persist() }
    }

    func assignRing(_ ring: Ring, to birdID: UUID?) {
        guard let i = rings.firstIndex(where: { $0.id == ring.id }) else { return }
        rings[i].assignedBirdID = birdID
        rings[i].status = birdID == nil ? .available : .assigned
        if birdID != nil { log(.ringed, "Assigned ring \(rings[i].code) to \(birdName(birdID))", related: rings[i].id) }
        persist()
    }

    func deleteRing(_ ring: Ring) { rings.removeAll { $0.id == ring.id }; persist() }

    // MARK: - Records

    func addRecord(_ record: BreedingRecord) { records.append(record); persist() }

    func updateRecord(_ record: BreedingRecord) {
        if let i = records.firstIndex(where: { $0.id == record.id }) { records[i] = record; persist() }
    }

    func duplicateRecord(_ record: BreedingRecord) {
        var copy = record
        copy.id = UUID()
        copy.title = record.title + " (copy)"
        copy.date = Date()
        records.append(copy)
        persist()
    }

    func deleteRecord(_ record: BreedingRecord) {
        ImageStorage.delete(record.photoFilename)
        records.removeAll { $0.id == record.id }
        persist()
    }

    // MARK: - Tasks

    func addTask(_ task: TaskItem) { tasks.append(task); persist() }

    func toggleTask(_ task: TaskItem) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) { tasks[i].isDone.toggle(); persist() }
    }

    func updateTask(_ task: TaskItem) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) { tasks[i] = task; persist() }
    }

    func deleteTask(_ task: TaskItem) { tasks.removeAll { $0.id == task.id }; persist() }

    // MARK: - Events

    func addEvent(_ event: CalendarEvent) { events.append(event); persist() }
    func deleteEvent(_ event: CalendarEvent) { events.removeAll { $0.id == event.id }; persist() }

    func events(on day: Date) -> [CalendarEvent] {
        events.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Photos

    @discardableResult
    func addPhoto(image: UIImage, category: PhotoCategory, relatedID: UUID?, caption: String) -> PhotoItem? {
        guard let filename = ImageStorage.save(image) else { return nil }
        let item = PhotoItem(filename: filename, category: category, relatedID: relatedID, caption: caption)
        photos.insert(item, at: 0)
        persist()
        return item
    }

    func addPhotoItem(_ item: PhotoItem) { photos.insert(item, at: 0); persist() }

    func deletePhoto(_ photo: PhotoItem) {
        ImageStorage.delete(photo.filename)
        photos.removeAll { $0.id == photo.id }
        persist()
    }

    // MARK: - Settings lists

    func addLineTag(_ tag: String) {
        let t = tag.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !lineTags.contains(t) else { return }
        lineTags.append(t); persist()
    }
    func removeLineTag(_ tag: String) { lineTags.removeAll { $0 == tag }; persist() }

    func addCategory(_ name: String) {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !categories.contains(t) else { return }
        categories.append(t); persist()
    }
    func removeCategory(_ name: String) { categories.removeAll { $0 == name }; persist() }

    // MARK: - Recommendations

    func recommendations() -> [Recommendation] {
        var recs: [Recommendation] = []
        let calc = calculator()

        for pair in pairs where pair.status != .closed {
            let f = calc.offspringF(sire: pair.sireID, dam: pair.damID)
            let band = RiskBand.from(f)
            if band >= .moderate {
                recs.append(Recommendation(
                    key: "avoid-\(pair.id.uuidString)",
                    kind: .avoidPair,
                    title: "Avoid breeding \(pairLabel(pair))",
                    detail: "Inbreeding F = \(Int(f * 100))% (\(band.label)). Pick a less-related mate to protect vigor and hatchability.",
                    severity: band,
                    relatedID: pair.id))
            }
        }

        for s in lineScores() where s.broodCount > 0 && s.bucket == .weak {
            recs.append(Recommendation(
                key: "line-\(s.line)",
                kind: .strengthenLine,
                title: "Strengthen line \(s.line)",
                detail: "Score \(Int(s.score))/100 · \(Int(s.hatchRatio * 100))% hatch. Introduce fresh bloodline or cull poor producers.",
                severity: .low,
                relatedID: nil))
        }

        for brood in openBroods where brood.ringedCount < brood.hatchedCount {
            recs.append(Recommendation(
                key: "checkring-\(brood.id.uuidString)",
                kind: .check,
                title: "Ring chicks of \(broodTitle(brood))",
                detail: "\(brood.hatchedCount - brood.ringedCount) chick(s) still need rings.",
                severity: .none,
                relatedID: brood.id))
        }

        return recs.filter { !dismissedRecKeys.contains($0.key) }
    }

    func dismissRecommendation(_ rec: Recommendation) { dismissedRecKeys.insert(rec.key); persist() }
    func saveRecommendation(_ rec: Recommendation) { savedRecKeys.insert(rec.key); persist() }
    func isSaved(_ rec: Recommendation) -> Bool { savedRecKeys.contains(rec.key) }

    // MARK: - Persistence

    func currentAppData() -> AppData {
        AppData(birds: birds, pairs: pairs, broods: broods, rings: rings, records: records,
                tasks: tasks, events: events, photos: photos, history: history,
                lineTags: lineTags, categories: categories,
                dismissedRecKeys: Array(dismissedRecKeys), savedRecKeys: Array(savedRecKeys),
                seeded: true)
    }

    func persist() {
        let data = currentAppData()
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(data) {
            try? encoded.write(to: fileURL, options: .atomic)
        }
    }

    private func apply(_ d: AppData) {
        birds = d.birds; pairs = d.pairs; broods = d.broods; rings = d.rings
        records = d.records; tasks = d.tasks; events = d.events; photos = d.photos
        history = d.history; lineTags = d.lineTags; categories = d.categories
        dismissedRecKeys = Set(d.dismissedRecKeys); savedRecKeys = Set(d.savedRecKeys)
        seeded = d.seeded
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(AppData.self, from: data) else { return }
        apply(decoded)
    }

    // MARK: - Backup / export / import

    func exportFileURL() -> URL? {
        let data = currentAppData()
        guard let encoded = try? JSONEncoder().encode(data) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BroodLine-Backup.json")
        try? encoded.write(to: url, options: .atomic)
        return url
    }

    func exportCSVURL() -> URL? {
        var csv = "Type,Ring/Label,Detail,Date\n"
        let df = ISO8601DateFormatter()
        for b in birds {
            csv += "Bird,\(b.ringID),\(b.sex.label) \(b.lineTag),\(b.hatchDate.map { df.string(from: $0) } ?? "")\n"
        }
        for p in pairs {
            csv += "Pair,\(pairLabel(p)),\(p.status.label),\(df.string(from: p.startDate))\n"
        }
        for br in broods {
            csv += "Brood,\(broodTitle(br)),\(br.hatchedCount)/\(br.eggCount) hatched,\(df.string(from: br.hatchDate))\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BroodLine-Export.csv")
        try? csv.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    func importData(from url: URL) -> Bool {
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(AppData.self, from: data) else { return false }
        apply(decoded)
        persist()
        return true
    }

    func resetToSampleData() {
        birds = []; pairs = []; broods = []; rings = []; records = []
        tasks = []; events = []; photos = []; history = []
        lineTags = []; categories = []; dismissedRecKeys = []; savedRecKeys = []
        SampleData.populate(self)
        persist()
    }
}
