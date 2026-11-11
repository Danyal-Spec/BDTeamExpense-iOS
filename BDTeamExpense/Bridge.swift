import UIKit
import WebKit

/// Native side of the app screens: sends requests to the group's Google Sheet server and opens the share sheet.
final class Bridge: NSObject, WKScriptMessageHandlerWithReply, WKScriptMessageHandler, WKNavigationDelegate {

    weak var webView: WKWebView?

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 40
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(becameActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func becameActive() {
        webView?.evaluateJavaScript("window.__onResume && window.__onResume()", completionHandler: nil)
    }

    /// config.json from the app bundle plus the app version, as a JavaScript object literal.
    static func configJSON() -> String {
        var config: [String: Any] = [:]
        if let url = Bundle.main.url(forResource: "config", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            config = parsed
        }
        config["version"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        config["platform"] = "ios"
        guard let data = try? JSONSerialization.data(withJSONObject: config),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    private static func allowed(_ url: URL) -> Bool {
        guard url.scheme == "https", let host = url.host else { return false }
        return host == "script.google.com" || host.hasSuffix(".googleusercontent.com")
    }

    // MARK: - "http": POST a request, reply with the response text

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage,
                               replyHandler: @escaping (Any?, String?) -> Void) {
        guard message.name == "http",
              let body = message.body as? [String: Any],
              let address = body["url"] as? String,
              let payload = body["body"] as? String,
              let url = URL(string: address), Bridge.allowed(url) else {
            replyHandler(nil, "This server link is not allowed.")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain;charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = payload.data(using: .utf8)

        // Google answers the POST with a redirect; URLSession follows it with a GET automatically.
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if error != nil {
                    replyHandler(nil, "No internet connection. Try again.")
                    return
                }
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard status < 400, let data = data, let text = String(data: data, encoding: .utf8) else {
                    replyHandler(nil, "Server error \(status). Check the server link.")
                    return
                }
                replyHandler(text, nil)
            }
        }.resume()
    }

    // MARK: - "share": open the system share sheet with some text

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "share", let text = message.body as? String else { return }
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let root = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = root.view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 1, height: 1)
        root.present(sheet, animated: true)
    }

    // MARK: - Keep the web view on the bundled screens; open anything else in Safari

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isFileURL || url.scheme == "about" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}
