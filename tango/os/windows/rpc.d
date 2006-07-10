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

module tango.os.windows.rpc;

import tango.os.windows.unknwn;

alias MIDL_user_allocate midl_user_allocate;
alias MIDL_user_free midl_user_free;

import tango.os.windows.rpcdce;  // also pulls in rpcdcep
import tango.os.windows.rpcnsi;
import tango.os.windows.rpcnterr;

import tango.os.windows.winerror;

extern (Windows) {
int I_RpcMapWin32Status(RPC_STATUS);
}
