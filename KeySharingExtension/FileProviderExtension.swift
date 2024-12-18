//
//  FileProviderExtension.swift
//  KeySharingExtension
//

import FileProvider
import os
import UIKit
import UniformTypeIdentifiers

let logger = Logger(subsystem: "purebred.samples", category: "KeySharingExtension")

/// Enable Strings to be thrown as Errors (poached from https://www.hackingwithswift.com/example-code/language/how-to-throw-errors-using-strings)
extension String: @retroactive Error {}
extension String: @retroactive LocalizedError {
    public var errorDescription: String? { self }
}

/**
 The KeySharing extension presents key chain information in several different ways to retain as much compatibility with
 legacy key sharing uniform type identifiers (UTIs) as possible.

 The KeySharingExtension presents three different types of items:
 - PKCS #12 files,
 - zip files
 - folders.
 Zip files and folders only exist with ``NSFileProviderItemIdentifier.rootContainer`` as parent. PKCS #12
 files may exist with ``NSFileProviderItemIdentifier.rootContainer`` as parent or a folder as parent.

 The following custom uniform type identifiers (UTIs) are supported:

 - purebred2025.select.all-user
 - purebred2025.select.all
 - purebred2025.select.authentication
 - purebred2025.select.signature
 - purebred2025.select.encryption
 - purebred2025.zip.all-user
 - purebred2025.zip.all
 - purebred2025.zip.authentication
 - purebred2025.zip.signature
 - purebred2025.zip.encryption
 - purebred2025.select.no-filter
 - purebred2025.zip.no-filter

 The purebred2025.select.* UTIs conform to the ``public.folder`` type, which is representated by the ``UTType.folder`` value.
 The purebred2025.zip.* UTIs conform to ``public.zip-archive``, which is represented by the ``UTType.zip`` value.
 Each purebred2025.select.* type from the legacy key sharing extension, i.e., those listed above, has a new UTI type
 that is named by appending "-p12" as a suffix.

 - purebred2025.select.all-user-p12
 - purebred2025.select.all-p12
 - purebred2025.select.authentication-p12
 - purebred2025.select.signature-p12
 - purebred2025.select.encryption-p12

 These UTIs confirm to the ``public.data``, as represented by ``UTType.pkcs12``.

 Identifiers manifest themselves in four ways.

 - PKCS #12 files with ``NSFileProviderItemIdentifier.rootContainer`` as parent are named with the kSecAttrLabel value from a given SecIdentity
 - PKCS #12 files with a folder as parent are named with the kSecAttrLabel value from a given SecIdentity prepended with the folder name
 - Folders are named with the folder name
 - Zip files are named with the folder name with ".zip" suffix
 */
class FileProviderExtension: NSFileProviderExtension, NSFileProviderThumbnailing {
    /**
     Create an enumerator for an item.

     When the user opens the browse tab of the UIDocumentsBrowserViewController and
     selects a file provider, this is called with
     NSFileProviderRootContainerItemIdentifier, and -[NSFileProviderEnumerator
     enumerateItemsForObserver:startingAtPage:] is immediately called to list the
     first items available under at the root level of the file provider.

     As the user navigates down into directories, new enumerators are created with
     this method, passing in the itemIdentifier of those directories.  Past
     enumerators are then invalidated.

     This method is also called with
     NSFileProviderWorkingSetContainerItemIdentifier, which is enumerated with
     -[NSFileProviderEnumerator enumerateChangesForObserver:fromSyncAnchor:].  That
     enumeration is special in that it isn't driven by the
     UIDocumentsBrowserViewController.  It happens in the background to sync the
     working set down to the device.

     This is also used to subscribe to live updates for a single document.  In that
     case, -[NSFileProviderEnumerator enumerateChangesToObserver:fromSyncAnchor:]
     will be called and the enumeration results shouldn't include items other than
     the very item that the enumeration was started on.

     If returning nil, you must set the error out parameter.
     */
    override func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier) throws -> any NSFileProviderEnumerator {
        FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
    }

    // swiftlint:disable cyclomatic_complexity
    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        let parts = identifier.rawValue.components(separatedBy: ".")
        let count = parts.count
        if count == 1 {
            return FileProviderItem(identifier: identifier)
        } else if parts[1] == "Signature" {
            if count == 4 {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.signature-p12"))
            } else {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.signature"))
            }
        } else if parts[1] == "PIV" {
            if count == 4 {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.authentication-p12"))
            } else {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.authentication"))
            }
        } else if parts[1] == "Encryption" {
            if count == 4 {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.encryption-p12"))
            } else {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.encryption"))
            }
        } else if parts[1] == "All" {
            if count == 4 {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.all-p12"))
            } else {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.all"))
            }
        } else if parts[1] == "All User" {
            if count == 4 {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.all-user-p12"))
            } else {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.all-user"))
            }
        } else if parts[1] == "Device" {
            if count == 4 {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.device-p12"))
            } else {
                return FileProviderItem.initFolder(identifier: identifier, contentType: UTType("purebred2025.select.device"))
            }
        }
        return FileProviderItem(identifier: identifier)
    }

    // swiftlint:enable cyclomatic_complexity
    /**
     Should return the URL corresponding to a specific identifier. Fail if it's not
     a subpath of documentStorageURL.

     This is a static mapping; each identifier must always return a path
     corresponding to the same file. By default, this returns the path relative to
     the path returned by documentStorageURL.
     */
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        let fpm = NSFileProviderManager.default
        let placeholder = fpm.documentStorageURL.appendingPathComponent(identifier.rawValue)
        return placeholder
    }

    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        let fpii = NSFileProviderItemIdentifier(url.lastPathComponent)
        return fpii
    }

    /**
     This method is called when a placeholder URL should be provided for the item at
     the given URL.

     The implementation of this method should call +[NSFileProviderManager
     writePlaceholderAtURL:withMetadata:error:] with the URL returned by
     +[NSFileProviderManager placeholderURLForURL:], then call the completion
     handler.
     */

    override func providePlaceholder(at url: URL) async throws {
        do {
            let fpmUrl = NSFileProviderManager.placeholderURL(for: url)
            let identifier = fpmUrl.lastPathComponent
            try NSFileProviderManager.writePlaceholder(at: fpmUrl, withMetadata: item(for: NSFileProviderItemIdentifier(identifier)))
        } catch {
            logger.error("providePlaceholder failed with \(error)")
        }
    }

    // swiftlint:disable cyclomatic_complexity
    /**
     Should ensure that the actual file is in the position returned by
     URLForItemWithPersistentIdentifier:, then call the completion handler.
     */
    override func startProvidingItem(at url: URL) async throws {
        var dataToReturn: Data?
        if url.absoluteString.hasSuffix(".zip") {
            let filename = url.lastPathComponent
            var uti = ""
            if filename == "All.zip" {
                uti = "purebred2025.zip.all"
            } else if filename == "All User.zip" {
                uti = "purebred2025.zip.all-user"
            } else if filename == "Signature.zip" {
                uti = "purebred2025.zip.signature"
            } else if filename == "Encryption.zip" {
                uti = "purebred2025.zip.encryption"
            } else if filename == "PIV.zip" {
                uti = "purebred2025.zip.authentication"
            } else if filename == "Unfiltered.zip" {
                uti = "purebred2025.zip.no-filter"
            } else if filename == "Device.zip" {
                uti = "purebred2025.zip.device"
            }
            var validTypes = [uti]
            if isNoFilter(validTypes) {
                validTypes.append("purebred2025.rsa.pkcs-12")
            }

            let kcds = KeyChainDataSource()
            kcds.loadKeyChainContents(utisToLoad: validTypes)
            dataToReturn = kcds.getPKCS12Zip()
        } else {
            let validTypes = ["purebred2025.rsa.pkcs-12"]
            let kcds = KeyChainDataSource()
            kcds.loadKeyChainContents(utisToLoad: validTypes)
            let parts = url.lastPathComponent.components(separatedBy: ".")
            if parts.count > 1 {
                let identifier = parts[parts.count - 1]
                dataToReturn = kcds.getPkcs12ForIdentifier(identifier: identifier)
            } else {
                dataToReturn = kcds.getPkcs12ForIdentifier(identifier: parts[0])
            }
        }

        if let dataToReturn {
            do {
                try dataToReturn.write(to: url)
            } catch {
                logger.error("Failed to write file to \(url) with: \(error)")
            }
        } else {
            logger.error("Failed to read data to return for \(url)")
        }
    }

    // swiftlint:enable cyclomatic_complexity

    // swiftlint:disable:next line_length
    override func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier], requestedSize _: CGSize, perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, (any Error)?) -> Void, completionHandler: @escaping ((any Error)?) -> Void) -> Progress {
        let progress = Progress(totalUnitCount: Int64(itemIdentifiers.count))
        var progressCounter: Int64 = 0

        func finishCurrent() {
            progressCounter += 1

            if progressCounter == progress.totalUnitCount {
                completionHandler(nil)
            }
        }

        if let url = Bundle.main.url(forResource: "0155-keys", withExtension: "png") {
            if let image = UIImage(contentsOfFile: url.path()) {
                for itemIdentifier in itemIdentifiers {
                    if !itemIdentifier.rawValue.hasSuffix(".zip") {
                        perThumbnailCompletionHandler(itemIdentifier, image.pngData(), nil)
                    }
                    finishCurrent()
                }
            } else {
                completionHandler(nil)
            }
        } else {
            completionHandler(nil)
        }

        return progress
    }

    // removed startProvidingItem that does not take a completionHandler

    /**
     Called after the last claim to the file has been released. At this point, it is
     safe for the file provider to remove the content file.

     Care should be taken that the corresponding placeholder file stays behind after
     the content file has been deleted.
     */
    override func stopProvidingItem(at _: URL) {}

    /**
     Called at some point after the file has changed; the provider may then trigger
     an upload.
     */
    override func itemChanged(at _: URL) {}
}

extension FileProviderExtension {
    override func supportedServiceSources(for _: NSFileProviderItemIdentifier) throws -> [any NSFileProviderServiceSource] {
        let fpuiExtService = KeySharingPasswordService(fpExtension: self)
        let services: [NSFileProviderServiceSource] = [fpuiExtService]
        return services
    }
}

class KeySharingPasswordService: NSObject, NSFileProviderServiceSource, NSXPCListenerDelegate, KeySharingPassword {
    func fetchPassword(_ completionHandler: PasswordHandler?) {
        if let completionHandler {
            let password = getOrSetPassword()
            completionHandler(password, nil)
        }
    }

    let listener = NSXPCListener.anonymous()
    let serviceName = keySharingPasswordv1
    let fpExtension: FileProviderExtension

    init(fpExtension: FileProviderExtension) {
        self.fpExtension = fpExtension
        super.init()
    }

    func makeListenerEndpoint() throws -> NSXPCListenerEndpoint {
        listener.delegate = self
        listener.resume()
        return listener.endpoint
    }

    func listener(
        _: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: KeySharingPassword.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
}
