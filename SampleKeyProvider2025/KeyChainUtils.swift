//
//  KeyChainUtils.swift
//  Key Sharing Common Code
//

import Foundation

/// Delete all key chain items for the given class.
func deleteAllItemsForSecClass(_ secClass: CFTypeRef) {
    let options: [CFString: Any] = [kSecClass: secClass]
    let status = SecItemDelete(options as CFDictionary)
    if status != errSecSuccess {
        logger.error("SecItemDelete failed with \(status)")
    }
}

/// Takes a buffer containing a binary DER-encoded PKCS #12 object and a string containing a password and attempts
/// to parse this into a ``SecIdentity`` that can be added to the key chain. Returns an OSStatus returned from a
/// keychain API function upon failure or errSecSuccess upon success. Duplicate key chain items are treated as success.
/// If the result of ``SecPKCS12Import`` cannot be processed, then errSecBadReq is returned.
func importP12(pkcs12Data: Data, password: String) -> OSStatus {
    let options: [CFString: Any] = [kSecImportExportPassphrase: password,
                                    kSecReturnRef: true,
                                    kSecReturnData: true,
                                    kSecReturnAttributes: true]
    var items: CFArray?
    var status = SecPKCS12Import(pkcs12Data as CFData, options as CFDictionary, &items)
    if status == errSecSuccess {
        guard let dictArray = items as? [[String: AnyObject]] else {
            logger.error("Failed to parse data from SecPKCS12Import as a dictionary")
            return errSecBadReq
        }

        let identity = dictArray[0]["identity"]
        if CFGetTypeID(identity) != SecIdentityGetTypeID() {
            logger.error("Failed to read SecIdentity from dictionary returned by SecPKCS12Import")
            return errSecBadReq
        }

        var certificate: SecCertificate?
        // swiftlint:disable:next force_cast
        status = SecIdentityCopyCertificate(identity as! SecIdentity, &certificate)
        if CFGetTypeID(certificate) != SecCertificateGetTypeID() {
            logger.error("Failed to read SecCertificate from SecIdentity returned by SecPKCS12Import")
            return errSecBadReq
        }

        // swiftlint:disable:next force_unwrapping
        let data = SecCertificateCopyData(certificate!) as Data
        let attrLabel = data.sha256()
        let options: [CFString: Any] = [kSecValueRef: identity as Any,
                                        kSecReturnPersistentRef: true,
                                        kSecAttrLabel: attrLabel]
        status = SecItemAdd(options as CFDictionary, nil)
        if status == errSecDuplicateItem {
            logger.debug("SecItemAdd failed with errSecDuplicateItem (\(status)). Treating as success.")
            status = errSecSuccess
        }
    } else {
        logger.error("SecPKCS12Import failed with \(status)")
    }
    return status
}
