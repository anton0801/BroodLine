import Foundation

protocol Honeycomb {
    func cap(_ archive: HiveArchive)
    func marknRoute(url: String, mode: String)
    func raisePrimedFlag()
    func uncap() -> HiveArchive
}

final class JSONHoneycomb: Honeycomb {
    
    private let fm = FileManager.default
    private let dataDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dataDir = docs.appendingPathComponent("BroodHive", isDirectory: true)
        if !fm.fileExists(atPath: dataDir.path) {
            try? fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
        }
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: HiveDiction.suiteHive) ?? .standard
    }
    
    private var archiveURL: URL {
        dataDir.appendingPathComponent(HiveDiction.hiveFile)
    }
    
    func cap(_ archive: HiveArchive) {
        let veiled = VeiledHive(
            pollens: glazeDict(archive.pollens),
            waggles: glazeDict(archive.waggles),
            routeURL: archive.routeURL,
            routeMode: archive.routeMode,
            unhived: archive.unhived,
            consentDrawn: archive.consentDrawn,
            consentBarred: archive.consentBarred,
            consentDanceAt: archive.consentDanceAt
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        do {
            let data = try encoder.encode(veiled)
            try data.write(to: archiveURL, options: .atomic)
        } catch {
            print("\(HiveDiction.logBee) Honeycomb cap failed: \(error)")
        }
        
        suiteStore.set(archive.consentDrawn, forKey: "bl_consent_drawn")
        suiteStore.set(archive.consentBarred, forKey: "bl_consent_barred")
        if let date = archive.consentDanceAt {
            suiteStore.set(date.timeIntervalSince1970, forKey: "bl_consent_dance_at")
        }
        homeStore.set(archive.consentDrawn, forKey: "bl_consent_drawn")
        homeStore.set(archive.consentBarred, forKey: "bl_consent_barred")
        if let date = archive.consentDanceAt {
            homeStore.set(date.timeIntervalSince1970, forKey: "bl_consent_dance_at")
        }
    }
    
    func marknRoute(url: String, mode: String) {
        suiteStore.set(url, forKey: HiveDictKey.routeURL)
        homeStore.set(url, forKey: HiveDictKey.routeURL)
        suiteStore.set(mode, forKey: HiveDictKey.routeMode)
    }
    
    func raisePrimedFlag() {
        suiteStore.set(true, forKey: HiveDictKey.primed)
        homeStore.set(true, forKey: HiveDictKey.primed)
    }
    
    func uncap() -> HiveArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        if fm.fileExists(atPath: archiveURL.path),
           let data = try? Data(contentsOf: archiveURL),
           let veiled = try? decoder.decode(VeiledHive.self, from: data) {
            return HiveArchive(
                pollens: unglazeDict(veiled.pollens),
                waggles: unglazeDict(veiled.waggles),
                routeURL: veiled.routeURL,
                routeMode: veiled.routeMode,
                unhived: veiled.unhived,
                consentDrawn: veiled.consentDrawn,
                consentBarred: veiled.consentBarred,
                consentDanceAt: veiled.consentDanceAt
            )
        }
        
        return restoreFromDefaults()
    }
    
    private func restoreFromDefaults() -> HiveArchive {
        let routeURL = homeStore.string(forKey: HiveDictKey.routeURL)
            ?? suiteStore.string(forKey: HiveDictKey.routeURL)
        let routeMode = suiteStore.string(forKey: HiveDictKey.routeMode)
        let primed = suiteStore.bool(forKey: HiveDictKey.primed)
        
        let drawn = suiteStore.bool(forKey: "bl_consent_drawn")
            || homeStore.bool(forKey: "bl_consent_drawn")
        let barred = suiteStore.bool(forKey: "bl_consent_barred")
            || homeStore.bool(forKey: "bl_consent_barred")
        let danceTs = suiteStore.double(forKey: "bl_consent_dance_at")
        let danceAt: Date? = danceTs > 0 ? Date(timeIntervalSince1970: danceTs) : nil
        
        return HiveArchive(
            pollens: [:], waggles: [:],
            routeURL: routeURL, routeMode: routeMode,
            unhived: !primed,
            consentDrawn: drawn, consentBarred: barred, consentDanceAt: danceAt
        )
    }
    
    private func glazeDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = glaze(v) }
        return result
    }
    
    private func unglazeDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = unglaze(v) ?? v }
        return result
    }
    
    private func glaze(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "+", with: "%")
            .replacingOccurrences(of: "/", with: "$")
    }
    
    private func unglaze(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "%", with: "+")
            .replacingOccurrences(of: "$", with: "/")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

struct VeiledHive: Codable {
    let pollens: [String: String]
    let waggles: [String: String]
    let routeURL: String?
    let routeMode: String?
    let unhived: Bool
    let consentDrawn: Bool
    let consentBarred: Bool
    let consentDanceAt: Date?
}
