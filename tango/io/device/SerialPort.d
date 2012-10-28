/*******************************************************************************

        copyright:      Copyright (c) 2008 Robin Kreis. All rights reserved

        license:        BSD style: $(LICENSE)

        author:         Robin Kreis

*******************************************************************************/

module tango.io.device.SerialPort;

private import  tango.core.Array : sort;

private import  tango.core.Exception,
                tango.io.device.Device,
                tango.stdc.stringz,
                tango.sys.Common;

version(Windows)
{
private import Integer = tango.text.convert.Integer;
private import tango.stdc.stringz;
}
else
version(Posix)
{
private import  tango.io.FilePath,
                tango.stdc.posix.termios;
}

/*******************************************************************************

        Enables applications to use a serial port (aka COM-port, ttyS).
        Usage is similar to that of File:
        ---
        auto serCond = new SerialPort("ttyS0");
        serCond.speed = 38400;
        serCond.write("Hello world!");
        serCond.close();
        ----

*******************************************************************************/

class SerialPort : Device
{
    private const(char)[]              str;
    private __gshared const(char)[][]  _ports;

    /***************************************************************************

            Create a new SerialPort instance. The port will be opened and
            set to raw mode with 9600-8N1.

            Params:
            port = A string identifying the port. On Posix, this must be a
                   device file like /dev/ttyS0. If the input doesn't begin
                   with "/", "/dev/" is automatically prepended, so "ttyS0"
                   is sufficent. On Windows, this must be a device name like
                   COM1.

    ***************************************************************************/

    this (const(char)[] port)
    {
        create (port);
    }

    /***************************************************************************

            Returns a string describing this serial port.
            For example: "ttyS0", "COM1", "cuad0".

    ***************************************************************************/

    override string toString ()
    {
        return str.idup;
    }

    /***************************************************************************

            Sets the baud rate of this port. Usually, the baud rate can
            only be set to fixed values (common values are 1200 * 2^n).

            Note that for Posix, the specification only mandates speeds up
            to 38400, excluding speeds such as 7200, 14400 and 28800.
            Most Posix systems have chosen to support at least higher speeds
            though.

            See_also: maxSpeed

            Throws: IOException if speed is unsupported.

    ***************************************************************************/

    SerialPort speed (uint speed)
    {
        version(Posix) {
            speed_t *baud = speed in baudRates;
            if(baud is null) {
                throw new IOException("Invalid baud rate.");
            }

            termios options;
            tcgetattr(handle, &options);
            cfsetospeed(&options, *baud);
            tcsetattr(handle, TCSANOW, &options);
        }
        version(Win32) {
            DCB config;
            GetCommState(io.handle, &config);
            config.BaudRate = speed;
            if(!SetCommState(io.handle, &config)) error();
        }
        return this;
    }

    /***************************************************************************

            Tries to enumerate all serial ports. While this usually works on
            Windows, it's more problematic on other OS. Posix provides no way
            to list serial ports, and the only option is searching through
            "/dev".

            Because there's no naming standard for the device files, this method
            must be ported for each OS. This method is also unreliable because
            the user could have created invalid device files, or deleted them.

            Returns:
            A string array of all the serial ports that could be found, in
            alphabetical order. Every string is formatted as a valid argument
            to the constructor, but the port may not be accessible.

    ***************************************************************************/

    static const(char)[][] ports ()
    {
        if(_ports !is null) {
            return _ports;
        }
        version(Windows) {
            // try opening COM1...COM255
            auto pre = `\\.\COM`;
            char[11] p = void;
            char[3] num = void;
            p[0..pre.length] = pre;
            for(int i = 1; i <= 255; ++i) {
                char[] portNum = Integer.format(num, i);
                p[pre.length..pre.length + portNum.length] = portNum;
                p[pre.length + portNum.length] = '\0';
                HANDLE port = CreateFileA(p.ptr, GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, 0, null);
                if(port != INVALID_HANDLE_VALUE) {
                    _ports ~= p[`\\.\`.length..$].dup; // cut the leading \\.\
                    CloseHandle(port);
                }
            }
        } else version(Posix) {
            auto dev = FilePath("/dev".dup);
            FilePath[] serPorts = dev.toList((FilePath path, bool isFolder) {
                if(isFolder) return false;
                version(linux) {
                    auto r = rest(path.name, "ttyUSB");
                    if(r is null) r = rest(path.name, "ttyS");
                    if(r.length == 0) return false;
                    return isInRange(r, '0', '9');
                } else version (darwin) { // untested
                    auto r = rest(path.name, "cu");
                    if(r.length == 0) return false;
                    return true;
                } else version(FreeBSD) { // untested
                    auto r = rest(path.name, "cuaa");
                    if(r is null) r = rest(path.name, "cuad");
                    if(r.length == 0) return false;
                    return isInRange(r, '0', '9');
                } else version(openbsd) { // untested
                    auto r = rest(path.name, "tty");
                    if(r.length != 2) return false;
                    return isInRange(r, '0', '9');
                } else version(solaris) { // untested
                    auto r = rest(path.name, "tty");
                    if(r.length != 1) return false;
                    return isInRange(r, 'a', 'z');
                } else {
                    return false;
                }
            });
            _ports.length = serPorts.length;
            foreach(i, path; serPorts) {
                _ports[i] = path.name;
            }
        }
        sort(_ports);
        return _ports;
    }

    version(Win32) {
        private void create (const(char)[] port)
        {
            str = port;
            io.handle = CreateFileA((`\\.\` ~ port).toStringz(), GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, 0, null);
            if(io.handle is INVALID_HANDLE_VALUE) {
                error();
            }
            DCB config;
            GetCommState(io.handle, &config);
            config.BaudRate = 9600;
            config.ByteSize = 8;
            config.Parity = NOPARITY;
            config.StopBits = ONESTOPBIT;
            config.flag0 |= bm_DCB_fBinary | bm_DCB_fParity;
            if(!SetCommState(io.handle, &config)) error();
        }
    }

    version(Posix) {
        private __gshared speed_t[uint] baudRates;

        shared static this()
        {
            baudRates[50] = B50;
            baudRates[75] = B75;
            baudRates[110] = B110;
            baudRates[134] = B134;
            baudRates[150] = B150;
            baudRates[200] = B200;
            baudRates[300] = B300;
            baudRates[600] = B600;
            baudRates[1200] = B1200;
            baudRates[1800] = B1800;
            baudRates[2400] = B2400;
            baudRates[9600] = B9600;
            baudRates[4800] = B4800;
            baudRates[19200] = B19200;
            baudRates[38400] = B38400;

            version( linux )
            {
                baudRates[57600] = B57600;
                baudRates[115200] = B115200;
                baudRates[230400] = B230400;
                baudRates[460800] = B460800;
                baudRates[500000] = B500000;
                baudRates[576000] = B576000;
                baudRates[921600] = B921600;
                baudRates[1000000] = B1000000;
                baudRates[1152000] = B1152000;
                baudRates[1500000] = B1500000;
                baudRates[2000000] = B2000000;
                baudRates[2500000] = B2500000;
                baudRates[3000000] = B3000000;
                baudRates[3500000] = B3500000;
                baudRates[4000000] = B4000000;
            }
            else version( FreeBSD )
            {
                baudRates[7200] = B7200;
                baudRates[14400] = B14400;
                baudRates[28800] = B28800;
                baudRates[57600] = B57600;
                baudRates[76800] = B76800;
                baudRates[115200] = B115200;
                baudRates[230400] = B230400;
                baudRates[460800] = B460800;
                baudRates[921600] = B921600;
            }
            else version( solaris )
            {
                baudRates[57600] = B57600;
                baudRates[76800] = B76800;
                baudRates[115200] = B115200;
                baudRates[153600] = B153600;
                baudRates[230400] = B230400;
                baudRates[307200] = B307200;
                baudRates[460800] = B460800;
            }
            else version ( darwin )
            {
                baudRates[7200] = B7200;
                baudRates[14400] = B14400;
                baudRates[28800] = B28800;
                baudRates[57600] = B57600;
                baudRates[76800] = B76800;
                baudRates[115200] = B115200;
                baudRates[230400] = B230400;
            }
        }

        private void create (const(char)[] file)
        {
            if(file.length == 0) throw new IOException("Empty port name");
            if(file[0] != '/') file = "/dev/" ~ file;

            if(file.length > 5 && file[0..5] == "/dev/")
                str = file[5..$];
            else
                str = "SerialPort@" ~ file;

            handle = posix.open(file.toStringz(), O_RDWR | O_NOCTTY | O_NONBLOCK);
            if(handle == -1) {
                error();
            }
            if(posix.fcntl(handle, F_SETFL, 0) == -1) { // disable O_NONBLOCK
                error();
            }

            termios options;
            if(tcgetattr(handle, &options) == -1) {
                error();
            }
            cfsetispeed(&options, B0); // same as output baud rate
            cfsetospeed(&options, B9600);
            makeRaw(&options); // disable echo and special characters
            tcsetattr(handle, TCSANOW, &options);
        }

        private void makeRaw (termios *options)
        {
            options.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP
                    | INLCR | IGNCR | ICRNL | IXON);
            options.c_oflag &= ~OPOST;
            options.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
            options.c_cflag &= ~(CSIZE | PARENB);
            options.c_cflag |= CS8;
        }


        private static inout(char)[] rest (inout(char)[] str, in char[] prefix) {
            if(str.length < prefix.length) return null;
            if(str[0..prefix.length] != prefix) return null;
            return str[prefix.length..$];
        }

        private static bool isInRange (const(char)[] str, char lower, char upper) {
            foreach(c; str) {
                if(c < lower || c > upper) return false;
            }
            return true;
        }
    }
}

