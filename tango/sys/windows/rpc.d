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

module tango.sys.windows.rpc;

import tango.sys.windows.unknwn;

alias MIDL_user_allocate midl_user_allocate;
alias MIDL_user_free midl_user_free;

import tango.sys.windows.rpcdce;  // also pulls in rpcdcep
import tango.sys.windows.rpcnsi;
import tango.sys.windows.rpcnterr;

import tango.sys.windows.winerror;

extern (Windows) {
int I_RpcMapWin32Status(RPC_STATUS);
}
