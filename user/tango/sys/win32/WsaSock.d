module tango.sys.win32.WsaSock;

public import tango.sys.Common;
private import tango.stdc.config; 
import  consts=tango.stdc.constants.socket;

struct Guid
{
        uint     g1;
        ushort   g2,
                 g3;
        ubyte[8] g4;
}

enum 
{
        WSADESCRIPTION_LEN = 256,
        WSASYS_STATUS_LEN = 128,
        WSAEWOULDBLOCK =  10035,
        WSAEINTR =        10004,
}

struct WSABUF
{
        uint    len;
        void*   buf;
}

struct WSADATA
{
        WORD wVersion;
        WORD wHighVersion;
        char szDescription[WSADESCRIPTION_LEN+1];
        char szSystemStatus[WSASYS_STATUS_LEN+1];
        ushort iMaxSockets;
        ushort iMaxUdpDg;
        char* lpVendorInfo;
}

enum 
{
        SIO_GET_EXTENSION_FUNCTION_POINTER = 0x40000000 | 0x80000000 | 0x08000000 | 6,
        SO_UPDATE_CONNECT_CONTEXT = 0x7010,
        SO_UPDATE_ACCEPT_CONTEXT = 0x700B
}

extern (Windows)
{
        int WSACleanup();
        int WSAGetLastError ();
        int WSAStartup(WORD wVersionRequested, WSADATA* lpWSAData);
        int WSAGetOverlappedResult (HANDLE, OVERLAPPED*, DWORD*, BOOL, DWORD*);
        int WSAIoctl (HANDLE s, DWORD op, LPVOID inBuf, DWORD cbIn, LPVOID outBuf, DWORD cbOut, DWORD* result, LPOVERLAPPED, void*);
        int WSARecv (HANDLE, WSABUF*, DWORD, DWORD*, DWORD*, OVERLAPPED*, void*);
        int WSASend (HANDLE, WSABUF*, DWORD, DWORD*, DWORD, OVERLAPPED*, void*);
}

pragma (lib, "ws2_32.lib");

struct timeval { 
    c_long seconds; 
    c_long microseconds; 
} 

struct sockaddr
{
        ushort   sa_family;
        char[14] sa_data = 0;
}

//transparent
struct fd_set
{
}

struct hostent
{
        char* h_name;
        char** h_aliases;
        short h_addrtype;
        short h_length;
        char** h_addr_list;

        char* h_addr()
        {
                return h_addr_list[0];
        }
}

typedef int socket_t = ~0;

extern (Windows)
{
        alias closesocket close;

        socket_t socket(int af, int type, int protocol);
        int ioctlsocket(socket_t s, int cmd, uint* argp);
        uint inet_addr(char* cp);
        int bind(socket_t s, sockaddr* name, int namelen);
        int connect(socket_t s, sockaddr* name, int namelen);
        int listen(socket_t s, int backlog);
        socket_t accept(socket_t s, sockaddr* addr, int* addrlen);
        int closesocket(socket_t s);
        int shutdown(socket_t s, int how);
        int getpeername(socket_t s, sockaddr* name, int* namelen);
        int getsockname(socket_t s, sockaddr* name, int* namelen);
        int send(socket_t s, void* buf, int len, int flags);
        int sendto(socket_t s, void* buf, int len, int flags, sockaddr* to, int tolen);
        int recv(socket_t s, void* buf, int len, int flags);
        int recvfrom(socket_t s, void* buf, int len, int flags, sockaddr* from, int* fromlen);
        int select(int nfds, fd_set* readfds, fd_set* writefds, fd_set* errorfds, timeval* timeout);
        int getsockopt(socket_t s, int level, int optname, void* optval, int* optlen);
        int setsockopt(socket_t s, int level, int optname, void* optval, int optlen);
        int gethostname(void* namebuffer, int buflen);
        char* inet_ntoa(uint ina);
        hostent* gethostbyname(char* name);
        hostent* gethostbyaddr(void* addr, int len, int type);
}

extern (Windows)
{
        bool function (socket_t, uint, void*, DWORD, DWORD, DWORD, DWORD*, OVERLAPPED*) AcceptEx;
        bool function (socket_t, HANDLE, DWORD, DWORD, OVERLAPPED*, void*, DWORD) TransmitFile;
        bool function (socket_t, void*, int, void*, DWORD, DWORD*, OVERLAPPED*) ConnectEx;
}

static this()
{
        WSADATA wd = void;
        if (WSAStartup (0x0202, &wd))
            throw new Exception("version of socket library is too old");

        DWORD result;

        Guid acceptG   = {0xb5367df1, 0xcbac, 0x11cf, [0x95,0xca,0x00,0x80,0x5f,0x48,0xa1,0x92]};
        Guid connectG  = {0x25a207b9, 0xddf3, 0x4660, [0x8e,0xe9,0x76,0xe5,0x8c,0x74,0x06,0x3e]};
        Guid transmitG = {0xb5367df0, 0xcbac, 0x11cf, [0x95,0xca,0x00,0x80,0x5f,0x48,0xa1,0x92]};

        auto s = cast(HANDLE) socket (consts.AF_INET, consts.SOCK_STREAM, consts.IPPROTO_TCP);
        assert (s != cast(HANDLE) -1);
        WSAIoctl (s, SIO_GET_EXTENSION_FUNCTION_POINTER, 
                  &connectG, connectG.sizeof, &ConnectEx, 
                  ConnectEx.sizeof, &result, null, null);

        WSAIoctl (s, SIO_GET_EXTENSION_FUNCTION_POINTER, 
                  &acceptG, acceptG.sizeof, &AcceptEx, 
                  AcceptEx.sizeof, &result, null, null);

        WSAIoctl (s, SIO_GET_EXTENSION_FUNCTION_POINTER, 
                  &transmitG, transmitG.sizeof, &TransmitFile, 
                  TransmitFile.sizeof, &result, null, null);
        closesocket (cast(socket_t) s);
}

static ~this()
{
        WSACleanup();
}
