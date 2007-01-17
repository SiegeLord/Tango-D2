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

extern (C) {
	extern const IID
		GUID_NULL,
		IID_IRpcChannel,
		IID_IRpcStub,
		IID_IStubManager,
		IID_IRpcProxy,
		IID_IProxyManager,
		IID_IPSFactory,
		IID_IInternalMoniker,
		IID_IDfReserved1,
		IID_IDfReserved2,
		IID_IDfReserved3,
		IID_IStub,
		IID_IProxy,
		IID_IEnumGeneric,
		IID_IEnumHolder,
		IID_IEnumCallback,
		IID_IOleManager,
		IID_IOlePresObj,
		IID_IDebug,
		IID_IDebugStream;

	extern const CLSID
		CLSID_StdMarshal,
		CLSID_PSGenObject,
		CLSID_PSClientSite,
		CLSID_PSClassObject,
		CLSID_PSInPlaceActive,
		CLSID_PSInPlaceFrame,
		CLSID_PSDragDrop,
		CLSID_PSBindCtx,
		CLSID_PSEnumerators,
		CLSID_StaticMetafile,
		CLSID_StaticDib,

		CID_CDfsVolume,

		CLSID_CCDFormKrnl,
		CLSID_CCDPropertyPage,
		CLSID_CCDFormDialog,
		CLSID_CCDCommandButton,
		CLSID_CCDComboBox,
		CLSID_CCDTextBox,
		CLSID_CCDCheckBox,
		CLSID_CCDLabel,
		CLSID_CCDOptionButton,
		CLSID_CCDListBox,
		CLSID_CCDScrollBar,
		CLSID_CCDGroupBox,
		CLSID_CCDGeneralPropertyPage,
		CLSID_CCDGenericPropertyPage,
		CLSID_CCDFontPropertyPage,
		CLSID_CCDColorPropertyPage,
		CLSID_CCDLabelPropertyPage,
		CLSID_CCDCheckBoxPropertyPage,
		CLSID_CCDTextBoxPropertyPage,
		CLSID_CCDOptionButtonPropertyPage,
		CLSID_CCDListBoxPropertyPage,
		CLSID_CCDCommandButtonPropertyPage,
		CLSID_CCDComboBoxPropertyPage,
		CLSID_CCDScrollBarPropertyPage,
		CLSID_CCDGroupBoxPropertyPage,
		CLSID_CCDXObjectPropertyPage,
		CLSID_CStdPropertyFrame,
		CLSID_CFormPropertyPage,
		CLSID_CGridPropertyPage,
		CLSID_CWSJArticlePage,
		CLSID_CSystemPage,
		CLSID_IdentityUnmarshal,
		CLSID_InProcFreeMarshaler,
		CLSID_Picture_Metafile,
		CLSID_Picture_EnhMetafile,
		CLSID_Picture_Dib,
		CLSID_StdGlobalInterfaceTable;

	extern const GUID GUID_TRISTATE;
}
