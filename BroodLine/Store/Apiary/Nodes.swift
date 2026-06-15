import Foundation
import AppsFlyerLib

final class PushSeizeLeaf: BTNode {
    let nodeID = "pushSeize"
    
    func tick(ticket: TreeTicket) async -> NodeStatus {
        guard let pushURL = UserDefaults.standard.string(forKey: HiveDictKey.pushURL),
              !pushURL.isEmpty else {
            return .failure
        }
        
        let needsConsent = ticket.hive.consentRipe
        
        ticket.hive.routeURL = pushURL
        ticket.hive.routeMode = "Active"
        ticket.hive.unhived = false
        ticket.hive.nested = true
        
        ticket.kit.honeycomb.cap(ticket.hive.crystallize())
        ticket.kit.honeycomb.marknRoute(url: pushURL, mode: "Active")
        ticket.kit.honeycomb.raisePrimedFlag()
        UserDefaults.standard.removeObject(forKey: HiveDictKey.pushURL)
        
        return .settled(needsConsent ? .askConsent : .fanOut)
    }
}

final class PollensGateLeaf: BTNode {
    let nodeID = "pollensGate"
    
    func tick(ticket: TreeTicket) async -> NodeStatus {
        guard ticket.hive.pollensReady else {
            return .settled(.idling)
        }
        return .success
    }
}

final class OrganicWaggleLeaf: BTNode {
    let nodeID = "organicWaggle"
    
    func tick(ticket: TreeTicket) async -> NodeStatus {
        let needsWaggle = ticket.hive.organicBee
            && ticket.hive.unhived
            && !ticket.hive.organicForaged
        
        guard needsWaggle else {
            return .success
        }
        
        ticket.hive.organicForaged = true
        ticket.kit.honeycomb.cap(ticket.hive.crystallize())
        
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !ticket.hive.nested else {
            return .success
        }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await ticket.kit.beacon.ping(deviceID: deviceID)
            for (k, v) in ticket.hive.waggles {
                if fetched[k] == nil { fetched[k] = v }
            }
            let mapped = fetched.mapValues { "\($0)" }
            ticket.hive.pollens = mapped
            ticket.kit.honeycomb.cap(ticket.hive.crystallize())
        } catch {
            print("\(HiveDiction.logBee) Organic waggle soft fail: \(error)")
        }
        
        return .success
    }
}

final class MeadowGatherLeaf: BTNode {
    let nodeID = "meadowGather"
    
    func tick(ticket: TreeTicket) async -> NodeStatus {
        guard ticket.hive.pollensReady else {
            return .settled(.idling)
        }
        
        let payload = ticket.hive.pollens.mapValues { $0 as Any }
        
        do {
            let url = try await ticket.kit.forager.gather(payload: payload)
            
            let needsConsent = ticket.hive.consentRipe
            
            ticket.hive.routeURL = url
            ticket.hive.routeMode = "Active"
            ticket.hive.unhived = false
            ticket.hive.nested = true
            
            ticket.kit.honeycomb.cap(ticket.hive.crystallize())
            ticket.kit.honeycomb.marknRoute(url: url, mode: "Active")
            ticket.kit.honeycomb.raisePrimedFlag()
            UserDefaults.standard.removeObject(forKey: HiveDictKey.pushURL)
            
            return .settled(needsConsent ? .askConsent : .fanOut)
        } catch {
            return .settled(.starved)
        }
    }
}
