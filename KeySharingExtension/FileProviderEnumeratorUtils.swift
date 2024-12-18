//
//  FileProviderEnumeratorUtils.swift
//  KeySharingExtension
//

import FileProvider
import UniformTypeIdentifiers

/// Takes a list of UTIs and returns true is a no-filter varient is in the list and false otherwise.
func isNoFilter(_ utis: [String]) -> Bool {
    if utis.contains("purebred2025.select.no-filter") || utis.contains("purebred2025.zip.no-filter") {
        true
    } else {
        false
    }
}

/// addFolder adds a FileProviderItem for a UTI that should conform to public.folder. The Info.plist for the
/// containing app lists the following UTIs that serve as folders:
///
///  - purebred2025.select.all
///  - purebred2025.select.all-user
///  - purebred2025.select.all.signature
///  - purebred2025.select.all.encryption
///  - purebred2025.select.all.authentication
///  - purebred2025.select.all.device
///
/// The key chain is then loaded for the given UTI and items are added for PKCS #12 objects consistent with the
/// UTI with the folder set as the item's parent.
func addFolder(observer: NSFileProviderEnumerationObserver, uti: String, keyChain: KeyChainDataSource, folder: String) {
    var validTypes = [uti]
    if isNoFilter(validTypes) {
        validTypes.append("purebred2025.rsa.pkcs-12")
    }
    keyChain.loadKeyChainContents(utisToLoad: validTypes)

    let utType = UTType(uti) ?? UTType.folder
    let utTypeP12 = UTType("\(uti)-p12") ?? UTType.pkcs12

    let fpi = FileProviderItem.initFolder(identifier: NSFileProviderItemIdentifier(folder), contentType: utType)
    observer.didEnumerate([fpi])

    let fpii = fpi.itemIdentifier

    let numItems = keyChain.count()
    var fileProviderItems: [FileProviderItem] = []
    for idx in 0 ... numItems {
        if let fpi = keyChain.getFileProviderItemAtIndex(index: idx, parent: fpii, contentType: utTypeP12) {
            fileProviderItems.append(fpi)
        }
    }
    observer.didEnumerate(fileProviderItems)
}

/// addZipFile adds a FileProviderItem for a UTI that should conform to public.zip-archive. The Info.plist for the
/// containing app lists the following UTIs that serve as folders:
///
///  - purebred2025.zip.all
///  - purebred2025.zip.all-user
///  - purebred2025.zip.all.signature
///  - purebred2025.zip.all.encryption
///  - purebred2025.zip.all.authentication
///  - purebred2025.zip.all.device
///
/// The key chain is then loaded for the given UTI and entries are added to a zip file for PKCS #12 objects consistent with the
/// UTI. The FileProviderItem is added with NSFileProviderItemIdentifier.rootContainer set as the item's parent.
func addZipFile(observer: NSFileProviderEnumerationObserver, uti: String, keyChain: KeyChainDataSource, folder: String) {
    var validTypes = [uti]
    if isNoFilter(validTypes) {
        validTypes.append("purebred2025.rsa.pkcs-12")
    }

    keyChain.loadKeyChainContents(utisToLoad: validTypes)
    let utZip = UTType(uti) ?? UTType.zip

    if let p12 = keyChain.getPKCS12Zip() {
        let itemIdentifier = NSFileProviderItemIdentifier(String(format: "\(folder).zip"))
        let item = FileProviderItem.initFile(identifier: itemIdentifier, docSize: p12.count as NSNumber,
                                             parent: NSFileProviderItemIdentifier.rootContainer, filename: itemIdentifier.rawValue, contentType: utZip, creationDate: nil)
        observer.didEnumerate([item])
    }
}

/// addPkcs12Files adds a FileProviderItem of type UTType.pkcs12 for each identity found in the key chain. The parent of each item
/// is set to NSFileProviderItemIdentifier.rootContainer set as the item's parent.
func addPkcs12Files(observer: NSFileProviderEnumerationObserver, keyChain: KeyChainDataSource) {
    keyChain.loadKeyChainContents(utisToLoad: ["purebred2025.rsa.pkcs-12"])

    let numItems = keyChain.count()
    let utTypeP12 = UTType("purebred2025.rsa.pkcs-12") ?? UTType.pkcs12

    let fpii = NSFileProviderItemIdentifier.rootContainer
    var fileProviderItems: [FileProviderItem] = []
    for idx in 0 ... numItems {
        if let fpi = keyChain.getFileProviderItemAtIndex(index: idx, parent: fpii, contentType: utTypeP12) {
            fileProviderItems.append(fpi)
        }
    }
    observer.didEnumerate(fileProviderItems)
}
