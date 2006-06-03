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

module tango.os.win32.rpc;

import tango.os.win32.unknwn;

alias MIDL_user_allocate midl_user_allocate;
alias MIDL_user_free midl_user_free;

import tango.os.win32.rpcdce;  // also pulls in rpcdcep
import tango.os.win32.rpcnsi;
import tango.os.win32.rpcnterr;

import tango.os.win32.winerror;

extern (Windows) {
int I_RpcMapWin32Status(RPC_STATUS);
}
