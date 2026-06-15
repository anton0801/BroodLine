import Foundation
import Combine

@MainActor
final class BroodLineDrone: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let beekeeper: Beekeeper
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?
    
    private var uiLocked: Bool = false
    
    init() {
        self.beekeeper = Loft.shared.provideBeekeeper()
        bindOutcomes()
    }
    
    deinit {
        deadlineTask?.cancel()
    }
    
    private func bindOutcomes() {
        beekeeper.outcomePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outcome in
                self?.handleOutcome(outcome)
            }
            .store(in: &cancellables)
    }
    
    func ignite() {
        beekeeper.raiseHive()
        armDeadline()
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        Task {
            beekeeper.absorbPollens(data)
            await beekeeper.swarm()
        }
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        beekeeper.absorbWaggles(data)
    }
    
    func acceptConsent() {
        beekeeper.acceptConsent {
            self.showPermissionPrompt = false
        }
    }
    
    func skipConsent() {
        showPermissionPrompt = false
        beekeeper.skipConsent()
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleOutcome(_ outcome: SwarmOutcome) {
        guard !uiLocked else { return }
        
        switch outcome {
        case .idling:
            break
        case .askConsent:
            showPermissionPrompt = true
        case .fanOut:
            navigateToWeb = true
        case .starved:
            navigateToMain = true
        }
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            
            let shouldFire = self.beekeeper.reportTimeUp()
            if shouldFire {
                self.handleOutcome(.starved)
            }
        }
    }
}
