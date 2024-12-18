//
//  ObjCUtils.h
//  Key Sharing Common Code
//

#ifndef ObjCUtils_h
#define ObjCUtils_h

#import <Foundation/Foundation.h>

/// The key sharing interfaces handles four different types of certificates: device certificates, derived signature certificates,
/// derived authentication certificates, and recovered encryption certificates. This enum serves to represent the type of
/// certificate based on analysis on the certificate's contents.
enum CertType : int
{
    CT_UNKNOWN = 0,
    CT_DEVICE,
    CT_SIGNATURE,
    CT_ENCRYPTION,
    CT_AUTHENTICATION,
};

/// Takes a ``CertType`` and a list of UTIs and returns true if the ``CertType`` is covered by the list of
/// UTIs and false otherwise.
bool CertTypeRequested(enum CertType ct, NSArray* utis);

/// Takes a ``SecCertificateRef``, decodes and analyzes it then returns a ``CertType`` that
/// describes the contents of the certificate.
enum CertType GetCertType(SecCertificateRef cert);

/// Takes a ``SecCertfificateRef`` and returns a double representing the number of seconds
/// since the UNIX epoch in the notBefore field.
double GetNotBefore(SecCertificateRef cert);

/// GetPKCS12 takes two buffers and a password value to use when creating a PKCS#12 object.
/// The first buffer (cert) contains a DER-encoded certificate that contain the public key
/// that corresponds the private key contained in the second buffer (privKey). The privKey
/// buffer is as returned from SecCopyItem and includes the public key concatenated with the
/// private key. This function uses the two pieces from the privKey buffer to create an encoded
/// private key value suitable for consumption by OpenSSL.
///
/// Upon success, it returns an NSData containing a PKCS#12 object containing the presented
/// buffers and encrypted using the presented password. NULL is returned upon an error.
NSData* GetPKCS12(NSData* cert, NSData* privKey, NSString* password);

/// Takes a ``SecCertificateRef`` and returns an ``NSString`` containing an ASCII hexadecimal
/// representation of the serial number field.
NSString* GetSerialNumber(SecCertificateRef cert);

/// Takes a ``SecCertificateRef``, determines the certificate, then checks the provided list of UTIs
/// and returns true if any zip UTI types are consistent with the certificate type and false otherwise
bool ZippedCertTypeRequested(SecCertificateRef cert, NSArray* utis);

#endif /* ObjCUtils_h */

