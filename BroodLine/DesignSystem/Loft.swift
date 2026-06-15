import Foundation

@MainActor
final class Loft {
    
    static let shared = Loft()
    
    private lazy var kitInstance: HoneyKit = HoneyKit.productionKit()
    private lazy var beekeeperInstance: Beekeeper = Beekeeper(kit: kitInstance)
    
    private init() {}
    
    func provideKit() -> HoneyKit {
        kitInstance
    }
    
    func provideBeekeeper() -> Beekeeper {
        beekeeperInstance
    }
}
