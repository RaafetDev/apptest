@preconcurrency
import UIKit
import WebKit
import AVFoundation

class ViewController: UIViewController {
    private var webView: WKWebView!
    private var canStartScript = false
    private var isScriptDone = false
    private var valueFound = false
    
    private var proxyHost: String?
    private var proxyPort: Int?
    private var proxyUser: String?
    private var proxyPassword: String?
    private var idenfyUrl: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupNotifications()
        
        webView.load(URLRequest(url: URL(string: "https://visa.vfsglobal.com/")!))
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
        
        view.addSubview(webView)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleVerifyURL(_:)), name: .didReceiveVerifyURL, object: nil)
    }
    
    @objc private func handleVerifyURL(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else { return }
        parseScheme(url)
    }
    
    private func parseScheme(_ url: URL) {
        let urlString = url.absoluteString
        guard let base64Part = urlString.replacingOccurrences(of: "rdverify://", with: "")
            .dropFirst(5)
            .dropLast(4)
            .padding(toLength: ((urlString.count + 3) / 4) * 4, withPad: "=", startingAt: 0),
              let decodedData = Data(base64Encoded: String(base64Part)),
              let jsonString = String(data: decodedData, encoding: .utf8),
              let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { return }
        
        if let proxyData = json["proxy"] as? [String: Any] {
            proxyUser = proxyData["login"] as? String
            proxyPassword = proxyData["password"] as? String
            proxyHost = proxyData["host"] as? String
            proxyPort = proxyData["port"] as? Int
        }
        
        idenfyUrl = json["idenfyLink"] as? String
        valueFound = true
        
        if valueFound {
            configureProxy()
        }
    }
    
    private func configureProxy() {
        guard let host = proxyHost, let port = proxyPort else { return }
        
        let proxyDict: [AnyHashable: Any] = [
            kCFProxyHostNameKey: host,
            kCFProxyPortNumberKey: port,
            kCFProxyTypeKey: kCFProxyTypeHTTPS
        ]
        
        if let username = proxyUser, let password = proxyPassword {
            URLCredential(user: username, password: password, persistence: .forSession)
        }
        
        URLSession.shared.configuration.connectionProxyDictionary = proxyDict
    }
    
    private func runScript() {
        guard canStartScript, !isScriptDone, let idenfyUrl = idenfyUrl else { return }
        
        let script = "window.open('\(idenfyUrl)','_self')"
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Script error: \(error)")
            }
        }
        isScriptDone = true
    }
}

extension ViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        canStartScript = true
        runScript()
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let user = proxyUser, let password = proxyPassword {
            let credential = URLCredential(user: user, password: password, persistence: .forSession)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
