module tango.sys.win32.WsaSock;

public import tango.sys.Common;

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

