import Foundation

/// Factory building SOCKS5 adapter.
open class SOCKS5AdapterFactory: ServerAdapterFactory {
//    override public init(serverHost: String, serverPort: Int) {
//        super.init(serverHost: serverHost, serverPort: serverPort)
//    }
    
    override public init(serverHost: String, serverPort: Int, userName: String? = nil, password: String? = nil) {
        super.init(serverHost: serverHost, serverPort: serverPort, userName: userName, password: password)
    }

    /**
     Get a SOCKS5 adapter.

     - parameter session: The connect session.

     - returns: The built adapter.
     */
    override open func getAdapterFor(session: ConnectSession) -> AdapterSocket {
        let adapter = SOCKS5Adapter(serverHost: serverHost, serverPort: serverPort, userName: userName, password: password)
        adapter.socket = RawSocketFactory.getRawSocket()
        return adapter
    }
}
