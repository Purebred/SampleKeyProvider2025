//
//  KeyAttributesDataSource.swift
//  Key Sharing Common Code
//

import Foundation

// swiftformat adds trailing commas and swiftlint complains about them
// swiftlint:disable trailing_comma

/// Selected attributes that are typically assocated with `SecIdentity` objects
private let gIdentityAttrs = [
    kSecAttrAccessible as String,
    kSecAttrAccessGroup as String,
    kSecAttrCertificateType as String,
    kSecAttrCertificateEncoding as String,
    kSecAttrLabel as String,
    // omit until a Name decoder is linked in
    //    kSecAttrSubject as String,
    //    kSecAttrIssuer as String,
    kSecAttrSerialNumber as String,
    kSecAttrSubjectKeyID as String,
    kSecAttrPublicKeyHash as String,
    kSecAttrKeyClass as String,
    kSecAttrApplicationLabel as String,
    kSecAttrIsPermanent as String,
    kSecAttrApplicationTag as String,
    kSecAttrKeyType as String,
    kSecAttrKeySizeInBits as String,
    kSecAttrEffectiveKeySize as String,
    kSecAttrCanEncrypt as String,
    kSecAttrCanDecrypt as String,
    kSecAttrCanDerive as String,
    kSecAttrCanSign as String,
    kSecAttrCanVerify as String,
    kSecAttrCanWrap as String,
    kSecAttrCanUnwrap as String,
]

// --------------------------------------------------------------
// Dictionary of keys to friendly names
// --------------------------------------------------------------
/// Friendly names for selected attributes.
private let gAttrMap = [
    kSecAttrAccessible as String: "Accessible",
    kSecAttrAccessGroup as String: "Access group",
    kSecAttrCertificateType as String: "Certificate type",
    kSecAttrCertificateEncoding as String: "Certificate encoding",
    kSecAttrLabel as String: "Label",
    kSecAttrSerialNumber as String: "Serial number",
    kSecAttrSubjectKeyID as String: "Subject key ID",
    kSecAttrPublicKeyHash as String: "Public key hash",
    kSecAttrKeyClass as String: "Key class",
    kSecAttrApplicationLabel as String: "Application label",
    kSecAttrIsPermanent as String: "Is permanent",
    kSecAttrApplicationTag as String: "Application tag",
    kSecAttrKeyType as String: "Key type",
    kSecAttrKeySizeInBits as String: "Key size in bits",
    kSecAttrEffectiveKeySize as String: "Effective key size",
    kSecAttrCanEncrypt as String: "Can encrypt",
    kSecAttrCanDecrypt as String: "Can decrypt",
    kSecAttrCanDerive as String: "Can derive",
    kSecAttrCanSign as String: "Can sign",
    kSecAttrCanVerify as String: "Can verify",
    kSecAttrCanUnwrap as String: "Can wrap",
    kSecAttrSubject as String: "Certificate Subject",
    kSecAttrIssuer as String: "Certificate Issuer",
]
// swiftlint:enable trailing_comma

/**
 ``KeyAttributesDataSource`` is used to map attributes associated with a key chain item to
 friendly names.
 */
class KeyAttributesDataSource: TableViewDataSource, ObservableObject {
    private var itemAttrs: [String: Any]
    private var mode: KeyChainDataSourceMode
    private var attrNames: [String]

    /// Initialize an instance is a dictionary containing attributes for a key chain item of the indicated mode.
    init(itemAttrs: [String: Any], mode: KeyChainDataSourceMode) {
        self.itemAttrs = itemAttrs
        self.mode = mode
        switch mode {
        case KeyChainDataSourceMode.ksmIdentities:
            self.attrNames = gIdentityAttrs
        }
    }

    /// Change the dictionary and mode associated with the instance.
    func setItemAttrs(itemAttrs: [String: Any], mode: KeyChainDataSourceMode) {
        self.itemAttrs = itemAttrs
        self.mode = mode
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    func getItemAttrs() -> [String: Any] {
        self.itemAttrs
    }

    // MARK: - TableViewDataSource Functions

    /// Return the number of recognized attributes in the current dictionary
    func count() -> Int {
        var count = 0
        for attr in attrNames where itemAttrs[attr] != nil {
            count += 1
        }
        return count
    }

    /// Return the attribute name for the indicated row.
    func titleForRow(row: Int) -> String {
        if row < attrNames.count {
            let attr = attrNames[row]
            if let val = gAttrMap[attr] {
                return val
            }
        }
        return "Unrecognized Attribute"
    }

    /// Return the attribute value for the indicated row.
    func subtitleForRow(row: Int) -> String? {
        if row < attrNames.count {
            let attr = attrNames[row]
            if let value = itemAttrs[attr] {
                return getAttrValueAsString(attribute: attr, value: value as CFTypeRef)
            }
        }
        return "Unrecognized Value"
    }
}
