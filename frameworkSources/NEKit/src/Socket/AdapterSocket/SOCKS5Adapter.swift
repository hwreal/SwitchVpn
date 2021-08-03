import Foundation
import CocoaLumberjackSwift

public class SOCKS5Adapter: AdapterSocket {
    enum SOCKS5AdapterStatus {
        case invalid,
             connecting,
             readingMethodResponse,
             readingMethodNeedAuth,
             authSuccess,
             authFailed,
             readingResponseFirstPart,
             readingResponseSecondPart,
             forwarding
    }
    public let serverHost: String
    public let serverPort: Int
    public var userName: String?
    public var password: String?
    
    var internalStatus: SOCKS5AdapterStatus = .invalid
    
    let helloData = Data(bytes: UnsafePointer<UInt8>(([0x05, 0x02, 0x00,0x02] as [UInt8])), count: 4)
    
    public enum ReadTag: Int {
        case methodResponse = -20000, connectResponseFirstPart, connectResponseSecondPart
    }
    
    public enum WriteTag: Int {
        case open = -21000, connectIPv4, connectIPv6, connectDomainLength, connectPort
    }
    
    public init(serverHost: String, serverPort: Int, userName: String? = nil, password: String? = nil) {
        self.serverHost = serverHost
        self.serverPort = serverPort
        self.userName = userName
        self.password = password
        
        super.init()
    }
    
    public override func openSocketWith(session: ConnectSession) {
        super.openSocketWith(session: session)
        
        guard !isCancelled else {
            return
        }
        
        do {
            internalStatus = .connecting
            try socket.connectTo(host: serverHost, port: serverPort, enableTLS: false, tlsSettings: nil)
        } catch {}
    }
    
    public override func didConnectWith(socket: RawTCPSocketProtocol) {
        super.didConnectWith(socket: socket)
        
        write(data: helloData)
        internalStatus = .readingMethodResponse
        socket.readDataTo(length: 2)
    }
    
    public override func didRead(data: Data, from socket: RawTCPSocketProtocol) {
        super.didRead(data: data, from: socket)
        DDLogError("收到数据data:\(data.hexStr)")

        switch internalStatus {
        case .readingMethodResponse:
            
            data.withUnsafeBytes { (ptr: UnsafePointer<UInt8>)  in
                switch ptr.advanced(by: 1).pointee{
                case 0:
                    //不需要认证
                    DDLogError("")
                    
                    DDLogError("****8***不需要认证")
                    internalStatus = .authSuccess
                    
                case 2:
                    // 需要账号密码
                    DDLogError("****8*** 需要账号密码")
                    guard let userName = userName, let password = password else {
                        DDLogError("****8*** 账号密码不能为空")
                        break
                    }
                    
                    internalStatus = .readingMethodNeedAuth
                    var auth:[UInt8] = [0x01]
                   
                    let usrNameL = userName.count
                    auth += [UInt8(usrNameL)]
                    auth += [UInt8](userName.utf8)
                    
                    let passwordL = password.count
                    auth += [UInt8(passwordL)]
                    auth += [UInt8](password.utf8)
                    
                    write(data: Data(bytes: auth))
                    
                    socket.readDataTo(length: 2)
                    
                default:
                    break
                    
                }
            }
            
        case .readingMethodNeedAuth:
            data.withUnsafeBytes { (ptr: UnsafePointer<UInt8>)  in
                switch ptr.advanced(by: 1).pointee{
                case 0:
                    //认证成功
                    DDLogError("****8*****认证成功")
                   // internalStatus = .authSuccess
                    
                    var response: [UInt8]
                    if session.isIPv4() {
                        response = [0x05, 0x01, 0x00, 0x01]
                        let address = IPAddress(fromString: session.host)!
                        response += [UInt8](address.dataInNetworkOrder)
                    } else if session.isIPv6() {
                        response = [0x05, 0x01, 0x00, 0x04]
                        let address = IPAddress(fromString: session.host)!
                        response += [UInt8](address.dataInNetworkOrder)
                    } else {
                        response = [0x05, 0x01, 0x00, 0x03]
                        response.append(UInt8(session.host.utf8.count))
                        response += [UInt8](session.host.utf8)
                    }
                    
                    let portBytes: [UInt8] = Utils.toByteArray(UInt16(session.port)).reversed()
                    response.append(contentsOf: portBytes)
                    write(data: Data(bytes: response))
                    
                    internalStatus = .readingResponseFirstPart
                    socket.readDataTo(length: 5)
                    
                default:
                    DDLogError("****8******认证失败")
                    internalStatus = .authFailed
                }
            }
            
            
        case .authSuccess:
            
            var response: [UInt8]
            if session.isIPv4() {
                response = [0x05, 0x01, 0x00, 0x01]
                let address = IPAddress(fromString: session.host)!
                response += [UInt8](address.dataInNetworkOrder)
            } else if session.isIPv6() {
                response = [0x05, 0x01, 0x00, 0x04]
                let address = IPAddress(fromString: session.host)!
                response += [UInt8](address.dataInNetworkOrder)
            } else {
                response = [0x05, 0x01, 0x00, 0x03]
                response.append(UInt8(session.host.utf8.count))
                response += [UInt8](session.host.utf8)
            }
            
            let portBytes: [UInt8] = Utils.toByteArray(UInt16(session.port)).reversed()
            response.append(contentsOf: portBytes)
            write(data: Data(bytes: response))
            
            internalStatus = .readingResponseFirstPart
            socket.readDataTo(length: 5)
            
        case .authFailed:
            DDLogError("****8***socks认证失败")
            
        case .readingResponseFirstPart:
            var readLength = 0
            data.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) in
                switch ptr.advanced(by: 3).pointee {
                case 1:
                    readLength = 3 + 2
                case 3:
                    readLength = Int(ptr.advanced(by: 1).pointee) + 2
                case 4:
                    readLength = 15 + 2
                default:
                    break
                }
            }
            internalStatus = .readingResponseSecondPart
            socket.readDataTo(length: readLength)
        case .readingResponseSecondPart:
            internalStatus = .forwarding
            observer?.signal(.readyForForward(self))
            delegate?.didBecomeReadyToForwardWith(socket: self)
        case .forwarding:
            delegate?.didRead(data: data, from: self)
        default:
            return
        }
    }
    
    override open func didWrite(data: Data?, by socket: RawTCPSocketProtocol) {
        super.didWrite(data: data, by: socket)
        DDLogError("发送数据data:\(data!.hexStr)")
        
        
        if internalStatus == .forwarding {
            delegate?.didWrite(data: data, by: self)
        }
    }
}
