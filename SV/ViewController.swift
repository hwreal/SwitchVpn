//
//  ViewController.swift
//  SV
//
//  Created by 黄威 on 2020/6/10.
//  Copyright © 2020 tencent. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
   
    var ssID:Int = 13000;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
       
        
        
        do{
            let btn = UIButton(frame: CGRect(x: 20, y: 100, width: 100, height: 50))
            btn.backgroundColor = .cyan
            btn.setTitleColor(.black, for: .normal)
            btn.setTitle("创建VPN", for: .normal)
            btn.addTarget(self, action: #selector(btnTouched1), for: .touchUpInside)
            view.addSubview(btn)
        }
        
        do{
            let btn = UIButton(frame: CGRect(x: 20, y: 200, width: 100, height: 50))
            btn.backgroundColor = .cyan
            btn.setTitleColor(.black, for: .normal)
            btn.setTitle("连接1", for: .normal)
            btn.addTarget(self, action: #selector(btnTouched2), for: .touchUpInside)
            view.addSubview(btn)
        }
        
        do{
            let btn = UIButton(frame: CGRect(x: 20, y: 300, width: 100, height: 50))
            btn.backgroundColor = .cyan
            btn.setTitleColor(.black, for: .normal)
            btn.setTitle("连接2", for: .normal)
            btn.addTarget(self, action: #selector(btnTouched3), for: .touchUpInside)
            view.addSubview(btn)
        }
        
        
        do{
            let btn = UIButton(frame: CGRect(x: 20, y: 400, width: 100, height: 50))
            btn.backgroundColor = .cyan
            btn.setTitleColor(.black, for: .normal)
            btn.setTitle("httpBin", for: .normal)
            btn.addTarget(self, action: #selector(btnTouched4), for: .touchUpInside)
            view.addSubview(btn)
        }
        
    }
    
    @objc func btnTouched1(){
        print("创建vpn")
        VPNMgr.shared.set()
    }
    
    
    @objc func btnTouched2(){
       // VPNMgr.shared.connect("192.168.7.9", 30001, usrName: "test1", password: "password1")
        VPNMgr.shared.connect("121.41.171.121", 10010, usrName: "testsocket", password: "123456")
    }
    
    
    @objc func btnTouched3(){
//        VPNMgr.shared.connect("192.168.7.9", 30002, usrName: "test2", password: "password2")
        VPNMgr.shared.connect("44.195.251.117", 10085, usrName: "0eKu", password: "vu3kwy")
    }
    
    
    @objc func btnTouched4(){
        ssID = ssID + 1
        URLSession.shared.dataTask(with: URL(string: "http://httpbin.org/get?ssID=\(ssID)")!) { (data, rep, error) in
            if error != nil{
                print("请求出错:\(error!)")
                return
            }
            
            let resStr = String(data: data!, encoding: .utf8)
            print("resStr:\n\(resStr!)")
        }.resume()
    }
    
}

