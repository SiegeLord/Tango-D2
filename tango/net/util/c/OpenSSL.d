/*******************************************************************************

        copyright:      Copyright (c) 2008 Jeff Davey. All rights reserved

        license:        BSD style: $(LICENSE)

        author:         Jeff Davey <j@submersion.com>

*******************************************************************************/

module tango.net.util.c.OpenSSL;

private import tango.sys.SharedLib;
private import tango.sys.Environment;

private import tango.stdc.stdio;
private import tango.stdc.stringz;
private import tango.stdc.config: c_long,c_ulong;

private import tango.io.FilePath;

private import tango.core.Thread;
private import tango.core.sync.Mutex;
private import tango.core.sync.ReadWriteMutex;

private import tango.text.convert.Format;
private import Integer = tango.text.convert.Integer;

/*******************************************************************************

    This module contains all of the dynamic bindings needed to the
    OpenSSL libraries (libssl.so/libssl32.dll and libcrypto.so/libeay32.dll) 

*******************************************************************************/

/*
   XXX TODO XXX

   A lot of unsigned longs and longs were converted to uint and int

   These will need to be reversed to support 64bit tango
   (should use c_long and c_ulong from tango.stdc.config)

   XXX TODO XXX
*/


version(linux)
{
    version(build)
    {
        pragma(link, "dl");
    }
}

enum uint BYTES_ENTROPY = 2048; // default bytes of entropy to load on startup.
__gshared private CRYPTO_dynlock_value *last = null;
__gshared Mutex _dynLocksMutex = null;
extern (C)
{
    enum int NID_sha1 = 64;
    enum int NID_md5 = 4;
    enum int RSA_PKCS1_OAEP_PADDING = 4;
    enum int RSA_PKCS1_PADDING = 1;
    enum int BIO_C_SET_NBIO = 102;
    enum int SHA_DIGEST_LENGTH = 20;
    enum int SSL_CTRL_SET_SESS_CACHE_MODE = 44;
    enum int MBSTRING_FLAG = 0x1000;
    enum int MBSTRING_ASC = MBSTRING_FLAG | 1;
    enum int EVP_PKEY_RSA = 6;
    enum int RSA_F4 = 0x1001;
    enum int SSL_SENT_SHUTDOWN = 1;
    enum int SSL_RECEIVED_SHUTDOWN = 2;
    enum int BIO_C_GET_SSL = 110;
    enum int BIO_CTRL_RESET = 1;
    enum int BIO_CTRL_INFO = 3;
    enum int BIO_FLAGS_READ = 0x01;
    enum int BIO_FLAGS_WRITE = 0x02;
    enum int BIO_FLAGS_IO_SPECIAL = 0x04;
    enum int BIO_FLAGS_SHOULD_RETRY = 0x08;
    enum int BIO_CLOSE = 0x00;
    enum int BIO_NOCLOSE = 0x01;
    enum int ASN1_STRFLGS_ESC_CTRL = 2;
    enum int ASN1_STRFLGS_ESC_MSB = 4;
    enum int XN_FLAG_SEP_MULTILINE = (4 << 16);
    enum int XN_FLAG_SPC_EQ = (1 << 23);
    enum int XN_FLAG_FN_LN = (1 << 21);
    enum int XN_FLAG_FN_ALIGN = (1 << 25);
    enum int XN_FLAG_MULTILINE = ASN1_STRFLGS_ESC_CTRL | ASN1_STRFLGS_ESC_MSB | XN_FLAG_SEP_MULTILINE | XN_FLAG_SPC_EQ | XN_FLAG_FN_LN | XN_FLAG_FN_ALIGN;

    enum immutable(char)* PEM_STRING_EVP_PKEY = "ANY PRIVATE KEY";
    enum immutable(char)* PEM_STRING_X509 = "CERTIFICATE";   
    enum immutable(char)* PEM_STRING_RSA_PUBLIC = "RSA PUBLIC KEY";    

    enum int SSL_CTRL_OPTIONS = 32;

    enum int SSL_OP_ALL = 0x00000FFFL;
    enum int SSL_OP_NO_SSLv2 = 0x01000000L;

    enum int CRYPTO_LOCK = 1;
    enum int CRYPTO_UNLOCK = 2;
    enum int CRYPTO_READ = 4;
    enum int CRYPTO_WRITE = 8;

    enum int ERR_TXT_STRING = 0x02;

    enum int MD5_CBLOCK = 64;
    enum int MD5_LBLOCK = MD5_CBLOCK / 4;
    enum int MD5_DIGEST_LENGTH = 16;

    enum int EVP_MAX_BLOCK_LENGTH = 32;
    enum int EVP_MAX_IV_LENGTH = 16;

    struct MD5_CTX
    {
        uint A;
        uint B;
        uint C;
        uint D;
        uint Nl;
        uint Nh;
        uint[MD5_LBLOCK] data;
        uint num;
    };

    struct EVP_CIPHER_CTX
    {
        void *cipher;
        void *engine;
        int encrypt;
        int buf_len;

        ubyte[EVP_MAX_IV_LENGTH] oiv;
        ubyte[EVP_MAX_IV_LENGTH] iv;
        ubyte buf[EVP_MAX_BLOCK_LENGTH];
        int num;

        void *ap_data;
        int key_len;
        c_ulong flags;
        void *cipher_data;
        int final_used;
        int block_mask;
        ubyte[EVP_MAX_BLOCK_LENGTH] finalv;
    };
    
    // fallback for OpenSSL 0.9.7l 28 Sep 2006 that defines only macros
    int EVP_CIPHER_CTX_block_size_097l(EVP_CIPHER_CTX *e){
        return *((cast(int*)e.cipher)+1);
    }

    struct BIO 
    {
        BIO_METHOD *method;
        int function(BIO *b, int a, char *c, int d, int e, int f) callback;
        char *cb_arg;
        int init;
        int shutdown;
        int flags;
        // yadda yadda
    };

    alias BIO* function(int sock, int close_flag) tBIO_new_socket;
    alias BIO* function(SSL_CTX *ctx, int client) tBIO_new_ssl;
    alias void function(BIO *bio) tBIO_free_all;
    alias BIO* function(BIO *b, BIO *append) tBIO_push;

    struct SSL_CTX {};
    struct SSL {};
    struct SSL_METHOD {};
    struct EVP_PKEY 
    {
        int type;
        int save_type;
        int references;
        void *ameth;
        void *engine;
        union Pkey
        {
                void *ptr;
                RSA *rsa;
                DSA *dsa;
                DH *dh;
        };
        Pkey pkey;
        
        
        // yadda yadda ...        
    };
    struct X509_STORE_CTX {};
    struct EVP_CIPHER {};
    struct X509_ALGOR {};
    struct ASN1_INTEGER {};
    struct EVP_MD {};

    struct ASN1_STRING
    {
        int length;
        int type;
        char *data;
        int flags;
    }

    alias ASN1_STRING ASN1_GENERALIZEDTIME;
    alias ASN1_STRING ASN1_TIME;

    struct X509_STORE {};
    struct X509_VAL
    {
        ASN1_TIME *notBefore;
        ASN1_TIME *notAfter;
    }
    struct X509_CINF  // being lazy here, only doing the first peices up to what I need
    {
        ASN1_INTEGER *vers;
        ASN1_INTEGER *serialNumber;
        X509_ALGOR *signature;
        X509_NAME *issuer;
        X509_VAL *validity;
        // yadda yadda
    }

    struct X509  // ditto X509_CINF
    {
        X509_CINF *cert_info; 
        // yadda yadda
    };
    struct X509_NAME {};
    struct RSA {};
    struct DSA {};
    struct DH {};
    struct BIO_METHOD {};
    struct EVP_PKEY_CTX {};
    
    alias int function(char *buf, int size, int rwflag, void *userdata) pem_password_cb;
    alias char *function() d2i_of_void;
    alias int function() i2d_of_void;
    alias SSL_CTX* function(SSL_METHOD *meth) tSSL_CTX_new;
    alias SSL_METHOD* function() tSSLv23_method;
    alias EVP_PKEY* function(int type, EVP_PKEY **a, ubyte **pp, int length) td2i_PrivateKey;
    alias int function(SSL_CTX *ctx, EVP_PKEY *pkey) tSSL_CTX_use_PrivateKey;
    alias void function(SSL_CTX *ctx, int mode, int function(int, X509_STORE_CTX *) callback) tSSL_CTX_set_verify;
    alias void function(EVP_PKEY *pkey) tEVP_PKEY_free;
    alias int function(SSL_CTX *ctx, int cmd, int larg, void *parg) tSSL_CTX_ctrl;
    alias int function(SSL_CTX *ctx, const(char) *str) tSSL_CTX_set_cipher_list;
    alias void function(SSL_CTX *) tSSL_CTX_free;
    alias void function() tSSL_load_error_strings;
    alias void function() tSSL_library_init;
    alias void function() tOpenSSL_add_all_digests;
    alias int function(const(char) *file, int max_bytes) tRAND_load_file;
    alias int function() tCRYPTO_num_locks;
    alias void function(uint function() cb) tCRYPTO_set_id_callback;
    alias void function(void function(int mode, int type, const(char) *file, int line) cb) tCRYPTO_set_locking_callback;
    alias void function(CRYPTO_dynlock_value *function(const(char) *file, int line) cb) tCRYPTO_set_dynlock_create_callback;    
    alias void function(void function(int mode, CRYPTO_dynlock_value *lock, const(char) *file, int lineNo) cb) tCRYPTO_set_dynlock_lock_callback;
    alias void function(void function(CRYPTO_dynlock_value *lock, const(char) *file, int line) cb) tCRYPTO_set_dynlock_destroy_callback;
    alias uint function(const(char) **file, int *line, const(char) **data, int *flags) tERR_get_error_line_data;
    alias void function(uint pid) tERR_remove_state;
    alias void function() tRAND_cleanup;
    alias void function() tERR_free_strings;
    alias void function() tEVP_cleanup;
    alias void function() tOBJ_cleanup;
    alias void function() tX509V3_EXT_cleanup;
    alias void function() tCRYPTO_cleanup_all_ex_data;
    alias int function(BIO *b, void *data, int len) tBIO_write;
    alias int function(BIO *b, void *data, int len) tBIO_read;
    alias int function(SSL_CTX *ctx) tSSL_CTX_check_private_key;
    alias EVP_PKEY* function(BIO *bp, EVP_PKEY **x, pem_password_cb *cb, in void *u) tPEM_read_bio_PrivateKey;
    alias EVP_PKEY* function(BIO *bp, EVP_PKEY **x, pem_password_cb *cb, in void *u) tPEM_read_bio_PUBKEY;
    alias BIO* function(const(char) *filename, const(char) *mode) tBIO_new_file;
    alias int function() tERR_peek_error;
    alias int function(BIO *b, int flags) tBIO_test_flags;
    alias int function(BIO *b, int cmd, int larg, void *parg) tBIO_ctrl; 
    alias void function(SSL *ssl, int mode) tSSL_set_shutdown;
    alias int function(SSL *ssl) tSSL_get_shutdown;
    alias int function(SSL_CTX *ctx, X509 *x) tSSL_CTX_use_certificate;
    alias void function(SSL_CTX *CTX, X509_STORE *store) tSSL_CTX_set_cert_store;
    alias int function(SSL_CTX *ctx, const(char) *CAfile, const(char) *CApath) tSSL_CTX_load_verify_locations;
    alias X509* function(X509_STORE_CTX *ctx) tX509_STORE_CTX_get_current_cert;
    alias int function(X509_STORE_CTX *ctx) tX509_STORE_CTX_get_error;
    alias int function(X509_STORE_CTX *ctx) tX509_STORE_CTX_get_error_depth;
    alias X509_STORE* function() tX509_STORE_new;
    alias void function(X509_STORE *v) tX509_STORE_free;
    alias int function(X509_STORE *store, X509 *x) tX509_STORE_add_cert;
//    alias int function(X509_STORE *store, int depth) tX509_STORE_set_depth;
    alias BIO* function(void *buff, int len) tBIO_new_mem_buf;
    alias RSA* function(int bits, uint e, void function(int a, int b, void *c) callback, void *cb_arg) tRSA_generate_key;
    alias EVP_PKEY* function() tEVP_PKEY_new;
    alias int function(EVP_PKEY *pkey, int type, char *key) tEVP_PKEY_assign;
    alias void function(RSA *r) tRSA_free;
    alias BIO* function(BIO_METHOD *type) tBIO_new;
    alias BIO_METHOD* function() tBIO_s_mem;
    alias int function(BIO *bp, EVP_PKEY *x, const(EVP_CIPHER) *cipher, char *kstr, int klen, pem_password_cb, in void *) tPEM_write_bio_PKCS8PrivateKey;
    alias int function(BIO *bp, EVP_PKEY *x) tPEM_write_bio_PUBKEY;
    alias EVP_CIPHER* function() tEVP_aes_256_cbc;
    alias void* function(d2i_of_void d2i, const(char) *name, BIO *bp, void **x, pem_password_cb cb, void *u) tPEM_ASN1_read_bio;
    alias X509* function() tX509_new;
    alias void function(X509 *x) tX509_free;
    alias int function(X509 *x, int ver) tX509_set_version;
    alias int function(ASN1_INTEGER *a, int v) tASN1_INTEGER_set;
    alias ASN1_INTEGER* function(X509 *x) tX509_get_serialNumber;
    alias int function(ASN1_INTEGER *a) tASN1_INTEGER_get;
    alias ASN1_TIME* function(ASN1_TIME *s, int adj) tX509_gmtime_adj;
    alias int function(X509 *x, EVP_PKEY *pkey) tX509_set_pubkey;
    alias X509_NAME* function(X509 *x) tX509_get_subject_name;
    alias int function(BIO *b, X509_NAME *nm, int indent, uint flags) tX509_NAME_print_ex;
    alias int function(X509 *x, X509_NAME *name) tX509_set_issuer_name;
    alias int function(X509 *x, EVP_PKEY *pkey, EVP_MD *md) tX509_sign;
    alias EVP_MD* function() tEVP_sha1;
    alias X509_STORE_CTX* function() tX509_STORE_CTX_new;
    alias int function(X509_STORE_CTX *ctx, X509_STORE *store, X509 *x509, void *shizzle) tX509_STORE_CTX_init;
    alias int function(X509_STORE_CTX *ctx) tX509_verify_cert;
    alias void function(X509_STORE_CTX *ctx) tX509_STORE_CTX_free;
    alias int function(i2d_of_void i2d, const(char) *name, BIO *bp, char *x, const(EVP_CIPHER) *enc, char *kstr, int klen, pem_password_cb cb, void *u) tPEM_ASN1_write_bio;
    alias int function(X509_NAME *name, in char* field, int type, const(char) *bytes, int len, int loc, int set) tX509_NAME_add_entry_by_txt;
    alias int function(SSL_CTX *ctx, ubyte *id, uint len) tSSL_CTX_set_session_id_context;
    alias int function(EVP_PKEY *a, EVP_PKEY *b) tEVP_PKEY_cmp_parameters;
    alias int function(X509 *a, X509 *b) tX509_cmp;
    alias void function() tOPENSSL_add_all_algorithms_noconf;
    alias ASN1_GENERALIZEDTIME *function(ASN1_TIME *t, ASN1_GENERALIZEDTIME **outTime) tASN1_TIME_to_generalizedtime;
    alias void function(ASN1_STRING *a) tASN1_STRING_free;
    alias int function() tRAND_poll;
    alias int function(RSA *rsa) tRSA_size;
    alias int function(int flen, ubyte *from, ubyte *to, RSA *rsa, int padding) tRSA_public_encrypt;
    alias int function(int flen, ubyte *from, ubyte *to, RSA *rsa, int padding) tRSA_private_decrypt;
    alias int function(int flen, ubyte *from, ubyte *to, RSA *rsa, int padding) tRSA_private_encrypt;
    alias int function(int flen, ubyte *from, ubyte *to, RSA *rsa, int padding) tRSA_public_decrypt;
    alias int function(int type, ubyte *m, uint m_length, ubyte *sigret, uint *siglen, RSA *rsa) tRSA_sign;
    alias int function(int type, ubyte *m, uint m_length, ubyte *sigbuf, uint siglen, RSA *rsa) tRSA_verify;
    alias void function(MD5_CTX *c) tMD5_Init;
    alias void function(MD5_CTX *c, in void *data, size_t len) tMD5_Update;
    alias void function(ubyte *md, MD5_CTX *c) tMD5_Final;
    alias int function(EVP_CIPHER_CTX *ctx, EVP_CIPHER *type, void *impl, ubyte *key, ubyte *iv) tEVP_EncryptInit_ex;
    alias int function(EVP_CIPHER_CTX *ctx, EVP_CIPHER *type, void *impl, ubyte *key, ubyte*iv) tEVP_DecryptInit_ex;
    alias int function(EVP_CIPHER_CTX *ctx, ubyte *outv, int *outl, ubyte *inv, int inl) tEVP_EncryptUpdate;
    alias int function(EVP_CIPHER_CTX *ctx, ubyte *outv, int *outl, ubyte *inv, int inl) tEVP_DecryptUpdate;
    alias int function(EVP_CIPHER_CTX *ctx, ubyte *outv, int *outl) tEVP_EncryptFinal_ex;
    alias int function(EVP_CIPHER_CTX *ctx, ubyte *outv, int *outl) tEVP_DecryptFinal_ex;
    alias int function(EVP_CIPHER_CTX *ctx) tEVP_CIPHER_CTX_block_size;
    alias EVP_CIPHER *function() tEVP_aes_128_cbc;
    alias int function(EVP_CIPHER_CTX *ctx) tEVP_CIPHER_CTX_cleanup;
    
    alias int function(int) tEVP_PKEY_type;
    alias RSA* function(EVP_PKEY *pkey) tEVP_PKEY_get1_RSA;
    alias DSA* function(EVP_PKEY *pkey) tEVP_PKEY_get1_DSA;
    
    
    alias EVP_PKEY_CTX* function(EVP_PKEY *pkey, void *e) tEVP_PKEY_CTX_new;
    alias void function(EVP_PKEY_CTX *ctx) tEVP_PKEY_CTX_free;   
    
    
    alias int function(EVP_PKEY_CTX *ctx) tEVP_PKEY_sign_init;
    alias int function(EVP_PKEY_CTX *ctx, ubyte *sig, size_t *siglen, const ubyte *tbs, size_t tbslen) tEVP_PKEY_sign;
    
    alias int function(EVP_PKEY_CTX *ctx) tEVP_PKEY_verify_init;
    alias int function(EVP_PKEY_CTX *ctx, const ubyte *sig, size_t siglen, const ubyte *tbs, size_t tbslen) tEVP_PKEY_verify;
    
    alias int function(EVP_PKEY_CTX *ctx) tEVP_PKEY_encrypt_init;
    alias int function(EVP_PKEY_CTX *ctx, ubyte *outdata, size_t *outlen, const ubyte *indata, size_t inlen) tEVP_PKEY_encrypt;
    
    alias int function(EVP_PKEY_CTX *ctx) tEVP_PKEY_decrypt_init;
    alias int function(EVP_PKEY_CTX *ctx, ubyte *outdata, size_t *outlen, const ubyte *indata, size_t inlen) tEVP_PKEY_decrypt;
    
    struct CRYPTO_dynlock_value
    {
        ReadWriteMutex lock;
        CRYPTO_dynlock_value *next;
        CRYPTO_dynlock_value *prev;
    }

    uint sslThreadId()
    {
        return cast(uint)cast(void*)Thread.getThis();
    }
    void sslStaticLock(int mode, int index, const(char) *sourceFile, int lineNo)
    {
        if (_locks)
        {
            if (mode & CRYPTO_LOCK)
            {
                if (mode & CRYPTO_READ)
                    _locks[index].reader.lock();
                else
                    _locks[index].writer.lock();
            }
            else
            {
                if (mode & CRYPTO_READ)
                    _locks[index].reader.unlock();
                else
                    _locks[index].writer.unlock();
            }

        } 
    }
    uint ablah = 0;
    CRYPTO_dynlock_value *sslDynamicLockCreate(const(char) *sourceFile, int lineNo)
    {
        auto rtn = new CRYPTO_dynlock_value;
        rtn.lock = new ReadWriteMutex;
        synchronized
        {
            if (last is null)
                last = rtn;
            else
            {
                rtn.prev = last;
                last.next = rtn;
                last = rtn;
            }        
        }
        return rtn; 
    }

    void sslDynamicLockLock(int mode, CRYPTO_dynlock_value *lock, const(char) *sourceFile, int lineNo)
    {
        if (lock && lock.lock)
        {
            if (mode & CRYPTO_LOCK)
            {
                if (mode & CRYPTO_READ)
                    lock.lock.reader.lock();
                else
                    lock.lock.writer.lock();
            }
            else
            {
                if (mode & CRYPTO_READ)
                    lock.lock.reader.unlock();
                else
                    lock.lock.writer.unlock();
            }
        } 
    }

    void sslDynamicLockDestroy(CRYPTO_dynlock_value *lock, const(char) *sourceFile, int lineNo)
    {
        synchronized
        {
            if (lock.prev)
                lock.prev.next = lock.next;
            if (lock.next)
                lock.next.prev = lock.prev;    
            if (lock is last)
                last = lock.prev;
            lock = lock.next = lock.prev = null;
        }
    }

}
private bool _bioTestFlags = true;
__gshared
{
tBIO_test_flags BIO_test_flags;
tBIO_new_socket BIO_new_socket;
tBIO_new_ssl BIO_new_ssl;
tBIO_free_all BIO_free_all;
tBIO_push BIO_push;
tBIO_read BIO_read;
tBIO_write BIO_write;
tSSL_CTX_new SSL_CTX_new;
tSSLv23_method SSLv23_method;
td2i_PrivateKey d2i_PrivateKey;
tSSL_CTX_use_PrivateKey SSL_CTX_use_PrivateKey;
tSSL_CTX_set_verify SSL_CTX_set_verify;
tEVP_PKEY_free EVP_PKEY_free;
tSSL_CTX_ctrl SSL_CTX_ctrl;
tSSL_CTX_set_cipher_list SSL_CTX_set_cipher_list;
tSSL_CTX_free SSL_CTX_free;
tSSL_load_error_strings SSL_load_error_strings;
tSSL_library_init SSL_library_init;
tRAND_load_file RAND_load_file;
tCRYPTO_num_locks CRYPTO_num_locks;
tCRYPTO_set_id_callback CRYPTO_set_id_callback;
tCRYPTO_set_locking_callback CRYPTO_set_locking_callback;
tCRYPTO_set_dynlock_create_callback CRYPTO_set_dynlock_create_callback;
tCRYPTO_set_dynlock_lock_callback CRYPTO_set_dynlock_lock_callback;
tCRYPTO_set_dynlock_destroy_callback CRYPTO_set_dynlock_destroy_callback;
tERR_get_error_line_data ERR_get_error_line_data;
tERR_remove_state ERR_remove_state;
tRAND_cleanup RAND_cleanup;
tERR_free_strings ERR_free_strings;
tEVP_cleanup EVP_cleanup;
tOBJ_cleanup OBJ_cleanup;
tX509V3_EXT_cleanup X509V3_EXT_cleanup;
tCRYPTO_cleanup_all_ex_data CRYPTO_cleanup_all_ex_data;
tSSL_CTX_check_private_key SSL_CTX_check_private_key;
tPEM_read_bio_PrivateKey PEM_read_bio_PrivateKey;
tPEM_read_bio_PUBKEY PEM_read_bio_PUBKEY;
tBIO_new_file BIO_new_file;
tERR_peek_error ERR_peek_error;
tBIO_ctrl BIO_ctrl;
tSSL_get_shutdown SSL_get_shutdown;
tSSL_set_shutdown SSL_set_shutdown;
tSSL_CTX_use_certificate SSL_CTX_use_certificate;
tSSL_CTX_set_cert_store SSL_CTX_set_cert_store;
tSSL_CTX_load_verify_locations SSL_CTX_load_verify_locations;
tX509_STORE_CTX_get_current_cert X509_STORE_CTX_get_current_cert;
tX509_STORE_CTX_get_error_depth X509_STORE_CTX_get_error_depth;
tX509_STORE_CTX_get_error X509_STORE_CTX_get_error;
tX509_STORE_new X509_STORE_new;
tX509_STORE_free X509_STORE_free;
tX509_STORE_add_cert X509_STORE_add_cert;
//tX509_STORE_set_depth X509_STORE_set_depth;
tBIO_new_mem_buf BIO_new_mem_buf;
tRSA_generate_key RSA_generate_key;
tEVP_PKEY_new EVP_PKEY_new;
tEVP_PKEY_assign EVP_PKEY_assign;
tRSA_free RSA_free;
tBIO_new BIO_new;
tBIO_s_mem BIO_s_mem;
tPEM_write_bio_PKCS8PrivateKey PEM_write_bio_PKCS8PrivateKey;
tPEM_write_bio_PUBKEY PEM_write_bio_PUBKEY;
tEVP_aes_256_cbc EVP_aes_256_cbc;
tPEM_ASN1_read_bio PEM_ASN1_read_bio;
d2i_of_void d2i_X509;
d2i_of_void d2i_RSAPublicKey;
tX509_new X509_new;
tX509_free X509_free;
tX509_set_version X509_set_version;
tASN1_INTEGER_set ASN1_INTEGER_set;
tX509_get_serialNumber X509_get_serialNumber;
tASN1_INTEGER_get ASN1_INTEGER_get;
tX509_gmtime_adj X509_gmtime_adj;
tX509_set_pubkey X509_set_pubkey;
tX509_get_subject_name X509_get_subject_name;
tX509_NAME_print_ex X509_NAME_print_ex;
tX509_set_issuer_name X509_set_issuer_name;
tX509_sign X509_sign;
tEVP_sha1 EVP_sha1;
tX509_STORE_CTX_new X509_STORE_CTX_new;
tX509_STORE_CTX_init X509_STORE_CTX_init;
tX509_verify_cert X509_verify_cert;
tX509_STORE_CTX_free X509_STORE_CTX_free;
tPEM_ASN1_write_bio PEM_ASN1_write_bio;
i2d_of_void i2d_X509;
i2d_of_void i2d_RSAPublicKey;
tX509_NAME_add_entry_by_txt X509_NAME_add_entry_by_txt;
tSSL_CTX_set_session_id_context SSL_CTX_set_session_id_context;
tEVP_PKEY_cmp_parameters EVP_PKEY_cmp_parameters;
tX509_cmp X509_cmp;
tOPENSSL_add_all_algorithms_noconf OPENSSL_add_all_algorithms_noconf;
tASN1_TIME_to_generalizedtime ASN1_TIME_to_generalizedtime;
tASN1_STRING_free ASN1_STRING_free;
tRAND_poll RAND_poll;
tRSA_size RSA_size;
tRSA_public_encrypt RSA_public_encrypt;
tRSA_private_decrypt RSA_private_decrypt;
tRSA_private_encrypt RSA_private_encrypt;
tRSA_public_decrypt RSA_public_decrypt;
tRSA_sign RSA_sign;
tRSA_verify RSA_verify;
tMD5_Init MD5_Init;
tMD5_Update MD5_Update;
tMD5_Final MD5_Final;
tEVP_EncryptInit_ex EVP_EncryptInit_ex;
tEVP_DecryptInit_ex EVP_DecryptInit_ex;
tEVP_EncryptUpdate EVP_EncryptUpdate;
tEVP_DecryptUpdate EVP_DecryptUpdate;
tEVP_EncryptFinal_ex EVP_EncryptFinal_ex;
tEVP_DecryptFinal_ex EVP_DecryptFinal_ex;
tEVP_aes_128_cbc EVP_aes_128_cbc;
tEVP_CIPHER_CTX_block_size EVP_CIPHER_CTX_block_size;
tEVP_CIPHER_CTX_cleanup EVP_CIPHER_CTX_cleanup;

tEVP_PKEY_type EVP_PKEY_type;
tEVP_PKEY_get1_RSA EVP_PKEY_get1_RSA;
tEVP_PKEY_get1_DSA EVP_PKEY_get1_DSA;

tEVP_PKEY_CTX_new EVP_PKEY_CTX_new;
tEVP_PKEY_CTX_free EVP_PKEY_CTX_free;
tEVP_PKEY_sign_init EVP_PKEY_sign_init;
tEVP_PKEY_sign EVP_PKEY_sign;
tEVP_PKEY_verify_init EVP_PKEY_verify_init;
tEVP_PKEY_verify EVP_PKEY_verify;

tEVP_PKEY_encrypt_init EVP_PKEY_encrypt_init;
tEVP_PKEY_encrypt EVP_PKEY_encrypt;
tEVP_PKEY_decrypt_init EVP_PKEY_decrypt_init;
tEVP_PKEY_decrypt EVP_PKEY_decrypt;
}
int PEM_write_bio_RSAPublicKey(BIO *bp, RSA *x)
{
    return PEM_ASN1_write_bio(i2d_RSAPublicKey, PEM_STRING_RSA_PUBLIC, bp, cast(char*)x, null, null, 0, null, null);
}

RSA *PEM_read_bio_RSAPublicKey(BIO *bp, RSA **x, pem_password_cb cb, void *u)
{
    return cast(RSA *)PEM_ASN1_read_bio(d2i_RSAPublicKey, PEM_STRING_RSA_PUBLIC, bp, cast(void **)x, cb, u);
}

int PEM_write_bio_X509(BIO *b, X509 *x)
{
    return PEM_ASN1_write_bio(i2d_X509, PEM_STRING_X509, b,cast(char *)x, null, null, 0, null, null);
}

ASN1_TIME *X509_get_notBefore(X509 *x)
{
    return x.cert_info.validity.notBefore;
}

ASN1_TIME *X509_get_notAfter(X509 *x)
{
    return x.cert_info.validity.notAfter;
}

int EVP_PKEY_assign_RSA(EVP_PKEY *key, RSA *rsa)
{
    return EVP_PKEY_assign(key, EVP_PKEY_RSA, cast(char*)rsa);
}

int BIO_get_mem_data(BIO *b, char **data)
{
    return BIO_ctrl(b, BIO_CTRL_INFO, 0, data);
}

void BIO_get_ssl(BIO *b, SSL **obj)
{
    BIO_ctrl(b, BIO_C_GET_SSL, 0, obj);
}

int SSL_CTX_set_options(SSL_CTX *ctx, int larg)
{
    return SSL_CTX_ctrl(ctx, SSL_CTRL_OPTIONS, larg, null);
}

int SSL_CTX_set_session_cache_mode(SSL_CTX *ctx, int mode)
{
    return SSL_CTX_ctrl(ctx, SSL_CTRL_SET_SESS_CACHE_MODE, mode, null);
}

int BIO_reset(BIO *b)
{
    return BIO_ctrl(b, BIO_CTRL_RESET, 0, null);
}

bool BIO_should_retry(BIO *b)
{
    if (_bioTestFlags)
        return cast(bool)BIO_test_flags(b, BIO_FLAGS_SHOULD_RETRY);
    return cast(bool)(b.flags & BIO_FLAGS_SHOULD_RETRY);
}

bool BIO_should_io_special(BIO *b)
{
    if (_bioTestFlags)
        return cast(bool)BIO_test_flags(b, BIO_FLAGS_IO_SPECIAL);
    return cast(bool)(b.flags & BIO_FLAGS_IO_SPECIAL);
}

bool BIO_should_read(BIO *b)
{
    if (_bioTestFlags)
        return cast(bool)BIO_test_flags(b, BIO_FLAGS_READ);
    return cast(bool)(b.flags & BIO_FLAGS_READ);
}

bool BIO_should_write(BIO *b)
{
    if (_bioTestFlags)
        return cast(bool)BIO_test_flags(b, BIO_FLAGS_WRITE);
    return cast(bool)(b.flags & BIO_FLAGS_WRITE);
}

X509* PEM_read_bio_X509(BIO *b, X509 **x, pem_password_cb cb, void *u)
{
    return cast(X509 *)PEM_ASN1_read_bio(d2i_X509, PEM_STRING_X509, b, cast(void**)x, cb, u);
}


private void bindFunc(T)(ref T func, const(char)[] funcName, SharedLib lib)
in
{
    assert(funcName);
    assert(lib);
}
body
{
    void *funcPtr = lib.getSymbol(toStringz(funcName));
    if (funcPtr)
    {
        void **point = cast(void **)&func;
        *point = funcPtr;
    }
    else
        throw new Exception("Could not load symbol: " ~ funcName.idup);
}

static __gshared SharedLib ssllib = null;
version(Win32)
{
    static __gshared SharedLib eaylib = null;
}
version(darwin){
    static __gshared SharedLib cryptolib = null;
}
static __gshared ReadWriteMutex[] _locks = null;


void throwOpenSSLError()
{
    if (ERR_peek_error())
    {
        char[] exceptionString;

        int flags, line;
        const(char) *data;
        const(char) *file;
        uint code;

        code = ERR_get_error_line_data(&file, &line, &data, &flags);
        while (code != 0)
        {
            if (data && (flags & ERR_TXT_STRING))
                exceptionString ~= Format.convert("ssl error code: {} {}:{} - {}\r\n", code, fromStringz(file), line, fromStringz(data));
            else
                exceptionString ~= Format.convert("ssl error code: {} {}:{}\r\n", code, fromStringz(file), line); 
            code = ERR_get_error_line_data(&file, &line, &data, &flags);
        }
        throw new Exception(exceptionString.idup);
    }
    else
        throw new Exception("Unknown OpenSSL error.");
}

void _initOpenSSL()
{
    SSL_load_error_strings();
    SSL_library_init();
    OPENSSL_add_all_algorithms_noconf();
    version(Posix)
        RAND_load_file("/dev/urandom", BYTES_ENTROPY);
    version(Win32)
    {
        RAND_poll();
    }

    uint numLocks = CRYPTO_num_locks();
    if ((_locks = new ReadWriteMutex[numLocks]) !is null)
    {
        uint i = 0;
        for (; i < numLocks; i++)
        {
            if((_locks[i] = new ReadWriteMutex()) is null)
                break;
        }
        if (i == numLocks)
        {
            CRYPTO_set_id_callback(&sslThreadId);
            CRYPTO_set_locking_callback(&sslStaticLock);

            CRYPTO_set_dynlock_create_callback(&sslDynamicLockCreate);
            CRYPTO_set_dynlock_lock_callback(&sslDynamicLockLock);
            CRYPTO_set_dynlock_destroy_callback(&sslDynamicLockDestroy);

        }
    } 
}

shared static this()
{
    version(Win32)
        loadEAY32();
    loadOpenSSL();
}
// Though it would be nice to do this, it can't be closed until all the sockets and etc have been collected.. not sure how to do that.
/*static ~this()
{
    closeOpenSSL();
}*/


SharedLib loadLib(const(char[])[] loadPath)
{
    SharedLib rtn;
    foreach(path; loadPath)
    {
        try
            rtn = SharedLib.load(path);
        catch (SharedLibException ex)
        {
            scope fp = new FilePath(path.dup);
            try
                rtn = SharedLib.load(fp.absolute(Environment.cwd()).toString());
            catch (SharedLibException ex)
            {}
        }
    }
    return rtn;
}

version (Win32)
{
    void loadEAY32()
    {
        const(char[])[] loadPath = [ "libeay32.dll" ];
        if ((eaylib = loadLib(loadPath)) !is null)
        {
            bindCrypto(eaylib);    
        }
    }

}

void bindCrypto(SharedLib ssllib)
{
    if (ssllib)
    {
        bindFunc(X509_cmp, "X509_cmp", ssllib);
        bindFunc(OPENSSL_add_all_algorithms_noconf, "OPENSSL_add_all_algorithms_noconf", ssllib);
        bindFunc(ASN1_TIME_to_generalizedtime, "ASN1_TIME_to_generalizedtime", ssllib);
        bindFunc(ASN1_STRING_free, "ASN1_STRING_free", ssllib);
        bindFunc(EVP_PKEY_cmp_parameters, "EVP_PKEY_cmp_parameters", ssllib);
        bindFunc(X509_STORE_CTX_get_current_cert, "X509_STORE_CTX_get_current_cert", ssllib);
        bindFunc(X509_STORE_CTX_get_error_depth, "X509_STORE_CTX_get_error_depth", ssllib);
        bindFunc(X509_STORE_CTX_get_error, "X509_STORE_CTX_get_error", ssllib);
        bindFunc(X509_STORE_new, "X509_STORE_new", ssllib);
        bindFunc(X509_STORE_free, "X509_STORE_free", ssllib);
        bindFunc(X509_STORE_add_cert, "X509_STORE_add_cert", ssllib);
//        bindFunc(X509_STORE_set_depth, "X509_STORE_set_depth", ssllib);
        bindFunc(BIO_new_mem_buf, "BIO_new_mem_buf", ssllib);
        bindFunc(RSA_generate_key, "RSA_generate_key", ssllib);
        bindFunc(EVP_PKEY_new, "EVP_PKEY_new", ssllib);
        bindFunc(EVP_PKEY_assign, "EVP_PKEY_assign", ssllib);
        bindFunc(RSA_free, "RSA_free", ssllib);
        bindFunc(BIO_new, "BIO_new", ssllib);
        bindFunc(BIO_s_mem, "BIO_s_mem", ssllib);
        bindFunc(PEM_write_bio_PKCS8PrivateKey, "PEM_write_bio_PKCS8PrivateKey", ssllib);
        bindFunc(PEM_write_bio_PUBKEY, "PEM_write_bio_PUBKEY", ssllib);
        bindFunc(EVP_aes_256_cbc, "EVP_aes_256_cbc", ssllib);
        bindFunc(PEM_ASN1_read_bio, "PEM_ASN1_read_bio", ssllib);
        bindFunc(d2i_X509, "d2i_X509", ssllib);
        bindFunc(d2i_RSAPublicKey, "d2i_RSAPublicKey", ssllib);
        bindFunc(X509_new, "X509_new", ssllib);
        bindFunc(X509_free, "X509_free", ssllib);
        bindFunc(X509_set_version, "X509_set_version", ssllib);
        bindFunc(ASN1_INTEGER_set, "ASN1_INTEGER_set", ssllib);
        bindFunc(X509_get_serialNumber, "X509_get_serialNumber", ssllib);
        bindFunc(ASN1_INTEGER_get, "ASN1_INTEGER_get", ssllib);
        bindFunc(X509_gmtime_adj, "X509_gmtime_adj", ssllib);
        bindFunc(X509_set_pubkey, "X509_set_pubkey", ssllib);
        bindFunc(X509_get_subject_name, "X509_get_subject_name", ssllib);
        bindFunc(X509_NAME_print_ex, "X509_NAME_print_ex", ssllib);
        bindFunc(X509_set_issuer_name, "X509_set_issuer_name", ssllib);
        bindFunc(X509_sign, "X509_sign", ssllib);
        bindFunc(EVP_sha1, "EVP_sha1", ssllib);
        bindFunc(X509_STORE_CTX_new, "X509_STORE_CTX_new", ssllib);
        bindFunc(X509_STORE_CTX_init, "X509_STORE_CTX_init", ssllib);
        bindFunc(X509_verify_cert, "X509_verify_cert", ssllib);
        bindFunc(X509_STORE_CTX_free, "X509_STORE_CTX_free", ssllib);
        bindFunc(PEM_ASN1_write_bio, "PEM_ASN1_write_bio", ssllib);
        bindFunc(i2d_X509, "i2d_X509", ssllib);
        bindFunc(i2d_RSAPublicKey, "i2d_RSAPublicKey", ssllib);
        bindFunc(X509_NAME_add_entry_by_txt, "X509_NAME_add_entry_by_txt", ssllib);
        bindFunc(PEM_read_bio_PrivateKey, "PEM_read_bio_PrivateKey", ssllib);
        bindFunc(PEM_read_bio_PUBKEY, "PEM_read_bio_PUBKEY", ssllib);
        bindFunc(BIO_new_file, "BIO_new_file", ssllib);
        bindFunc(ERR_peek_error, "ERR_peek_error", ssllib);
        try
            bindFunc(BIO_test_flags, "BIO_test_flags", ssllib); // 0.9.7 doesn't have this function, it access the struct directly
        catch (Exception ex)
            _bioTestFlags = false;
        bindFunc(BIO_ctrl, "BIO_ctrl", ssllib);
        bindFunc(RAND_load_file, "RAND_load_file", ssllib);
        bindFunc(CRYPTO_num_locks, "CRYPTO_num_locks", ssllib);
        bindFunc(CRYPTO_set_id_callback, "CRYPTO_set_id_callback", ssllib);
        bindFunc(CRYPTO_set_locking_callback, "CRYPTO_set_locking_callback", ssllib);
        bindFunc(CRYPTO_set_dynlock_create_callback, "CRYPTO_set_dynlock_create_callback", ssllib);
        bindFunc(CRYPTO_set_dynlock_lock_callback, "CRYPTO_set_dynlock_lock_callback", ssllib);
        bindFunc(CRYPTO_set_dynlock_lock_callback, "CRYPTO_set_dynlock_lock_callback", ssllib);
        bindFunc(CRYPTO_set_dynlock_destroy_callback, "CRYPTO_set_dynlock_destroy_callback", ssllib);
        bindFunc(ERR_get_error_line_data, "ERR_get_error_line_data", ssllib);
        bindFunc(ERR_remove_state, "ERR_remove_state", ssllib);
        bindFunc(RAND_cleanup, "RAND_cleanup", ssllib);
        bindFunc(ERR_free_strings, "ERR_free_strings", ssllib);
        bindFunc(EVP_cleanup, "EVP_cleanup", ssllib);
        bindFunc(OBJ_cleanup, "OBJ_cleanup", ssllib);
        bindFunc(X509V3_EXT_cleanup, "X509V3_EXT_cleanup", ssllib);
        bindFunc(CRYPTO_cleanup_all_ex_data, "CRYPTO_cleanup_all_ex_data", ssllib);
        bindFunc(BIO_read, "BIO_read", ssllib);
        bindFunc(BIO_write, "BIO_write", ssllib);
        bindFunc(EVP_PKEY_free, "EVP_PKEY_free", ssllib);
        bindFunc(d2i_PrivateKey, "d2i_PrivateKey", ssllib);    
        bindFunc(BIO_free_all, "BIO_free_all", ssllib);
        bindFunc(BIO_push, "BIO_push", ssllib);    
        bindFunc(BIO_new_socket, "BIO_new_socket", ssllib);
        bindFunc(RAND_poll, "RAND_poll", ssllib);
        bindFunc(RSA_size, "RSA_size", ssllib);
        bindFunc(RSA_public_encrypt, "RSA_public_encrypt", ssllib);
        bindFunc(RSA_private_decrypt, "RSA_private_decrypt", ssllib);
        bindFunc(RSA_private_encrypt, "RSA_private_encrypt", ssllib);
        bindFunc(RSA_public_decrypt, "RSA_public_decrypt", ssllib);
        bindFunc(RSA_sign, "RSA_sign", ssllib);
        bindFunc(RSA_verify, "RSA_verify", ssllib);
        bindFunc(MD5_Init, "MD5_Init", ssllib);
        bindFunc(MD5_Update, "MD5_Update", ssllib);
        bindFunc(MD5_Final, "MD5_Final", ssllib);
        bindFunc(EVP_EncryptInit_ex, "EVP_EncryptInit_ex", ssllib);
        bindFunc(EVP_DecryptInit_ex, "EVP_DecryptInit_ex", ssllib);
        bindFunc(EVP_EncryptUpdate, "EVP_EncryptUpdate", ssllib);
        bindFunc(EVP_DecryptUpdate,  "EVP_DecryptUpdate", ssllib);
        bindFunc(EVP_EncryptFinal_ex, "EVP_EncryptFinal_ex", ssllib);
        bindFunc(EVP_DecryptFinal_ex, "EVP_DecryptFinal_ex", ssllib);
        bindFunc(EVP_aes_128_cbc, "EVP_aes_128_cbc", ssllib);
        try {
            bindFunc(EVP_CIPHER_CTX_block_size, "EVP_CIPHER_CTX_block_size", ssllib);
        } catch (Exception e){
            // openSSL 0.9.7l defines only macros, not the function
            EVP_CIPHER_CTX_block_size=&EVP_CIPHER_CTX_block_size_097l;
        }
        bindFunc(EVP_CIPHER_CTX_cleanup, "EVP_CIPHER_CTX_cleanup", ssllib);
        
        bindFunc(EVP_PKEY_type, "EVP_PKEY_type", ssllib);
        bindFunc(EVP_PKEY_get1_RSA, "EVP_PKEY_get1_RSA", ssllib);
        bindFunc(EVP_PKEY_get1_DSA, "EVP_PKEY_get1_DSA", ssllib);
       
        bindFunc(EVP_PKEY_CTX_new, "EVP_PKEY_CTX_new", ssllib);
        bindFunc(EVP_PKEY_CTX_free, "EVP_PKEY_CTX_free", ssllib);
        
        bindFunc(EVP_PKEY_sign_init, "EVP_PKEY_sign_init", ssllib);
        bindFunc(EVP_PKEY_sign, "EVP_PKEY_sign", ssllib);
        
        bindFunc(EVP_PKEY_verify_init, "EVP_PKEY_verify_init", ssllib);
        bindFunc(EVP_PKEY_verify, "EVP_PKEY_verify", ssllib);
        
        bindFunc(EVP_PKEY_encrypt_init, "EVP_PKEY_encrypt_init", ssllib);
        bindFunc(EVP_PKEY_encrypt, "EVP_PKEY_encrypt", ssllib);
        
        bindFunc(EVP_PKEY_decrypt_init, "EVP_PKEY_decrypt_init", ssllib);
        bindFunc(EVP_PKEY_decrypt, "EVP_PKEY_decrypt", ssllib);


        /*EVP_PKEY_CTX_new
        EVP_PKEY_CTX_free
        int EVP_PKEY_sign_init(EVP_PKEY_CTX *ctx);
    int EVP_PKEY_sign(EVP_PKEY_CTX *ctx,
                unsigned char *sig, size_t *siglen,
                const unsigned char *tbs, size_t tbslen);
    int EVP_PKEY_verify_init(EVP_PKEY_CTX *ctx);
    int EVP_PKEY_verify(EVP_PKEY_CTX *ctx,
                const unsigned char *sig, size_t siglen,
                const unsigned char *tbs, size_t tbslen);

    int EVP_PKEY_encrypt_init(EVP_PKEY_CTX *ctx);
    int EVP_PKEY_encrypt(EVP_PKEY_CTX *ctx,
                unsigned char *out, size_t *outlen,
                const unsigned char *in, size_t inlen);
    int EVP_PKEY_decrypt_init(EVP_PKEY_CTX *ctx);
    int EVP_PKEY_decrypt(EVP_PKEY_CTX *ctx,
                unsigned char *out, size_t *outlen,
                const unsigned char *in, size_t inlen);*/
        
    }
}

void loadOpenSSL()
{
    version (linux)
    {
        const(char[])[] loadPath = [ "libssl.so.0.9.8", "libssl.so.1.0.0", "libssl.so" ];
    }
    version (Windows)
    {
        const(char[])[] loadPath = [ "libssl32.dll" ];
    }
    version (darwin)
    {
        const(char[])[] loadPath = [ "/usr/lib/libssl.dylib", "libssl.dylib" ];
    }
    version (FreeBSD)
    {
        const(char[])[] loadPath = [ "libssl.so.5", "libssl.so" ];
    }
    version (solaris)
    {
        const(char[])[] loadPath = [ "libssl.so.0.9.8", "libssl.so.1.0.0", "libssl.so" ];
    }
    if ((ssllib = loadLib(loadPath)) !is null)
    {

        bindFunc(BIO_new_ssl, "BIO_new_ssl", ssllib);
        bindFunc(SSL_CTX_free, "SSL_CTX_free", ssllib);
        bindFunc(SSL_CTX_new, "SSL_CTX_new", ssllib);
        bindFunc(SSLv23_method, "SSLv23_method", ssllib);
        bindFunc(SSL_CTX_use_PrivateKey, "SSL_CTX_use_PrivateKey", ssllib);
        bindFunc(SSL_CTX_set_verify, "SSL_CTX_set_verify", ssllib);
        bindFunc(SSL_CTX_ctrl, "SSL_CTX_ctrl", ssllib);
        bindFunc(SSL_CTX_set_cipher_list, "SSL_CTX_set_cipher_list", ssllib);
        bindFunc(SSL_load_error_strings, "SSL_load_error_strings", ssllib);
        bindFunc(SSL_library_init, "SSL_library_init", ssllib);
        bindFunc(SSL_CTX_check_private_key, "SSL_CTX_check_private_key", ssllib);
        bindFunc(SSL_get_shutdown, "SSL_get_shutdown", ssllib);
        bindFunc(SSL_set_shutdown, "SSL_set_shutdown", ssllib);
        bindFunc(SSL_CTX_use_certificate, "SSL_CTX_use_certificate", ssllib);
        bindFunc(SSL_CTX_set_cert_store, "SSL_CTX_set_cert_store", ssllib);
        bindFunc(SSL_CTX_load_verify_locations, "SSL_CTX_load_verify_locations", ssllib);
        bindFunc(SSL_CTX_set_session_id_context, "SSL_CTX_set_session_id_context", ssllib);
        version(Posix)
        {
            version(darwin){
                string[] loadPathCrypto = [ "/usr/lib/libcrypto.dylib", "libcrypto.dylib" ];
                cryptolib = loadLib(loadPathCrypto);
                if (cryptolib !is null) bindCrypto(cryptolib);
            } else {
                bindCrypto(ssllib);
            }
        }

        _initOpenSSL();
    }
    else
        throw new Exception("Could not load OpenSSL library.");
}

void closeOpenSSL()
{
    CRYPTO_set_id_callback(null);
    CRYPTO_set_locking_callback(null);
    CRYPTO_set_dynlock_create_callback(null);
    CRYPTO_set_dynlock_lock_callback(null);
    CRYPTO_set_dynlock_destroy_callback(null);
    ERR_remove_state(0);
    RAND_cleanup();
    ERR_free_strings();
    EVP_cleanup();
    OBJ_cleanup();
    X509V3_EXT_cleanup();
    CRYPTO_cleanup_all_ex_data();
    if (ssllib)
        ssllib.unload();
    version(darwin){
        if (cryptolib)
            cryptolib.unload();
    }
    version(Win32)
    {
        if (eaylib)
            eaylib.unload();
    }
}
