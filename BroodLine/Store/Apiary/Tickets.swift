import Foundation

final class HoneyKit {
    let honeycomb: Honeycomb
    let beacon: Beacon
    let forager: Forager
    let toller: Toller
    
    init(honeycomb: Honeycomb, beacon: Beacon, forager: Forager, toller: Toller) {
        self.honeycomb = honeycomb
        self.beacon = beacon
        self.forager = forager
        self.toller = toller
    }
    
    static func productionKit() -> HoneyKit {
        HoneyKit(
            honeycomb: JSONHoneycomb(),
            beacon: AppsFlyerBeacon(),
            forager: HTTPForager(),
            toller: NotificationToller()
        )
    }
}
