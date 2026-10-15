import UIKit
import WebKit

/// Full-screen web view that runs the bundled game.
final class GameViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private let background = UIColor(named: "LaunchBackground") ?? .black

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: BundleSchemeHandler.scheme)
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true

        let controller = WKUserContentController()
        // Lets the page know it runs inside the app (invite links then point at the website).
        controller.addUserScript(WKUserScript(source: "window.ASHEN_APP=true;",
                                              injectionTime: .atDocumentStart, forMainFrameOnly: true))
        // Feels like an app: no pinch or double-tap zoom.
        controller.addUserScript(WKUserScript(source: """
            (function(){var m=document.querySelector('meta[name=viewport]');
            if(m)m.setAttribute('content','width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover');})();
            """, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = background
        webView.scrollView.backgroundColor = background
        // The page lays itself out around the notch and home indicator (env(safe-area-inset-*)).
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        #if DEBUG
        if #available(iOS 16.4, *) { webView.isInspectable = true }
        #endif
        self.webView = webView
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: BundleSchemeHandler.startURL))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Navigation

    /// Our own pages load in place; anything else (http, https, mailto) opens outside the app.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() else { return .allow }
        if scheme == BundleSchemeHandler.scheme || scheme == "about" || scheme == "blob" || scheme == "data" {
            return .allow
        }
        if navigationAction.targetFrame?.isMainFrame ?? true {
            Task { _ = await UIApplication.shared.open(url) }
            return .cancel
        }
        return .allow
    }

    /// window.open / target=_blank links open in Safari.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url, ["http", "https", "mailto"].contains(url.scheme?.lowercased() ?? "") {
            UIApplication.shared.open(url)
        } else if let url = navigationAction.request.url, url.scheme == BundleSchemeHandler.scheme {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    /// iOS may kill the web content process in the background; bring the game back instead of a blank screen.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.load(URLRequest(url: BundleSchemeHandler.startURL))
    }
}
