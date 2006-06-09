/***********************************************************************\
*                                 rpc.d                                 *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/

/* Moved to rpcdecp (duplicate definition).
typedef void *I_RPC_HANDLE;
alias long RPC_STATUS;
// Moved to rpcdce:
RpcImpersonateClient
RpcRevertToSelf

*/

module tango.os.windows.c.rpc;

//version (build) { pragma(nolink); }


import tango.os.windows.c.unknwn;

alias MIDL_user_allocate midl_user_allocate;
alias MIDL_user_free midl_user_free;

import tango.os.windows.c.rpcdce;  // also pulls in rpcdcep
import tango.os.windows.c.rpcnsi;
import tango.os.windows.c.rpcnterr;

import tango.os.windows.c.winerror;

extern (Windows) {
int I_RpcMapWin32Status(RPC_STATUS);
}
