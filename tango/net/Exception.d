
module tango.net.Exception;

private import tango.sys.Common;

private import tango.io.Exception;


/// Base exception thrown from a Socket.
class SocketException: IOException
{
        int errorCode; /// Platform-specific error code.
        
        
        this(char[] msg, int err = 0)
        {
                errorCode = err;
                
                if (errorCode > 0)
                    msg = msg ~ SysError.lookup (errorCode);
                
                super(msg);
        }
}

/**
 * Base exception thrown from an InternetHost.
 */
class HostException: IOException
{
        int errorCode;  /// Platform-specific error code.
        
        
        this(char[] msg, int err = 0)
        {
                errorCode = err;
                super(msg);
        }
}

/**
 * Base exception thrown from an Address.
 */
class AddressException: IOException
{
        this(char[] msg)
        {
                super(msg);
        }
}

/** */
class SocketAcceptException: SocketException
{
        this(char[] msg, int err = 0)
        {
                super(msg, err);
        }
}

