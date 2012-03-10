/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.termios;

private import tango.stdc.posix.config;
public import tango.stdc.posix.sys.types; // for pid_t
private import tango.core.Octal;
extern (C):

//
// Required
//
/*
cc_t
speed_t
tcflag_t

NCCS

struct termios
{
    tcflag_t   c_iflag;
    tcflag_t   c_oflag;
    tcflag_t   c_cflag;
    tcflag_t   c_lflag;
    cc_t[NCCS] c_cc;
}

VEOF
VEOL
VERASE
VINTR
VKILL
VMIN
VQUIT
VSTART
VSTOP
VSUSP
VTIME

BRKINT
ICRNL
IGNBRK
IGNCR
IGNPAR
INLCR
INPCK
ISTRIP
IXOFF
IXON
PARMRK

OPOST

B0
B50
B75
B110
B134
B150
B200
B300
B600
B1200
B1800
B2400
B4800
B9600
B19200
B38400

CSIZE
    CS5
    CS6
    CS7
    CS8
CSTOPB
CREAD
PARENB
PARODD
HUPCL
CLOCAL

ECHO
ECHOE
ECHOK
ECHONL
ICANON
IEXTEN
ISIG
NOFLSH
TOSTOP

TCSANOW
TCSADRAIN
TCSAFLUSH

TCIFLUSH
TCIOFLUSH
TCOFLUSH

TCIOFF
TCION
TCOOFF
TCOON

speed_t cfgetispeed(in termios*);
speed_t cfgetospeed(in termios*);
int     cfsetispeed(termios*, speed_t);
int     cfsetospeed(termios*, speed_t);
int     tcdrain(int);
int     tcflow(int, int);
int     tcflush(int, int);
int     tcgetattr(int, termios*);
int     tcsendbreak(int, int);
int     tcsetattr(int, int, in termios*);
*/

version( darwin )
{
    alias ubyte cc_t;
    alias uint  speed_t;
    alias uint  tcflag_t;

    const NCCS  = 20;

    struct termios
    {
        tcflag_t   c_iflag;
        tcflag_t   c_oflag;
        tcflag_t   c_cflag;
        tcflag_t   c_lflag;
        cc_t[NCCS] c_cc;
        speed_t    c_ispeed;
        speed_t    c_ospeed;
    }

    const VEOF      = 0;
    const VEOL      = 1;
    const VERASE    = 3;
    const VINTR     = 8;
    const VKILL     = 5;
    const VMIN      = 16;
    const VQUIT     = 9;
    const VSTART    = 12;
    const VSTOP     = 13;
    const VSUSP     = 10;
    const VTIME     = 17;

    const BRKINT    = 0x0000002;
    const ICRNL     = 0x0000100;
    const IGNBRK    = 0x0000001;
    const IGNCR     = 0x0000080;
    const IGNPAR    = 0x0000004;
    const INLCR     = 0x0000040;
    const INPCK     = 0x0000010;
    const ISTRIP    = 0x0000020;
    const IXOFF     = 0x0000400;
    const IXON      = 0x0000200;
    const PARMRK    = 0x0000008;

    const OPOST     = 0x0000001;

    // Posix baudrates
    const B0        = 0;
    const B50       = 50;
    const B75       = 75;
    const B110      = 110;
    const B134      = 134;
    const B150      = 150;
    const B200      = 200;
    const B300      = 300;
    const B600      = 600;
    const B1200     = 1200;
    const B1800     = 1800;
    const B2400     = 2400;
    const B4800     = 4800;
    const B9600     = 9600;
    const B19200    = 19200;
    const B38400    = 38400;

    // Non-Posix baudrates
    const B7200     = 7200;
    const B14400    = 14400;
    const B28800    = 28800;
    const B57600    = 57600;
    const B76800    = 76800;
    const B115200   = 115200;
    const B230400   = 230400;

    const CSIZE     = 0x0000300;
    const   CS5     = 0x0000000;
    const   CS6     = 0x0000100;
    const   CS7     = 0x0000200;
    const   CS8     = 0x0000300;
    const CSTOPB    = 0x0000400;
    const CREAD     = 0x0000800;
    const PARENB    = 0x0001000;
    const PARODD    = 0x0002000;
    const HUPCL     = 0x0004000;
    const CLOCAL    = 0x0008000;

    const ECHO      = 0x00000008;
    const ECHOE     = 0x00000002;
    const ECHOK     = 0x00000004;
    const ECHONL    = 0x00000010;
    const ICANON    = 0x00000100;
    const IEXTEN    = 0x00000400;
    const ISIG      = 0x00000080;
    const NOFLSH    = 0x80000000;
    const TOSTOP    = 0x00400000;

    const TCSANOW   = 0;
    const TCSADRAIN = 1;
    const TCSAFLUSH = 2;

    const TCIFLUSH  = 1;
    const TCOFLUSH  = 2;
    const TCIOFLUSH = 3;

    const TCIOFF    = 3;
    const TCION     = 4;
    const TCOOFF    = 1;
    const TCOON     = 2;

    speed_t cfgetispeed(in termios*);
    speed_t cfgetospeed(in termios*);
    int     cfsetispeed(termios*, speed_t);
    int     cfsetospeed(termios*, speed_t);
    int     tcdrain(int);
    int     tcflow(int, int);
    int     tcflush(int, int);
    int     tcgetattr(int, termios*);
    int     tcsendbreak(int, int);
    int     tcsetattr(int, int, in termios*);

}
else version( linux )
{
    alias ubyte cc_t;
    alias uint  speed_t;
    alias uint  tcflag_t;

    const NCCS  = 32;

    struct termios
    {
        tcflag_t   c_iflag;
        tcflag_t   c_oflag;
        tcflag_t   c_cflag;
        tcflag_t   c_lflag;
        cc_t       c_line;
        cc_t[NCCS] c_cc;
        speed_t    c_ispeed;
        speed_t    c_ospeed;
    }

    const VEOF      = 4;
    const VEOL      = 11;
    const VERASE    = 2;
    const VINTR     = 0;
    const VKILL     = 3;
    const VMIN      = 6;
    const VQUIT     = 1;
    const VSTART    = 8;
    const VSTOP     = 9;
    const VSUSP     = 10;
    const VTIME     = 5;

    const BRKINT    = octal!2;
    const ICRNL     = octal!400;
    const IGNBRK    = octal!1;
    const IGNCR     = octal!200;
    const IGNPAR    = octal!4;
    const INLCR     = octal!100;
    const INPCK     = octal!20;
    const ISTRIP    = octal!40;
    const IXOFF     = octal!10000;
    const IXON      = octal!2000;
    const PARMRK    = octal!10;

    const OPOST     = octal!1;

    // Posix baudrates
    const B0        = 0;
    const B50       = octal!1;
    const B75       = octal!2;
    const B110      = octal!3;
    const B134      = octal!4;
    const B150      = octal!5;
    const B200      = octal!6;
    const B300      = octal!7;
    const B600      = octal!10;
    const B1200     = octal!11;
    const B1800     = octal!12;
    const B2400     = octal!13;
    const B4800     = octal!14;
    const B9600     = octal!15;
    const B19200    = octal!16;
    const B38400    = octal!17;

    // Non-Posix baudrates
    const B57600    = octal!10001; 
    const B115200   = octal!10002; 
    const B230400   = octal!10003; 
    const B460800   = octal!10004; 
    const B500000   = octal!10005; 
    const B576000   = octal!10006; 
    const B921600   = octal!10007; 
    const B1000000  = octal!10010; 
    const B1152000  = octal!10011; 
    const B1500000  = octal!10012; 
    const B2000000  = octal!10013; 
    const B2500000  = octal!10014; 
    const B3000000  = octal!10015; 
    const B3500000  = octal!10016; 
    const B4000000  = octal!10017;

    const CSIZE     = octal!60;
    const   CS5     = 0;
    const   CS6     = octal!20;
    const   CS7     = octal!40;
    const   CS8     = octal!60;
    const CSTOPB    = octal!100;
    const CREAD     = octal!200;
    const PARENB    = octal!400;
    const PARODD    = octal!1000;
    const HUPCL     = octal!2000;
    const CLOCAL    = octal!4000;

    const ECHO      = octal!10;
    const ECHOE     = octal!20;
    const ECHOK     = octal!40;
    const ECHONL    = octal!100;
    const ICANON    = octal!2;
    const IEXTEN    = octal!100000;
    const ISIG      = octal!1;
    const NOFLSH    = octal!200;
    const TOSTOP    = octal!400;

    const TCSANOW   = 0;
    const TCSADRAIN = 1;
    const TCSAFLUSH = 2;

    const TCIFLUSH  = 0;
    const TCOFLUSH  = 1;
    const TCIOFLUSH = 2;

    const TCIOFF    = 2;
    const TCION     = 3;
    const TCOOFF    = 0;
    const TCOON     = 1;

    speed_t cfgetispeed(in termios*);
    speed_t cfgetospeed(in termios*);
    int     cfsetispeed(termios*, speed_t);
    int     cfsetospeed(termios*, speed_t);
    int     tcdrain(int);
    int     tcflow(int, int);
    int     tcflush(int, int);
    int     tcgetattr(int, termios*);
    int     tcsendbreak(int, int);
    int     tcsetattr(int, int, in termios*);
}
else version (FreeBSD)
{
    alias ubyte cc_t;
    alias uint  speed_t;
    alias uint  tcflag_t;

    const NCCS  = 20;

    struct termios
    {
        tcflag_t   c_iflag;
        tcflag_t   c_oflag;
        tcflag_t   c_cflag;
        tcflag_t   c_lflag;
        cc_t[NCCS] c_cc;
        speed_t    c_ispeed;
        speed_t    c_ospeed;
    }

    const VEOF      = 0;
    const VEOL      = 1;
    const VERASE    = 3;
    const VINTR     = 8;
    const VKILL     = 5;
    const VMIN      = 16;
    const VQUIT     = 9;
    const VSTART    = 12;
    const VSTOP     = 13;
    const VSUSP     = 10;
    const VTIME     = 17;

    const BRKINT    = 0x0000002;
    const ICRNL     = 0x0000100;
    const IGNBRK    = 0x0000001;
    const IGNCR     = 0x0000080;
    const IGNPAR    = 0x0000004;
    const INLCR     = 0x0000040;
    const INPCK     = 0x0000010;
    const ISTRIP    = 0x0000020;
    const IXOFF     = 0x0000400;
    const IXON      = 0x0000200;
    const PARMRK    = 0x0000008;

    const OPOST     = 0x0000001;

    // Posix baudrates
    const B0        = 0;
    const B50       = 50;
    const B75       = 75;
    const B110      = 110;
    const B134      = 134;
    const B150      = 150;
    const B200      = 200;
    const B300      = 300;
    const B600      = 600;
    const B1200     = 1200;
    const B1800     = 1800;
    const B2400     = 2400;
    const B4800     = 4800;
    const B9600     = 9600;
    const B19200    = 19200;
    const B38400    = 38400;

    // Non-Posix baudrates
    const B7200     = 7200;
    const B14400    = 14400;
    const B28800    = 28800;
    const B57600    = 57600;
    const B76800    = 76800;
    const B115200   = 115200;
    const B230400   = 230400;
    const B460800   = 460800;
    const B921600   = 921600;

    const CSIZE     = 0x0000300; 
    const   CS5     = 0x0000000;
    const   CS6     = 0x0000100;
    const   CS7     = 0x0000200;
    const   CS8     = 0x0000300;
    const CSTOPB    = 0x0000400;
    const CREAD     = 0x0000800;
    const PARENB    = 0x0001000;
    const PARODD    = 0x0002000;
    const HUPCL     = 0x0004000;
    const CLOCAL    = 0x0008000;

    const ECHO      = 0x00000008;
    const ECHOE     = 0x00000002;
    const ECHOK     = 0x00000004;
    const ECHONL    = 0x00000010;
    const ICANON    = 0x00000100;
    const IEXTEN    = 0x00000400;
    const ISIG      = 0x00000080;
    const NOFLSH    = 0x80000000;
    const TOSTOP    = 0x00400000;

    const TCSANOW   = 0;
    const TCSADRAIN = 1;
    const TCSAFLUSH = 2;

    const TCIFLUSH  = 1;
    const TCOFLUSH  = 2;
    const TCIOFLUSH = 3;

    const TCIOFF    = 3;
    const TCION     = 4;
    const TCOOFF    = 1;
    const TCOON     = 2;

    speed_t cfgetispeed(in termios*);
    speed_t cfgetospeed(in termios*);
    int     cfsetispeed(termios*, speed_t);
    int     cfsetospeed(termios*, speed_t);
    int     tcdrain(int);
    int     tcflow(int, int);
    int     tcflush(int, int);
    int     tcgetattr(int, termios*);
    int     tcsendbreak(int, int);
    int     tcsetattr(int, int, in termios*);

}
else version ( solaris )
{
    alias ubyte cc_t;
    alias uint  speed_t;
    alias uint  tcflag_t;

    const NCCS  = 19;

    struct termios
    {
		tcflag_t	c_iflag;	/* input modes */
		tcflag_t	c_oflag;	/* output modes */
		tcflag_t	c_cflag;	/* control modes */
		tcflag_t	c_lflag;	/* line discipline modes */
		cc_t[NCCS]	c_cc;	/* control chars */
    }

    const VEOF      = 4;
    const VEOL      = 5;
    const VERASE    = 2;
    const VINTR     = 0;
    const VKILL     = 3;
    const VMIN      = 4;
    const VQUIT     = 1;
    const VSTART    = 8;
    const VSTOP     = 9;
    const VSUSP     = 11;
    const VTIME     = 5;

    const BRKINT    = octal!2;
    const ICRNL     = octal!400;
    const IGNBRK    = octal!1;
    const IGNCR     = octal!200;
    const IGNPAR    = octal!4;
    const INLCR     = octal!100;
    const INPCK     = octal!20;
    const ISTRIP    = octal!40;
    const IXOFF     = octal!10000;
    const IXON      = octal!2000;
    const PARMRK    = octal!10;

    const OPOST     = octal!1;

    // Posix baudrates
    const B0        = 0;
    const B50       = 1;
    const B75       = 2;
    const B110      = 3;
    const B134      = 4;
    const B150      = 5;
    const B200      = 6;
    const B300      = 7;
    const B600      = 8;
    const B1200     = 9;
    const B1800     = 10;
    const B2400     = 11;
    const B4800     = 12;
    const B9600     = 13;
    const B19200    = 14;
    const B38400    = 15;

    // Non-Posix baudrates
    const B57600    = 16;
    const B76800    = 17;
    const B115200   = 18;
    const B153600   = 19;
    const B230400   = 20;
    const B307200   = 21;
    const B460800   = 22;

    const CSIZE     = octal!60;
    const   CS5     = 0;
    const   CS6     = octal!20;
    const   CS7     = octal!40;
    const   CS8     = octal!60;
    const CSTOPB    = octal!100;
    const CREAD     = octal!200;
    const PARENB    = octal!400;
    const PARODD    = octal!1000;
    const HUPCL     = octal!2000;
    const CLOCAL    = octal!4000;

    const ECHO      = octal!10;
    const ECHOE     = octal!20;
    const ECHOK     = octal!40;
    const ECHONL    = octal!100;
    const ICANON    = octal!2;
    const IEXTEN    = octal!100000;
    const ISIG      = octal!1;
    const NOFLSH    = octal!200;
    const TOSTOP    = octal!400;

	const TIOC		= ('T'<<8);

    const TCSANOW   = TIOC|14;
    const TCSADRAIN = TIOC|15;
    const TCSAFLUSH = TIOC|16;

    const TCIFLUSH  = 0;
    const TCOFLUSH  = 1;
    const TCIOFLUSH = 2;

    const TCIOFF    = 2;
    const TCION     = 3;
    const TCOOFF    = 0;
    const TCOON     = 1;

    speed_t cfgetispeed(in termios*);
    speed_t cfgetospeed(in termios*);
    int     cfsetispeed(termios*, speed_t);
    int     cfsetospeed(termios*, speed_t);
    int     tcdrain(int);
    int     tcflow(int, int);
    int     tcflush(int, int);
    int     tcgetattr(int, termios*);
    int     tcsendbreak(int, int);
    int     tcsetattr(int, int, in termios*);
}

//
// XOpen (XSI)
//
/*
IXANY

ONLCR
OCRNL
ONOCR
ONLRET
OFILL
NLDLY
    NL0
    NL1
CRDLY
    CR0
    CR1
    CR2
    CR3
TABDLY
    TAB0
    TAB1
    TAB2
    TAB3
BSDLY
    BS0
    BS1
VTDLY
    VT0
    VT1
FFDLY
    FF0
    FF1

pid_t   tcgetsid(int);
*/

version( linux )
{
    const IXANY     = octal!4000;

    const ONLCR     = octal!4;
    const OCRNL     = octal!10;
    const ONOCR     = octal!20;
    const ONLRET    = octal!40;
    const OFILL     = octal!100;
    const NLDLY     = octal!400;
    const   NL0     = 0;
    const   NL1     = octal!400;
    const CRDLY     = octal!3000;
    const   CR0     = 0;
    const   CR1     = octal!1000;
    const   CR2     = octal!2000;
    const   CR3     = octal!3000;
    const TABDLY    = octal!14000;
    const   TAB0    = 0;
    const   TAB1    = octal!4000;
    const   TAB2    = octal!10000;
    const   TAB3    = octal!14000;
    const BSDLY     = octal!20000;
    const   BS0     = 0;
    const   BS1     = octal!20000;
    const VTDLY     = octal!40000;
    const   VT0     = 0;
    const   VT1     = octal!40000;
    const FFDLY     = octal!100000;
    const   FF0     = 0;
    const   FF1     = octal!100000;

    pid_t   tcgetsid(int);
}
else version( solaris )
{
    const IXANY     = octal!4000;

    const ONLCR     = octal!4;
    const OCRNL     = octal!10;
    const ONOCR     = octal!20;
    const ONLRET    = octal!40;
    const OFILL     = octal!100;
    const NLDLY     = octal!400;
    const   NL0     = 0;
    const   NL1     = octal!400;
    const CRDLY     = octal!3000;
    const   CR0     = 0;
    const   CR1     = octal!1000;
    const   CR2     = octal!2000;
    const   CR3     = octal!3000;
    const TABDLY    = octal!14000;
    const   TAB0    = 0;
    const   TAB1    = octal!4000;
    const   TAB2    = octal!10000;
    const   TAB3    = octal!14000;

    const BSDLY     = octal!20000;
    const   BS0     = 0;
    const   BS1     = octal!20000;
    const VTDLY     = octal!40000;
    const   VT0     = 0;
    const   VT1     = octal!40000;
    const FFDLY     = octal!100000;
    const   FF0     = 0;
    const   FF1     = octal!100000;

    pid_t   tcgetsid(int);
}
