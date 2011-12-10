/**
 * Author:          Lester L. Martin II
 *                  UWB, bobef
 * Copyright:       (c) Lester L. Martin II
 *                  UWB, bobef
 * Based upon prior FtpClient.d 
 * License:         BSD style: $(LICENSE)
 * Initial release:  August 8, 2008  
 */

module tango.net.ftp.FtpClient;

private 
{
    import tango.net.ftp.Telnet;
    import tango.text.Util;
    import tango.time.Clock;
    import tango.text.Regex: Regex;
    import tango.time.chrono.Gregorian;
    import tango.core.Array;
    import tango.net.device.Socket;
    import tango.io.device.Conduit;
    import tango.io.device.Array;
    import tango.io.device.File;

    import Text = tango.text.Util;
    import Ascii = tango.text.Ascii;
    import Integer = tango.text.convert.Integer;
    import Timestamp = tango.text.convert.TimeStamp;
}

/******************************************************************************
 An FTP progress delegate.
 
 You may need to add the restart position to this, and use SIZE to determine
 percentage completion.  This only represents the number of bytes
 transferred.
 
 Params:
 pos =                 the current offset into the stream
 ******************************************************************************/
alias void delegate(in size_t pos) FtpProgress;

/******************************************************************************
 The format of data transfer.
 ******************************************************************************/
enum FtpFormat 
{
    /**********************************************************************
     Indicates ASCII NON PRINT format (line ending conversion to CRLF.)
     **********************************************************************/
    ascii,
    /**********************************************************************
     Indicates IMAGE format (8 bit binary octets.)
     **********************************************************************/
    image,
}

/******************************************************************************
 A FtpAddress structure that contains all 
 that is needed to access a FTPConnection; Contributed by Bobef
 
 Since: 0.99.8
 ******************************************************************************/
struct FtpAddress 
{
    static FtpAddress* opCall(char[] str) {
        if(str.length == 0)
            return null;
        try {
            auto ret = new FtpAddress;
            //remove ftp://
            auto i = locatePattern(str, "ftp://");
            if(i == 0)
                str = str[6 .. $];

            //check for username and/or password user[:pass]@
            i = locatePrior(str, '@');
            if(i != str.length) {
                char[] up = str[0 .. i];
                str = str[i + 1 .. $];
                i = locate(up, ':');
                if(i != up.length) {
                    ret.user = up[0 .. i];
                    ret.pass = up[i + 1 .. $];
                } else
                    ret.user = up;
            }

            //check for port
            i = locatePrior(str, ':');
            if(i != str.length) {
                ret.port = cast(uint) Integer.toLong(str[i + 1 .. $]);
                str = str[0 .. i];
            }

            //check any directories after the adress
            i = locate(str, '/');
            if(i != str.length)
                ret.directory = str[i + 1 .. $];

            //the rest should be the address
            ret.address = str[0 .. i];
            if(ret.address.length == 0)
                return null;

            return ret;

        } catch(Object o) {
            return null;
        }
    }

    char[] address;
    char[] directory;
    char[] user = "anonymous";
    char[] pass = "anonymous@anonymous";
    uint port = 21;
}

/******************************************************************************
 A server response, consisting of a code and a potentially multi-line 
 message.
 ******************************************************************************/
struct FtpResponse 
{
    /**********************************************************************
     The response code.
     
     The digits in the response code can be used to determine status
     programatically.
     
     First Digit (status):
     1xx =             a positive, but preliminary, reply
     2xx =             a positive reply indicating completion
     3xx =             a positive reply indicating incomplete status
     4xx =             a temporary negative reply
     5xx =             a permanent negative reply
     
     Second Digit (subject):
     x0x =             condition based on syntax
     x1x =             informational
     x2x =             connection
     x3x =             authentication/process
     x5x =             file system
     **********************************************************************/
    char[3] code = "000";

    /*********************************************************************
     The message from the server.
     
     With some responses, the message may contain parseable information.
     For example, this is true of the 257 response.
     **********************************************************************/
    char[] message = null;
}

/******************************************************************************
 Active or passive connection mode.
 ******************************************************************************/
enum FtpConnectionType 
{
    /**********************************************************************
     Active - server connects to client on open port.
     **********************************************************************/
    active,
    /**********************************************************************
     Passive - server listens for a connection from the client.
     **********************************************************************/
    passive,
}

/******************************************************************************
 Detail about the data connection.
 
 This is used to properly send PORT and PASV commands.
 ******************************************************************************/
struct FtpConnectionDetail 
{
    /**********************************************************************
     The type to be used.
     **********************************************************************/
    FtpConnectionType type = FtpConnectionType.passive;

    /**********************************************************************
     The address to give the server.
     **********************************************************************/
    Address address = null;

    /**********************************************************************
     The address to actually listen on.
     **********************************************************************/
    Address listen = null;
}

/******************************************************************************
 A supported feature of an FTP server.
 ******************************************************************************/
struct FtpFeature 
{
    /**********************************************************************
     The command which is supported, e.g. SIZE.
     **********************************************************************/
    char[] command = null;
    /**********************************************************************
     Parameters for this command; e.g. facts for MLST.
     **********************************************************************/
    char[] params = null;
}

/******************************************************************************
 The type of a file in an FTP listing.
 ******************************************************************************/
enum FtpFileType 
{
    /**********************************************************************
     An unknown file or type (no type fact.)
     **********************************************************************/
    unknown,
    /**********************************************************************
     A regular file, or similar.
     **********************************************************************/
    file,
    /**********************************************************************
     The current directory (e.g. ., but not necessarily.)
     **********************************************************************/
    cdir,
    /**********************************************************************
     A parent directory (usually "..".)
     **********************************************************************/
    pdir,
    /**********************************************************************
     Any other type of directory.
     **********************************************************************/
    dir,
    /**********************************************************************
     Another type of file.  Consult the "type" fact.
     **********************************************************************/
    other,
}

/******************************************************************************
 Information about a file in an FTP listing.
 ******************************************************************************/
struct FtpFileInfo 
{
    /**********************************************************************
     The filename.
     **********************************************************************/
    char[] name = null;
    /**********************************************************************
     Its type.
     **********************************************************************/
    FtpFileType type = FtpFileType.unknown;
    /**********************************************************************
     Size in bytes (8 bit octets), or ulong.max if not available.
     Since: 0.99.8
     **********************************************************************/
    ulong size = ulong.max;
    /**********************************************************************
     Modification time, if available.
     **********************************************************************/
    Time modify = Time.max;
    /**********************************************************************
     Creation time, if available (not often.)
     **********************************************************************/
    Time create = Time.max;
    /**********************************************************************
     The file's mime type, if known.
     **********************************************************************/
    char[] mime = null;
    /***********************************************************************
     An associative array of all facts returned by the server, lowercased.
     ***********************************************************************/
    char[][char[]] facts;
}

/*******************************************************************************
 Changed location Since: 0.99.8
 Documentation Pending
 *******************************************************************************/
class FtpException: Exception 
{
    char[3] responseCode_ = "000";

    /***********************************************************************
     Construct an FtpException based on a message and code.
     
     Params:
     message =         the exception message
     code =            the code (5xx for fatal errors)
     ***********************************************************************/
    this(char[] message, char[3] code = "420") {
        this.responseCode_[] = code;
        super(message);
    }

    /***********************************************************************
     Construct an FtpException based on a response.
     
     Params:
     r =               the server response
     ***********************************************************************/
    this(FtpResponse r) {
        this.responseCode_[] = r.code;
        super(r.message);
    }

    /***********************************************************************
     A string representation of the error.
     ***********************************************************************/
    char[] toString() {
        char[] buffer = new char[this.msg.length + 4];

        buffer[0 .. 3] = this.responseCode_;
        buffer[3] = ' ';
        buffer[4 .. buffer.length] = this.msg;

        return buffer;
    }
}

/*******************************************************************************
 Seriously changed Since: 0.99.8
 Documentation pending
 *******************************************************************************/
class FTPConnection: Telnet 
{

    FtpFeature[] supportedFeatures_ = null;
    FtpConnectionDetail inf_;
    size_t restartPos_ = 0;
    char[] currFile_ = "";
    Socket dataSocket_;
    TimeSpan timeout_ = TimeSpan.fromMillis(5000);

    /***********************************************************************
     Added Since: 0.99.8
     ***********************************************************************/
    public TimeSpan timeout() {
        return timeout_;
    }

    /***********************************************************************
     Added Since: 0.99.8
     ***********************************************************************/
    public void timeout(TimeSpan t) {
        timeout_ = t;
    }

    /***********************************************************************
     Added Since: 0.99.8
     ***********************************************************************/
    public TimeSpan shutdownTime() {
        return timeout_ + timeout_;
    }

    /***********************************************************************
     Added Since: 0.99.8
     ***********************************************************************/
    public FtpFeature[] supportedFeatures() {
        if(supportedFeatures_ !is null) {
            return supportedFeatures_;
        }
        getFeatures();
        return supportedFeatures_;
    }

    /***********************************************************************
     Changed Since: 0.99.8
     ***********************************************************************/
    void exception(char[] message) {
        throw new FtpException(message);
    }

    /***********************************************************************
     Changed Since: 0.99.8
     ***********************************************************************/
    void exception(FtpResponse fr) {
        exception(fr.message);
    }

    public this() {

    }

    public this(char[] hostname, char[] username = "anonymous",
            char[] password = "anonymous@anonymous", uint port = 21) {
        this.connect(hostname, username, password, port);
    }

    /***********************************************************************
     Added Since: 0.99.8
     ***********************************************************************/
    public this(FtpAddress fad) {
        connect(fad);
    }

    /***********************************************************************
     Added Since: 0.99.8
     ***********************************************************************/
    public void connect(FtpAddress fad) {
        this.connect(fad.address, fad.user, fad.pass, fad.port);
    }

    /************************************************************************
     Changed Since: 0.99.8
     ************************************************************************/
    public void connect(char[] hostname, char[] username = "anonymous",
            char[] password = "anonymous@anonymous", uint port = 21)
    in {
        // We definitely need a hostname and port.
        assert(hostname.length > 0);
        assert(port > 0);
    }
    body {

        if(socket_ !is null) {
            socket_.close();
        }

        this.findAvailableServer(hostname, port);

        scope(failure) {
            close();
        }

        readResponse("220");

        if(username.length == 0) {
            return;
        }

        sendCommand("USER", username);
        FtpResponse response = readResponse();

        if(response.code == "331") {
            sendCommand("PASS", password);
            response = readResponse();
        }

        if(response.code != "230" && response.code != "202") {
            exception(response);
        }
    }

    public void close() {
        //make sure no open data connection and if open data connection then kill
        if(dataSocket_ !is null)
            this.finishDataCommand(dataSocket_);
        if(socket_ !is null) {
            try {
                sendCommand("QUIT");
                readResponse("221");
            } catch(FtpException) {

            }

            socket_.close();

            delete supportedFeatures_;
            delete socket_;
        }
    }

    public void setPassive() {
        inf_.type = FtpConnectionType.passive;

        delete inf_.address;
        delete inf_.listen;
    }

    public void setActive(char[] ip, ushort port, char[] listen_ip = null,
            ushort listen_port = 0)
    in {
        assert(ip.length > 0);
        assert(port > 0);
    }
    body {
        inf_.type = FtpConnectionType.active;
        inf_.address = new IPv4Address(ip, port);

        // A local-side port?
        if(listen_port == 0)
            listen_port = port;

        // Any specific IP to listen on?
        if(listen_ip == null)
            inf_.listen = new IPv4Address(IPv4Address.ADDR_ANY, listen_port);
        else
            inf_.listen = new IPv4Address(listen_ip, listen_port);
    }

    public void cd(char[] dir)
    in {
        assert(dir.length > 0);
    }
    body {
        sendCommand("CWD", dir);
        readResponse("250");
    }

    public void cdup() {
        sendCommand("CDUP");
        FtpResponse fr = readResponse();
        if(fr.code == "200" || fr.code == "250")
            return;
        else
            exception(fr);
    }

    public char[] cwd() {
        sendCommand("PWD");
        auto response = readResponse("257");

        return parse257(response);
    }

    public void chmod(char[] path, int mode)
    in {
        assert(path.length > 0);
        assert(mode >= 0 && (mode >> 16) == 0);
    }
    body {
        char[] tmp = "000";
        // Convert our octal parameter to a string.
        Integer.format(tmp, cast(long) mode, "o");
        sendCommand("SITE CHMOD", tmp, path);
        readResponse("200");
    }

    public void del(char[] path)
    in {
        assert(path.length > 0);
    }
    body {
        sendCommand("DELE", path);
        auto response = readResponse("250");

        //Try it as a directory, then...?
        if(response.code != "250")
            rm(path);
    }

    public void rm(char[] path)
    in {
        assert(path.length > 0);
    }
    body {
        sendCommand("RMD", path);
        readResponse("250");
    }

    public void rename(char[] old_path, char[] new_path)
    in {
        assert(old_path.length > 0);
        assert(new_path.length > 0);
    }
    body {
        // Rename from... rename to.  Pretty simple.
        sendCommand("RNFR", old_path);
        readResponse("350");

        sendCommand("RNTO", new_path);
        readResponse("250");
    }

    /***********************************************************************
     Added Since: 0.99.8
     ***********************************************************************/
    int exist(char[] file) {
        try {
            auto fi = getFileInfo(file);
            if(fi.type == FtpFileType.file) {
                return 1;
            } else if(fi.type == FtpFileType.dir || fi.type == FtpFileType.cdir || fi.type == FtpFileType.pdir) {
                return 2;
            }
        } catch(FtpException o) {
            if(o.responseCode_ != "501") {
                return 0;
            }
        }
        return 0;
    }

    public size_t size(char[] path, FtpFormat format = FtpFormat.image)
    in {
        assert(path.length > 0);
    }
    body {
        type(format);

        sendCommand("SIZE", path);
        auto response = this.readResponse("213");

        // Only try to parse the numeric bytes of the response.
        size_t end_pos = 0;
        while(end_pos < response.message.length) {
            if(response.message[end_pos] < '0' || response.message[end_pos] > '9')
                break;
            end_pos++;
        }

        return cast(int) Integer.parse((response.message[0 .. end_pos]));
    }

    public void type(FtpFormat format) {
        if(format == FtpFormat.ascii)
            sendCommand("TYPE", "A");
        else
            sendCommand("TYPE", "I");

        readResponse("200");
    }

    /***********************************************************************
     Added Since: 0.99.8
     ***********************************************************************/
    Time modified(char[] file)
    in {
        assert(file.length > 0);
    }
    body {
        this.sendCommand("MDTM", file);
        auto response = this.readResponse("213");

        // The whole response should be a timeval.
        return this.parseTimeval(response.message);
    }

    protected Time parseTimeval(char[] timeval) {
        if(timeval.length < 14)
            throw new FtpException("CLIENT: Unable to parse timeval", "501");

        return Gregorian.generic.toTime(
                Integer.atoi(timeval[0 .. 4]),
                Integer.atoi(timeval[4 .. 6]), 
                Integer.atoi(timeval[6 .. 8]),
                Integer.atoi(timeval[8 .. 10]),
                Integer.atoi(timeval[10 .. 12]),
                Integer.atoi(timeval[12 .. 14]));
    }

    public void noop() {
        this.sendCommand("NOOP");
        this.readResponse("200");
    }

    public char[] mkdir(char[] path)
    in {
        assert(path.length > 0);
    }
    body {
        this.sendCommand("MKD", path);
        auto response = this.readResponse("257");

        return this.parse257(response);
    }

    public void getFeatures() {
        this.sendCommand("FEAT");
        auto response = this.readResponse();

        // 221 means FEAT is supported, and a list follows.  Otherwise we don't know...
        if(response.code != "211")
            delete supportedFeatures_;
        else {
            char[][] lines = Text.splitLines(response.message);

            // There are two more lines than features, but we also have FEAT.
            supportedFeatures_ = new FtpFeature[lines.length - 1];
            supportedFeatures_[0].command = "FEAT";

            for(size_t i = 1; i < lines.length - 1; i++) {
                size_t pos = Text.locate(lines[i], ' ');

                supportedFeatures_[i].command = lines[i][0 .. pos];
                if(pos < lines[i].length - 1)
                    supportedFeatures_[i].params = lines[i][pos + 1 .. lines[i].length];
            }

            delete lines;
        }
    }

    public void sendCommand(char[] command, char[][] parameters...) {

        char[] socketCommand = command;

        // Send the command, parameters, and then a CRLF.

        foreach(char[] param; parameters) {
            socketCommand ~= " " ~ param;

        }

        socketCommand ~= "\r\n";

        debug(FtpDebug) {
            Stdout.formatln("[sendCommand] Sending command '{0}'",
                    socketCommand);
        }
        sendData(socketCommand);
    }

    public FtpResponse readResponse(char[] expected_code) {
        debug(FtpDebug) {
            Stdout.formatln("[readResponse] Expected Response {0}",
                    expected_code)();
        }
        auto response = readResponse();
        debug(FtpDebug) {
            Stdout.formatln("[readResponse] Actual Response {0}", response.code)();
        }

        if(response.code != expected_code)
            exception(response);

        return response;
    }

    public FtpResponse readResponse() {
        assert(this.socket_ !is null);

        // Pick a time at which we stop reading.  It can't take too long, but it could take a bit for the whole response.
        Time end_time = Clock.now + TimeSpan.fromMillis(2500) * 10;

        FtpResponse response;
        char[] single_line = null;

        // Danger, Will Robinson, don't fall into an endless loop from a malicious server.
        while(Clock.now < end_time) {
            single_line = this.readLine();

            // This is the first line.
            if(response.message.length == 0) {
                // The first line must have a code and then a space or hyphen.
                // #1
                // Response might be exactly 4 chars e.g. '230-'
                // (see ftp-stud.fht-esslingen.de or ftp.sunfreeware.com)
                if(single_line.length < 4) {
                    response.code[] = "500";
                    break;
                }

                // The code is the first three characters.
                response.code[] = single_line[0 .. 3];
                response.message = single_line[4 .. single_line.length];
            }
            // This is either an extra line, or the last line.
            else {
                response.message ~= "\n";

                // If the line starts like "123-", that is not part of the response message.
                if(single_line.length > 4 && single_line[0 .. 3] == response.code)
                    response.message ~= single_line[4 .. single_line.length];
                // If it starts with a space, that isn't either.
                else if(single_line.length > 2 && single_line[0] == ' ')
                    response.message ~= single_line[1 .. single_line.length];
                else
                    response.message ~= single_line;
            }

            // We're done if the line starts like "123 ".  Otherwise we're not.
            // #1
            // Response might be exactly 4 chars e.g. '220 '
            // (see ftp.knoppix.nl)
            if(single_line.length >= 4 && single_line[0 .. 3] == response.code && single_line[3] == ' ')
                break;
        }

        return response;
    }

    protected char[] parse257(FtpResponse response) {
        char[] path = new char[response.message.length];
        size_t pos = 1, len = 0;

        // Since it should be quoted, it has to be at least 3 characters in length.
        if(response.message.length <= 2)
            exception(response);

        //assert (response.message[0] == '"');

        // Trapse through the response...
        while(pos < response.message.length) {
            if(response.message[pos] == '"') {
                // #2
                // Is it the last character?
                if(pos + 1 == response.message.length)
                    // then we are done
                    break;

                // An escaped quote, keep going.  False alarm.
                if(response.message[++pos] == '"')
                    path[len++] = response.message[pos];
                else
                    break;
            } else
                path[len++] = response.message[pos];

            pos++;
        }

        // Okay, done!  That wasn't too hard.
        path.length = len;
        return path;
    }

    /*******************************************************************************
     Get a data socket from the server.
     
     This sends PASV/PORT as necessary.
     
     Returns:             the data socket or a listener
     Changed Since: 0.99.8
     *******************************************************************************/
    protected Socket getDataSocket() {
        //make sure no open data connection and if open data connection then kill
        if(dataSocket_ !is null)
            this.finishDataCommand(dataSocket_);

        // What type are we using?
        switch(this.inf_.type) {
            default:
                exception("unknown connection type");

            // Passive is complicated.  Handle it in another member.
            case FtpConnectionType.passive:
                return this.connectPassive();

            // Active is simpler, but not as fool-proof.
            case FtpConnectionType.active:
                IPv4Address data_addr = cast(IPv4Address) this.inf_.address;

                // Start listening.
                Socket listener = new Socket;
                listener.bind(this.inf_.listen);
                listener.socket.listen(32);

                // Use EPRT if we know it's supported.
                if(this.is_supported("EPRT")) {
                    char[64] tmp = void;

                    this.sendCommand("EPRT", Text.layout(tmp, "|1|%0|%1|",
                            data_addr.toAddrString, data_addr.toPortString));
                    // this.sendCommand("EPRT", format("|1|%s|%s|", data_addr.toAddrString(), data_addr.toPortString()));
                    this.readResponse("200");
                } else {
                    int h1, h2, h3, h4, p1, p2;
                    h1 = (data_addr.addr() >> 24) % 256;
                    h2 = (data_addr.addr() >> 16) % 256;
                    h3 = (data_addr.addr() >> 8_) % 256;
                    h4 = (data_addr.addr() >> 0_) % 256;
                    p1 = (data_addr.port() >> 8_) % 256;
                    p2 = (data_addr.port() >> 0_) % 256;

                    // low overhead method to format a numerical string
                    char[64] tmp = void;
                    char[20] foo = void;
                    auto str = Text.layout(tmp, "%0,%1,%2,%3,%4,%5",
                                    Integer.format(foo[0 .. 3], h1), 
                                    Integer.format(foo[3 .. 6], h2), 
                                    Integer.format(foo[6 .. 9], h3), 
                                    Integer.format(foo[9 .. 12], h4), 
                                    Integer.format(foo[12 .. 15], p1), 
                                    Integer.format(foo[15 .. 18], p2));

                    // This formatting is weird.
                    // this.sendCommand("PORT", format("%d,%d,%d,%d,%d,%d", h1, h2, h3, h4, p1, p2));

                    this.sendCommand("PORT", str);
                    this.readResponse("200");
                }

                return listener;
        }
    }

    /*******************************************************************************
     Send a PASV and initiate a connection.
     
     Returns:             a connected socket
     Changed Since: 0.99.8
     *******************************************************************************/
    public Socket connectPassive() {
        Address connect_to = null;

        // SPSV, which is just a port number.
        if(this.is_supported("SPSV")) {
            this.sendCommand("SPSV");
            auto response = this.readResponse("227");

            // Connecting to the same host.
            IPv4Address
                    remote = cast(IPv4Address) this.socket_.socket.remoteAddress();
            assert(remote !is null);

            uint address = remote.addr();
            uint port = cast(int) Integer.parse(((response.message)));

            connect_to = new IPv4Address(address, cast(ushort) port);
        }
        // Extended passive mode (IP v6, etc.)
        else if(this.is_supported("EPSV")) {
            this.sendCommand("EPSV");
            auto response = this.readResponse("229");

            // Try to pull out the (possibly not parenthesized) address.
            auto r = Regex(`\([^0-9][^0-9][^0-9](\d+)[^0-9]\)`);
            if(!r.test(response.message[0 .. find(response.message, '\n')]))
                throw new FtpException("CLIENT: Unable to parse address", "501");

            IPv4Address
                    remote = cast(IPv4Address) this.socket_.socket.remoteAddress();
            assert(remote !is null);

            uint address = remote.addr();
            uint port = cast(int) Integer.parse(((r.match(1))));

            connect_to = new IPv4Address(address, cast(ushort) port);
        } else {
            this.sendCommand("PASV");
            auto response = this.readResponse("227");

            // Try to pull out the (possibly not parenthesized) address.
            auto r = Regex(`(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)(,\s*(\d+))?`);
            if(!r.test(response.message[0 .. find(response.message, '\n')]))
                throw new FtpException("CLIENT: Unable to parse address", "501");

            // Now put it into something std.socket will understand.
            char[] address = r.match(1) ~ "." ~ r.match(2) ~ "." ~ r.match(3) ~ "." ~ r.match(4);
            ushort port = (((cast(int) Integer.parse(r.match(5))) << 8) + (r.match(7).
                           length > 0 ? cast(ushort) Integer.parse(r.match(7)) : 0));

            // Okay, we've got it!
            connect_to = new IPv4Address(address, port);
        }

        scope(exit)
            delete connect_to;

        // This will throw an exception if it cannot connect.
        auto sock = new Socket;
        sock.connect(connect_to);
        return sock;
    }

    /*
     Socket sock = new Socket();
     sock.connect(connect_to);
     return sock;
     */

    public bool isSupported(char[] command)
    in {
        assert(command.length > 0);
    }
    body {
        if(this.supportedFeatures_.length == 0)
            return true;

        // Search through the list for the feature.
        foreach(FtpFeature feat; this.supportedFeatures_) {
            if(Ascii.icompare(feat.command, command) == 0)
                return true;
        }

        return false;
    }

    public bool is_supported(char[] command) {
        if(this.supportedFeatures_.length == 0)
            return false;

        return this.isSupported(command);
    }

    /*******************************************************************************
     Prepare a data socket for use.
     
     This modifies the socket in some cases.
     
     Params:
     data =            the data listener socket
     Changed Since: 0.99.8
     ********************************************************************************/
    protected void prepareDataSocket(ref Socket data) {
        switch(this.inf_.type) {
            default:
                exception("unknown connection type");

            case FtpConnectionType.active:
                Berkeley new_data;

                scope set = new SocketSet;

                // At end_time, we bail.
                Time end_time = Clock.now + this.timeout;

                while(Clock.now < end_time) {
                    set.reset();
                    set.add(data.socket);

                    // Can we accept yet?
                    int code = set.select(set, null, null, timeout.micros);
                    if(code == -1 || code == 0)
                        break;

                    data.socket.accept(new_data);
                    break;
                }

            if(new_data.sock is new_data.sock.init)
               throw new FtpException("CLIENT: No connection from server", "420");

            // We don't need the listener anymore.
            data.shutdown.detach;

            // This is the actual socket.
            data.socket.sock = new_data.sock;
            break;

            case FtpConnectionType.passive:
            break;
        }
    }

    /*****************************************************************************
     Changed Since: 0.99.8
     *****************************************************************************/
    public void finishDataCommand(Socket data) {
        // Close the socket.  This tells the server we're done (EOF.)
        data.close();
        data.detach();

        // We shouldn't get a 250 in STREAM mode.
        FtpResponse r = readResponse();
        if(!(r.code == "226" || r.code == "420"))
            exception("Bad finish");

    }

    /*****************************************************************************
     Changed Since: 0.99.8
     *****************************************************************************/
    public Socket processDataCommand(char[] command, char[][] parameters...) {
        // Create a connection.
        Socket data = this.getDataSocket();
        scope(failure) {
            // Close the socket, whether we were listening or not.
            data.close();
        }

        // Tell the server about it.
        this.sendCommand(command, parameters);

        // We should always get a 150/125 response.
        auto response = this.readResponse();
        if(response.code != "150" && response.code != "125")
            exception(response);

        // We might need to do this for active connections.
        this.prepareDataSocket(data);

        return data;
    }

    public FtpFileInfo[] ls(char[] path = "")
    // default to current dir
    in {
        assert(path.length == 0 || path[path.length - 1] != '/');
    }
    body {
        FtpFileInfo[] dir;

        // We'll try MLSD (which is so much better) first... but it may fail.
        bool mlsd_success = false;
        Socket data = null;

        // Try it if it could/might/maybe is supported.
        if(this.isSupported("MLST")) {
            mlsd_success = true;

            // Since this is a data command, processDataCommand handles
            // checking the response... just catch its Exception.
            try {
                if(path.length > 0)
                    data = this.processDataCommand("MLSD", path);
                else
                    data = this.processDataCommand("MLSD");
            } catch(FtpException)
                mlsd_success = false;
        }

        // If it passed, parse away!
        if(mlsd_success) {
            auto listing = new Array(256, 65536);
            this.readStream(data, listing);
            this.finishDataCommand(data);

            // Each line is something in that directory.
            char[][] lines = Text.splitLines(cast(char[]) listing.slice());
            scope(exit)
                delete lines;

            foreach(char[] line; lines) {
                if(line.length == 0)
                    continue;
                // Parse each line exactly like MLST does.
                try {
                    FtpFileInfo info = this.parseMlstLine(line);
                    if(info.name.length > 0)
                        dir ~= info;
                } catch(FtpException) {
                    return this.sendListCommand(path);
                }
            }

            return dir;
        }
        // Fall back to LIST.
        else
            return this.sendListCommand(path);
    }

    /*****************************************************************************
     Changed Since: 0.99.8
     *****************************************************************************/
    protected void readStream(Socket data, OutputStream stream,
            FtpProgress progress = null)
    in {
        assert(data !is null);
        assert(stream !is null);
    }
    body {
        // Set up a SocketSet so we can use select() - it's pretty efficient.
        scope set = new SocketSet;

        // At end_time, we bail.
        Time end_time = Clock.now + this.timeout;

        // This is the buffer the stream data is stored in.
        ubyte[8 * 1024] buf;
        int buf_size = 0;

        bool completed = false;
        size_t pos;
        while(Clock.now < end_time) {
            set.reset();
            set.add(data.socket);

            // Can we read yet, can we read yet?
            int code = set.select(set, null, null, timeout.micros);
            if(code == -1 || code == 0)
                break;

            buf_size = data.socket.receive(buf);
            if(buf_size == data.socket.ERROR)
                break;

            if(buf_size == 0) {
                completed = true;
                break;
            }

            stream.write(buf[0 .. buf_size]);

            pos += buf_size;
            if(progress !is null)
                progress(pos);

            // Give it more time as long as data is going through.
            end_time = Clock.now + this.timeout;
        }

        // Did all the data get received?
        if(!completed)
            throw new FtpException("CLIENT: Timeout when reading data", "420");
    }

    /*****************************************************************************
     Changed Since: 0.99.8
     *****************************************************************************/
    protected void sendStream(Socket data, InputStream stream,
            FtpProgress progress = null)
    in {
        assert(data !is null);
        assert(stream !is null);
    }
    body {
        // Set up a SocketSet so we can use select() - it's pretty efficient.
        scope set = new SocketSet;

        // At end_time, we bail.
        Time end_time = Clock.now + this.timeout;

        // This is the buffer the stream data is stored in.
        ubyte[8 * 1024] buf;
        size_t buf_size = 0, buf_pos = 0;
        int delta = 0;

        size_t pos = 0;
        bool completed = false;
        while(!completed && Clock.now < end_time) {
            set.reset();
            set.add(data.socket);

            // Can we write yet, can we write yet?
            int code = set.select(null, set, null, timeout.micros);
            if(code == -1 || code == 0)
                break;

            if(buf_size - buf_pos <= 0) {
                if((buf_size = stream.read(buf)) is stream.Eof)
                    buf_size = 0 , completed = true;
                buf_pos = 0;
            }

            // Send the chunk (or as much of it as possible!)
            delta = data.socket.send(buf[buf_pos .. buf_size]);
            if(delta == data.socket.ERROR)
                break;

            buf_pos += delta;

            pos += delta;
            if(progress !is null)
                progress(pos);

            // Give it more time as long as data is going through.
            if(delta != 0)
                end_time = Clock.now + this.timeout;
        }

        // Did all the data get sent?
        if(!completed)
            throw new FtpException("CLIENT: Timeout when sending data", "420");
    }

    protected FtpFileInfo[] sendListCommand(char[] path) {
        FtpFileInfo[] dir;
        Socket data = null;

        if(path.length > 0)
            data = this.processDataCommand("LIST", path);
        else
            data = this.processDataCommand("LIST");

        // Read in the stupid non-standardized response.
        auto listing = new Array(256, 65536);
        this.readStream(data, listing);
        this.finishDataCommand(data);

        // Split out the lines.  Most of the time, it's one-to-one.
        char[][] lines = Text.splitLines(cast(char[]) listing.slice());
        scope(exit)
            delete lines;

        foreach(char[] line; lines) {
            if(line.length == 0)
                continue;
            // If there are no spaces, or if there's only one... skip the line.
            // This is probably like a "total 8" line.
            if(Text.locate(line, ' ') == Text.locatePrior(line, ' '))
                continue;

            // Now parse the line, or try to.
            FtpFileInfo info = this.parseListLine(line);
            if(info.name.length > 0)
                dir ~= info;
        }

        return dir;
    }

    protected FtpFileInfo parseListLine(char[] line) {
        FtpFileInfo info;
        size_t pos = 0;

        // Convenience function to parse a word from the line.
        char[] parse_word() {
            size_t start = 0, end = 0;

            // Skip whitespace before.
            while(pos < line.length && line[pos] == ' ')
                pos++;

            start = pos;
            while(pos < line.length && line[pos] != ' ')
                pos++;
            end = pos;

            // Skip whitespace after.
            while(pos < line.length && line[pos] == ' ')
                pos++;

            return line[start .. end];
        }

        // We have to sniff this... :/.
        switch(!Text.contains("0123456789", line[0])) {
            // Not a number; this is UNIX format.
            case true:
                // The line must be at least 20 characters long.
                if(line.length < 20)
                    return info;

                // The first character tells us what it is.
                if(line[0] == 'd')
                    info.type = FtpFileType.dir;
                // #3
                // Might be a link entry - additional test down below
                else if(line[0] == 'l')
                    info.type = FtpFileType.other;
                else if(line[0] == '-')
                    info.type = FtpFileType.file;
                else
                    info.type = FtpFileType.unknown;

                // Parse out the mode... rwxrwxrwx = 777.
                char[] unix_mode = "0000".dup;
                void read_mode(int digit) {
                    for(pos = 1 + digit * 3; pos <= 3 + digit * 3; pos++) {
                        if(line[pos] == 'r')
                            unix_mode[digit + 1] |= 4;
                        else if(line[pos] == 'w')
                            unix_mode[digit + 1] |= 2;
                        else if(line[pos] == 'x')
                            unix_mode[digit + 1] |= 1;
                    }
                }

                // This makes it easier, huh?
                read_mode(0);
                read_mode(1);
                read_mode(2);

                info.facts["UNIX.mode"] = unix_mode;

                // #4
                // Not only parse lines like
                //    drwxrwxr-x    2 10490    100          4096 May 20  2005 Acrobat
                //    lrwxrwxrwx    1 root     other           7 Sep 21  2007 Broker.link -> Acrobat
                //    -rwxrwxr-x    1 filelib  100           468 Nov  1  1999 Web_Users_Click_Here.html
                // but also parse lines like 
                //    d--x--x--x   2 staff        512 Sep 24  2000 dev
                // (see ftp.sunfreeware.com)

                // Links, owner.  These are hard to translate to MLST facts.
                parse_word();
                parse_word();

                // Group or size in bytes
                char[] group_or_size = parse_word();
                size_t oldpos = pos;

                // Size in bytes or month
                char[] size_or_month = parse_word();

                if(!Text.contains("0123456789", size_or_month[0])) {
                    // Oops, no size here - go back to previous column
                    pos = oldpos;
                    info.size = cast(ulong) Integer.parse(group_or_size);
                } else
                    info.size = cast(ulong) Integer.parse(size_or_month);

                // Make sure we still have enough space.
                if(pos + 13 >= line.length)
                    return info;

                // Not parsing date for now.  It's too weird (last 12 months, etc.)
                pos += 13;

                info.name = line[pos .. line.length];
                // #3
                // Might be a link entry - additional test here
                if(info.type == FtpFileType.other) {
                    // Is name like 'name -> /some/other/path'?
                    size_t pos2 = Text.locatePattern(info.name, " -> ");
                    if(pos2 != info.name.length) {
                        // It is a link - split into target and name
                        info.facts["target"] = info.name[pos2 + 4 .. info.name.length];
                        info.name = info.name[0 .. pos2];
                        info.facts["type"] = "link";
                    }
                }
            break;

            // A number; this is DOS format.
            case false:
                // We need some data here, to parse.
                if(line.length < 18)
                    return info;

                // The order is 1 MM, 2 DD, 3 YY, 4 HH, 5 MM, 6 P
                auto r = Regex(`(\d\d)-(\d\d)-(\d\d)\s+(\d\d):(\d\d)(A|P)M`);
                // #5
                // wrong test
                if(!r.test(line))
                    return info;

                if(Timestamp.dostime(r.match(0), info.modify) is 0)
                    info.modify = Time.max;

                pos = r.match(0).length;
                delete r;

                // This will either be <DIR>, or a number.
                char[] dir_or_size = parse_word();

                if(dir_or_size.length < 0)
                    return info;
                else if(dir_or_size[0] == '<')
                    info.type = FtpFileType.dir;
                else {
                    // #5
                    // It is a file
                    info.size = cast(ulong) Integer.parse((dir_or_size));
                    info.type = FtpFileType.file;
                }

                info.name = line[pos .. line.length];
            break;

            // Something else, not supported.
            default:
                throw new FtpException("CLIENT: Unsupported LIST format", "501");
        }

        // Try to fix the type?
        if(info.name == ".")
            info.type = FtpFileType.cdir;
        else if(info.name == "..")
            info.type = FtpFileType.pdir;

        return info;
    }

    protected FtpFileInfo parseMlstLine(char[] line) {
        FtpFileInfo info;

        // After this loop, filename_pos will be location of space + 1.
        size_t filename_pos = 0;
        while(filename_pos < line.length && line[filename_pos++] != ' ')
            continue;

        if(filename_pos == line.length)
            throw new FtpException("CLIENT: Bad syntax in MLSx response", "501");
        /*{
         info.name = "";
         return info;
         }*/

        info.name = line[filename_pos .. line.length];

        // Everything else is frosting on top.
        if(filename_pos > 1) {
            char[][]
                    temp_facts = Text.delimit(line[0 .. filename_pos - 1], ";");

            // Go through each fact and parse them into the array.
            foreach(char[] fact; temp_facts) {
                int pos = Text.locate(fact, '=');
                if(pos == fact.length)
                    continue;

                info.facts[Ascii.toLower(fact[0 .. pos])] = fact[pos + 1 .. fact.length];
            }

            // Do we have a type?
            if("type" in info.facts) {
                // Some reflection might be nice here.
                switch(Ascii.toLower(info.facts["type"])) {
                    case "file":
                        info.type = FtpFileType.file;
                    break;

                    case "cdir":
                        info.type = FtpFileType.cdir;
                    break;

                    case "pdir":
                        info.type = FtpFileType.pdir;
                    break;

                    case "dir":
                        info.type = FtpFileType.dir;
                    break;

                    default:
                        info.type = FtpFileType.other;
                }
            }

            // Size, mime, etc...
            if("size" in info.facts)
                info.size = cast(ulong) Integer.parse((info.facts["size"]));
            if("media-type" in info.facts)
                info.mime = info.facts["media-type"];

            // And the two dates.
            if("modify" in info.facts)
                info.modify = this.parseTimeval(info.facts["modify"]);
            if("create" in info.facts)
                info.create = this.parseTimeval(info.facts["create"]);
        }

        return info;
    }

    public FtpFileInfo getFileInfo(char[] path)
    in {
        assert(path.length > 0);
    }
    body {
        // Start assuming the MLST didn't work.
        bool mlst_success = false;
        FtpResponse response;
        auto inf = ls(path);
        if(inf.length == 1)
            return inf[0];
        else {
            debug(FtpUnitTest) {
                Stdout("In getFileInfo.").newline.flush;
            }
            {
                // Send a list command.  This may list the contents of a directory, even.
                FtpFileInfo[] temp = this.sendListCommand(path);

                // If there wasn't at least one line, the file didn't exist?
                // We should have already handled that.
                if(temp.length < 1)
                    throw new FtpException(
                            "CLIENT: Bad LIST response from server", "501");

                // If there are multiple lines, try to return the correct one.
                if(temp.length != 1)
                    foreach(FtpFileInfo info; temp) {
                        if(info.type == FtpFileType.cdir)
                            return info;
                    }

                // Okay then, the first line.  Best we can do?
                return temp[0];
            }
        }
    }

    public void put(char[] path, char[] local_file,
            FtpProgress progress = null, FtpFormat format = FtpFormat.image)
    in {
        assert(path.length > 0);
        assert(local_file.length > 0);
    }
    body {
        // Open the file for reading...
        auto file = new File(local_file);
        scope(exit) {
            file.detach();
            delete file;
        }

        // Seek to the correct place, if specified.
        if(this.restartPos_ > 0) {
            file.seek(this.restartPos_);
            this.restartPos_ = 0;
        } else {
            // Allocate space for the file, if we need to.
            //this.allocate(file.length);
        }

        // Now that it's open, we do what we always do.
        this.put(path, file, progress, format);
    }

    /********************************************************************************
     Store data from a stream on the server.
     
     Calling this function will change the current data transfer format.
     
     Params:
     path =            the path to the remote file
     stream =          data to store, or null for a blank file
     progress =        a delegate to call with progress information
     format =          what format to send the data in
     ********************************************************************************/
    public void put(char[] path, InputStream stream = null,
            FtpProgress progress = null, FtpFormat format = FtpFormat.image)
    in {
        assert(path.length > 0);
    }
    body {
        // Change to the specified format.
        this.type(format);

        // Okay server, we want to store something...
        Socket data = this.processDataCommand("STOR", path);

        // Send the stream over the socket!
        if(stream !is null)
            this.sendStream(data, stream, progress);

        this.finishDataCommand(data);
    }

    /********************************************************************************
     Append data to a file on the server.
     
     Calling this function will change the current data transfer format.
     
     Params:
     path =            the path to the remote file
     stream =          data to append to the file
     progress =        a delegate to call with progress information
     format =          what format to send the data in
     ********************************************************************************/
    public void append(char[] path, InputStream stream,
            FtpProgress progress = null, FtpFormat format = FtpFormat.image)
    in {
        assert(path.length > 0);
        assert(stream !is null);
    }
    body {
        // Change to the specified format.
        this.type(format);

        // Okay server, we want to store something...
        Socket data = this.processDataCommand("APPE", path);

        // Send the stream over the socket!
        this.sendStream(data, stream, progress);

        this.finishDataCommand(data);
    }

    /*********************************************************************************
     Seek to a byte offset for the next transfer.
     
     Params:
     offset =          the number of bytes to seek forward
     **********************************************************************************/
    public void restartSeek(size_t offset) {
        char[16] tmp;
        this.sendCommand("REST", Integer.format(tmp, cast(long) offset));
        this.readResponse("350");

        // Set this for later use.
        this.restartPos_ = offset;
    }

    /**********************************************************************************
     Allocate space for a file.
     
     After calling this, append() or put() should be the next command.
     
     Params:
     bytes =           the number of bytes to allocate
     ***********************************************************************************/
    public void allocate(long bytes)
    in {
        assert(bytes > 0);
    }
    body {
        char[16] tmp;
        this.sendCommand("ALLO", Integer.format(tmp, bytes));
        auto response = this.readResponse();

        // For our purposes 200 and 202 are both fine.
        if(response.code != "200" && response.code != "202")
            exception(response);
    }

    /**********************************************************************************
     Retrieve a remote file's contents into a local file.
     
     Calling this function will change the current data transfer format.
     
     Params:
     path =            the path to the remote file
     local_file =      the path to the local file
     progress =        a delegate to call with progress information
     format =          what format to read the data in
     **********************************************************************************/
    public void get(char[] path, char[] local_file,
            FtpProgress progress = null, FtpFormat format = FtpFormat.image)
    in {
        assert(path.length > 0);
        assert(local_file.length > 0);
    }
    body {
        File file = null;

        // We may either create a new file...
        if(this.restartPos_ == 0)
            file = new File(local_file, File.ReadWriteCreate);
        // Or open an existing file, and seek to the specified position (read: not end, necessarily.)
        else {
            file = new File(local_file, File.ReadWriteExisting);
            file.seek(this.restartPos_);

            this.restartPos_ = 0;
        }

        scope(exit) {
            file.detach();
            delete file;
        }

        // Now that it's open, we do what we always do.
        this.get(path, file, progress, format);
    }

    /*********************************************************************************
     Enable UTF8 on servers that don't use this as default. Might need some work
     *********************************************************************************/
    public void enableUTF8() {
        sendCommand("OPTS UTF8 ON");
        readResponse("200");
    }

    /**********************************************************************************
     Retrieve a remote file's contents into a local file.
     
     Calling this function will change the current data transfer format.
     
     Params:
     path =            the path to the remote file
     stream =          stream to write the data to
     progress =        a delegate to call with progress information
     format =          what format to read the data in
     ***********************************************************************************/
    public void get(char[] path, OutputStream stream,
            FtpProgress progress = null, FtpFormat format = FtpFormat.image)
    in {
        assert(path.length > 0);
        assert(stream !is null);
    }
    body {
        // Change to the specified format.
        this.type(format);

        // Okay server, we want to get this file...
        Socket data = this.processDataCommand("RETR", path);

        // Read the stream in from the socket!
        this.readStream(data, stream, progress);

        this.finishDataCommand(data);
    }

    /*****************************************************************************
     Added Since: 0.99.8
     *****************************************************************************/
    public InputStream input(char[] path) {
        type(FtpFormat.image);
        dataSocket_ = this.processDataCommand("RETR", path);
        return dataSocket_;
    }

    /*****************************************************************************
     Added Since: 0.99.8
     *****************************************************************************/
    public OutputStream output(char[] path) {
        type(FtpFormat.image); 
        dataSocket_ = this.processDataCommand("STOR", path);
        return dataSocket_;
    }
}
