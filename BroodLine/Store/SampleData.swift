//
//  SampleData.swift
//  BroodLine
//
//  First-launch seed: a 4-generation Brahma pedigree plus an unrelated Leghorn
//  hen, giving one high-inbreeding pair (full siblings) and one healthy,
//  productive pair so every screen has meaningful content.
//

import UIKit

enum SampleData {
    static func populate(_ store: DataStore) {
        let cal = Calendar.current
        func ago(_ days: Int) -> Date { cal.date(byAdding: .day, value: -days, to: Date()) ?? Date() }

        store.lineTags = ["Brahma", "Leghorn", "Orpington"]
        store.categories = ["Brood", "Weight", "Award", "Health"]

        // Founders (great-grandparents)
        let atlas   = Bird(ringID: "BR-001", name: "Atlas",   sex: .male,   lineTag: "Brahma", hatchDate: ago(1500), status: .breeding)
        let bella   = Bird(ringID: "BR-002", name: "Bella",   sex: .female, lineTag: "Brahma", hatchDate: ago(1480), status: .breeding)
        let caesar  = Bird(ringID: "BR-003", name: "Caesar",  sex: .male,   lineTag: "Brahma", hatchDate: ago(1490))
        let duchess = Bird(ringID: "BR-004", name: "Duchess", sex: .female, lineTag: "Brahma", hatchDate: ago(1470))

        // Grandparents
        var echo  = Bird(ringID: "BR-010", name: "Echo",  sex: .male,   lineTag: "Brahma", hatchDate: ago(1100), status: .breeding)
        echo.sireID = atlas.id; echo.damID = bella.id
        var fauna = Bird(ringID: "BR-011", name: "Fauna", sex: .female, lineTag: "Brahma", hatchDate: ago(1080), status: .breeding)
        fauna.sireID = caesar.id; fauna.damID = duchess.id

        // Parents — Goliath & Gemma are full siblings
        var goliath = Bird(ringID: "BR-020", name: "Goliath", sex: .male,   lineTag: "Brahma", hatchDate: ago(700), status: .breeding)
        goliath.sireID = echo.id; goliath.damID = fauna.id
        var gemma   = Bird(ringID: "BR-021", name: "Gemma",   sex: .female, lineTag: "Brahma", hatchDate: ago(690), status: .breeding)
        gemma.sireID = echo.id; gemma.damID = fauna.id

        // Unrelated Leghorn hen
        let hera = Bird(ringID: "LG-030", name: "Hera", sex: .female, lineTag: "Leghorn", hatchDate: ago(650), status: .breeding)

        // Current generation — offspring of Goliath × Hera
        var igor = Bird(ringID: "BR-040", name: "Igor", sex: .male,   lineTag: "Brahma", hatchDate: ago(120))
        igor.sireID = goliath.id; igor.damID = hera.id
        var iris = Bird(ringID: "BR-041", name: "Iris", sex: .female, lineTag: "Brahma", hatchDate: ago(120))
        iris.sireID = goliath.id; iris.damID = hera.id

        store.birds = [atlas, bella, caesar, duchess, echo, fauna, goliath, gemma, hera, igor, iris]

        // Pairs
        let riskyPair    = BreedingPair(sireID: goliath.id, damID: gemma.id, label: "", startDate: ago(40),  status: .active)
        let healthyPair  = BreedingPair(sireID: goliath.id, damID: hera.id,  label: "", startDate: ago(200), status: .active)
        let retiredPair  = BreedingPair(sireID: echo.id,    damID: duchess.id, label: "Echo × Duchess", startDate: ago(800), status: .closed)
        store.pairs = [riskyPair, healthyPair, retiredPair]

        // Broods (from the healthy pair)
        let firstBrood  = Brood(pairID: healthyPair.id, hatchDate: ago(170), eggCount: 8, hatchedCount: 7, ringedCount: 7, malesCount: 3, femalesCount: 4, status: .closed)
        let springBrood = Brood(pairID: healthyPair.id, hatchDate: ago(20),  eggCount: 9, hatchedCount: 6, ringedCount: 2, malesCount: 3, femalesCount: 3, status: .open)
        store.broods = [firstBrood, springBrood]

        // Rings
        store.rings = [
            Ring(code: "BR-040", assignedBirdID: igor.id, status: .assigned, date: ago(110)),
            Ring(code: "BR-041", assignedBirdID: iris.id, status: .assigned, date: ago(110)),
            Ring(code: "BR-050", status: .available),
            Ring(code: "BR-051", status: .available),
            Ring(code: "BR-052", status: .available),
            Ring(code: "LG-060", status: .lost, date: ago(300))
        ]

        // Records
        store.records = [
            BreedingRecord(title: "Goliath — Best Cock", subject: SubjectRef(kind: .bird, id: goliath.id), date: ago(90), category: "Award", value: "1st place", comment: "Regional show", status: "Won"),
            BreedingRecord(title: "Igor weight check", subject: SubjectRef(kind: .bird, id: igor.id), date: ago(15), category: "Weight", value: "2600", comment: "Healthy growth", status: "Logged"),
            BreedingRecord(title: "Spring brood", subject: SubjectRef(kind: .pair, id: healthyPair.id), date: ago(20), category: "Brood", value: "6 hatched", comment: "Strong clutch", status: "Open")
        ]

        // Tasks
        store.tasks = [
            TaskItem(title: "Ring remaining chicks of spring brood", dueDate: ago(-3), isDone: false),
            TaskItem(title: "Review Pair Goliath × Gemma (inbreeding)", dueDate: ago(2), isDone: false),
            TaskItem(title: "Deworm breeding stock", dueDate: nil, isDone: true)
        ]

        // History
        store.history = [
            HistoryEntry(type: .hatched, date: ago(20),  text: "Hatched 6 chicks from Goliath × Hera"),
            HistoryEntry(type: .ringed,  date: ago(15),  text: "Assigned ring BR-041 to Iris"),
            HistoryEntry(type: .paired,  date: ago(40),  text: "Paired Goliath × Gemma"),
            HistoryEntry(type: .paired,  date: ago(200), text: "Paired Goliath × Hera")
        ]

        // Events
        store.events = [
            CalendarEvent(title: "Mating · Goliath × Gemma", date: ago(40), type: .mating, relatedID: riskyPair.id),
            CalendarEvent(title: "Brood due · Goliath × Gemma", date: ago(19), type: .broodDue, relatedID: riskyPair.id),
            CalendarEvent(title: "Ringing · spring brood", date: ago(15), type: .ringing, relatedID: springBrood.id),
            CalendarEvent(title: "Vaccination round", date: ago(-5), type: .custom, relatedID: nil)
        ]

        // Photos (generated gradient placeholders so the gallery isn't empty)
        var seededPhotos: [PhotoItem] = []
        if let f = ImageStorage.makePlaceholder(symbol: "bird.fill", colors: [UIColor(hex: "#34D399"), UIColor(hex: "#0A0F0C")]) {
            seededPhotos.append(PhotoItem(filename: f, category: .sire, relatedID: goliath.id, caption: "Goliath"))
        }
        if let f = ImageStorage.makePlaceholder(symbol: "bird", colors: [UIColor(hex: "#FBBF77"), UIColor(hex: "#0A0F0C")]) {
            seededPhotos.append(PhotoItem(filename: f, category: .dam, relatedID: hera.id, caption: "Hera"))
        }
        if let f = ImageStorage.makePlaceholder(symbol: "circle.hexagongrid.fill", colors: [UIColor(hex: "#38BDF8"), UIColor(hex: "#0A0F0C")]) {
            seededPhotos.append(PhotoItem(filename: f, category: .brood, relatedID: springBrood.id, caption: "Spring brood"))
        }
        if let f = ImageStorage.makePlaceholder(symbol: "trophy.fill", colors: [UIColor(hex: "#FBBF24"), UIColor(hex: "#0A0F0C")]) {
            seededPhotos.append(PhotoItem(filename: f, category: .award, relatedID: goliath.id, caption: "Best Cock"))
        }
        store.photos = seededPhotos
    }
}
