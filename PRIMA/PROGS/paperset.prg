Define Class AddPrinterForm As Custom && olepublic
	Hidden cUnit, cPrinterName, nFormHeight, nFormWidth, nLeftMargin, ;
		nTopMargin, nRightMargin, nBottomMargin, ;
		nInch2mm, nCm2mm, nCoefficient, hHeap

	cUnit = "English"      && inches or Metric - cm's
	cPrinterName = ""
	nFormHeight = 0
	nFormWidth = 0
	nLeftMargin = 0
	nTopMargin = 0
	nRightMargin = 0
	nBottomMargin = 0

	nApiErrorCode = 0
	cApiErrorMessage = ""
	cErrorMessage = ""

	nInch2mm = 25.4
	nCm2mm = 10
	nCoefficient = 0

	hHeap = 0

	Procedure Init(tcUnit)
		If Pcount() = 1 And Inlist(tcUnit, "English", "Metric")
			This.cUnit = Proper(tcUnit)
		Endif
		This.LoadApiDlls()
		This.hHeap = HeapCreate(0, 4096, 0)
* Use Windows default printer
		This.cPrinterName = Set("Printer",2)
		This.nCoefficient = Iif(Proper(This.cUnit) = "English", ;
			this.nInch2mm, This.nCm2mm) * 1000
	Endproc

	Procedure Destroy
		If This.hHeap <> 0
			HeapDestroy(This.hHeap)
		Endif

	Endproc

	Procedure SetFormMargins(tnLeft, tnTop, tnRight, tnBottom)
		With This
			.nLeftMargin    = tnLeft   * .nCoefficient
			.nTopMargin    = tnTop    * .nCoefficient
			.nRightMargin    = tnRight  * .nCoefficient
			.nBottomMargin    = tnBottom * .nCoefficient
		Endwith
	Endproc

	Procedure AddForm(tcFormName, tnWidth, tnHeight, tcPrinterName)
		Local lhPrinter, llSuccess, lcForm

		This.nFormWidth  = tnWidth  * This.nCoefficient
		This.nFormHeight = tnHeight * This.nCoefficient
		If Pcount() > 3
			This.cPrinterName = tcPrinterName
		Else
			This.cPrinterName = Set("Printer",2)
		Endif

		This.ClearErrors()
		lhPrinter = 0
		If OpenPrinter(This.cPrinterName, @lhPrinter, 0) = 0
			This.cErrorMessage = "Unable to get printer handle for '" ;
				+ This.cPrinterName + "."
			This.nApiErrorCode = GetLastError()
			This.cApiErrorMessage = This.ApiErrorText(This.nApiErrorCode)
			Return .F.
		Endif

		lnFormName = HeapAlloc(This.hHeap, 0, Len(tcFormName) + 1)
		= Sys(2600, lnFormName, Len(tcFormName) + 1, tcFormName + Chr(0))

* Build FORM_INFO_1 structure
		With This
			lcForm = This.Num2LOng(0) + ;      && Flags
			This.Num2LOng(lnFormName) + ;
				this.Num2LOng(.nFormWidth) + ;
				this.Num2LOng(.nFormHeight) + ;
				this.Num2LOng(.nLeftMargin) + ;
				this.Num2LOng(.nTopMargin) + ;
				this.Num2LOng(.nFormWidth - .nRightMargin) + ;
				this.Num2LOng(.nFormHeight - .nBottomMargin)
		Endwith

* Finally, call the API


		If AddForm(lhPrinter, 1, @lcForm) = 0
			This.cErrorMessage = "Unable to Add Form '" + tcFormName + "' "+;
				IIF(!EMPTY(tcPrinterName),"in Printer "+tcPrinterName,"")
			This.nApiErrorCode = GetLastError()
			This.cApiErrorMessage = This.ApiErrorText(This.nApiErrorCode)
			llSuccess = .F.
		Else
			llSuccess = .T.
		Endif
		= HeapFree(This.hHeap, 0, lnFormName)
		= ClosePrinter(lhPrinter)

		Return llSuccess




	Procedure SetForm(tcFormName,tnWidth,tnHeight,tcPrinterName)
		Local lhPrinter, llSuccess, lcForm
		If Pcount() > 3
			This.cPrinterName = tcPrinterName
		Else
			This.cPrinterName = Set("Printer",2)
		Endif
		This.ClearErrors()

		lhPrinter = 0
		If OpenPrinter(This.cPrinterName, @lhPrinter, 0) = 0
			This.cErrorMessage = "Unable to get printer handle for '" ;
				+ This.cPrinterName + "."
			This.nApiErrorCode = GetLastError()
			This.cApiErrorMessage = This.ApiErrorText(This.nApiErrorCode)
			Return .F.
		Endif

		lnFormName = HeapAlloc(This.hHeap, 0, Len(tcFormName) + 1)
		= Sys(2600, lnFormName, Len(tcFormName) + 1, tcFormName + Chr(0))

		This.nFormWidth  = tnWidth  * This.nCoefficient
		This.nFormHeight = tnHeight * This.nCoefficient

		With This
			lcForm = This.Num2LOng(0) + ;      && Flags
			This.Num2LOng(lnFormName) + ;
				this.Num2LOng(.nFormWidth) + ;
				this.Num2LOng(.nFormHeight) + ;
				this.Num2LOng(.nLeftMargin) + ;
				this.Num2LOng(.nTopMargin) + ;
				this.Num2LOng(.nFormWidth - .nRightMargin) + ;
				this.Num2LOng(.nFormHeight - .nBottomMargin)
		Endwith
* Finally, call the API
		llSuccess =SetForm(lhPrinter, tcFormName,1,@lcForm)
		If llSuccess = 0
			This.cErrorMessage = "Unable to Add Form '" + tcFormName + "'."
			This.nApiErrorCode = GetLastError()
			This.cApiErrorMessage = This.ApiErrorText(This.nApiErrorCode)
		Endif
		= HeapFree(This.hHeap, 0, lnFormName)
		= ClosePrinter(lhPrinter)
		Return llSuccess





	Procedure ClearErrors
		This.cErrorMessage = ""
		This.nApiErrorCode = 0
		This.cApiErrorMessage = ""
	Endproc

	Procedure DeleteForm(tcFormName, tcPrinterName)
		Local lhPrinter, llSuccess

		If Pcount() > 1
			This.cPrinterName = tcPrinterName
		Else
			This.cPrinterName = Set("Printer",2)
		Endif

		This.ClearErrors()
		lhPrinter = 0
		If OpenPrinter(This.cPrinterName, @lhPrinter, 0) = 0
			This.cErrorMessage = "Unable to get printer handle for '" + This.cPrinterName + "."
			This.nApiErrorCode = GetLastError()
			This.cApiErrorMessage = This.ApiErrorText(This.nApiErrorCode)
			Return .F.
		Endif

* Finally, call the API
		If DeleteForm(lhPrinter, tcFormName) = 0
			This.cErrorMessage = "Unable to delete Form '" + tcFormName + "'."
			This.nApiErrorCode = GetLastError()
			This.cApiErrorMessage = This.ApiErrorText(This.nApiErrorCode)
			llSuccess = .F.
		Else
			llSuccess = .T.
		Endif
		= ClosePrinter(lhPrinter)
		Return llSuccess

	Function Num2LOng(tnNum)
		Declare RtlMoveMemory In WIN32API As RtlCopyLong ;
			string @Dest, Long @Source, Long Length
		Local lcString
		lcString = Space(4)
		=RtlCopyLong(@lcString, Bitor(tnNum,0), 4)
		Return lcString
	Endfunc

	Function Long2Num(tcLong)
		Declare RtlMoveMemory In WIN32API As RtlCopyNum ;
			long @Dest, String @Source, Long Length
		Local lnNum
		lnNum = 0
		= RtlCopyNum(@lnNum, tcLong, 4)
		Return lnNum
	Endfunc

	Hidden Procedure ApiErrorText
		Lparameters tnErrorCode
		Local lcErrBuffer
		lcErrBuffer = Repl(Chr(0),1024)
		= FormatMessage(0x1000 ,.Null., tnErrorCode, 0, @lcErrBuffer, 1024,0)
		Return Strtran(Left(lcErrBuffer, At(Chr(0),lcErrBuffer)- 1 ), ;
			"file", "form", -1, -1, 3)

	Endproc

	Hidden Procedure LoadApiDlls
		Declare Integer OpenPrinter In winspool.drv;
			string  pPrinterName,;
			integer @phPrinter,;
			integer pDefault
		Declare Integer ClosePrinter In winspool.drv;
			integer hPrinter
		Declare Integer AddForm In winspool.drv;
			integer hPrinter,;
			integer Level,;
			string  @pForm
		Declare Integer DeleteForm In winspool.drv;
			integer hPrinter,;
			string  pFormName
		Declare Integer HeapCreate In Win32API;
			integer dwOptions, Integer dwInitialSize,;
			integer dwMaxSize
		Declare Integer HeapAlloc In Win32API;
			integer hHeap, Integer dwFlags, Integer dwBytes
		Declare lstrcpy In Win32API;
			string @lpstring1, Integer lpstring2
		Declare Integer HeapFree In Win32API;
			integer hHeap, Integer dwFlags, Integer lpMem
		Declare HeapDestroy In Win32API;
			integer hHeap
		Declare Integer GetLastError In kernel32
		Declare Integer FormatMessage In kernel32.Dll ;
			integer dwFlags, String @lpSource, ;
			integer dwMessageId, Integer dwLanguageId, ;
			string @lpBuffer, Integer nSize, Integer Arguments

		Declare Integer SetForm In winspool.drv ;
			integer phPrinter,;
			string pFormName,;
			integer plevel,;
			string pForm

	Endproc

Enddefine
