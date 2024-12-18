# ``SampleKeyProvider2025``

Provides a facsimile of Purebred Registration's key sharing 2025 extension to enable testing key import operations

## Overview

[Purebred](https://public.cyber.mil/pki-pke/purebred-2/) is the derived credential issuing system for the United States (U.S.) Department of Defense (DoD). Since 2016, the Purebred app for iOS has featured a custom "key sharing" interface that allows PKCS #12 objects and the corresponding passwords to be shared from the Purebred app to unrelated apps via the iOS file provider extension APIs and the system pasteboard. Two sample apps were prepared as a demonstration and to enable application developers to test integration with the key sharing interface and to demonstrate usage: [SampleKeyProvider](https://github.com/Purebred/SampleKeyProvider) and [KeyShareConsumer](https://github.com/Purebred/KeyShareConsumer). 

Since 2020, the Purebred app for iOS has featured a [persistent token](https://developer.apple.com/documentation/cryptotokenkit) extension that enables unrelated apps to use keys provisioned via Purebred without exporting and sharing the private keys. The persistent token interface is the preferred way to exercise Purebred-provisioned keys on iOS devices. As with key sharing, two sample apps were prepared to enable application developers to test integration with the persistent token interface and to demonstrate usage: [CtkProvider](https://github.com/Purebred/CtkProvider) and [CtkConsumer](https://github.com/Purebred/CtkConsumer).

In the years since 2016, several APIs that underpin the key sharing mechanism have been deprecated. To avoid use of deprecated APIs, the key sharing mechanism has been updated. Unfortunately, these changes are not cross-compatible and result in changes to the user experience. Two new sample apps, [SampleKeyProvider2025](https://github.com/Purebred/SampleKeyProvider2025) and [KeyShareConsumer2025](https://github.com/Purebred/KeyShareConsumer2025), are now available to facilitate testing and usage of the updated key sharing interface.

The ``SampleKeyProvider2025`` app provides an implementation of the document provider interface exposed by the Purebred Registration app to facilitate testing without needing to enroll with a Purebred server. PKCS #12 files can be imported into the ``SampleKeyProvider2025`` app using iTunes file sharing. Alternatively, a set of PKCS #12 files from a test Red Hat CA instance are included in the app and can be imported into the key chain directly. These files are similar to derived Common Access Card (CAC) credentials .
