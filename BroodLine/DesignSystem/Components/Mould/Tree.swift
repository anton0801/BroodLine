import Foundation

final class TreeTicket {
    var hive: Hive
    let kit: HoneyKit
    var harvestedOutcome: SwarmOutcome?
    
    init(hive: Hive, kit: HoneyKit) {
        self.hive = hive
        self.kit = kit
    }
}

enum NodeStatus {
    case success
    case failure
    case running
    case settled(SwarmOutcome)
}

protocol BTNode: AnyObject {
    var nodeID: String { get }
    func tick(ticket: TreeTicket) async -> NodeStatus
}

final class BTSequence: BTNode {
    let nodeID: String
    private let children: [BTNode]
    
    init(_ id: String, _ children: [BTNode]) {
        self.nodeID = id
        self.children = children
    }
    
    func tick(ticket: TreeTicket) async -> NodeStatus {
        for child in children {
            let status = await child.tick(ticket: ticket)
            switch status {
            case .success:
                continue
            case .failure:
                return .failure
            case .running:
                return .running
            case .settled(let outcome):
                return .settled(outcome)
            }
        }
        return .success
    }
}

final class BTSelector: BTNode {
    let nodeID: String
    private let children: [BTNode]
    
    init(_ id: String, _ children: [BTNode]) {
        self.nodeID = id
        self.children = children
    }
    
    func tick(ticket: TreeTicket) async -> NodeStatus {
        for child in children {
            let status = await child.tick(ticket: ticket)
            switch status {
            case .success:
                return .success
            case .failure:
                continue
            case .running:
                return .running
            case .settled(let outcome):
                return .settled(outcome)
            }
        }
        return .failure
    }
}
