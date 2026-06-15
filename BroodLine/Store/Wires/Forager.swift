import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

protocol Forager {
    func gather(payload: [String: Any]) async throws -> String
}

final class HTTPForager: Forager {
    
    private let session: URLSession
    private let lulls: [Double] = [82.0, 164.0, 328.0]
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private func oneSweep(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw HiveSnare(.droneLost, stage: "forager.response")
        }
        
        if http.statusCode == 404 {
            throw HiveSnare(.meadowFenced404, stage: "forager.404")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HiveSnare(.waxCracked, stage: "forager.json")
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw HiveSnare(.waxCracked, stage: "forager.missingOk")
        }
        
        if !ok {
            throw HiveSnare(.combSealed, stage: "forager.okFalse")
        }
        
        guard let url = json["url"] as? String, !url.isEmpty else {
            throw HiveSnare(.waxCracked, stage: "forager.missingURL")
        }
        
        return url
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func gather(payload: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: HiveDiction.backendMeadow) else {
            throw HiveSnare(.waxCracked, stage: "forager.url")
        }
        
        var body: [String: Any] = payload
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(HiveDiction.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: HiveDictKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastSnare: Error?
        
        for (idx, gap) in lulls.enumerated() {
            do {
                return try await oneSweep(request)
            } catch let snare as HiveSnare {
                if snare.isFenced {
                    throw snare
                }
                if snare.isSwarm, let coolDown = snare.coolDown {
                    try await Task.sleep(nanoseconds: UInt64(coolDown * 1_000_000_000))
                    continue
                }
                lastSnare = snare
                if idx < lulls.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(gap * 1_000_000_000))
                }
            } catch {
                lastSnare = error
                if idx < lulls.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(gap * 1_000_000_000))
                }
            }
        }
        
        if let lastSnare = lastSnare {
            throw lastSnare
        }
        throw HiveSnare(.droneLost, stage: "forager.exhausted")
    }
    
}
