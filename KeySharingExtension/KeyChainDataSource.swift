//
//  KeyChainDataSource.swift
//  Key Sharing Common Code
//

import SwiftUI
import ZIPFoundation

// swiftlint:disable file_length
// swiftlint:disable type_body_length

/**
 In the legacy key sharing implemetation, KeyChainDataSource had three modes of usage,
 each defined by the type of item sought in the key chain. However, only one mode was ever
 used. In this implementation, only the mode focused on `SecIdentity` elements was
 retained. Other modes can be added later by extending this enum if necessary.
 */
enum KeyChainDataSourceMode {
    /// Queries for `SecIdentity` instances in the key chain. This is the default and
    /// is the only option implemented here.
    case ksmIdentities
}

/**
 The ``KeyChainDataSource`` class is used to support table views that display key chain contents
 and to support a file provider interface to allow sharing keys with other apps. In those contexts.
 changes are signaled via ``objectWillChange`` from ``ObservableObject``. This is called
 when ``loadKeyChainContents`` is invoked. The methods from ``TableViewDataSource``
 enable management of table view contents.
 */
class KeyChainDataSource: TableViewDataSource, ObservableObject {
    /// Defines the type of objects to query from the key chain
    var mode: KeyChainDataSourceMode = .ksmIdentities

    /// Array of labels corresponding to objects retrieved via `SecItemCopyMatching` in ``loadKeyChainContents``
    private var itemLabels: [String] = []

    /// Set to false by default and by  ``clearContents()`` and set to true when ``loadKeyChainContents()`` succeeds
    private var initialized = false

    /// List of UTIs that are currently loaded.
    private var utis: [String] = []

    // MARK: Public methods

    /// Initializes an instance with a non-default mode. This is untested and is not used here.
    func initWithMode(mode: KeyChainDataSourceMode) {
        self.mode = mode
        initialized = false
    }

    /// Clears items read via ``loadKeyChainContents()`` and returns an instance to an uninitialized state
    func clearContents() {
        itemLabels.removeAll()
        initialized = false
    }

    /// Retrieves attributes for the ``SecIdentity`` associated with the given identifier as a ``KeyAttributesDataSource``
    /// suitable for sustaining display of the attributes in a table view.
    func getAttributesForIdentifier(identifier: String) -> KeyAttributesDataSource {
        for (index, label) in itemLabels.enumerated() where label == identifier {
            return getAttributesForRow(row: index)
        }
        return KeyAttributesDataSource(itemAttrs: [:], mode: mode)
    }

    /// Returns the item associated with the given index as a ``KeyAttributesDataSource``
    func getAttributesForRow(row: Int) -> KeyAttributesDataSource {
        var itemAttrs = [String: Any]()
        if row < itemLabels.count {
            if let tmpAttrs = getAttributesForRowAsDict(row: row) {
                itemAttrs = tmpAttrs
            }
        }
        return KeyAttributesDataSource(itemAttrs: itemAttrs, mode: mode)
    }

    /// Returns the item associated with the given index as a dictionary
    func getAttributesForRowAsDict(row: Int) -> [String: Any]? {
        if row >= itemLabels.count {
            return nil
        }
        let identifier = itemLabels[row]
        var query: [CFString: Any] = [kSecMatchLimit: kSecMatchLimitOne,
                                      kSecReturnRef: true,
                                      kSecReturnData: true,
                                      kSecAttrLabel: identifier,
                                      kSecReturnAttributes: true]

        // Set up the mode-specific pieces of the query
        switch mode {
        case KeyChainDataSourceMode.ksmIdentities:
            query[kSecClass] = kSecClassIdentity
        }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let dict = result as? [String: AnyObject] {
            return dict
        }
        return nil
    }

    /// ``getPkcs12ForIdentifier`` prepares a PKCS #12 object containing the certificate and private key
    /// extracted from the ``SecIdentity`` associated with the given identifier, if any. The password used to
    /// encrypt the PKCS #12 contents can be retrieved via the ``KeySharingPassword`` interface.
    func getPkcs12ForIdentifier(identifier: String) -> Data? {
        for (index, label) in itemLabels.enumerated() where label == identifier {
            if let dict = getAttributesForRowAsDict(row: index) {
                if let cert = getCertificateFromDictionary(curDict: dict) {
                    let certData = SecCertificateCopyData(cert) as NSData as Data
                    if let valueData = dict[kSecValueData as String] {
                        if CFGetTypeID(valueData as CFTypeRef) == CFDataGetTypeID() {
                            // swiftlint:disable:next force_cast
                            let privateKeyData = valueData as! Data
                            let password = getOrSetPassword()
                            if let p12 = GetPKCS12(certData, privateKeyData, password) {
                                return p12
                            }
                        } else {
                            logger.error("Expected CFData (\(CFDataGetTypeID())) from kSecValueData but found \(CFGetTypeID(valueData as CFTypeRef)).")
                        }
                    }
                }
            }
        }
        return nil
    }

    struct DataAndFilename {
        let data: Data
        let filename: String
    }

    // swiftlint:disable cyclomatic_complexity
    func getPkcs12AndFilenameForIdentifier(identifier: String) -> DataAndFilename? {
        for (index, label) in itemLabels.enumerated() where label == identifier {
            if let dict = getAttributesForRowAsDict(row: index) {
                if let cert = getCertificateFromDictionary(curDict: dict) {
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

                    let serial = GetSerialNumber(cert)
                    let certData = SecCertificateCopyData(cert) as NSData as Data
                    if let valueData = dict[kSecValueData as String] {
                        if CFGetTypeID(valueData as CFTypeRef) == CFDataGetTypeID() {
                            // swiftlint:disable:next force_cast
                            let privateKeyData = valueData as! Data
                            let password = getOrSetPassword()
                            if let p12 = GetPKCS12(certData, privateKeyData, password) {
                                let filename = "\(label)_\(serial ?? "").p12"
                                return DataAndFilename(data: p12, filename: filename)
                            }
                        } else {
                            logger.error("Expected CFData (\(CFDataGetTypeID())) from kSecValueData but found \(CFGetTypeID(valueData as CFTypeRef)).")
                        }
                    }
                }
            }
        }
        return nil
    }

    // swiftlint:enable cyclomatic_complexity

    /// ``getPkcs12ForIdentifier`` prepares a zip file containing PKCS #12 objects containing the certificate and private key
    /// extracted from the ``SecIdentity`` items associated with the currently configured uniform type identifier(s). The password used to
    /// encrypt PKCS #12 file contents can be retrieved via the ``KeySharingPassword`` interface. The same password is used for
    /// each PKCS #12 file.
    func getPKCS12Zip() -> Data? {
        do {
            let archive = try Archive(accessMode: .create)
            for label in itemLabels {
                if let dataAndFilename = getPkcs12AndFilenameForIdentifier(identifier: label) {
                    func provider(_ position: Int64, _ size: Int) throws -> Data {
                        let posInt = Int(truncatingIfNeeded: position)
                        return dataAndFilename.data.subdata(in: posInt ..< posInt + size)
                    }

                    try? archive.addEntry(with: dataAndFilename.filename, type: .file, uncompressedSize: Int64(dataAndFilename.data.count), provider: provider)
                }
            }
            return archive.data
        } catch {
            logger.error("Failed to prepare zip file for \(self.utis)")
        }
        return nil
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    /// Clears any previously load contents then queries the key chain per the current ``mode`` value.
    func loadKeyChainContents(utisToLoad: [String]) {
        clearContents()
        utis = utisToLoad
        if utis.isEmpty {
            utis.append("purebred2025.rsa.pkcs-12")
            utis.append("purebred2025.select.no-filter")
        }

        var sigItems: [String] = []
        var pivItems: [String] = []
        var devItems: [String] = []
        var sigTime: Double = 0
        var pivTime: Double = 0
        var devTime: Double = 0

        var query: [CFString: Any] = [kSecMatchLimit: kSecMatchLimitAll,
                                      kSecReturnRef: true,
                                      kSecReturnAttributes: true]

        // Set up the mode-specific pieces of the query
        switch mode {
        case KeyChainDataSourceMode.ksmIdentities:
            query[kSecClass] = kSecClassIdentity
        }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if errSecSuccess == status, result != nil {
            if CFGetTypeID(result) == CFArrayGetTypeID() {
                if let curItems = result as? [[String: AnyObject]] {
                    for curItem in curItems {
                        if let cert = getCertificateFromDictionary(curDict: curItem) {
                            let curNotBefore = GetNotBefore(cert)
                            let certType = GetCertType(cert)
                            if CertTypeRequested(certType, utis) || ZippedCertTypeRequested(cert, utis) {
                                initialized = true

                                // always add encryption certs, without consideration of notBefore time
                                if CT_ENCRYPTION == certType || utis.contains("purebred2025.select.no-filter") || utis.contains("purebred2025.zip.no-filter") {
                                    // items.append(curItem)
                                    if let label = curItem[kSecAttrLabel as String] as? String {
                                        itemLabels.append(label)
                                    }
                                } else if CT_DEVICE == certType {
                                    devTime = accumulateLatest(collection: &devItems, curItem: curItem, collectionTime: devTime, curItemTime: curNotBefore)
                                } else if CT_SIGNATURE == certType {
                                    sigTime = accumulateLatest(collection: &sigItems, curItem: curItem, collectionTime: sigTime, curItemTime: curNotBefore)
                                } else if CT_AUTHENTICATION == certType {
                                    pivTime = accumulateLatest(collection: &pivItems, curItem: curItem, collectionTime: pivTime, curItemTime: curNotBefore)
                                }
                            }
                        }
                    }
                    itemLabels.append(contentsOf: devItems)
                    itemLabels.append(contentsOf: sigItems)
                    itemLabels.append(contentsOf: pivItems)
                } else {
                    logger.error("Failed to convert SecItemCopyMatching result to [Dictionary<String, AnyObject>]")
                }
            }
        } else {
            logger.error("Failed to load key chain contents with \(status)")
        }
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length

    // MARK: TableViewDataSource methods

    /// Returns the number of items read by ``loadKeyChainContents()``
    func count() -> Int {
        itemLabels.count
    }

    /// Returns the common name from the certificate associated with the given index or Unrecognized in the event of an error
    func titleForRow(row: Int) -> String {
        if let cert = getCertificateForRow(row: row) {
            let certType = GetCertType(cert)
            let label = switch certType {
            case CT_AUTHENTICATION:
                "PIV"
            case CT_SIGNATURE:
                "Signature"
            case CT_ENCRYPTION:
                "Encryption"
            case CT_DEVICE:
                "Device"
            default:
                "Unknown"
            }
            return "\(label) certificate"
        }
        return "Unrecognized"
    }

    /// Returns an empty string at present
    func subtitleForRow(row: Int) -> String? {
        if let cert = getCertificateForRow(row: row) {
            if let serial = GetSerialNumber(cert) {
                return "Serial number: \(serial)"
            }
        }
        return ""
    }

    // MARK: Private methods

    /// ``accumulateLatest`` supports creating collections of items that share a notBefore date with goal of arriving at a collection with the most recent notBefore value.
    private func accumulateLatest(collection: inout [String], curItem: [String: AnyObject], collectionTime: Double, curItemTime: Double) -> Double {
        var newTime = collectionTime

        if collection.isEmpty {
            if let label = curItem[kSecAttrLabel as String] as? String {
                collection.append(label)
            }

            newTime = curItemTime
        } else {
            if collectionTime == curItemTime {
                if let label = curItem[kSecAttrLabel as String] as? String {
                    collection.append(label)
                }
            } else if curItemTime > collectionTime {
                collection.removeAll()
                // items.append(item)
                if let label = curItem[kSecAttrLabel as String] as? String {
                    collection.append(label)
                }
                newTime = curItemTime
            }
        }

        return newTime
    }

    /// Returns the `SecCertificate` extracted from the identity associated with the given identitifer, if any.
    private func getCertForIdentifier(identifier: String) -> SecCertificate? {
        for (index, label) in itemLabels.enumerated() where label == identifier {
            return getCertificateForRow(row: index)
        }
        return nil
    }

    /// Retrieve the `SecCertificate` associated with the indicated index. If the index is out of range
    /// or if the mode is `ksmKeys`, then nil is returned.
    private func getCertificateForRow(row: Int) -> SecCertificate? {
        if let curDict = getAttributesForRowAsDict(row: row) {
            getCertificateFromDictionary(curDict: curDict)
        } else {
            nil
        }
    }

    /// Returns the `notBefore value  extracted from the identity associated with the given identitifer, if any,
    /// as a Double containing seconds since the Unix epoch.
    private func getNotBeforeForIdentifier(identifier: String) -> Double {
        if let cert = getCertForIdentifier(identifier: identifier) {
            return GetNotBefore(cert)
        }
        return 0
    }
}

/// Generates a string of the given length containing randomly selected characters from a set of letters, numbers, and special characters.
private func randomPassword(length: Int) -> String {
    let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{};':,./<>?`~"
    // swiftlint:disable:next force_unwrapping
    return String((0 ..< length).map { _ in characters.randomElement()! })
}

/// `getOrSetPassword` searched the key chain for a password for the "PurebredKeySharing". If
/// a value is found, it is returned. If a value is not found, a 32 character random password is generated,
/// saved to the key chain then returned.
func getOrSetPassword() -> String {
    let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                  kSecAttrService: "PurebredKeySharing",
                                  kSecAttrAccount: "PurebredKeySharing",
                                  kSecReturnData: true,
                                  kSecMatchLimit: kSecMatchLimitOne]

    var passwordData: CFTypeRef?
    var status = SecItemCopyMatching(query as CFDictionary, &passwordData)
    if errSecSuccess == status, passwordData != nil {
        if CFGetTypeID(passwordData) == CFDataGetTypeID() {
            if let password = passwordData as? Data {
                let str = String(decoding: password, as: UTF8.self)
                return str
            }
        }
    } else {
        logger.error("Failed to find password for PurebredKeySharing service with \(status). Generating new value and continuing...")
    }
    let password = randomPassword(length: 32)
    let attrs: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                  kSecAttrService: "PurebredKeySharing",
                                  kSecAttrAccount: "PurebredKeySharing",
                                  kSecValueData: password.data(using: String.Encoding.utf8) as Any]
    status = SecItemAdd(attrs as CFDictionary, nil)
    if errSecSuccess != status {
        logger.error("Failed to save password for PurebredKeySharing service with \(status). Returning new value and continuing...")
    }
    return password
}

/// `getCertificateFromDictionary` takes a dictionary that should contain a SecIdentity in the kSecValueRef key and returns
/// a certificate extracted from that identity. Returns nil upon failure.
func getCertificateFromDictionary(curDict: [String: Any]) -> SecCertificate? {
    if let value = curDict[kSecValueRef as String] {
        if CFGetTypeID(value as CFTypeRef) == SecIdentityGetTypeID() {
            // swiftlint:disable:next force_cast
            let identity = value as! SecIdentity
            var certificate: SecCertificate?
            let status = SecIdentityCopyCertificate(identity, &certificate)
            if errSecSuccess != status {
                logger.error("Failed to copy certificate from identity with \(status)")
                return nil
            }
            return certificate
        } else {
            logger.error("Expected SecIdentity (\(SecIdentityGetTypeID())) from kSecValueRef but found \(CFGetTypeID(value as CFTypeRef)). Was a new mode added to KeyChainDataSourceMode?")
        }
    } else {
        logger.error("Expected to find kSecValueRef in dictionary but did not.")
    }
    return nil
}

// swiftlint:enable type_body_length
// swiftlint:enable file_length
