//
//  ObjCUtils.m
//  Key Sharing Common Code
//

#import <Foundation/Foundation.h>
#include "ObjCUtils.h"

//openssl includes
#include <openssl/err.h>
#include <openssl/pkcs12.h>
#include <openssl/x509v3.h>

// Definitions of local methods
bool HasEmailAddress(SecCertificateRef cert);
bool HasOtherName(SecCertificateRef cert);

int PrepareAndExportPkcs12(
    const unsigned char* keyBuf,
    int keyBufLen,
    const unsigned char* certBuf,
    int certBufLen,
    unsigned char** p12Buf,
    size_t* p12BufLen,
    const char* inputPassword);


// MARK: - Public Methods

/// Takes a ``CertType`` and a list of UTIs and returns true if the ``CertType`` is covered by the list of
/// UTIs and false otherwise.
bool CertTypeRequested(enum CertType ct, NSArray* utis) {
    if(nil == utis || [utis containsObject:@"purebred2025.rsa.pkcs-12"] || [utis containsObject:@"purebred2025.select.all"])
    {
        return true;
    }

    if(CT_UNKNOWN == ct)
        return false;
    else if(CT_DEVICE != ct && [utis containsObject:@"purebred2025.select.all-user"])
        return true;
    else if(CT_DEVICE == ct && [utis containsObject:@"purebred2025.select.device"])
        return true;
    else if(CT_SIGNATURE == ct && [utis containsObject:@"purebred2025.select.signature"])
        return true;
    else if(CT_ENCRYPTION == ct && [utis containsObject:@"purebred2025.select.encryption"])
        return true;
    else if(CT_AUTHENTICATION == ct && [utis containsObject:@"purebred2025.select.authentication"])
        return true;
    
    return false;
}

/// Takes a ``SecCertificateRef``, decodes and analyzes it then returns a ``CertType`` that
/// describes the contents of the certificate.
enum CertType GetCertType(SecCertificateRef cert)
{
    enum CertType retval = CT_UNKNOWN;
    CFDataRef cfData = SecCertificateCopyData(cert);
    const unsigned char* p = (const unsigned char*)CFDataGetBytePtr(cfData);
    X509 *certificateX509 = d2i_X509(NULL, &p, CFDataGetLength(cfData));
    CFRelease(cfData);
    if (certificateX509 != NULL) {
        int digitalSignature = 0;
        int nonRepudiation = 0;
        int keyEncipherment = 0;
        ASN1_BIT_STRING *keyUsage = (ASN1_BIT_STRING *)X509_get_ext_d2i((X509 *) certificateX509, NID_key_usage, NULL, NULL);
        if(NULL != keyUsage)
        {
            digitalSignature = ASN1_BIT_STRING_get_bit(keyUsage, 0);
            nonRepudiation = ASN1_BIT_STRING_get_bit(keyUsage, 1);
            keyEncipherment = ASN1_BIT_STRING_get_bit(keyUsage, 2);

            if(digitalSignature && keyEncipherment) {
                retval = CT_DEVICE;
            }
            else if(digitalSignature && nonRepudiation) {
                retval = CT_SIGNATURE;
            }
            else if(digitalSignature)
            {
                if(HasEmailAddress(cert)) {
                    retval = CT_SIGNATURE;
                }
                else if(HasOtherName(cert)) {
                    retval = CT_AUTHENTICATION;
                }
                else {
                    retval = CT_DEVICE;
                }
            }
            else if(keyEncipherment) {
                retval = CT_ENCRYPTION;
            }
        }
    }
    X509_free(certificateX509);
    return retval;
}

/// Takes a ``SecCertfificateRef`` and returns a double representing the number of seconds
/// since the UNIX epoch in the notBefore field.
double GetNotBefore(SecCertificateRef cert) {
    CFDataRef cfData = SecCertificateCopyData(cert);
    const unsigned char* p = (const unsigned char*)CFDataGetBytePtr(cfData);
    X509 *certificateX509 = d2i_X509(NULL, &p, CFDataGetLength(cfData));
    CFRelease(cfData);
    if (certificateX509 != NULL) {
        const ASN1_TIME * notBefore = X509_get0_notBefore(certificateX509);
        struct tm tm;
        int result = ASN1_TIME_to_tm(notBefore, &tm);
        X509_free(certificateX509);
        if (result == 1) {
            double dateInEpoch = mktime(&tm);
            return dateInEpoch;
        }
    }
    return 0;
}

/// GetPKCS12 takes two buffers and a password value to use when creating a PKCS#12 object.
/// The first buffer (cert) contains a DER-encoded certificate that contain the public key
/// that corresponds the private key contained in the second buffer (privKey). The privKey
/// buffer is as returned from SecCopyItem and includes the public key concatenated with the
/// private key. This function uses the two pieces from the privKey buffer to create an encoded
/// private key value suitable for consumption by OpenSSL.
///
/// Upon success, it returns an NSData containing a PKCS#12 object containing the presented
/// buffers and encrypted using the presented password. NULL is returned upon an error.
NSData* GetPKCS12(NSData* cert, NSData* privKey, NSString* password) {
    unsigned char* p12Buf = NULL;
    size_t p12BufLen = 0;
    
    const unsigned char* pkBits = (const unsigned char*)[privKey bytes];
    size_t pkLen = [privKey length];
    const unsigned char* certBits = (const unsigned char*)[cert bytes];
    size_t certLen = [cert length];
    
    if(NULL == pkBits || NULL == certBits) {
        return NULL;
    }

    int retval = PrepareAndExportPkcs12(pkBits, (int)pkLen, certBits, (int)certLen, &p12Buf, &p12BufLen, [password cStringUsingEncoding:NSUTF8StringEncoding]);
    if(0 == retval && NULL != p12Buf && 0 != p12BufLen) {
        NSData* p12Data = [NSData dataWithBytes:p12Buf length:p12BufLen];
        free(p12Buf);
        return p12Data;
    }
    else {
        return NULL;
    }
}

/// Takes a ``SecCertificateRef`` and returns an ``NSString`` containing an ASCII hexadecimal
/// representation of the serial number field.
NSString* GetSerialNumber(SecCertificateRef cert) {
    CFDataRef cfData = SecCertificateCopyData(cert);
    const unsigned char* p = (const unsigned char*)CFDataGetBytePtr(cfData);
    X509 *certificateX509 = d2i_X509(NULL, &p, CFDataGetLength(cfData));
    CFRelease(cfData);
    if (certificateX509 != NULL) {
        ASN1_INTEGER * serial = X509_get_serialNumber(certificateX509);
        BIGNUM *bnser = ASN1_INTEGER_to_BN(serial, NULL);
        char *asciiHex = BN_bn2hex(bnser);
        NSString* retval = [NSString stringWithUTF8String: asciiHex];
        BN_free(bnser);
        X509_free(certificateX509);
        return retval;
    }
    return @"";
}

/// Takes a ``SecCertificateRef``, determines the certificate, then checks the provided list of UTIs
/// and returns true if any zip UTI types are consistent with the certificate type and false otherwise
bool ZippedCertTypeRequested(SecCertificateRef cert, NSArray* utis)
{
    if(nil == utis || [utis containsObject:@"purebred2025.zip.all"] || [utis containsObject:@"purebred2025.zip.no-filter"]) {
        return true;
    }
    
    enum CertType ct = GetCertType(cert);
    if(CT_UNKNOWN == ct)
        return false;
    else if(CT_DEVICE != ct && [utis containsObject:@"purebred2025.zip.all-user"])
        return true;
    else if(CT_DEVICE == ct && [utis containsObject:@"purebred2025.zip.device"])
        return true;
    else if(CT_SIGNATURE == ct && [utis containsObject:@"purebred2025.zip.signature"])
        return true;
    else if(CT_ENCRYPTION == ct && [utis containsObject:@"purebred2025.zip.encryption"])
        return true;
    else if(CT_AUTHENTICATION == ct && [utis containsObject:@"purebred2025.zip.authentication"])
        return true;
    
    return false;
}


/// Takes a private key, a certificate, and a password and returns a PKCS #12 object containing the key and certificate and encrypted
/// using the password.
int PrepareAndExportPkcs12(
    const unsigned char* keyBuf,
    int keyBufLen,
    const unsigned char* certBuf,
    int certBufLen,
    unsigned char** p12Buf,
    size_t* p12BufLen,
    const char* inputPassword)
{
    int rv = 0; //FIPS_mode_set(0);
    OpenSSL_add_all_algorithms();
    
    rv = 0;
    
    PKCS8_PRIV_KEY_INFO *p8i = 0;
    EVP_PKEY *privkey = 0;
    X509 *cert = 0;
    PKCS12 *p12 = 0;
    
    BIO *berr = NULL;
    BIO *keybio = NULL;
    BIO *certbio = NULL;
    BIO *p12bio = NULL;
    
    //create bio for stderr but don't fail if not created (just don't use and don't free below)
    berr = BIO_new_fp(stderr, BIO_NOCLOSE);
    
    //create a bio containing the PKCS8 object passed in
    keybio = BIO_new_mem_buf((void *) keyBuf, keyBufLen);
    if (!keybio) {
        BIO_free(berr);
        return -1;
    }
    
    //create a buffer containing the certificate passed in
    certbio = BIO_new_mem_buf((void *) certBuf, certBufLen);
    if (!certbio) {
        BIO_free(berr);
        BIO_free(keybio);
        return -2;
    }
    
    //create a bio to receive the encoded PKCS12
    p12bio = BIO_new(BIO_s_mem());
    if (!p12bio) {
        BIO_free(berr);
        BIO_free(keybio);
        BIO_free(certbio);
        return -3;
    }
    
    {
        //try to parse the PKCS8 buffer loaded into the keybio above
        p8i = d2i_PKCS8_PRIV_KEY_INFO_bio(keybio, NULL);
        if (!p8i)
        {
            BIO_free(keybio);
            keybio = BIO_new_mem_buf((void *) keyBuf, keyBufLen);
            if (!keybio) {
                BIO_free(berr);
                return -1;
            }
            privkey = d2i_PrivateKey_bio(keybio, NULL);
            if(!privkey) return -202;
        }
        else
        {
            //extract the private key from the PKCS8 object
            privkey = EVP_PKCS82PKEY(p8i);
            if (!privkey)
                return -203;
        }
        
        //try to parse the certificate loaded into the certbio above
        cert = d2i_X509_bio(certbio, NULL);
        if (!cert)
            return -204;
        
        //create a new PKCS12 object containing the certificate and private key
        p12 = PKCS12_create(inputPassword, "SKP", privkey, cert, 0, NID_pbe_WithSHA1And3_Key_TripleDES_CBC, -1, 0, 0, 0);
        if (!p12)
        {
            long errcode = ERR_get_error();
            while( errcode ) {
                char errstring[1024];
                memset(errstring, 0x00, sizeof(errstring));
                ERR_error_string_n(errcode, errstring, sizeof(errstring));
                errcode = ERR_get_error();
            }
            ERR_clear_error();
            return -205;
        }
        
        const EVP_MD *macmd = NULL;
        
        macmd = EVP_get_digestbynid(NID_sha1);
        PKCS12_set_mac(p12, inputPassword, -1, NULL, 0, 0, macmd);
        
        //encode the PKCS12 object into the p12bio
        if (!i2d_PKCS12_bio(p12bio, p12))
            return -206;
        
        //get a pointer to the encoded PKCS 12 object
        BUF_MEM *ptr = NULL;
        BIO_get_mem_ptr(p12bio, &ptr);
        
        *p12BufLen = (int)ptr->length;
        (*p12Buf) = (unsigned char*)malloc(*p12BufLen);
        memcpy(*p12Buf, ptr->data, *p12BufLen);
    }
    
    //clean-up
    if (p12) PKCS12_free(p12);
    if (cert) X509_free(cert);
    if (p8i) PKCS8_PRIV_KEY_INFO_free(p8i);
    if (privkey) EVP_PKEY_free(privkey);
    if (berr) BIO_free(berr);
    BIO_free(keybio);
    BIO_free(certbio);
    BIO_free(p12bio);
    
    //return will either be 0 or -4 (because an exception was caught)
    return rv;
}
// MARK: - Local Methods

bool HasEmailAddress(SecCertificateRef cert)
{
    CFDataRef cfData = SecCertificateCopyData(cert);
    const unsigned char* p = (const unsigned char*)CFDataGetBytePtr(cfData);
    X509 *certificateX509 = d2i_X509(NULL, &p, CFDataGetLength(cfData));
    CFRelease(cfData);
    if (certificateX509 != NULL) {
        STACK_OF(GENERAL_NAME) *subjectAltNames = NULL;
        
        // Try to extract the names within the SAN extension from the certificate
        subjectAltNames = (STACK_OF(GENERAL_NAME) *)X509_get_ext_d2i((X509 *) certificateX509, NID_subject_alt_name, NULL, NULL);
        
        int altNameCount = sk_GENERAL_NAME_num(subjectAltNames);
        for (int ii = 0; ii < altNameCount; ++ii)
        {
            GENERAL_NAME* generalName = sk_GENERAL_NAME_value(subjectAltNames, ii);
            if (generalName->type == GEN_EMAIL)
            {
                X509_free(certificateX509);
                return true;
            }
        }
        X509_free(certificateX509);
    }
    return false;
}

bool HasOtherName(SecCertificateRef cert)
{
    CFDataRef cfData = SecCertificateCopyData(cert);
    const unsigned char* p = (const unsigned char*)CFDataGetBytePtr(cfData);
    X509 *certificateX509 = d2i_X509(NULL, &p, CFDataGetLength(cfData));
    CFRelease(cfData);
    if (certificateX509 != NULL) {
        
        STACK_OF(GENERAL_NAME) *subjectAltNames = NULL;
        
        // Try to extract the names within the SAN extension from the certificate
        subjectAltNames = (STACK_OF(GENERAL_NAME) *)X509_get_ext_d2i((X509 *) certificateX509, NID_subject_alt_name, NULL, NULL);
        
        int altNameCount = sk_GENERAL_NAME_num(subjectAltNames);
        for (int ii = 0; ii < altNameCount; ++ii)
        {
            GENERAL_NAME* generalName = sk_GENERAL_NAME_value(subjectAltNames, ii);
            if (generalName->type == GEN_OTHERNAME && 12 == generalName->d.otherName->value->type)
            {
                X509_free(certificateX509);
                return true;
            }
        }
        X509_free(certificateX509);
    }
    return false;
}
