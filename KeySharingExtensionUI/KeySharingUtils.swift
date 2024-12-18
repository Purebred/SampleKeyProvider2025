//
//  KeySharingUtils.swift
//  Key Sharing Common Code
//

import UniformTypeIdentifiers

// MARK: Extensions

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

// MARK: Public methods

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
/// Takes a ``String`` that indicates an attribute type and a ``CFTypeRef`` containing an attribute value and returns a String
/// representation of that value.
public func getAttrValueAsString(attribute: String, value: CFTypeRef) -> String {
    if kSecAttrAccessible as String == attribute {
        getAttrAccessibleAsString(value: value)
    } else if kSecAttrAccessGroup as String == attribute {
        // swiftlint:disable:next force_cast
        value as! CFString as String
    } else if kSecAttrCertificateType as String == attribute {
        getCertificateTypeAsString(value: value)
    } else if kSecAttrCertificateEncoding as String == attribute {
        getCertificateEncodingAsString(value: value)
    } else if kSecAttrLabel as String == attribute {
        // swiftlint:disable:next force_cast
        value as! CFString as String
    } else if kSecAttrSubject as String == attribute {
        getDataAsAsciiHexString(value: value)
    } else if kSecAttrIssuer as String == attribute {
        getDataAsAsciiHexString(value: value)
    } else if kSecAttrSerialNumber as String == attribute {
        getDataAsAsciiHexString(value: value)
    } else if kSecAttrSubjectKeyID as String == attribute {
        getDataAsAsciiHexString(value: value)
    } else if kSecAttrPublicKeyHash as String == attribute {
        getDataAsAsciiHexString(value: value)
    } else if kSecAttrKeyClass as String == attribute {
        getKeyClassAsString(value: value)
    } else if kSecAttrApplicationLabel as String == attribute {
        getDataAsAsciiHexString(value: value)
    } else if kSecAttrIsPermanent as String == attribute {
        getCFBooleanAsString(value: value)
    } else if kSecAttrApplicationTag as String == attribute {
        // swiftlint:disable:next force_cast
        String(decoding: value as! CFData as Data, as: UTF8.self)
    } else if kSecAttrKeyType as String == attribute {
        getKeyTypeAsString(value: value)
    } else if kSecAttrKeySizeInBits as String == attribute {
        getCFNumberAsString(value: value)
    } else if kSecAttrEffectiveKeySize as String == attribute {
        getCFNumberAsString(value: value)
    } else if kSecAttrCanEncrypt as String == attribute {
        getCFBooleanAsString(value: value)
    } else if kSecAttrCanDecrypt as String == attribute {
        getCFBooleanAsString(value: value)
    } else if kSecAttrCanDerive as String == attribute {
        getCFBooleanAsString(value: value)
    } else if kSecAttrCanSign as String == attribute {
        getCFBooleanAsString(value: value)
    } else if kSecAttrCanVerify as String == attribute {
        getCFBooleanAsString(value: value)
    } else if kSecAttrCanWrap as String == attribute {
        getCFBooleanAsString(value: value)
    } else if kSecAttrCanUnwrap as String == attribute {
        getCFBooleanAsString(value: value)
    } else {
        "Unknown value"
    }
}

// swiftlint:enable function_body_length
// swiftlint:enable cyclomatic_complexity

/// Read the uniform type identifiers configured in the Settings app and return them as an array.
public func readSettingsAsUTType() -> [UTType] {
    let utis = readSettingsAsString()
    var retval: [UTType] = []
    for uti in utis {
        if let utType = UTType(uti) {
            retval.append(utType)
        } else {
            logger.error("Did not find uniform type identifier definition for \(uti). Ignoring and continuing...")
        }
    }

    return retval
}

// MARK: Private methods

private func getCFNumberAsString(value: CFTypeRef) -> String {
    if CFNumberGetTypeID() == CFGetTypeID(value) {
        // swiftlint:disable:next force_cast
        let number = value as! CFNumber as NSNumber
        return number.stringValue
    }
    return "Unrecognized"
}

private func getCFBooleanAsString(value: CFTypeRef) -> String {
    if CFBooleanGetTypeID() == CFGetTypeID(value) {
        // swiftlint:disable:next force_cast
        let cfBoolean = value as! CFBoolean
        if CFBooleanGetValue(cfBoolean) {
            return "Yes"
        } else {
            return "No"
        }
    } else if CFNumberGetTypeID() == CFGetTypeID(value) {
        // some attributes that are documented as being CFBoolean are actually CFNumber
        // swiftlint:disable:next force_cast
        let number = value as! CFNumber as NSNumber
        if number == 0 {
            return "No"
        } else {
            return "Yes"
        }
    }
    return "Unrecognized"
}

private func getCertificateTypeAsString(value: CFTypeRef) -> String {
    if CFNumberGetTypeID() == CFGetTypeID(value) {
        // swiftlint:disable:next force_cast
        let number = value as! CFNumber as NSNumber
        switch number {
        case 1:
            return "X509v1"
        case 2:
            return "X509v2"
        case 3:
            return "X509v3"
        default:
            return "Unrecognized certificate type"
        }
    }
    return "Unrecognized"
}

private func getKeyClassAsString(value: CFTypeRef) -> String {
    if CFNumberGetTypeID() == CFGetTypeID(value) {
        // swiftlint:disable:next force_cast
        let number = value as! CFNumber as NSNumber
        let nStr = number.stringValue
        if kSecAttrKeyClassPublic as String == nStr {
            return "Public key"
        } else if kSecAttrKeyClassPrivate as String == nStr {
            return "Private key"
        } else if kSecAttrKeyClassSymmetric as String == nStr {
            return "Symmetric key"
        } else {
            return "Unrecognized key class"
        }
    }
    return "Unrecognized"
}

private func getKeyTypeAsString(value: CFTypeRef) -> String {
    if CFNumberGetTypeID() == CFGetTypeID(value) {
        // swiftlint:disable:next force_cast
        let number = value as! CFNumber as NSNumber
        let nStr = number.stringValue
        if kSecAttrKeyTypeRSA as String == nStr {
            return "RSA"
        } else if kSecAttrKeyTypeEC as String == nStr {
            return "Elliptic curve"
        } else if kSecAttrKeyTypeECSECPrimeRandom as String == nStr {
            return "Elliptic curve SEC prime random"
        } else {
            return "Unrecognized key type"
        }
    }
    return "Unrecognized"
}

private func getAttrAccessibleAsString(value: CFTypeRef) -> String {
    if CFStringGetTypeID() == CFGetTypeID(value) {
        // swiftlint:disable:next force_cast
        let str = value as! CFString as String
        return str
    }
    return "Unrecognized"
}

private func getCertificateEncodingAsString(value: CFTypeRef) -> String {
    if CFNumberGetTypeID() == CFGetTypeID(value) {
        // swiftlint:disable:next force_cast
        let number = value as! CFNumber as NSNumber
        if number == 3 {
            return "DER"
        } else {
            return "Unrecognized certificate encoding   "
        }
    }
    return "Unrecognized"
}

private func getDataAsAsciiHexString(value: CFTypeRef) -> String {
    if CFDataGetTypeID() == CFGetTypeID(value) {
        // swiftlint:disable:next force_cast
        let data = value as! CFData as Data
        return data.hexadecimal
    }
    return "Unrecognized"
}

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
private func readSettingsAsString() -> [String] {
    var utis: [String] = []
    let defaults = UserDefaults.standard
    if defaults.bool(forKey: "toggle_com_rsa_pkcs12") {
        utis.append("com.rsa.pkcs-12")
    }
    if defaults.bool(forKey: "toggle_purebred_select_all") {
        utis.append("purebred2025.select.all")
        utis.append("purebred2025.select.all-p12")
    }
    if defaults.bool(forKey: "toggle_purebred_select_all-user") {
        utis.append("purebred2025.select.all-user")
        utis.append("purebred2025.select.all-user-p12")
    }
    if defaults.bool(forKey: "toggle_purebred_select_signature") {
        utis.append("purebred2025.select.signature")
        utis.append("purebred2025.select.signature-p12")
    }
    if defaults.bool(forKey: "toggle_purebred_select_encryption") {
        utis.append("purebred2025.select.encryption")
        utis.append("purebred2025.select.encryption-p12")
    }
    if defaults.bool(forKey: "toggle_purebred_select_authentication") {
        utis.append("purebred2025.select.authentication")
        utis.append("purebred2025.select.authentication-p12")
    }
    if defaults.bool(forKey: "toggle_purebred_select_device") {
        utis.append("purebred2025.select.device")
    }
    if defaults.bool(forKey: "toggle_purebred_select_no_filter") {
        utis.append("purebred2025.select.no_filter")
    }
    if defaults.bool(forKey: "toggle_purebred_select_no-filter") {
        utis.append("purebred2025.select.no-filter")
    }
    if defaults.bool(forKey: "toggle_purebred_zip_all") {
        utis.append("purebred2025.zip.all")
    }
    if defaults.bool(forKey: "toggle_purebred_zip_all-user") {
        utis.append("purebred2025.zip.all-user")
    }
    if defaults.bool(forKey: "toggle_purebred_zip_signature") {
        utis.append("purebred2025.zip.signature")
    }
    if defaults.bool(forKey: "toggle_purebred_zip_encryption") {
        utis.append("purebred2025.zip.encryption")
    }
    if defaults.bool(forKey: "toggle_purebred_zip_authentication") {
        utis.append("purebred2025.zip.authentication")
    }
    if defaults.bool(forKey: "toggle_purebred_zip_device") {
        utis.append("purebred2025.zip.device")
    }
    if defaults.bool(forKey: "toggle_purebred_zip_no_filter") {
        utis.append("purebred2025.zip.no_filter")
    }
    if defaults.bool(forKey: "toggle_purebred_zip_no-filter") {
        utis.append("purebred2025.zip.no-filter")
    }

    if utis.isEmpty {
        utis.append("com.rsa.pkcs-12")
    }

    return utis
}

// swiftlint:enable function_body_length
// swiftlint:enable cyclomatic_complexity
