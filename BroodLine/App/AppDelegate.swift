import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private lazy var componentHub = ComponentHub(host: self)
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        componentHub.broadcastDidLaunch()
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            componentHub.pushPart.swallow(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        componentHub.broadcastDidActivate()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            UserDefaults.standard.set(t, forKey: HiveDictKey.fcm)
            UserDefaults.standard.set(t, forKey: HiveDictKey.push)
            UserDefaults(suiteName: HiveDiction.suiteHive)?.set(t, forKey: "shared_fcm")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        componentHub.pushPart.swallow(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        componentHub.pushPart.swallow(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        componentHub.pushPart.swallow(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        componentHub.fusionPart.absorbAttribution(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        componentHub.fusionPart.absorbAttribution([
            "error": true,
            "error_desc": error.localizedDescription
        ])
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        componentHub.fusionPart.absorbDeeplink(link.clickEvent)
    }
}

protocol DelegateComponent: AnyObject {
    var componentID: String { get }
    func onDidLaunch()
    func onDidActivate()
}

extension DelegateComponent {
    func onDidActivate() {}
}

final class ComponentHub {
    private weak var host: AppDelegate?
    
    let firebasePart = FirebaseComponent()
    let messagingPart: MessagingComponent
    let notificationsPart: NotificationsComponent
    let appsFlyerPart: AppsFlyerComponent
    let fusionPart = FusionComponent()
    let pushPart = PushComponent()
    
    private var components: [DelegateComponent] = []
    
    init(host: AppDelegate) {
        self.host = host
        self.messagingPart = MessagingComponent(host: host)
        self.notificationsPart = NotificationsComponent(host: host)
        self.appsFlyerPart = AppsFlyerComponent(host: host)
        
        components = [
            firebasePart,
            messagingPart,
            notificationsPart,
            appsFlyerPart,
            fusionPart,
            pushPart
        ]
    }
    
    func broadcastDidLaunch() {
        for component in components {
            component.onDidLaunch()
        }
    }
    
    func broadcastDidActivate() {
        for component in components {
            component.onDidActivate()
        }
    }
}

final class FirebaseComponent: DelegateComponent {
    let componentID = "firebase"
    
    func onDidLaunch() {
        FirebaseApp.configure()
    }
}

final class MessagingComponent: DelegateComponent {
    let componentID = "messaging"
    private weak var host: MessagingDelegate?
    
    init(host: MessagingDelegate) {
        self.host = host
    }
    
    func onDidLaunch() {
        Messaging.messaging().delegate = host
        UIApplication.shared.registerForRemoteNotifications()
    }
}

final class NotificationsComponent: DelegateComponent {
    let componentID = "notifications"
    private weak var host: UNUserNotificationCenterDelegate?
    
    init(host: UNUserNotificationCenterDelegate) {
        self.host = host
    }
    
    func onDidLaunch() {
        UNUserNotificationCenter.current().delegate = host
    }
}

final class AppsFlyerComponent: DelegateComponent {
    let componentID = "appsFlyer"
    private weak var attDelegate: AppsFlyerLibDelegate?
    private weak var linkDelegate: DeepLinkDelegate?
    
    init(host: AppDelegate) {
        self.attDelegate = host
        self.linkDelegate = host
    }
    
    func onDidLaunch() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = HiveDiction.trackerKey
        sdk.appleAppID = HiveDiction.appCode
        sdk.delegate = attDelegate
        sdk.deepLinkDelegate = linkDelegate
        sdk.isDebug = false
    }
    
    func onDidActivate() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}
