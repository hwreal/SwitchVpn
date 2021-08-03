//
//  PacketTunnelProvider.swift
//  SVE
//
//  Created by 黄威 on 2020/6/10.
//  Copyright © 2020 tencent. All rights reserved.
//

import NetworkExtension
import os.log
import NEKit
import CocoaLumberjack
import CocoaLumberjackSwift
import MMDB

class PacketTunnelProvider: NEPacketTunnelProvider {
    var interface: TUNInterface!
    // Since tun2socks is not stable, this is recommended to set to false
    var enablePacketProcessing = true
    
    var proxyPort: Int!
    
    var proxyServer: ProxyServer!
    
 
    
    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        DDLog.removeAllLoggers()
        
        // warning: setting to .Debug level might be way too verbose.
        DDLog.add(DDOSLogger.sharedInstance)
        dynamicLogLevel = .all
        
        DDLogError("PacketTunnelProvider:startTunnel11111111111111")
        // Use the build-in debug observer. ip.addr == 34.198.151.234 || ip.addr == 192.168.7.72
        ObserverFactory.currentFactory = DebugObserverFactory()
        let directAdapterFactory = DirectAdapterFactory()
        let httpAdapterFactory = HTTPAdapterFactory(serverHost: "192.168.111.222", serverPort: 8080, auth: nil)
        
       let protocolCon =  protocolConfiguration
        
        var sip = ""
        var sport = 0
        var usrName = ""
        var password = ""
        
        if let op = options {
            DDLogError("###4")
            let ip = op["ip"] as! NSString
            DDLogError("###5")
            let port = op["port"] as! NSString
            DDLogError("###6")
            
            DDLogError(ip as String)
            DDLogError(port as String)
            DDLogError("###7 \(ip) \(port)")
            sip = ip as String
            sport = Int(port as String)!
            
            usrName = op["usrName"] as! NSString as String
            password = op["password"] as! NSString as String

        }
        DDLogError("11111111111111 开始连接S5,\(sip) port:\(sport), usrName:\(usrName), password:\(password)")
        
//        let socksAdapterFactory = SOCKS5AdapterFactory.init(serverHost: sip, serverPort: sport)
        
        let socksAdapterFactory = SOCKS5AdapterFactory(serverHost: sip, serverPort: sport, userName: usrName, password: password)
        
//        ServerAdapterFactory(serverHost: <#T##String#>, serverPort: <#T##Int#>)
//        SOCKS5AdapterFactory(serverHost: <#T##String#>, serverPort: <#T##Int#>)
        
        let listRule = DomainListRule.init(adapterFactory: socksAdapterFactory, criteria: [
            DomainListRule.MatchCriterion.keyword("baidu"),
//            DomainListRule.MatchCriterion.keyword("sina"),
            DomainListRule.MatchCriterion.prefix("ocsp"),
            DomainListRule.MatchCriterion.keyword("httpbin")
        ])
        let allRule = AllRule(adapterFactory: socksAdapterFactory)
        
        // Create rule manager, rules will be matched in order.
        let ruleManager = RuleManager(fromRules: [allRule], appendDirect: true)
        
        
        RuleManager.currentManager = ruleManager
        proxyPort = 9090
        
        RawSocketFactory.TunnelProvider = self
        
        // the `tunnelRemoteAddress` is meaningless because we are not creating a tunnel.
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
        networkSettings.mtu = 1500
        
        let ipv4Settings = NEIPv4Settings(addresses: ["192.169.89.1"], subnetMasks: ["255.255.255.0"])
        if enablePacketProcessing {
            ipv4Settings.includedRoutes = [NEIPv4Route.default()]
            ipv4Settings.excludedRoutes = [
                NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "100.64.0.0", subnetMask: "255.192.0.0"),
                NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
                NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
                NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
            ]
        }
        
        networkSettings.ipv4Settings = ipv4Settings
        
        let proxySettings = NEProxySettings()
        //        proxySettings.autoProxyConfigurationEnabled = true
        //        proxySettings.proxyAutoConfigurationJavaScript = "function FindProxyForURL(url, host) {return \"SOCKS 127.0.0.1:\(proxyPort)\";}"
        proxySettings.httpEnabled = true
        proxySettings.httpServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.httpsEnabled = true
        proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.excludeSimpleHostnames = true
        // This will match all domains
        proxySettings.matchDomains = [""]
        networkSettings.proxySettings = proxySettings
        
        // the 198.18.0.0/15 is reserved for benchmark.
        if enablePacketProcessing {
            let DNSSettings = NEDNSSettings(servers: ["198.18.0.1"])
            DNSSettings.matchDomains = [""]
            DNSSettings.matchDomainsNoSearch = false
            networkSettings.dnsSettings = DNSSettings
        }
        
        setTunnelNetworkSettings(networkSettings) {
            error in
            guard error == nil else {
                
                
                DDLogError("Encountered an error setting up the network: \(error!)")
                completionHandler(error)
                return
            }
            
            self.proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: "127.0.0.1"), port: Port(port: UInt16(self.proxyPort)))
            try! self.proxyServer.start()
            
            completionHandler(nil)
            
            if self.enablePacketProcessing {
                self.interface = TUNInterface(packetFlow: self.packetFlow)
                
                let range = try? IPRange.init(startIP: IPAddress(fromString: "198.18.1.1")!, endIP: IPAddress(fromString: "198.18.255.255")!)
                var pool:IPPool? = nil
                if let range = range {
                    pool = IPPool.init(range: range)
                }
                let dnsServer = DNSServer(address: IPAddress(fromString: "198.18.0.1")!, port: Port(port: 53), fakeIPPool: pool)
                let resolver = UDPDNSResolver(address: IPAddress(fromString: "114.114.114.114")!, port: Port(port: 53))
                dnsServer.registerResolver(resolver)
                self.interface.register(stack:dnsServer)
                DNSServer.currentServer = dnsServer
                
                let udpStack = UDPDirectStack()
                self.interface.register(stack:udpStack)
                
                let tcpStack = TCPStack.stack
                tcpStack.proxyServer = self.proxyServer
                self.interface.register(stack:tcpStack)
                self.interface.start()
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        
        DDLogError("111111111111 断开VPN")
        
        if enablePacketProcessing {
            interface.stop()
            interface = nil
            DNSServer.currentServer = nil
        }
        
        proxyServer.stop()
        proxyServer = nil
        RawSocketFactory.TunnelProvider = nil
        
        completionHandler()
        
        // For unknown reason, the extension will be running for several extra seconds, which prevents us from starting another configuration immediately. So we crash the extension now.
        // I do not find any consequences.
        exit(EXIT_SUCCESS)
    }
}
