//
//  KeySharingPassword.swift
//  Key Sharing Common Code
//

/// Type alias for the completion handler used by the ``KeySharingPassword`` protocol. Accepts a password value
/// or an error.
typealias PasswordHandler = (_ password: String?, _ error: NSError?) -> Void

/// Name of the key sharing service.
let keySharingPasswordv1 = NSFileProviderServiceName("red.hound.KeySharingPassword-v1.0.0")

/// The ``KeySharingPassword`` protocol  is implemented by a service in an app that supports key sharing 2025. The [SampleKeyProvider2025](https://github.com/Purebred/SampleKeyProvider2025) app
/// provides a reference implementation. The protocol provides means to convey the password for PKCS 12 files served by the app and replaces the use of the system
/// pasteboard in the legacy key sharing implementation.
@objc protocol KeySharingPassword {
    /// Accepts a completion handler to allow for conveyance of a password value
    func fetchPassword(_ completionHandler: PasswordHandler?)
}
