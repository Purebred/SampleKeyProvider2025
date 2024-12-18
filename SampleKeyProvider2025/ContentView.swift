//
//  ContentView.swift
//  SampleKeyProvider2025
//

import SwiftUI

/// Displays the UI, which consists of three buttons that allow importing PKCS #12 files from iTunes file sharing, importing PKCS #12 files that
/// are hardcoded in the app, and clearing the app's key chain.
struct ContentView: View {
    @State private var isShowingImport = false
    @State private var isShowingAlert = false
    @State private var message = ""
    var body: some View {
        NavigationStack {
            VStack {
                Button("Import PKCS #12 files from File Sharing", action: importFromFileSharing).frame(maxWidth: .infinity, alignment: .center).listRowSeparator(.hidden).padding()
                Button("Import sample PKCS #12 files", action: importSample).frame(maxWidth: .infinity, alignment: .center).listRowSeparator(.hidden).padding()
                Button("Clear Key Chain", action: clearKeyChain).frame(maxWidth: .infinity, alignment: .center).listRowSeparator(.hidden).padding()
            }.navigationBarTitle("Sample Key Provider Utility v2", displayMode: .inline).frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }.scrollContentBackground(.hidden).sheet(isPresented: $isShowingImport) {
            Pkcs12ImportView()
        }.alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Status"), message: Text(
                message), dismissButton: .default(Text("OK")))
        }
    }

    private func importFromFileSharing() {
        isShowingImport = true
    }

    private func importSample() {
        let fileNames = ["TESTRECOVERY.5557779001871871_caEmailEncrPlusCitizenUserCert2048_20181103000000Z",
                         "TESTRECOVERY.5557779001871871_caEmailEncrPlusCitizenUserCert2048_20211103000000Z",
                         "TESTRECOVERY.5557779001871871_caEmailEncrPlusCitizenUserCert2048_20241203000000Z",
                         "TESTRECOVERY.5557779001871871_caEmailEncrPlusCitizenUserCert2048_20271203000000Z",
                         "TESTRECOVERY.5557779001871871_caEmailSignPlusCitizenUserCert2048_20181103000000Z",
                         "TESTRECOVERY.5557779001871871_caEmailSignPlusCitizenUserCert2048_20211103000000Z",
                         "TESTRECOVERY.5557779001871871_caEmailSignPlusCitizenUserCert2048_20241203000000Z",
                         "TESTRECOVERY.5557779001871871_caEmailSignPlusCitizenUserCert2048_20271203000000Z",
                         "TESTRECOVERY.5557779001871871_caPIVAuthPlusSCLUserCert2048_20181103000000Z",
                         "TESTRECOVERY.5557779001871871_caPIVAuthPlusSCLUserCert2048_20211103000000Z",
                         "TESTRECOVERY.5557779001871871_caPIVAuthPlusSCLUserCert2048_20241203000000Z",
                         "TESTRECOVERY.5557779001871871_caPIVAuthPlusSCLUserCert2048_20271203000000Z"]

        var successCount = 0
        var errorCount = 0
        for fileName in fileNames {
            if let url = Bundle.main.url(forResource: fileName, withExtension: "p12") {
                do {
                    let pkcs12Data = try Data(contentsOf: url)
                    if errSecSuccess != importP12(pkcs12Data: pkcs12Data, password: "password") {
                        logger.error("Failed to import PKCS #12 object from \(fileName)")
                        errorCount += 1
                    } else {
                        logger.info("Successfully imported PKCS #12 object from \(fileName)")
                        successCount += 1
                    }
                } catch {
                    logger.error("Failed to process \(fileName): \(String(describing: error))")
                    errorCount += 1
                }
            } else {
                logger.error("Failed to find \(fileName) in main bundle")
                errorCount += 1
            }
        }
        var tmpMessage = "Successfully imported \(successCount) PKCS #12 files."
        if errorCount > 0 {
            tmpMessage.append(" Failed to import \(errorCount) PKCS #12 files")
        }
        self.message = tmpMessage
        self.isShowingAlert = true
    }

    private func clearKeyChain() {
        deleteAllItemsForSecClass(kSecClassGenericPassword)
        deleteAllItemsForSecClass(kSecClassInternetPassword)
        deleteAllItemsForSecClass(kSecClassCertificate)
        deleteAllItemsForSecClass(kSecClassKey)
        deleteAllItemsForSecClass(kSecClassIdentity)
    }
}

#Preview {
    ContentView()
}
