//
//  FileProviderItem.swift
//  KeySharingExtension
//

import FileProvider
import UniformTypeIdentifiers

/**
 Identifiers manifest themselves in four ways.

 - PKCS #12 files with ``NSFileProviderItemIdentifier.rootContainer`` as parent are named with the kSecAttrLabel value from a given SecIdentity
 - PKCS #12 files with a folder as parent are named with the kSecAttrLabel value from a given SecIdentity prepended with the folder name
 - Folders are named with the folder name
 - Zip files are named with the folder name with ".zip" suffix
 */
class FileProviderItem: NSObject, NSFileProviderItem {
    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    init(identifier: NSFileProviderItemIdentifier, loadParts: Bool = true) {
        logger.debug("init for \(identifier.rawValue)")

        _itemIdentifier = identifier
        _parentItemIdentifier = .rootContainer
        _capabilities = .allowsReading
        let version = Data("1.1".utf8)
        _itemVersion = NSFileProviderItemVersion(contentVersion: version, metadataVersion: version)
        if _itemIdentifier == NSFileProviderItemIdentifier.rootContainer {
            _contentType = UTType.folder
        } else {
            _contentType = UTType("purebred2025.rsa.pkcs-12") ?? UTType.pkcs12
        }
        _filename = identifier.rawValue
        _documentSize = nil

        if loadParts, identifier != NSFileProviderItemIdentifier.rootContainer {
            if !identifier.rawValue.hasSuffix(".zip") {
                let parts = identifier.rawValue.components(separatedBy: ".")
                let tmpId = if parts.count > 1 {
                    parts[parts.count - 1]
                } else {
                    parts[0]
                }

                if let fpi = getFileProviderPartsForIdentifier(identifier: tmpId) {
                    _filename = fpi.filename
                    _creationDate = fpi.creationDate
                    _documentSize = fpi.documentSize

                    if parts.count > 1 {
                        _parentItemIdentifier = NSFileProviderItemIdentifier(rawValue: parts[0])
                    }
                }
            } else {
                let parts = identifier.rawValue.split(separator: ".")
                let kcds = KeyChainDataSource()
                var contentType = UTType.zip
                if parts[0] == "All" {
                    kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.all"])
                    contentType = UTType("purebred2025.zip.all") ?? UTType.zip
                } else if parts[0] == "All User" {
                    kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.all-user"])
                    contentType = UTType("purebred2025.zip.all-user") ?? UTType.zip
                } else if parts[0] == "PIV" {
                    kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.piv"])
                    contentType = UTType("purebred2025.zip.piv") ?? UTType.zip
                } else if parts[0] == "Signature" {
                    kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.signature"])
                    contentType = UTType("purebred2025.zip.signature") ?? UTType.zip
                } else if parts[0] == "Encryption" {
                    kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.encryption"])
                    contentType = UTType("purebred2025.zip.encryption") ?? UTType.zip
                } else if parts[0] == "Unfiltered" {
                    kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.no-filter", "purebred2025.rsa.pkcs-12"])
                    contentType = UTType("purebred2025.zip.no-filter") ?? UTType.zip
                }
                if let data = kcds.getPKCS12Zip() {
                    _filename = identifier.rawValue
                    _creationDate = Date()
                    _documentSize = data.count as NSNumber
                    _contentType = contentType
                }
            }
        }
    }

    // swiftlint:enable function_body_length
    // swiftlint:enable cyclomatic_complexity

    static func initFolder(identifier: NSFileProviderItemIdentifier, contentType: UTType?) -> FileProviderItem {
        // logger.debug("initFolder for \(identifier.rawValue) and type \(contentType ?? UTType.folder)")

        let fpi = if identifier == NSFileProviderItemIdentifier.rootContainer {
            FileProviderItem(identifier: identifier, loadParts: false)
        } else {
            FileProviderItem(identifier: identifier, loadParts: false)
        }
        if let contentType {
            fpi.contentType = contentType
        } else {
            fpi.contentType = UTType.folder
        }
        return fpi
    }

    // swiftformat moves the opening brace to a new line when the line length lint is addressed (but no when line it too long)
    // swiftlint:disable opening_brace
    // swiftlint:disable function_parameter_count
    static func initFile(identifier: NSFileProviderItemIdentifier, docSize: NSNumber,
                         parent: NSFileProviderItemIdentifier, filename: String, contentType: UTType, creationDate: Date?) -> FileProviderItem
    {
        // logger.debug("initWithItemIdentifier for identifier: \(identifier.rawValue), docSize: \(docSize), fileName: \(filename) and etc")

        let fpi = FileProviderItem(identifier: identifier, loadParts: false)
        fpi.contentType = contentType
        fpi.documentSize = docSize
        fpi.parentItemIdentifier = parent
        fpi.filename = filename
        fpi.creationDate = creationDate
        return fpi
    }

    // swiftlint:enable function_parameter_count
    // swiftlint:enable opening_brace

    private var _filename: String
    var filename: String {
        get {
            _filename
        }
        set {
            _filename = newValue
        }
    }

    private var _itemIdentifier: NSFileProviderItemIdentifier
    var itemIdentifier: NSFileProviderItemIdentifier {
        get {
            _itemIdentifier
        }
        set {
            _itemIdentifier = newValue
        }
    }

    private var _parentItemIdentifier: NSFileProviderItemIdentifier
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        get {
            _parentItemIdentifier
        }
        set {
            _parentItemIdentifier = newValue
        }
    }

    private var _capabilities: NSFileProviderItemCapabilities
    var capabilities: NSFileProviderItemCapabilities {
        get {
            _capabilities
        }
        set {
            _capabilities = newValue
        }
    }

    private var _itemVersion: NSFileProviderItemVersion
    var itemVersion: NSFileProviderItemVersion {
        get {
            _itemVersion
        }
        set {
            _itemVersion = newValue
        }
    }

    private var _contentType: UTType
    var contentType: UTType {
        get {
            _contentType
        }
        set {
            _contentType = newValue
        }
    }

    private var _documentSize: NSNumber?
    var documentSize: NSNumber? {
        get {
            _documentSize
        }
        set {
            _documentSize = newValue
        }
    }

    private var _creationDate: Date?
    var creationDate: Date? {
        get {
            _creationDate
        }
        set {
            _creationDate = newValue
        }
    }

    // This is the value that governs ordering by date in the UI (just reusing
    // creationDate since the contents are never modified anyway)
    var contentModificationDate: Date? {
        get {
            _creationDate
        }
        set {
            _creationDate = newValue
        }
    }
}
