//
//  VPNMgr.swift
//  ocspvpn
//
//  Created by qiyun zhang on 2020/4/21.
//  Copyright © 2020 z. All rights reserved.
//


import Foundation
import NetworkExtension

final class VPNMgr {
    
    static let shared = VPNMgr()
    
    var manager: NETunnelProviderManager!
    
    var disConnectBlock:()->() = {}
    
    func remove() {
        manager.loadFromPreferences { (err) in
            if let error = err {
                print(error)
            }
            else {
                self.manager.removeFromPreferences { (err) in
                    if let error = err {
                        print(error)
                    }
                }
            }
        }
    }
    
    func set() {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if error == nil,
               let managers = managers, managers.count > 0 {
                for mgr in managers {
                    if let provider = mgr.protocolConfiguration as? NETunnelProviderProtocol,
                    provider.providerBundleIdentifier == Bundle.main.bundleIdentifier! + ".SVE" {
                        print("The vpn already configured. We will use it.")
                        self.manager = mgr
                        self.createVPN()
                        self.saveVPN()
                    }
                }
            }
            if self.manager == nil {
                print("The vpn config is NULL, we will config it")
                self.manager = NETunnelProviderManager.init()
                self.createVPN()
                self.saveVPN()
            }
        }
        
    }
//
//    fileprivate func setRulerConfig(_ manager:NETunnelProviderManager){
//        var conf = [String:AnyObject]()
//        conf["ss_address"] = ip_address as AnyObject?
//        conf["ss_port"] = port as AnyObject?
//        conf["ss_method"] = algorithm as AnyObject? // 大写 没有横杠 看Extension中的枚举类设定 否则引发fatal error
//        conf["ss_password"] = password as AnyObject?
//        conf["ymal_conf"] = getRuleConf() as AnyObject?
//        let orignConf = manager.protocolConfiguration as! NETunnelProviderProtocol
//        orignConf.providerConfiguration = conf
//        manager.protocolConfiguration = orignConf
//        print(ip_address,port,algorithm,password)
//    }

    
    func createVPN() {
        var conf = [String:AnyObject]()
        conf["ss_address"] = "ip111" as AnyObject?
//        conf["ss_port"] = port as AnyObject?
//        conf["ss_method"] = algorithm as AnyObject? // 大写 没有横杠 看Extension中的枚举类设定 否则引发fatal error
//        conf["ss_password"] = password as AnyObject?
//        conf["ymal_conf"] = getRuleConf() as AnyObject?
        
        
        let providerProtocol = NETunnelProviderProtocol.init()
        providerProtocol.providerBundleIdentifier = Bundle.main.bundleIdentifier! + ".SVE"
        providerProtocol.serverAddress = "127.0.0.1"
        providerProtocol.providerConfiguration = conf
        
        
        manager.protocolConfiguration = providerProtocol
        manager.localizedDescription = "PacketTunnel"
        manager.isEnabled = true
        let anyRule = NEOnDemandRuleConnect()
        anyRule.interfaceTypeMatch = .any
//        manager.onDemandRules = [anyRule]
        manager.isEnabled = true
//        manager.isOnDemandEnabled = true
        manager.localizedDescription = "OVPN"
        
    }
    
    func saveVPN() {
        manager.saveToPreferences { (error) in
            if error == nil {
                self.manager.loadFromPreferences { (err) in
                    if err == nil {
                        print("save vpn success")
                        NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: self.manager.connection, queue: nil) { noti in
                            if self.manager.connection.status == .disconnected {
                                self.disConnectBlock()
                            }
                            
                        }
                    }
                }
            }
            else {
                print(error!)
            }
        }
    }
    
    func connect(_ ip:String, _ port:Int, usrName: String? = nil, password: String? = nil) {
        print("开始连接...")
//        try? manager.connection.startVPNTunnel()
        let dict:NSDictionary = ["ip":ip,"port":"\(port)","usrName":usrName ?? "", "password":password ?? ""]
        
        if self.manager.connection.status == .disconnected {
            
            try? manager.connection.startVPNTunnel(options: dict as! [String : NSObject])
        }
        else {
            disconnect {
                try? self.manager.connection.startVPNTunnel(options: dict as! [String : NSObject])
            }
        }
    }
    
    func disconnect(completion:@escaping ()->()) {
        manager.connection.stopVPNTunnel()
        self.disConnectBlock = completion
    }
}

