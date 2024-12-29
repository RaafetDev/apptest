import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == "rdverify" {
            NotificationCenter.default.post(name: .didReceiveVerifyURL, object: nil, userInfo: ["url": url])
            return true
        }
        return false
    }
}

extension Notification.Name {
    static let didReceiveVerifyURL = Notification.Name("didReceiveVerifyURL")
}
