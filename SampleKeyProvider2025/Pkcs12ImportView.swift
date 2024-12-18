//
//  Pkcs12ImportView.swift
//  SampleKeyProvider2025
//

import Foundation
import SwiftUI

private class Pkcs12ImportModel: ObservableObject {
    @Published var filename: String?
    @Published var dirName = ""
    @Published var password = ""
    @Published var message = ""
    @Published var localFileManager = FileManager()
    @Published var dirEnum: FileManager.DirectoryEnumerator?
}

/**
 ``Pkcs12ImportView`` displays a view that enables a user to iterate over PKCS #12 files found in the documents directory (as shared
 via iTunes files sharing). The files may be importing, skipped over, or deleted.
 */
struct Pkcs12ImportView: View {
    @StateObject private var mod = Pkcs12ImportModel()
    var body: some View {
        NavigationStack {
            Form {
                Text(mod.message)

                TopLabeledTextField(text: $mod.password, placeholderText: "Enter password", labelText: "Password").lineLimit(1)
                // The "buttonStyle(BorderlessButtonStyle())" bit was poached from:
                // https://www.hackingwithswift.com/forums/swiftui/buttons-in-a-form-section/6175.
                // This trick avoids having both buttons in the HStack clicked when either is clicked.
                HStack {
                    Button("Import\nKey", action: importKey)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .buttonStyle(BorderlessButtonStyle()).padding()
                    Button("Skip\nKey", action: skipKey).frame(maxWidth: .infinity, alignment: .trailing).buttonStyle(BorderlessButtonStyle()).padding()
                    Button("Delete\nKey", action: deleteKey).frame(maxWidth: .infinity, alignment: .trailing).buttonStyle(BorderlessButtonStyle()).padding()
                }
            }
        }.scrollContentBackground(.hidden).onAppear(perform: {
            mod.dirName = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            mod.dirEnum = mod.localFileManager.enumerator(atPath: mod.dirName)
            getNext()
        })
    }

    private func getNext() {
        if let dirEnum = mod.dirEnum {
            if let filename = dirEnum.nextObject() as? String {
                mod.filename = filename
                mod.message = "A file that may contain cryptographic keys has been detected.  Enter your password below then click " +
                    "the Import button to import the keys.  Click the Cancel button to abort the import operation or the Delete button to " +
                    "delete the file.  The file is named: \(filename)"
            } else {
                mod.message = "No PKCS #12 files were found. Use iTunes file sharing to provide one or more PKCS #12 files for importing."
            }
        }
    }

    private func importKey() {
        if let filename = mod.filename {
            let docsUrl = URL(fileURLWithPath: mod.dirName)
            let p12Url = docsUrl.appendingPathComponent(filename)
            do {
                let data = try Data(contentsOf: p12Url)
                let status = importP12(pkcs12Data: data, password: mod.password)
                if errSecSuccess != status {
                    logger.error("Failed to import PKCS #12 file with \(status)")
                }
            } catch {
                logger.error("Failed to import PKCS #12 file with \(error)")
            }
        }
        mod.password = ""
        getNext()
    }

    private func skipKey() {
        getNext()
    }

    private func deleteKey() {
        if let filename = mod.filename {
            if mod.localFileManager.isDeletableFile(atPath: filename) {
                do {
                    try mod.localFileManager.removeItem(atPath: filename)
                } catch {
                    logger.error("Failed to delete \(filename) with \(error)")
                }
            }
        }
        getNext()
    }
}

#Preview {
    Pkcs12ImportView()
}
