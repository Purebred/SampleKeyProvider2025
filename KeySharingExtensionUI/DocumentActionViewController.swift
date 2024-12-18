//
//  DocumentActionViewController.swift
//  KeySharingExtensionUI
//

import FileProviderUI
import os
import SwiftUI
import UIKit

let logger = Logger(subsystem: "purebred.samples", category: "KeySharingExtensionUI")

/**
 The KeySharingExtensionUI displays attributes read from the key chain for a presented item.

 The extension is only invoked for PKCS #12 files due to the ``NSExtensionFileProviderActionActivationRule`` in the Info.plist.
 The KeySharingExtension assigns identifiers to PKCS #12 files based on whether the file is stored relatative to ``NSFileProviderItemIdentifier.rootContainer ``
 or a folder associated with a ``purebred2025.select.*`` uniform type identifier (UTI).
 */
class DocumentActionViewController: FPUIActionExtensionViewController {
    var contentView = ContentView()
    let kcds = KeyChainDataSource()

    override func prepare(forAction _: String, itemIdentifiers: [NSFileProviderItemIdentifier]) {
        if itemIdentifiers.isEmpty {
            logger.error("The DocumentActionViewController was invoked with no itemIdentifiers")
            return
        }
        if itemIdentifiers[0].rawValue.hasSuffix(".zip") {
            contentView.zfds.setZipFile(itemIdentifiers[0].rawValue)
            self.contentView.mod.zipViewer = true
        } else {
            contentView.mod.zipViewer = false
            let parts = itemIdentifiers[0].rawValue.components(separatedBy: ".")
            kcds.loadKeyChainContents(utisToLoad: [])
            let attrs = if parts.count == 2 {
                kcds.getAttributesForIdentifier(identifier: parts[1])
            } else {
                kcds.getAttributesForIdentifier(identifier: parts[0])
            }
            contentView.kads.setItemAttrs(itemAttrs: attrs.getItemAttrs(), mode: .ksmIdentities)
        }
    }

    @IBAction func cancelButtonTapped(_: Any) {
        extensionContext.completeRequest()
    }

    @IBSegueAction func embedSwiftUi(_ coder: NSCoder) -> UIViewController? {
        UIHostingController(coder: coder, rootView: contentView)
    }
}
