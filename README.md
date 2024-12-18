# SampleKeyProvider2025

[Purebred](https://public.cyber.mil/pki-pke/purebred-2/) is the derived credential issuing system for the United States (U.S.) Department of Defense (DoD). Since 2016, the Purebred app for iOS has featured a custom "key sharing" interface that allows PKCS #12 objects and the corresponding passwords to be shared from the Purebred app to unrelated apps via the iOS file provider extension APIs and the system pasteboard. Two sample apps were prepared as a demonstration and to enable application developers to test integration with the key sharing interface and to demonstrate usage: [SampleKeyProvider](https://github.com/Purebred/SampleKeyProvider) and [KeyShareConsumer](https://github.com/Purebred/KeyShareConsumer). 

Since 2020, the Purebred app for iOS has featured a [persistent token](https://developer.apple.com/documentation/cryptotokenkit) extension that enables unrelated apps to use keys provisioned via Purebred without exporting and sharing the private keys. The persistent token interface is the preferred way to exercise Purebred-provisioned keys on iOS devices. As with key sharing, two sample apps were prepared to enable application developers to test integration with the persistent token interface and to demonstrate usage: [CtkProvider](https://github.com/Purebred/CtkProvider) and [CtkConsumer](https://github.com/Purebred/CtkConsumer).

In the years since 2016, several APIs that underpin the key sharing mechanism have been deprecated. To avoid use of deprecated APIs, the key sharing mechanism has been updated. Unfortunately, these changes are not cross-compatible and result in changes to the user experience. Two new sample apps, SampleKeyProvider2025 and KeyShareConsumer2025, are now available to facilitate testing and usage of the updated key sharing interface.

## Primary differences between legacy key sharing and key sharing 2025

From a consuming app point of view, the changes are relatively small. The app must launch the extension using an instance of [UIDocumentPickerViewController](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller?language=objc) that was initialized using a different method before and the must read the required password from a service provided by the file provider extension instead of the system pasteboard. For the providing application, i.e., Sample Key Provider or Purebred, the changes are more significant.

In legacy key sharing, the bulk of the work was performed by the file provider user interface extension. In key sharing 2025, the bulk of the work is done by the file provider extension in concert with the operating system. The file provider provides a list of items that are available, i.e., ultimately PKCS #12 files and zip files. The operating system provides a Files app-like display of those items. Passwords are now shared via an instance of [NSFileProviderServiceSource](https://developer.apple.com/documentation/fileprovider/nsfileproviderservicesource?language=objc) that implements the custom ``KeySharingPassword`` protocol, which is defined as shown below.

```swift
typealias PasswordHandler = (_ password: String?, _ error: NSError?) -> Void

let keySharingPasswordv1 = NSFileProviderServiceName("red.hound.KeySharingPassword-v1.0.0")

@objc protocol KeySharingPassword {
    func fetchPassword(_ completionHandler: PasswordHandler?)
}
```

The file provider generates a random password on first use and stores the value in the key chain to facilitate access by the key sharing password service, which returns the password to the consuming application.

### Documentation

Documentation can be generated using XCode via the `Product->Build Documentation` menu item. Alternatively, the following steps can be performed to build documentation from source.

```bash
mkdir ~/Desktop/skpdocs
xcodebuild docbuild -scheme SampleKeyProvider2025 -workspace SampleKeyProvider2025.xcworkspace -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath ~/Desktop/skpdocs/
xcodebuild docbuild -scheme KeySharingExtension -workspace SampleKeyProvider2025.xcworkspace -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath ~/Desktop/skpdocs/
xcodebuild docbuild -scheme KeySharingExtensionUI -workspace SampleKeyProvider2025.xcworkspace -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath ~/Desktop/skpdocs/
```

The resulting `SampleKeyProvider2025.doccarchive`, `KeySharingExtension.doccarchive`, and `KeySharingExtensionUI.doccarchive` can be subsequently found in the `~/Desktop/kscdocs/Build/Products/Debug-iphonesimulator` folder.

### Building

Prior to attempting to build the project, replace the each project's bundle identifier, App Group, and Keychain Group. Make sure to update the `NSExtensionFileProviderDocumentGroup` in the Info.plist in the `KeySharingExtension` project otherwise the extension will not be presented to consuming applications as an option.