/***********************************************************************\
*                              rpcnsip.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module tango.os.windows.c.rpcnsip;

//version (build) { pragma(nolink); }

private import tango.os.windows.c.rpcdcep;
private import tango.os.windows.c.rpcnsi;
private import tango.os.windows.c.rpcdce;

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
