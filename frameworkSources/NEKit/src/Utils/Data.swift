import Foundation

extension Data {
    func withUnsafeRawPointer<ResultType>(_ body: (UnsafeRawPointer) throws -> ResultType) rethrows -> ResultType {
        return try self.withUnsafeBytes { (ptr: UnsafePointer<Int8>) -> ResultType in
            let rawPtr = UnsafeRawPointer(ptr)
            return try body(rawPtr)
        }
    }
}



extension Data {
    init(hexString:String) {
        var hexStr = hexString.replacingOccurrences(of: " ", with: "")
        hexStr = hexStr.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
        assert(hexStr.count % 2 == 0, "输入字符串格式不对，8位代表一个字符")
        var bytes: [UInt8] = []
        var sum = 0
        // 整形的 utf8 编码范围
        let intRange = 48...57
        // 小写 a~f 的 utf8 的编码范围
        let lowercaseRange = 97...102
        // 大写 A~F 的 utf8 的编码范围
        let uppercasedRange = 65...70
        
        for (index, c) in hexStr.utf8CString.enumerated() {
            var intC = Int(c.byteSwapped)
            if intC == 0 {
                break
            } else if intRange.contains(intC) {
                intC -= 48
            } else if lowercaseRange.contains(intC) {
                intC -= 87
            } else if uppercasedRange.contains(intC) {
                intC -= 55
            } else {
                assertionFailure("每个字符都需要在0~9，a~f，A~F内")
            }
            sum = sum * 16 + intC
            // 每两个十六进制字母代表8位，即一个字节
            if index % 2 != 0 {
                bytes.append(UInt8(sum))
                sum = 0
            }
        }
        self.init(bytes)
    }

    
    var hexString:String {
        let bytes = [UInt8](self)
        let arr = bytes.map{ byte -> String in
            var str = String(format: "%0x", byte)
            if str.count == 1 {
                str = "0" + str
            }
            return str
        }
        let str = arr.joined()
        return str
    }
    
    var hexStr: String{
        let arr = [UInt8](self)
        var ret = "\n"
        var lineS = ""
        for (i, v) in arr.enumerated() {
            var s1 = String(format: "%02X", v)
            if i % 2 == 1 {
                s1 = s1 + " "
            }
            
            if i % 16 == 15{
                s1 = s1 + "\n"
            }
            
            if i % 16 == 0{
                s1 = String(format: "%08X:  ", i) + s1
            }
            
            lineS = lineS + s1
            
            if (i + 1) % 16 == 0 {
                ret = ret + lineS
                lineS = ""
            }else{
                if i == arr.count - 1 {
                    ret = ret + lineS
                }
            }
            
            
        }
        return ret + "\n"
        
        //return arr.map{String(format: "%02X ", $0)}.joined()
    }
}
