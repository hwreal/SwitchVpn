import Foundation

/// Factory building adapter with proxy server host and port.
open class ServerAdapterFactory: AdapterFactory {
    let serverHost: String
    let serverPort: Int
    
    public var userName: String?
    public var password: String?
    
    public init(serverHost: String, serverPort: Int,userName: String? = nil, password: String? = nil) {
        self.serverHost = serverHost
        self.serverPort = serverPort
        self.userName = userName
        self.password = password
    }
}
