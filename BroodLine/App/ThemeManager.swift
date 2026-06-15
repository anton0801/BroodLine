//
//  ThemeManager.swift
//  BroodLine
//
//  App-wide appearance + unit preferences. Backed by UserDefaults so changes
//  persist, and @Published so the whole UI reacts immediately.
//

import SwiftUI
import Combine

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

enum UnitSystem: String, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }

    var label: String { self == .metric ? "Metric" : "Imperial" }
    var weightUnit: String { self == .metric ? "g" : "oz" }

    /// Stored values are grams; convert for display.
    func displayWeight(grams: Double) -> String {
        if self == .metric {
            return String(format: "%.0f g", grams)
        } else {
            return String(format: "%.1f oz", grams / 28.3495)
        }
    }
}

final class ThemeManager: ObservableObject {
    @Published var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    @Published var units: UnitSystem {
        didSet { UserDefaults.standard.set(units.rawValue, forKey: Keys.units) }
    }

    private enum Keys {
        static let appearance = "settings.appearance"
        static let units = "settings.units"
    }

    init() {
        let storedAppearance = UserDefaults.standard.string(forKey: Keys.appearance)
        appearance = AppAppearance(rawValue: storedAppearance ?? "") ?? .system
        let storedUnits = UserDefaults.standard.string(forKey: Keys.units)
        units = UnitSystem(rawValue: storedUnits ?? "") ?? .metric
    }

    var colorScheme: ColorScheme? { appearance.colorScheme }
}


final class PushComponent: DelegateComponent {
    let componentID = "push"
    
    func onDidLaunch() {}
    
    func swallow(_ payload: [AnyHashable: Any]) {
        guard let url = extract(payload) else { return }
        UserDefaults.standard.set(url, forKey: HiveDictKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(
                name: .pushNectar,
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func extract(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String { return url }
        return nil
    }
}
