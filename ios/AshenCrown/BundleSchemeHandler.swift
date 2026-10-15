import Foundation
import UniformTypeIdentifiers
import WebKit

/// Serves the game files bundled in the app's `Web` folder at `ashen://localhost/...`.
/// A custom scheme gives the page a stable origin, so saved decks (localStorage) persist
/// between launches and the page runs as a secure context.
final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "ashen"
    static let startURL = URL(string: "\(scheme)://localhost/index.html")!

    private let root: URL = Bundle.main.resourceURL!.appendingPathComponent("Web", isDirectory: true).standardizedFileURL

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }
        var path = url.path
        if path.isEmpty || path == "/" { path = "/index.html" }
        let file = root.appendingPathComponent(String(path.dropFirst())).standardizedFileURL

        // Only files inside Web/ may be read.
        guard file.path.hasPrefix(root.path + "/"), let data = try? Data(contentsOf: file) else {
            let notFound = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": "text/plain"])!
            urlSchemeTask.didReceive(notFound)
            urlSchemeTask.didReceive(Data())
            urlSchemeTask.didFinish()
            return
        }

        var mime = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        if mime.hasPrefix("text/") || mime == "application/javascript" { mime += "; charset=utf-8" }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [
            "Content-Type": mime,
            "Content-Length": String(data.count),
            "Cache-Control": "no-cache",
        ])!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Responses are delivered synchronously, so there is nothing to cancel.
    }
}
