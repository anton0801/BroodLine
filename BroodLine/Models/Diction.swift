import Foundation

enum HiveDiction {
    static let appCode = "6779298236"
    static let trackerKey = "cY7ysCRx3QUDaAP6hoqmv4"
    static let suiteHive = "group.broodline.hive"
    static let cookieComb = "broodline_comb"
    static let backendMeadow = "https://brooddline.com/config.php"
    static let logBee = "🐝 [BroodLine]"
    static let hiveFile = "bl_hive_archive.json"
}

extension Notification.Name {
    static let attributionPollen = Notification.Name("ConversionDataReceived")
    static let deeplinksPollen = Notification.Name("deeplink_values")
    static let pushNectar = Notification.Name("LoadTempURL")
}
