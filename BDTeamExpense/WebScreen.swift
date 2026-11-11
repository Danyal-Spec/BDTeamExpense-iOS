import SwiftUI
import UIKit
import WebKit

/// Shows the bundled app screens (www/index.html) and connects them to `Bridge`.
struct WebScreen: UIViewRepresentable {

    func makeCoordinator() -> Bridge { Bridge() }

    func makeUIView(context: Context) -> WKWebView {
        let bridge = context.coordinator
        let config = WKWebViewConfiguration()
        let content = config.userContentController
        content.addScriptMessageHandler(bridge, contentWorld: .page, name: "http")
        content.add(bridge, name: "share")
        content.addUserScript(WKUserScript(
            source: "window.APP_CONFIG = \(Bridge.configJSON());",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true))

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = bridge
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 11 / 255, green: 93 / 255, blue: 75 / 255, alpha: 1)
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.bounces = false
        web.allowsLinkPreview = false
        bridge.webView = web

        if let folder = Bundle.main.url(forResource: "www", withExtension: nil) {
            web.loadFileURL(folder.appendingPathComponent("index.html"), allowingReadAccessTo: folder)
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
