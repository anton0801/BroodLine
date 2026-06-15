import SwiftUI
import UIKit

@main
struct BroodLineApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var manageAppDelegat

    var body: some Scene {
        WindowGroup {
            LaunchView()
        }
    }
}
