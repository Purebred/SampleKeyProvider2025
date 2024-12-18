//
//  KeyChainDataSource+Extension.swift
//  KeySharingExtension
//

import FileProvider
import Foundation
import UniformTypeIdentifiers

/// ``FileProviderParts`` contains values for ``FileProviderItem`` that vary with PKCS #12 contents.
struct FileProviderParts {
    var filename: String
    var identifier: NSFileProviderItemIdentifier
    var documentSize: NSNumber
    var creationDate: Date
    init(documentSize: NSNumber, identifier: String, filename: String, creationDate: Date) {
        self.documentSize = documentSize
        self.identifier = NSFileProviderItemIdentifier(rawValue: identifier)
        self.filename = filename
        self.creationDate = creationDate
    }
}

/// ``getFileProviderPartsFromDict`` takes a dictionary that notionally contains a ``SecIdentity`` and returns
/// a ``FileProviderParts`` instance populated with information relative to that ``SecIdentitiy``.
private func getFileProviderPartsFromDict(_ dict: [String: Any]) -> FileProviderParts? {
    if let cert = getCertificateFromDictionary(curDict: dict) {
        let data = SecCertificateCopyData(cert) as NSData as Data
        let notBefore = GetNotBefore(cert)
        let date = if notBefore != 0 {
            Date(timeIntervalSince1970: notBefore)
        } else {
            Date()
        }
        if let serial = GetSerialNumber(cert) {
            let certType = GetCertType(cert)
            let label = switch certType {
            case CT_AUTHENTICATION:
                "piv"
            case CT_SIGNATURE:
                "signature"
            case CT_ENCRYPTION:
                "encryption"
            case CT_DEVICE:
                "device"
            default:
                "unknown"
            }
            let identifier = dict[kSecAttrLabel as String] as? String ?? data.sha256()
            if let valueData = dict[kSecValueData as String] {
                // swiftlint:disable:next force_cast
                let privateKeyBits = valueData as! Data
                let password = getOrSetPassword()
                if let p12 = GetPKCS12(data, privateKeyBits, password) {
                    let filename = "\(label)_\(serial).p12"
                    let fpi = FileProviderParts(documentSize: p12.count as NSNumber, identifier: identifier,
                                                filename: filename, creationDate: date)
                    return fpi
                } else {
                    logger.error("Failed to prepare PKCS #12 object for certificate with serial \(serial) and identifier \(identifier)")
                }
            }
        }
    }
    return nil
}

/// ``getFileProviderPartsForIdentifier`` searches the key chain for a ``SecIdentity`` that contains a ``kSecAttrLabel``
/// attribute that matches the given ``identifier`` then returns a ``FileProviderParts`` containing information about the PKCS #12
/// object extracted from that ``SecIdentity``.
func getFileProviderPartsForIdentifier(identifier: String) -> FileProviderParts? {
    let query: [CFString: Any] = [kSecMatchLimit: kSecMatchLimitOne,
                                  kSecReturnRef: true,
                                  kSecReturnData: true,
                                  kSecAttrLabel: identifier,
                                  kSecClass: kSecClassIdentity,
                                  kSecReturnAttributes: true]

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecSuccess, let dict = result as? [String: Any] {
        return getFileProviderPartsFromDict(dict)
    }

    return nil
}

extension KeyChainDataSource {
    func getFileProviderItemAtIndex(index: Int, parent: NSFileProviderItemIdentifier, contentType: UTType) -> FileProviderItem? {
        if let dict = getAttributesForRowAsDict(row: index) {
            if var fileParts = getFileProviderPartsFromDict(dict) {
                if parent != NSFileProviderItemIdentifier.rootContainer {
                    fileParts.identifier = NSFileProviderItemIdentifier(rawValue: String("\(parent.rawValue).\(fileParts.identifier.rawValue)"))
                }

                let fpi = FileProviderItem.initFile(identifier: fileParts.identifier, docSize: fileParts.documentSize, parent: parent,
                                                    filename: fileParts.filename, contentType: contentType, creationDate: fileParts.creationDate)
                return fpi
            }
        }
        return nil
    }
}
