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
        config.websiteDataStore = .default()
        config.preferences.javaScriptEnabled = true
        
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
        guard let base64String = urlString.replacingOccurrences(of: "rdverify://", with: "")
            .dropFirst(5)
            .dropLast(4)
            .addingBase64Padding() else { return }
        
        do {
            guard let decodedData = Data(base64Encoded: base64String),
                  let jsonString = String(data: decodedData, encoding: .utf8),
                  let jsonData = jsonString.data(using: .utf8) else { return }
            
            let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            
            if let proxyData = json?["proxy"] as? [String: Any] {
                proxyUser = proxyData["login"] as? String
                proxyPassword = proxyData["password"] as? String
                proxyHost = proxyData["host"] as? String
                proxyPort = proxyData["port"] as? Int
            }
            
            idenfyUrl = json?["idenfyLink"] as? String
            valueFound = true
            
            if valueFound {
                configureProxy()
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }
    
    private func configureProxy() {
        guard let host = proxyHost, let port = proxyPort else { return }
        
        let proxyHost = "\(host):\(port)"
        let configuration = URLSessionConfiguration.default
        configuration.connectionProxyDictionary = [
            kCFProxyHostNameKey: host,
            kCFProxyPortNumberKey: port,
            kCFProxyTypeKey: kCFProxyTypeHTTPS
        ]
        
        if let username = proxyUser, let password = proxyPassword {
            configuration.connectionProxyDictionary?[kCFProxyUsernameKey] = username
            configuration.connectionProxyDictionary?[kCFProxyPasswordKey] = password
        }
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

extension String {
    func addingBase64Padding() -> String? {
        let remainder = self.count % 4
        if remainder == 0 { return self }
        let paddingLength = 4 - remainder
        return self + String(repeating: "=", count: paddingLength)
    }
}
