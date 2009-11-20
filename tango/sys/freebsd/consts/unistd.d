module tango.sys.freebsd.consts.unistd;
/+ http://opengroup.org/onlinepubs/007908799/xsh/unistd.h.html +/
enum {
    STDIN_FILENO = 0,
    STDOUT_FILENO = 1,
    STDERR_FILENO = 2,
    F_OK          = 0,
    R_OK          = 0x04,
    W_OK          = 0x02,
    X_OK          = 0x01,
    F_ULOCK       = 0,
    F_LOCK        = 1,
    F_TLOCK       = 2,
    F_TEST        = 3,
}
