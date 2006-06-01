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

module win32.rpc;

import win32.unknwn;

alias MIDL_user_allocate midl_user_allocate;
alias MIDL_user_free midl_user_free;

import win32.rpcdce;  // also pulls in rpcdcep
import win32.rpcnsi;
import win32.rpcnterr;

import win32.winerror;

extern (Windows) {
int I_RpcMapWin32Status(RPC_STATUS);
}
