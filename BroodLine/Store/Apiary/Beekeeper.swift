import Foundation
import Combine

@MainActor
final class Beekeeper {
    
    private var hive: Hive = Hive()
    private var raised: Bool = false
    
    let latch = SwarmLatch()
    
    private let kit: HoneyKit
    private let rootTree: BTNode
    
    private let outcomeSubject = PassthroughSubject<SwarmOutcome, Never>()
    var outcomePublisher: AnyPublisher<SwarmOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var consentTask: Task<Void, Never>?
    
    init(kit: HoneyKit) {
        self.kit = kit
        
        let pushBranch = BTSelector("pushBranch", [
            PushSeizeLeaf()
        ])
        
        let foragingBranch = BTSequence("foragingBranch", [
            PollensGateLeaf(),
            OrganicWaggleLeaf(),
            MeadowGatherLeaf()
        ])
        
        self.rootTree = BTSelector("root", [
            pushBranch,
            foragingBranch
        ])
    }
    
    private func ensureRaised() {
        guard !raised else { return }
        let archive = kit.honeycomb.uncap()
        hive = Hive.revive(from: archive)
        raised = true
    }
    
    func raiseHive() {
        ensureRaised()
    }
    
    func absorbPollens(_ raw: [String: Any]) {
        ensureRaised()
        let mapped = raw.mapValues { "\($0)" }
        hive.pollens = mapped
        kit.honeycomb.cap(hive.crystallize())
    }
    
    func absorbWaggles(_ raw: [String: Any]) {
        ensureRaised()
        let mapped = raw.mapValues { "\($0)" }
        hive.waggles = mapped
        kit.honeycomb.cap(hive.crystallize())
    }
    
    func swarm() async {
        ensureRaised()
        guard !latch.isDropped else { return }
        
        let ticket = TreeTicket(hive: hive, kit: kit)
        
        let status = await rootTree.tick(ticket: ticket)
        
        hive = ticket.hive
        
        switch status {
        case .settled(let outcome):
            if case .idling = outcome {
                outcomeSubject.send(.idling)
                return
            }
            if latch.tryDrop() {
                outcomeSubject.send(outcome)
            }
        case .success, .failure, .running:
            outcomeSubject.send(.idling)
        }
    }
    
    func acceptConsent(fun: @escaping () -> Void) {
        ensureRaised()
        consentTask = Task { [weak self] in
            guard let self = self else { return }
            
            let granted = await self.kit.toller.ringBell()
            let now = Date()
            
            self.hive.consentDrawn = granted
            self.hive.consentBarred = !granted
            self.hive.consentDanceAt = now
            
            self.kit.honeycomb.cap(self.hive.crystallize())
            
            if granted {
                self.kit.toller.wireSwarmCall()
            }
            
            self.outcomeSubject.send(.fanOut)
            fun()
        }
    }
    
    func skipConsent() {
        ensureRaised()
        let now = Date()
        hive.consentDanceAt = now
        kit.honeycomb.cap(hive.crystallize())
        outcomeSubject.send(.fanOut)
    }
    
    func reportTimeUp() -> Bool {
        return latch.tryDrop()
    }
}
