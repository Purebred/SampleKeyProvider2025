//
//  SampleKeyProviderUtils.swift
//  SampleKeyProvider2025
//

import Foundation

// poached from https://stackoverflow.com/questions/25388747/sha256-in-swift
extension Data {
    public func sha256() -> String {
        hexStringFromData(input: digest(input: self as NSData))
    }

    private func digest(input: NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    private func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)

        var hexString = ""
        for byte in bytes {
            hexString += String(format: "%02x", UInt8(byte))
        }

        return hexString.uppercased()
    }

    // poached from https://stackoverflow.com/questions/26501276/converting-hex-string-to-nsdata-in-swift
    /// Hexadecimal string representation of `Data` object.

    var hexadecimal: String {
        map { String(format: "%02x", $0) }
            .joined()
    }
}
