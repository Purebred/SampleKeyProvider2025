//
//  KeyZipFileDataSource.swift
//  KeyShareConsumer2025
//

import Foundation
import ZIPFoundation

/**
 ``KeyZipFileDataSource`` is used to map attributes associated with a key chain item to
 friendly names.
 */
class KeyZipFileDataSource: TableViewDataSource, ObservableObject {
    private var kcds = KeyChainDataSource()
    private var zipFile: String = ""
    private var fileNames: [String] = []

    func setZipFile(_ zipFile: String) {
        self.zipFile = zipFile

        let parts = zipFile.split(separator: ".")
        let kcds = KeyChainDataSource()
        if parts[0] == "All" {
            kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.all"])
        } else if parts[0] == "All User" {
            kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.all-user"])
        } else if parts[0] == "PIV" {
            kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.piv"])
        } else if parts[0] == "Signature" {
            kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.signature"])
        } else if parts[0] == "Encryption" {
            kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.encryption"])
        } else if parts[0] == "Unfiltered" {
            kcds.loadKeyChainContents(utisToLoad: ["purebred2025.zip.no-filter", "com.rsa.pkcs-12"])
        }
        if let data = kcds.getPKCS12Zip() {
            do {
                let archive = try Archive(data: data, accessMode: .read)
                for entry in archive {
                    fileNames.append(entry.path)
                }
            } catch {
                logger.error("Failed to process zip file for display with: \(error)")
            }
        } else {
            logger.error("Failed to read zip file data to prepare display")
        }
        self.objectWillChange.send()
    }

    // MARK: - TableViewDataSource Functions

    func count() -> Int {
        fileNames.count
    }

    func titleForRow(row: Int) -> String {
        if row < fileNames.count {
            fileNames[row]
        } else {
            "Unrecognized"
        }
    }

    func subtitleForRow(row _: Int) -> String? {
        ""
    }
}
