//
//  FileProviderEnumerator.swift
//  KeySharingExtension
//

import FileProvider
import UniformTypeIdentifiers

/**
 The FileProviderEnumerator reports the full set of items that are accessible via the key sharing mechanism. All items are always reported
 to the system, which is different than the legacy key sharing implementation. A consuming application may only request to import certain
 uniform type identifiers (UTIs), in which case the operating system will disable options reported by this enumerator that are inconsistent
 with the requested UTIs.
 */
class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    private let enumeratedItemIdentifier: NSFileProviderItemIdentifier

    // MARK: NSFileProviderEnumerator methods

    init(enumeratedItemIdentifier: NSFileProviderItemIdentifier) {
        self.enumeratedItemIdentifier = enumeratedItemIdentifier
        super.init()
    }

    func invalidate() {}

    /// enumerateItems adds items to the presented observer for the following UTIs:
    ///
    /// - purebred2025.select.all-user
    /// - purebred2025.select.all
    /// - purebred2025.select.authentication
    /// - purebred2025.select.signature
    /// - purebred2025.select.encryption
    /// - purebred2025.zip.all-user
    /// - purebred2025.zip.all
    /// - purebred2025.zip.authentication
    /// - purebred2025.zip.signature
    /// - purebred2025.zip.encryption
    /// - purebred2025.select.no-filter
    /// - purebred2025.zip.no-filter
    ///
    /// For each key in the key chain, an item corresponding to a PKCS #12 file is added to the rootContainer. For each zip UTI, an item is
    /// added to the rootContainer. For each select UTI, a folder is added to the rootContainer. For each folder, an item corresponding to a
    /// PKCS #12 of the indicated type is added to the folder.
    ///
    /// At present, these UTIs are not supported via key sharing:
    ///
    /// - purebred2025.select.device
    /// - purebred2025.zip.device
    ///
    /// UTIs with underscores in place of '-' have been deprecated.
    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt _: NSFileProviderPage) {
        let keyChain = KeyChainDataSource()

        addPkcs12Files(observer: observer, keyChain: keyChain)

        addFolder(observer: observer, uti: "purebred2025.select.all-user", keyChain: keyChain, folder: "All User")
        addFolder(observer: observer, uti: "purebred2025.select.all", keyChain: keyChain, folder: "All")
        addFolder(observer: observer, uti: "purebred2025.select.authentication", keyChain: keyChain, folder: "PIV")
        addFolder(observer: observer, uti: "purebred2025.select.signature", keyChain: keyChain, folder: "Signature")
        addFolder(observer: observer, uti: "purebred2025.select.encryption", keyChain: keyChain, folder: "Encryption")
        addFolder(observer: observer, uti: "purebred2025.select.device", keyChain: keyChain, folder: "Device")
        addFolder(observer: observer, uti: "purebred2025.select.no-filter", keyChain: keyChain, folder: "Unfiltered")

        addZipFile(observer: observer, uti: "purebred2025.zip.all-user", keyChain: keyChain, folder: "All User")
        addZipFile(observer: observer, uti: "purebred2025.zip.all", keyChain: keyChain, folder: "All")
        addZipFile(observer: observer, uti: "purebred2025.zip.authentication", keyChain: keyChain, folder: "PIV")
        addZipFile(observer: observer, uti: "purebred2025.zip.signature", keyChain: keyChain, folder: "Signature")
        addZipFile(observer: observer, uti: "purebred2025.zip.encryption", keyChain: keyChain, folder: "Encryption")
        addZipFile(observer: observer, uti: "purebred2025.zip.device", keyChain: keyChain, folder: "Device")
        addZipFile(observer: observer, uti: "purebred2025.zip.no-filter", keyChain: keyChain, folder: "Unfiltered")

        observer.finishEnumerating(upTo: nil)
    }
}
