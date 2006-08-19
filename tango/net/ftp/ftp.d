module tango.net.ftp.ftp;

private import tango.net.ftp.telnet;

private import std.socket, std.date;
private import std.stdio, std.stream, std.file, std.cstream;
private import std.regexp, std.string, std.conv;

/// An FTP progress delegate.
///
/// You may need to add the restart position to this, and use SIZE to determine
/// percentage completion.  This only represents the number of bytes
/// transferred.
///
/// Params:
///    pos =                 the current offset into the stream
alias void delegate(in size_t pos) ftp_progress_dg;

/// The format of data transfer.
enum ftp_format
{
	/// Indicates ASCII NON PRINT format (line ending conversion to CRLF.)
	ascii,
	/// Indicates IMAGE format (8 bit binary octets.)
	image,
}

/// A server response, consisting of a code and a potentially multi-line message.
struct ftp_response
{
	/// The response code.
	///
	/// The digits in the response code can be used to determine status
	/// programatically.
	///
	/// First Digit (status):
	///    1xx =             a positive, but preliminary, reply
	///    2xx =             a positive reply indicating completion
	///    3xx =             a positive reply indicating incomplete status
	///    4xx =             a temporary negative reply
	///    5xx =             a permanent negative reply
	///
	/// Second Digit (subject):
	///    x0x =             condition based on syntax
	///    x1x =             informational
	///    x2x =             connection
	///    x3x =             authentication/process
	///    x5x =             file system
	char[3] code = "000";

	/// The message from the server.
	///
	/// With some responses, the message may contain parseable information.
	/// For example, this is true of the 257 response.
	char[] message = null;
}

/// Active or passive connection mode.
enum ftp_connection_type
{
	/// Active - server connects to client on open port.
	active,
	/// Passive - server listens for a connection from the client.
	passive,
}

/// Detail about the data connection.
///
/// This is used to properly send PORT and PASV commands.
struct ftp_connection_detail
{
	/// The type to be used.
	ftp_connection_type type = ftp_connection_type.passive;

	/// The address to give the server.
	Address address = null;

	/// The address to actually listen on.
	Address listen = null;
}

/// A supported feature of an FTP server.
struct ftp_feature
{
	/// The command which is supported, e.g. SIZE.
	char[] command = null;
	/// Parameters for this command; e.g. facts for MLST.
	char[] params = null;
}

/// The type of a file in an FTP listing.
enum ftp_file_type
{
	/// An unknown file or type (no type fact.)
	unknown,
	/// A regular file, or similar.
	file,
	/// The current directory (e.g. ., but not necessarily.)
	cdir,
	/// A parent directory (usually "..".)
	pdir,
	/// Any other type of directory.
	dir,
	/// Another type of file.  Consult the "type" fact.
	other,
}

/// Information about a file in an FTP listing.
struct ftp_file_info
{
	/// The filename.
	char[] name = null;
	/// Its type.
	ftp_file_type type = ftp_file_type.unknown;
	/// Size in bytes (8 bit octets), or -1 if not available.
	long size = -1;
	/// Modification time, if available.
	d_time modify = d_time_nan;
	/// Creation time, if available (not often.)
	d_time create = d_time_nan;
	/// The file's mime type, if known.
	char[] mime = null;
	/// An associative array of all facts returned by the server, lowercased.
	char[][char[]] facts;
}

/// A connection to an FTP server.
///
/// Example:
/// ----------
/// auto ftp = new FTPConnection("hostname", 21, "user", "pass");
///
/// ftp.mkdir("test");
/// ftp.close();
/// ----------
///
/// Standards:               RFC 959, RFC 2228, RFC 2389, RFC 2428
///
/// Bugs:
///    Does not support several uncommon FTP commands and responses.
class FTPConnection
{
	/// The control connection socket.
	public Socket socket = null;

	/// The number of seconds to wait for socket communication or connection.
	public float timeout = 30.0;

	/// Supported features (if known.)
	///
	/// This will be empty if not known, or else contain at least FEAT.
	public ftp_feature[] supported_features = null;

	/// Data connection information.
	protected ftp_connection_detail data_info;

	/// The last-set restart position.
	///
	/// This is only used when a local file is used for a RETR or STOR.
	protected size_t restart_pos = 0;

	/// Construct an FTPConnection without connecting immediately.
	public this()
	{
	}

	/// Connect to an FTP server with a username and password.
	///
	/// Params:
	///    hostname =        the hostname or IP address to connect to
	///    port =            the port number to connect to
	///    username =        username to be sent
	///    password =        password to be sent, if requested
	public this(char[] hostname, int port, char[] username, char[] password)
	{
		this.connect(hostname, port, username, password);
	}

	/// Connect to an FTP server with a username and password.
	///
	/// Params:
	///    hostname =        the hostname or IP address to connect to
	///    port =            the port number to connect to
	///    username =        username to be sent
	///    password =        password to be sent, if requested
	public void connect(char[] hostname, int port, char[] username, char[] password)
	in
	{
		// We definitely need a hostname and port.
		assert (hostname.length > 0);
		assert (port > 0);
	}
	body
	{
		// Close any active connection.
		if (this.socket !is null)
			this.close();

		// Connect to whichever FTP server responds first.
		this.find_available_server(hostname, port);
		this.socket.blocking = false;

		scope (failure)
			this.close();

		// The welcome message should always be a 220.  120 and 421 are considered errors.
		this.read_response("220");

		if (username.length == 0)
			return;

		// Send the username.  Anything but 230, 331, or 332 is basically an error.
		this.send_command("USER", username);
		auto response = this.read_response();

		// 331 means username okay, please proceed with password.
		if (response.code == "331")
		{
			this.send_command("PASS", password);
			response = this.read_response();
		}

		// We don't support ACCT (332) so we should get a 230 here.
		if (response.code != "230" && response.code != "202")
			throw new FTPException(response);
	}

	/// Close the connection to the server.
	public void close()
	{
		assert (this.socket !is null);

		// Don't even try to close it if it's not open.
		if (this.socket !is null)
		{
			try
			{
				this.send_command("QUIT");
				this.read_response("221");
			}
			// Ignore if the above could not be completed.
			catch (FTPException)
			{
			}

			// Shutdown the socket...
			this.socket.shutdown(SocketShutdown.BOTH);
			this.socket.close();

			// Clear out everything.
			delete this.supported_features;
			delete this.socket;
		}
	}

	/// Set the connection to use passive mode for data tranfers.
	///
	/// This is the default.
	public void set_passive()
	{
		this.data_info.type = ftp_connection_type.passive;

		delete this.data_info.address;
		delete this.data_info.listen;
	}

	/// Set the connection to use active mode for data transfers.
	///
	/// This may not work behind firewalls.
	///
	/// Params:
	///    ip =              the ip address to use
	///    port =            the port to use
	///    listen_ip =       the ip to listen on, or null for any
	///    listen_port =     the port to listen on, or 0 for the same port
	public void set_active(char[] ip, ushort port, char[] listen_ip = null, ushort listen_port = 0)
	in
	{
		assert (ip.length > 0);
		assert (port > 0);
	}
	body
	{
		this.data_info.type = ftp_connection_type.active;
		this.data_info.address = new InternetAddress(ip, port);

		// A local-side port?
		if (listen_port == 0)
			listen_port = port;

		// Any specific IP to listen on?
		if (listen_ip == null)
			this.data_info.listen = new InternetAddress(InternetAddress.ADDR_ANY, listen_port);
		else
			this.data_info.listen = new InternetAddress(listen_ip, listen_port);
	}


	/// Change to the specified directory.
	public void chdir(char[] dir)
	in
	{
		assert (dir.length > 0);
	}
	body
	{
		this.send_command("CWD", dir);
		this.read_response("250");
	}

	/// Change to the parent of this directory.
	public void cdup()
	{
		this.send_command("CDUP");
		this.read_response("200");
	}

	/// Determine the current directory.
	///
	/// Returns:             the current working directory
	public char[] getcwd()
	{
		this.send_command("PWD");
		auto response = this.read_response("257");

		return this.parse_257(response);
	}

	/// Change the permissions of a file.
	///
	/// This is a popular feature of most FTP servers, but not explicitly outlined
	/// in the spec.  It does not work on, for example, Windows servers.
	///
	/// Params:
	///    path =            the path to the file to chmod
	///    mode =            the desired mode; expected in octal (0777, 0644, etc.)
	public void chmod(char[] path, int mode)
	in
	{
		assert (path.length > 0);
		assert (mode >= 0 && (mode >> 16) == 0);
	}
	body
	{
		// Convert our octal parameter to a string.
		this.send_command("SITE CHMOD", format("%03s", std.string.toUtf8(cast(long) mode, 8u)), path);
		this.read_response("200");
	}

	/// Remove a file or directory.
	///
	/// Params:
	///    path =            the path to the file or directory to delete
	public void unlink(char[] path)
	in
	{
		assert (path.length > 0);
	}
	body
	{
		this.send_command("DELE", path);
		auto response = this.read_response();

		// Try it as a directory, then...?
		if (response.code != "250")
			this.rmdir(path);
	}

	/// Remove a directory.
	///
	/// Params:
	///    path =            the directory to delete
	public void rmdir(char[] path)
	in
	{
		assert (path.length > 0);
	}
	body
	{
		this.send_command("RMD", path);
		this.read_response("250");
	}

	/// Rename/move a file or directory.
	///
	/// Params:
	///    old_path =        the current path to the file
	///    new_path =        the new desired path
	public void rename(char[] old_path, char[] new_path)
	in
	{
		assert (old_path.length > 0);
		assert (new_path.length > 0);
	}
	body
	{
		// Rename from... rename to.  Pretty simple.
		this.send_command("RNFR", old_path);
		this.read_response("350");

		this.send_command("RNTO", new_path);
		this.read_response("250");
	}

	/// Determine the size in bytes of a file.
	///
	/// This size is dependent on the current type (ASCII or IMAGE.)
	///
	/// Params:
	///    path =            the file to retrieve the size of
	///    format =          what format the size is desired in
	public size_t size(char[] path, ftp_format format = ftp_format.image)
	in
	{
		assert (path.length > 0);
	}
	body
	{
		this.type(format);

		this.send_command("SIZE", path);
		auto response = this.read_response("213");

		// Only try to parse the numeric bytes of the response.
		size_t end_pos = 0;
		while (end_pos < response.message.length)
		{
			if (response.message[end_pos] < '0' || response.message[end_pos] > '9')
				break;
			end_pos++;
		}

		return toInt(response.message[0 .. end_pos]);
	}

	/// Send a command and process the data socket.
	///
	/// This opens the data connection and checks for the appropriate response.
	///
	/// Params:
	///    command =         the command to send (e.g. STOR)
	///    parameters =      any arguments to send
	///
	/// Returns:             the data socket
	public Socket process_data_command(char[] command, char[][] parameters ...)
	{
		// Create a connection.
		Socket data = this.get_data_socket();
		scope (failure)
		{
			// Close the socket, whether we were listening or not.
			data.shutdown(SocketShutdown.BOTH);
			data.close();
		}

		// Tell the server about it.
		this.send_command(command, parameters);

		// We should always get a 150/125 response.
		auto response = this.read_response();
		if (response.code != "150" && response.code != "125")
			throw new FTPException(response);

		// We might need to do this for active connections.
		this.prepare_data_socket(data);

		return data;
	}

	/// Clean up after the data socket and process the response.
	///
	/// This closes the socket and reads the 226 response.
	///
	/// Params:
	///    data =            the data socket
	public void finish_data_command(Socket data)
	{
		// Close the socket.  This tells the server we're done (EOF.)
		data.shutdown(SocketShutdown.BOTH);
		data.close();

		// We shouldn't get a 250 in STREAM mode.
		this.read_response("226");
	}

	/// Get a data socket from the server.
	///
	/// This sends PASV/PORT as necessary.
	///
	/// Returns:             the data socket or a listener
	protected Socket get_data_socket()
	{
		// What type are we using?
		switch (this.data_info.type)
		{
		// Passive is complicated.  Handle it in another member.
		case ftp_connection_type.passive:
			return this.connect_passive();

		// Active is simpler, but not as fool-proof.
		case ftp_connection_type.active:
			InternetAddress data_addr = cast(InternetAddress) this.data_info.address;

			// Start listening.
			Socket listener = new TcpSocket();
			listener.bind(this.data_info.listen);
			listener.listen(32);

			// Use EPRT if we know it's supported.
			if (this.is_supported("EPRT"))
			{
				this.send_command("EPRT", format("|1|%s|%s|", data_addr.toAddrString(), data_addr.toPortString()));
				this.read_response("200");
			}
			else
			{
				ushort h1, h2, h3, h4, p1, p2;
				h1 = (data_addr.addr() >> 24) % 256;
				h2 = (data_addr.addr() >> 16) % 256;
				h3 = (data_addr.addr() >> 8_) % 256;
				h4 = (data_addr.addr() >> 0_) % 256;
				p1 = (data_addr.port() >> 8_) % 256;
				p2 = (data_addr.port() >> 0_) % 256;

				// This formatting is weird.
				this.send_command("PORT", format("%d,%d,%d,%d,%d,%d", h1, h2, h3, h4, p1, p2));
				this.read_response("200");
			}

			return listener;
		}
	}

	/// Prepare a data socket for use.
	///
	/// This modifies the socket in some cases.
	///
	/// Params:
	///    data =            the data listener socket
	protected void prepare_data_socket(inout Socket data)
	{
		switch (this.data_info.type)
		{
		case ftp_connection_type.active:
			Socket new_data = null;

			SocketSet set = new SocketSet();
			scope (exit)
				delete set;

			// At end_time, we bail.
			d_time end_time = getUTCtime() + cast(d_time) (this.timeout * TicksPerSecond);

			while (getUTCtime() < end_time)
			{
				set.reset();
				set.add(data);

				// Can we accept yet?
				int code = Socket.select(set, null, null, cast(int) (this.timeout * 1_000_000));
				if (code == -1 || code == 0)
					break;

				new_data = data.accept();
				break;
			}

			if (new_data is null)
				throw new FTPException("CLIENT: No connection from server", "420");

			// We don't need the listener anymore.
			data.shutdown(SocketShutdown.BOTH);
			data.close();

			// This is the actual socket.
			data = new_data;
			break;

		case ftp_connection_type.passive:
			break;
		}
	}

	/// Send a PASV and initiate a connection.
	///
	/// Returns:             a connected socket
	public Socket connect_passive()
	{
		Address connect_to = null;

		// SPSV, which is just a port number.
		if (this.is_supported("SPSV"))
		{
			this.send_command("SPSV");
			auto response = this.read_response("227");

			// Connecting to the same host.
			InternetAddress remote = cast(InternetAddress) this.socket.remoteAddress();
			assert (remote !is null);

			uint address = remote.addr();
			uint port = toInt(response.message);

			connect_to = new InternetAddress(address, port);
		}
		// Extended passive mode (IP v6, etc.)
		else if (this.is_supported("EPSV"))
		{
			this.send_command("EPSV");
			auto response = this.read_response("229");

			// Try to pull out the (possibly not parenthesized) address.
			auto r = std.regexp.search(response.message, `\([^0-9][^0-9][^0-9](\d+)[^0-9]\)`);
			if (r is null)
				throw new FTPException("CLIENT: Unable to parse address", "501");

			InternetAddress remote = cast(InternetAddress) this.socket.remoteAddress();
			assert (remote !is null);

			uint address = remote.addr();
			uint port = toInt(r.match(1));

			connect_to = new InternetAddress(address, port);
		}
		else
		{
			this.send_command("PASV");
			auto response = this.read_response("227");

			// Try to pull out the (possibly not parenthesized) address.
			auto r = std.regexp.search(response.message, `(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)(,\s*(\d+))?`);
			if (r is null)
				throw new FTPException("CLIENT: Unable to parse address", "501");

			// Now put it into something std.socket will understand.
			char[] address = format("%s.%s.%s.%s", r.match(1), r.match(2), r.match(3), r.match(4));
			uint port = (toInt(r.match(5)) << 8) + (r.match(7).length > 0 ? toInt(r.match(7)) : 0);

			// Okay, we've got it!
			connect_to = new InternetAddress(address, port);
		}

		scope (exit)
			delete connect_to;

		debug (ftp_connection)
			writefln("[FTP]     (Connecting to %s)", connect_to.toUtf8());

		// This will throw an exception if it cannot connect.
		return new TcpSocket(connect_to);
	}

	/// Change the type of data transfer.
	///
	/// ASCII mode implies that line ending conversion should be made.
	/// Only NON PRINT is supported.
	///
	/// Params:
	///    type =            ftp_format.ascii or ftp_format.image
	public void type(ftp_format format)
	{
		if (format == ftp_format.ascii)
			this.send_command("TYPE", "A");
		else
			this.send_command("TYPE", "I");

		this.read_response("200");
	}

	/// Store a local file on the server.
	///
	/// Calling this function will change the current data transfer format.
	///
	/// Params:
	///    path =            the path to the remote file
	///    local_file =      the path to the local file
	///    progress =        a delegate to call with progress information
	///    format =          what format to send the data in
	public void store_file(char[] path, char[] local_file, ftp_progress_dg progress = null, ftp_format format = ftp_format.image)
	in
	{
		assert (path.length > 0);
		assert (local_file.length > 0);
	}
	body
	{
		// Open the file for reading...
		BufferedFile file = new BufferedFile(local_file, FileMode.In);
		scope (exit)
		{
			file.close();
			delete file;
		}

		// Seek to the correct place, if specified.
		if (this.restart_pos > 0)
		{
			file.seekSet(this.restart_pos);
			this.restart_pos = 0;
		}
		else
		{
			// Allocate space for the file, if we need to.
			this.allocate(std.file.getSize(local_file));
		}

		// Now that it's open, we do what we always do.
		this.store_file(path, file, progress, format);
	}

	/// Store data from a stream on the server.
	///
	/// Calling this function will change the current data transfer format.
	///
	/// Params:
	///    path =            the path to the remote file
	///    stream =          data to store, or null for a blank file
	///    progress =        a delegate to call with progress information
	///    format =          what format to send the data in
	public void store_file(char[] path, Stream stream = null, ftp_progress_dg progress = null, ftp_format format = ftp_format.image)
	in
	{
		assert (path.length > 0);
	}
	body
	{
		// Change to the specified format.
		this.type(format);

		// Okay server, we want to store something...
		Socket data = this.process_data_command("STOR", path);

		// Send the stream over the socket!
		if (stream !is null)
			this.send_stream(data, stream, progress);

		this.finish_data_command(data);
	}

	/// Append data to a file on the server.
	///
	/// Calling this function will change the current data transfer format.
	///
	/// Params:
	///    path =            the path to the remote file
	///    stream =          data to append to the file
	///    progress =        a delegate to call with progress information
	///    format =          what format to send the data in
	public void append(char[] path, Stream stream, ftp_progress_dg progress = null, ftp_format format = ftp_format.image)
	in
	{
		assert (path.length > 0);
		assert (stream !is null);
	}
	body
	{
		// Change to the specified format.
		this.type(format);

		// Okay server, we want to store something...
		Socket data = this.process_data_command("APPE", path);

		// Send the stream over the socket!
		this.send_stream(data, stream, progress);

		this.finish_data_command(data);
	}

	/// Seek to a byte offset for the next transfer.
	///
	/// Params:
	///    offset =          the number of bytes to seek forward
	public void restart_seek(size_t offset)
	{
		this.send_command("REST", std.string.toUtf8(offset));
		this.read_response("350");

		// Set this for later use.
		this.restart_pos = offset;
	}

	/// Allocate space for a file.
	///
	/// After calling this, append() or store_file() should be the next command.
	///
	/// Params:
	///    bytes =           the number of bytes to allocate
	public void allocate(size_t bytes)
	in
	{
		assert (bytes > 0);
	}
	body
	{
		this.send_command("ALLO", std.string.toUtf8(bytes));
		auto response = this.read_response();

		// For our purposes 200 and 202 are both fine.
		if (response.code != "200" && response.code != "202")
			throw new FTPException(response);
	}

	/// Retrieve a remote file's contents into a local file.
	///
	/// Calling this function will change the current data transfer format.
	///
	/// Params:
	///    path =            the path to the remote file
	///    local_file =      the path to the local file
	///    progress =        a delegate to call with progress information
	///    format =          what format to read the data in
	public void retrieve_file(char[] path, char[] local_file, ftp_progress_dg progress = null, ftp_format format = ftp_format.image)
	in
	{
		assert (path.length > 0);
		assert (local_file.length > 0);
	}
	body
	{
		BufferedFile file = null;

		// We may either create a new file...
		if (this.restart_pos == 0)
			file = new BufferedFile(local_file, FileMode.OutNew);
		// Or open an existing file, and seek to the specified position (read: not end, necessarily.)
		else
		{
			file = new BufferedFile(local_file, FileMode.Out);
			file.seekSet(this.restart_pos);

			this.restart_pos = 0;
		}

		scope (exit)
		{
			file.close();
			delete file;
		}

		// Now that it's open, we do what we always do.
		this.retrieve_file(path, file, progress, format);
	}

	/// Retrieve a remote file's contents into a local file.
	///
	/// Calling this function will change the current data transfer format.
	///
	/// Params:
	///    path =            the path to the remote file
	///    stream =          stream to write the data to
	///    progress =        a delegate to call with progress information
	///    format =          what format to read the data in
	public void retrieve_file(char[] path, Stream stream, ftp_progress_dg progress = null, ftp_format format = ftp_format.image)
	in
	{
		assert (path.length > 0);
		assert (stream !is null);
	}
	body
	{
		// Change to the specified format.
		this.type(format);

		// Okay server, we want to get this file...
		Socket data = this.process_data_command("RETR", path);

		// Read the stream in from the socket!
		this.read_stream(data, stream, progress);

		this.finish_data_command(data);
	}

	/// Get information about a single file.
	///
	/// Return an ftp_file_info struct about the specified path.
	/// This may not work consistently on directories (but should.)
	///
	/// Params:
	///    path =            the file or directory to get information about
	///
	/// Returns:             the file information
	public ftp_file_info get_file_info(char[] path)
	in
	{
		assert (path.length > 0);
	}
	body
	{
		// Start assuming the MLST didn't work.
		bool mlst_success = false;
		ftp_response response;

		// Check if MLST might be supported...
		if (this.maybe_supported("MLST"))
		{
			this.send_command("MLST", path);
			response = this.read_response();

			// If we know it was supported for sure, this is an error.
			if (this.is_supported("MLST"))
				throw new FTPException(response);
			// Otherwise, it probably means we need to try a LIST.
			else
				mlst_success = response.code == "250";
		}

		// Okay, we got the MLST response... parse it.
		if (mlst_success)
		{
			char[][] lines = splitlines(response.message);

			// We need at least 3 lines - first and last and header/footer lines.
			// Note that more than 3 could be returned; e.g. multiple lines about the one file.
			if (lines.length <= 2)
				throw new FTPException("CLIENT: Bad MLST response from server", "501");

			// Return the first line's information.
			return parse_mlst_line(lines[1]);
		}
		else
		{
			// Send a list command.  This may list the contents of a directory, even.
			ftp_file_info[] temp = this.send_list_command(path);

			// If there wasn't at least one line, the file didn't exist?
			// We should have already handled that.
			if (temp.length < 1)
				throw new FTPException("CLIENT: Bad LIST response from server", "501");

			// If there are multiple lines, try to return the correct one.
			if (temp.length != 1)
				foreach (ftp_file_info info; temp)
				{
					if (info.type == ftp_file_type.cdir)
						return info;
				}

			// Okay then, the first line.  Best we can do?
			return temp[0];
		}
	}

	/// Get a listing of a directory's contents.
	///
	/// Don't end path in a /.  Blank means the current directory.
	///
	/// Params:
	///    path =            the directory to list
	///
	/// Returns:             an array of the contents
	public ftp_file_info[] get_dir_contents(char[] path)
	in
	{
		assert (path.length == 0 || path[path.length - 1] != '/');
	}
	body
	{
		ftp_file_info[] dir;

		// We'll try MLSD (which is so much better) first... but it may fail.
		bool mlsd_success = false;
		Socket data = null;

		// Try it if it could/might/maybe is supported.
		if (this.maybe_supported("MLST"))
		{
			mlsd_success = true;

			// Since this is a data command, process_data_command handles
			// checking the response... just catch its Exception.
			try
			{
				if (path.length > 0)
					data = this.process_data_command("MLSD", path);
				else
					data = this.process_data_command("MLSD");
			}
			catch (FTPException)
				mlsd_success = false;
		}

		// If it passed, parse away!
		if (mlsd_success)
		{
			MemoryStream listing = new MemoryStream();
			this.read_stream(data, listing);
			this.finish_data_command(data);

			// Each line is something in that directory.
			char[][] lines = splitlines(cast(char[]) listing.data());
			scope (exit)
				delete lines;

			foreach (char[] line; lines)
			{
				// Parse each line exactly like MLST does.
				ftp_file_info info = this.parse_mlst_line(line);
				if (info.name.length > 0)
					dir ~= info;
			}

			return dir;
		}
		// Fall back to LIST.
		else
			return this.send_list_command(path);
	}

	/// Send a LIST command to determine a directory's content.
	///
	/// The format of a LIST response is not guaranteed.  If available,
	/// MLSD should be used instead.
	///
	/// Params:
	///    path =            the file or directory to list
	///
	/// Returns:             an array of the contents
	protected ftp_file_info[] send_list_command(char[] path)
	{
		ftp_file_info[] dir;
		Socket data = null;

		if (path.length > 0)
			data = this.process_data_command("LIST", path);
		else
			data = this.process_data_command("LIST");

		// Read in the stupid non-standardized response.
		MemoryStream listing = new MemoryStream();
		this.read_stream(data, listing);
		this.finish_data_command(data);

		// Split out the lines.  Most of the time, it's one-to-one.
		char[][] lines = splitlines(cast(char[]) listing.data());
		scope (exit)
			delete lines;

		foreach (char[] line; lines)
		{
			// If there are no spaces, or if there's only one... skip the line.
			// This is probably like a "total 8" line.
			if (std.string.find(line, ' ') == std.string.rfind(line, ' '))
				continue;

			// Now parse the line, or try to.
			ftp_file_info info = this.parse_list_line(line);
			if (info.name.length > 0)
				dir ~= info;
		}

		return dir;
	}

	/// Parse a LIST response line.
	///
	/// The format here isn't even specified, so we have to try to detect
	/// commmon ones.
	///
	/// Params:
	///    line =            the line to parse
	///
	/// Returns:             information about the file
	protected ftp_file_info parse_list_line(char[] line)
	{
		ftp_file_info info;
		size_t pos = 0;

		// Convenience function to parse a word from the line.
		char[] parse_word()
		{
			size_t start = 0, end = 0;

			// Skip whitespace before.
			while (pos < line.length && line[pos] == ' ')
				pos++;

			start = pos;
			while (pos < line.length && line[pos] != ' ')
				pos++;
			end = pos;

			// Skip whitespace after.
			while (pos < line.length && line[pos] == ' ')
				pos++;

			return line[start .. end];
		}

		// We have to sniff this... :/.
		switch (std.string.find(std.string.digits, line[0]) == -1)
		{
		// Not a number; this is UNIX format.
		case true:
			// The line must be at least 20 characters long.
			if (line.length < 20)
				return info;

			// The first character tells us what it is.
			if (line[0] == 'd')
				info.type = ftp_file_type.dir;
			else if (line[0] == '-')
				info.type = ftp_file_type.file;
			else
				info.type = ftp_file_type.unknown;

			// Parse out the mode... rwxrwxrwx = 777.
			char[] unix_mode = "0000".dup;
			void read_mode(int digit)
			{
				for (pos = 1 + digit * 3; pos <= 3 + digit * 3; pos++)
				{
					if (line[pos] == 'r')
						unix_mode[digit + 1] |= 4;
					else if (line[pos] == 'w')
						unix_mode[digit + 1] |= 2;
					else if (line[pos] == 'x')
						unix_mode[digit + 1] |= 1;
				}
			}

			// This makes it easier, huh?
			read_mode(0);
			read_mode(1);
			read_mode(2);

			info.facts["UNIX.mode"] = unix_mode;

			// Links, owner, group.  These are hard to translate to MLST facts.
			parse_word();
			parse_word();
			parse_word();

			// Size in bytes, this one is good.
			info.size = toLong(parse_word());

			// Make sure we still have enough space.
			if (pos + 13 >= line.length)
				return info;

			// Not parsing date for now.  It's too weird (last 12 months, etc.)
			pos += 13;

			info.name = line[pos .. line.length];
			break;

		// A number; this is DOS format.
		case false:
			// We need some data here, to parse.
			if (line.length < 18)
				return info;

			// The order is 1 MM, 2 DD, 3 YY, 4 HH, 5 MM, 6 P
			auto r = std.regexp.search(line, `(\d\d)-(\d\d)-(\d\d)\s+(\d\d):(\d\d)(A|P)M`);
			if (r is null)
				return info;

			d_time t, d;
			try
			{
				int hour = toInt(r.match(4)) + (r.match(6) == "P" ? 12 : 0);
				int year = toInt(r.match(3));

				// This is not Y2K70 compliant!  Neither is the DOS listing!
				if (year < 70)
					year += 2000;
				else if (year < 100)
					year += 1900;

				t = MakeTime(hour, toInt(r.match(5)), 0, 0);
				d = MakeDay(year, toInt(r.match(1)) - 1, toInt(r.match(2)));

				info.modify = TimeClip(MakeDate(d, t));
			}
			catch
			{
				info.modify = d_time_nan;
			}

			pos = r.match(0).length;
			delete r;

			// This will either be <DIR>, or a number.
			char[] dir_or_size = parse_word();

			if (dir_or_size.length < 0)
				return info;
			else if (dir_or_size[0] == '<')
				info.type = ftp_file_type.dir;
			else
				info.size = toLong(dir_or_size);

			info.name = line[pos .. line.length];
			break;

		// Something else, not supported.
		default:
			throw new FTPException("CLIENT: Unsupported LIST format", "501");
		}

		// Try to fix the type?
		if (info.name == ".")
			info.type = ftp_file_type.cdir;
		else if (info.name == "..")
			info.type = ftp_file_type.pdir;

		return info;
	}

	/// Parse an MLST/MLSD response line.
	///
	/// The format here is very rigid, and has facts followed by a filename.
	///
	/// Params:
	///    line =            the line to parse
	///
	/// Returns:             information about the file
	protected ftp_file_info parse_mlst_line(char[] line)
	{
		ftp_file_info info;

		// After this loop, filename_pos will be location of space + 1.
		size_t filename_pos = 0;
		while (filename_pos < line.length && line[filename_pos++] != ' ')
			continue;

		if (filename_pos == line.length)
			throw new FTPException("CLIENT: Bad syntax in MLSx response", "501");

		info.name = line[filename_pos .. line.length];

		// Everything else is frosting on top.
		if (filename_pos > 1)
		{
			char[][] temp_facts = std.string.split(line[0 .. filename_pos - 1], ";");

			// Go through each fact and parse them into the array.
			foreach (char[] fact; temp_facts)
			{
				int pos = std.string.find(fact, '=');
				if (pos == -1)
					continue;

				info.facts[tolower(fact[0 .. pos])] = fact[pos + 1 .. fact.length];
			}

			// Do we have a type?
			if ("type" in info.facts)
			{
				// Some reflection might be nice here.
				switch (tolower(info.facts["type"]))
				{
				case "file":
					info.type = ftp_file_type.file;
					break;

				case "cdir":
					info.type = ftp_file_type.cdir;
					break;

				case "pdir":
					info.type = ftp_file_type.pdir;
					break;

				case "dir":
					info.type = ftp_file_type.dir;
					break;

				default:
					info.type = ftp_file_type.other;
				}
			}

			// Size, mime, etc...
			if ("size" in info.facts)
				info.size = toLong(info.facts["size"]);
			if ("media-type" in info.facts)
				info.mime = info.facts["media-type"];

			// And the two dates.
			if ("modify" in info.facts)
				info.modify = this.parse_timeval(info.facts["modify"]);
			if ("create" in info.facts)
				info.create = this.parse_timeval(info.facts["create"]);
		}

		return info;
	}

	/// Parse a timeval from an FTP response.
	///
	/// This is basically an ISO 8601 date, but even more rigid.
	///
	/// Params:
	///    timeval =         the YYYYMMDDHHMMSS date
	///
	/// Returns:             a d_time representing the same date
	protected d_time parse_timeval(char[] timeval)
	{
		// The order is 1 YYYY, 2 MM, 3 DD, 4 HH, 5 MM, 6 SS.
		auto r = std.regexp.search(timeval, `^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$`);
		if (r is null)
			throw new FTPException("CLIENT: Unable to parse timeval", "501");

		d_time t, d;
		try
		{
			// Attempt to slap these together...
			t = MakeTime(toInt(r.match(4)), toInt(r.match(5)), toInt(r.match(6)), 0);
			d = MakeDay(toInt(r.match(1)), toInt(r.match(2)) - 1, toInt(r.match(3)));

			t = TimeClip(MakeDate(d, t));
		}
		catch
		{
			// This might mean toInt() failed, or who knows.
			t = d_time_nan;
		}

		return t;
	}

	/// Get the modification time of a file.
	///
	/// Not supported by a lot of servers.
	///
	/// Params:
	///    path =            the file or directory in question
	///
	/// Returns:             a d_time representing the mtime
	public d_time filemtime(char[] path)
	in
	{
		assert (path.length > 0);
	}
	body
	{
		this.send_command("MDTM", path);
		auto response = this.read_response("213");

		// The whole response should be a timeval.
		return this.parse_timeval(response.message);
	}

	/// Create a directory.
	///
	/// Depending on server model, a cwd with the same path may not work.
	/// Use the return value instead to escape this problem.
	///
	/// Params:
	///    path =            the directory to create
	///
	/// Returns:             the path to the directory created
	public char[] mkdir(char[] path)
	in
	{
		assert (path.length > 0);
	}
	body
	{
		this.send_command("MKD", path);
		auto response = this.read_response("257");

		return this.parse_257(response);
	}

	/// Get supported features from the server.
	///
	/// This may not be supported, in which case the list will remain empty.
	/// Otherwise, it will contain at least FEAT.
	public void get_features()
	{
		this.send_command("FEAT");
		auto response = this.read_response();

		// 221 means FEAT is supported, and a list follows.  Otherwise we don't know...
		if (response.code != "211")
			delete this.supported_features;
		else
		{
			char[][] lines = splitlines(response.message);

			// There are two more lines than features, but we also have FEAT.
			this.supported_features = new ftp_feature[lines.length - 1];
			this.supported_features[0].command = "FEAT";

			for (size_t i = 1; i < lines.length - 1; i++)
			{
				size_t pos = std.string.find(lines[i], ' ');
				if (pos == -1)
					pos = lines[i].length;

				this.supported_features[i].command = lines[i][0 .. pos];
				if (pos < lines[i].length - 1)
					this.supported_features[i].params = lines[i][pos + 1 .. lines[i].length];
			}

			delete lines;
		}
	}

	/// Check if a specific feature might be supported.
	///
	/// Example:
	/// ----------
	/// if (ftp.maybe_supported("SIZE"))
	///     size = ftp.size("example.txt");
	/// ----------
	///
	/// Params:
	///    command =         the command in question
	public bool maybe_supported(char[] command)
	in
	{
		assert (command.length > 0);
	}
	body
	{
		if (this.supported_features.length == 0)
			return true;

		// Search through the list for the feature.
		foreach (ftp_feature feat; this.supported_features)
		{
			if (std.string.icmp(feat.command, command) == 0)
				return true;
		}

		return false;
	}

	/// Check if a specific feature is known to be supported.
	///
	/// Example:
	/// ----------
	/// if (ftp.is_supported("SIZE"))
	///     size = ftp.size("example.txt");
	/// ----------
	///
	/// Params:
	///    command =         the command in question
	public bool is_supported(char[] command)
	{
		if (this.supported_features.length == 0)
			return false;

		return this.maybe_supported(command);
	}

	/// Send a site-specific command.
	///
	/// The command might be WHO, for example, returning a list of users online.
	/// These are typically heavily server-specific.
	///
	/// Params:
	///    command =         the command to send (after SITE)
	///    parameters =      any additional parameters to send
	///                      (each will be prefixed by a space)
	public ftp_response site_command(char[] command, char[][] parameters ...)
	in
	{
		assert (command.length > 0);
	}
	body
	{
		// Because of the way send_command() works, we have to tweak this a bit.
		char[][] temp_params = new char[][parameters.length + 1];
		temp_params[0] = command;
		temp_params[1 .. temp_params.length][] = parameters;

		this.send_command("SITE", temp_params);
		auto response = this.read_response();

		// Check to make sure it didn't fail.
		if (response.code[0] != '2')
			throw new FTPException(response);

		return response;
	}

	/// Send a NOOP, typically used to keep the connection alive.
	public void noop()
	{
		this.send_command("NOOP");
		this.read_response("200");
	}

	/// Send the stream to the server.
	///
	/// Params:
	///    data =            the socket to write to
	///    stream =          the stream to read from
	///    progress =        a delegate to call with progress information
	protected void send_stream(Socket data, Stream stream, ftp_progress_dg progress = null)
	in
	{
		assert (data !is null);
		assert (stream !is null);
	}
	body
	{
		// Set up a SocketSet so we can use select() - it's pretty efficient.
		SocketSet set = new SocketSet();
		scope (exit)
			delete set;

		// At end_time, we bail.
		d_time end_time = getUTCtime() + cast(d_time) (this.timeout * TicksPerSecond);

		// This is the buffer the stream data is stored in.
		ubyte[16384] buf;
		size_t buf_size = 0, buf_pos = 0;
		int delta = 0;

		size_t pos = 0;
		while (!stream.eof() && getUTCtime() < end_time)
		{
			set.reset();
			set.add(data);

			// Can we write yet, can we write yet?
			int code = Socket.select(null, set, null, cast(int) (this.timeout * 1_000_000));
			if (code == -1 || code == 0)
				break;

			if (buf_size - buf_pos <= 0)
			{
				buf_size = stream.read(buf);
				buf_pos = 0;
			}

			// Send the chunk (or as much of it as possible!)
			delta = data.send(buf[buf_pos .. buf_size]);
			if (delta == data.ERROR)
				break;

			buf_pos += delta;

			pos += delta;
			if (progress !is null)
				progress(pos);

			// Give it more time as long as data is going through.
			if (delta != 0)
				end_time = getUTCtime() + cast(d_time) (this.timeout * TicksPerSecond);
		}

		// Did all the data get sent?
		if (!stream.eof())
			throw new FTPException("CLIENT: Timeout when sending data", "420");
	}

	/// Reads from the server to a stream until EOF.
	///
	/// Params:
	///    data =            the socket to read from
	///    stream =          the stream to write to
	///    progress =        a delegate to call with progress information
	protected void read_stream(Socket data, Stream stream, ftp_progress_dg progress = null)
	in
	{
		assert (data !is null);
		assert (stream !is null);
	}
	body
	{
		// Set up a SocketSet so we can use select() - it's pretty efficient.
		SocketSet set = new SocketSet();
		scope (exit)
			delete set;

		// At end_time, we bail.
		d_time end_time = getUTCtime() + cast(d_time) (this.timeout * TicksPerSecond);

		// This is the buffer the stream data is stored in.
		ubyte[16384] buf;
		int buf_size = 0;

		bool completed = false;
		size_t pos;
		while (getUTCtime() < end_time)
		{
			set.reset();
			set.add(data);

			// Can we read yet, can we read yet?
			int code = Socket.select(set, null, null, cast(int) (this.timeout * 1_000_000));
			if (code == -1 || code == 0)
				break;

			buf_size = data.receive(buf);
			if (buf_size == data.ERROR)
				break;

			if (buf_size == 0)
			{
				completed = true;
				break;
			}

			stream.write(buf[0 .. buf_size]);

			pos += buf_size;
			if (progress !is null)
				progress(pos);

			// Give it more time as long as data is going through.
			end_time = getUTCtime() + cast(d_time) (this.timeout * TicksPerSecond);
		}

		// Did all the data get received?
		if (!completed)
			throw new FTPException("CLIENT: Timeout when reading data", "420");
	}

	/// Parse a 257 response (which begins with a quoted path.)
	///
	/// Params:
	///    response =        the response to parse
	///
	/// Returns:             the path in the response
	protected char[] parse_257(ftp_response response)
	{
		char[] path = new char[response.message.length];
		size_t pos = 1, len = 0;

		// Since it should be quoted, it has to be at least 3 characters in length.
		if (response.message.length <= 2)
			throw new FTPException(response);

		assert (response.message[0] == '"');

		// Trapse through the response...
		while (pos < response.message.length)
		{
			if (response.message[pos] == '"')
			{
				// An escaped quote, keep going.  False alarm.
				if (response.message[++pos] == '"')
					path[len++] = response.message[pos];
				else
					break;
			}
			else
				path[len++] = response.message[pos];

			pos++;
		}

		// Okay, done!  That wasn't too hard.
		path.length = len;
		return path;
	}

	/// Send a command to the FTP server.
	///
	/// Does not get/wait for the response.
	///
	/// Params:
	///    command =         the command to send
	///    ... =             additional parameters to send (a space will be prepended to each)
	public void send_command(char[] command, char[][] parameters ...)
	{
		assert (this.socket !is null);

		// Write this out as a log?
		debug (ftp_connection)
		{
			writef("[FTP]     %s", command);
			foreach (char[] param; parameters)
				writef(" %s", param);
			writefln("");
		}

		// Send the command, parameters, and then a CRLF.
		this.socket_send(command);
		foreach (char[] param; parameters)
		{
			this.socket_send(" ");
			this.socket_send(param);
		}
		this.socket_send("\r\n");
	}

	/// Read in response lines from the server, expecting a certain code.
	///
	/// Params:
	///    expected_code =   the code expected from the server
	///
	/// Returns:             the response from the server
	///
	/// Throws:              FTPException if code does not match
	public ftp_response read_response(char[] expected_code)
	{
		auto response = this.read_response();

		if (response.code != expected_code)
			throw new FTPException(response);

		return response;
	}

	/// Read in the response line(s) from the server.
	///
	/// Returns:             the response from the server
	public ftp_response read_response()
	{
		assert (this.socket !is null);

		// Pick a time at which we stop reading.  It can't take too long, but it could take a bit for the whole response.
		d_time end_time = getUTCtime() + cast(d_time) (this.timeout * 10 * TicksPerSecond);

		ftp_response response;
		char[] single_line = null;

		// Danger, Will Robinson, don't fall into an endless loop from a malicious server.
		while (getUTCtime() < end_time)
		{
			single_line = this.socket_readline();

			debug (ftp_connection)
				writefln("[FTP] %s", single_line);

			// This is the first line.
			if (response.message.length == 0)
			{
				// The first line must have a code and then a space or hyphen.
				if (single_line.length <= 4)
				{
					response.code[] = "500";
					break;
				}

				// The code is the first three characters.
				response.code[] = single_line[0 .. 3];
				response.message = single_line[4 .. single_line.length];
			}
			// This is either an extra line, or the last line.
			else
			{
				response.message ~= "\n";

				// If the line starts like "123-", that is not part of the response message.
				if (single_line.length > 4 && single_line[0 .. 3] == response.code)
					response.message ~= single_line[4 .. single_line.length];
				// If it starts with a space, that isn't either.
				else if (single_line.length > 2 && single_line[0] == ' ')
					response.message ~= single_line[1 .. single_line.length];
				else
					response.message ~= single_line;
			}

			// We're done if the line starts like "123 ".  Otherwise we're not.
			if (single_line.length > 4 && single_line[0 .. 3] == response.code && single_line[3] == ' ')
				break;
		}

		return response;
	}

	mixin TelnetUtilities!(FTPException);
}

/// An exception caused by an unexpected FTP response.
///
/// Even after such an exception, the connection may be in a usable state.
/// Use the response code to determine more information about the error.
///
/// Standards:               RFC 959, RFC 2228, RFC 2389, RFC 2428
class FTPException: Exception
{
	/// The three byte response code.
	char[3] response_code = "000";

	/// Construct an FTPException based on a message and code.
	///
	/// Params:
	///    message =         the exception message
	///    code =            the code (5xx for fatal errors)
	this (char[] message, char[3] code = "420")
	{
		this.response_code[] = code;
		super(message);
	}

	/// Construct an FTPException based on a response.
	///
	/// Params:
	///    r =               the server response
	this (ftp_response r)
	{
		this.response_code[] = r.code;
		super(r.message);
	}

	/// A string representation of the error.
	char[] toUtf8()
	{
		char[] buffer = new char[this.msg.length + 4];

		buffer[0 .. 3] = this.response_code;
		buffer[3] = ' ';
		buffer[4 .. buffer.length] = this.msg;

		return buffer;
	}
}