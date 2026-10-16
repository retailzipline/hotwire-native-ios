import Embassy
import Foundation

extension DefaultHTTPServer {
    static func turboServer(eventLoop: EventLoop, port: Int = 8080) -> DefaultHTTPServer {
        return DefaultHTTPServer(eventLoop: eventLoop, port: port) { environ, startResponse, sendBody in
            let path = environ["PATH_INFO"] as! String

            func respondWithFile(resourceName: String, resourceType: String) {
                let fileURL = Bundle.module.url(forResource: resourceName, withExtension: resourceType, subdirectory: "Server")!
                let data = try! Data(contentsOf: fileURL)
                let contentType = (resourceType == "js") ? "application/javascript" : "text/html"

                startResponse("200 OK", [("Content-Type", contentType)])
                sendBody(data)
                sendBody(Data())
            }

            switch path {
            case "/turbo-7.0.0-beta.1.js":
                respondWithFile(resourceName: "turbo-7.0.0-beta.1", resourceType: "js")
            case "/turbolinks-5.2.0.js":
                respondWithFile(resourceName: "turbolinks-5.2.0", resourceType: "js")
            case "/turbolinks-5.3.0-dev.js":
                respondWithFile(resourceName: "turbolinks-5.3.0-dev", resourceType: "js")
            case "/":
                respondWithFile(resourceName: "turbo", resourceType: "html")
            case "/turbolinks":
                respondWithFile(resourceName: "turbolinks", resourceType: "html")
            case "/turbolinks-5.3":
                respondWithFile(resourceName: "turbolinks-5.3", resourceType: "html")
            case "/missing-library":
                startResponse("200 OK", [("Content-Type", "text/html")])
                sendBody("<html></html>".data(using: .utf8)!)
                sendBody(Data())
            case "/failing-iframe":
                startResponse("200 OK", [("Content-Type", "text/html")])
                sendBody("<html><body><iframe src=\"/unauthorized\"></iframe></body></html>".data(using: .utf8)!)
                sendBody(Data())
            case "/protected-redirect":
                // Redirects to another origin only when the session cookie arrives, like a protected Rails page.
                guard (environ["HTTP_COOKIE"] as? String)?.contains("session=abc") == true else {
                    startResponse("401 Unauthorized", [])
                    sendBody(Data())
                    return
                }
                startResponse("302 Found", [("Location", "http://[::1]:8080/missing-library")])
                sendBody(Data())
            case "/unauthorized":
                startResponse("401 Unauthorized", [("Content-Type", "text/html")])
                sendBody(Data())
            default:
                startResponse("404 Not Found", [("Content-Type", "text/plain")])
                sendBody(Data())
            }
        }
    }
}
