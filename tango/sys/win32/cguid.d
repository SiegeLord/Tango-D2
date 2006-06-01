/***********************************************************************\
*                                cguid.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.cguid;
private import win32.basetyps;

extern (C)
{
extern IID GUID_NULL;

extern IID IID_IRpcChannel;
extern IID IID_IRpcStub;
extern IID IID_IStubManager;
extern IID IID_IRpcProxy;
extern IID IID_IProxyManager;
extern IID IID_IPSFactory;
extern IID IID_IInternalMoniker;
extern IID IID_IDfReserved1;
extern IID IID_IDfReserved2;
extern IID IID_IDfReserved3;
extern IID IID_IStub;
extern IID IID_IProxy;
extern IID IID_IEnumGeneric;
extern IID IID_IEnumHolder;
extern IID IID_IEnumCallback;
extern IID IID_IOleManager;
extern IID IID_IOlePresObj;
extern IID IID_IDebug;
extern IID IID_IDebugStream;

extern CLSID CLSID_StdMarshal;
extern CLSID CLSID_PSGenObject;
extern CLSID CLSID_PSClientSite;
extern CLSID CLSID_PSClassObject;
extern CLSID CLSID_PSInPlaceActive;
extern CLSID CLSID_PSInPlaceFrame;
extern CLSID CLSID_PSDragDrop;
extern CLSID CLSID_PSBindCtx;
extern CLSID CLSID_PSEnumerators;
extern CLSID CLSID_StaticMetafile;
extern CLSID CLSID_StaticDib;

extern CLSID CID_CDfsVolume;

extern CLSID CLSID_CCDFormKrnl;
extern CLSID CLSID_CCDPropertyPage;
extern CLSID CLSID_CCDFormDialog;
extern CLSID CLSID_CCDCommandButton;
extern CLSID CLSID_CCDComboBox;
extern CLSID CLSID_CCDTextBox;
extern CLSID CLSID_CCDCheckBox;
extern CLSID CLSID_CCDLabel;
extern CLSID CLSID_CCDOptionButton;
extern CLSID CLSID_CCDListBox;
extern CLSID CLSID_CCDScrollBar;
extern CLSID CLSID_CCDGroupBox;
extern CLSID CLSID_CCDGeneralPropertyPage;
extern CLSID CLSID_CCDGenericPropertyPage;
extern CLSID CLSID_CCDFontPropertyPage;
extern CLSID CLSID_CCDColorPropertyPage;
extern CLSID CLSID_CCDLabelPropertyPage;
extern CLSID CLSID_CCDCheckBoxPropertyPage;
extern CLSID CLSID_CCDTextBoxPropertyPage;
extern CLSID CLSID_CCDOptionButtonPropertyPage;
extern CLSID CLSID_CCDListBoxPropertyPage;
extern CLSID CLSID_CCDCommandButtonPropertyPage;
extern CLSID CLSID_CCDComboBoxPropertyPage;
extern CLSID CLSID_CCDScrollBarPropertyPage;
extern CLSID CLSID_CCDGroupBoxPropertyPage;
extern CLSID CLSID_CCDXObjectPropertyPage;
extern CLSID CLSID_CStdPropertyFrame;
extern CLSID CLSID_CFormPropertyPage;
extern CLSID CLSID_CGridPropertyPage;
extern CLSID CLSID_CWSJArticlePage;
extern CLSID CLSID_CSystemPage;
extern CLSID CLSID_IdentityUnmarshal;
extern CLSID CLSID_InProcFreeMarshaler;
extern CLSID CLSID_Picture_Metafile;
extern CLSID CLSID_Picture_EnhMetafile;
extern CLSID CLSID_Picture_Dib;
extern CLSID CLSID_StdGlobalInterfaceTable;

extern GUID GUID_TRISTATE;
}
