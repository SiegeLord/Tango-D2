/***********************************************************************\
*                              rpcnsip.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.rpcnsip;
private import win32.rpcdcep;
private import win32.rpcnsi;
private import win32.rpcdce;

struct RPC_IMPORT_CONTEXT_P {
	RPC_NS_HANDLE LookupContext;
	RPC_BINDING_HANDLE ProposedHandle;
	RPC_BINDING_VECTOR *Bindings;
}
alias RPC_IMPORT_CONTEXT_P * PRPC_IMPORT_CONTEXT_P;

extern(Windows) {
RPC_STATUS I_RpcNsGetBuffer(in PRPC_MESSAGE);
RPC_STATUS I_RpcNsSendReceive(in PRPC_MESSAGE, out RPC_BINDING_HANDLE*);
void I_RpcNsRaiseException(in PRPC_MESSAGE, in RPC_STATUS);
RPC_STATUS I_RpcReBindBuffer(in PRPC_MESSAGE);
RPC_STATUS I_NsServerBindSearch();
RPC_STATUS I_NsClientBindSearch();
void I_NsClientBindDone();
}
