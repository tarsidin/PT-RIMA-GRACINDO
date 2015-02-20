** 120627 - Procedure create nama kertas untuk custom
Procedure fnSetPaper
	Lparameters vNamaKertas,nLebar,nPanjang,cNamaPrinter
	Set Procedure To progs\paperset.prg Additive
	Local        ;
		vDir,;
		lAda,;
		vFile,;
		cString,;
		nLength,;
		nOccurs,;
		nSizeX ,;
		nSizeY ,;
		nStart ,;
		cPaper ,;
		cSize  ,;
		cPrinterName,;
		cPaperNameWithSize
	Local oForm
	oForm = Createobject("Form")

* Windows API
	Declare Long GetLastError In WIN32API
	Declare Long SetDefaultPrinter In WINSPOOL.DRV String pPrinterName

** 120627 - Default Printer Windows
	Local lcSaveWinDefPrinter
	lcSaveWinDefPrinter = Set("PRINTER", 2)

*------------------------------------------

** 120627 - Looping sebanyak Nama printer yang terinstall
	Local aPrnt(100,1), nPrnt
	nPrnt = Aprinters(aPrnt)
	For i = 1 To nPrnt
		cNamaPrinter = aPrnt(i,1)

		If SetDefaultPrinter(cNamaPrinter) = 0
			Wait Window "Error set default printer to "+cNamaPrinter Timeout 1
		Endif


		Decl Integer SetPaperName In Include\Printer.Dll String,String
		Decl String  GetPaperList In Include\Printer.Dll String
		cPrinterName = Set("Printer",2) && Defaul Printer Name
		cString                      = GetPaperList(cPrinterName)+':'
		nOccurs                      = Occurs(':',cString)

		Dime aPaperSize(1,3)
		aPaperSize(1,1)              =''
		aPaperSize(1,2)              = 0
		aPaperSize(1,3)              = 0
		nStart                       = 0
		lAda=.F.
		For i = 2 To nOccurs Step 2
			nStart                       = nStart + 1
			nLength                      = At(':',cString,i) - nStart
			cPaperNameWithSize           = Subs(cString,nStart,nLength)
			cPaper                       = Subs(cPaperNameWithSize,1,At(':',cPaperNameWithSize)-1)
			cSize                        = Subs(cPaperNameWithSize,  At(':',cPaperNameWithSize)+1)
			nSizeX                       = Roun(Val(Subs(cSize,1,At(',',cSize)-1))/10,0)
			nSizeY                       = Roun(Val(Subs(cSize,  At(',',cSize)+1))/10,0)
			nStart                       = At(':',cString,i)
			Dime aPaperSize(i/2,3)
			aPaperSize(i/2,1)            = cPaper && paper name
			aPaperSize(i/2,2)            = nSizeX && width
			aPaperSize(i/2,3)            = nSizeY && height

			If Upper(cPaper)==Upper(vNamaKertas)
				vNamaKertas=cPaper
				lAda = .T.
			Endif
		Endf
		oForm.AddObject('ObjPrint','AddPrinterForm')
		lReturn = .T.

		If lAda
			lReturn = oForm.ObjPrint.DeleteForm(vNamaKertas)
		Endif


		If lReturn
			If Isnull(cNamaPrinter) Or Type('cNamaPrinter') <> "C" Or Len(Alltrim(cNamaPrinter)) = 0
				lReturn = oForm.ObjPrint.AddForm(vNamaKertas,nLebar,nPanjang)
			Else
				lReturn = oForm.ObjPrint.AddForm(vNamaKertas,nLebar,nPanjang,cNamaPrinter)
			Endif
			If !lReturn
				Wait Window oForm.ObjPrint.cErrorMessage Timeout 2
			Else
				Exit
			Endif

		Endif
	Endfor

	oForm.RemoveObject('OBjPrint')
	SetPaperName(cPrinterName,vNamaKertas)
	Set Printer To Default
	Set Printer To Name (cPrinterName)
	=SetDefaultPrinter(lcSaveWinDefPrinter)
	Release oForm
	If lReturn
		Wait Window "Ukuran kertas "+Upper(vNamaKertas)+" telah berHASIL dibuat..." Timeout 1
	Endif
	
	Return lReturn
Endproc


Procedure fnPaperID
** Updated: July 07, 2008
** Bug fixed by: Julio Veloz
	Lparameters cKertas

	#Define DC_PAPERS 2
	#Define DC_PAPERS_Size 2
	#Define DC_PAPERNAMES 16
	#Define DC_PAPERNAMES_Size 64
	Declare Long DeviceCapabilities In WinSpool.drv ;
		String cPrinterName, String cPort, Short nCapFlags, ;
		String @O_cBuffer, Long pDevMode

	Local Array la_Printer[1]
	Local ln_Row, ln_Result, ln_I, ln_Index
	Local lc_PrinterName, lc_Buffer
	Local lc_FindPaperName, lc_PaperName, lc_PaperSizeID
	lc_PrinterName = Set( 'Printer', 2 ) && Get default windows printer
	= Aprinters( la_Printer )
	ln_Row = Ascan( la_Printer, lc_PrinterName, 1, 0, 0, 9 )
	ln_Result = DeviceCapabilities( la_Printer[ ln_Row, 1 ], ;
		la_Printer[ ln_Row, 2 ], DC_PAPERNAMES, 0, 0 )
	If (ln_Result > 0)
		ln_Index = -1
*!*		lc_FindPaperName = INPUTBOX("Masukan Nama kertas yang akan dicari...","Input Nama Kertas","")

		lc_FindPaperName = cKertas
		If Empty(lc_FindPaperName)
			Return .F.
		Endif

		lc_FindPaperName = Upper( lc_FindPaperName )
		lc_Buffer = Replicate( Chr(0), ln_Result * DC_PAPERNAMES_Size )
		ln_Result = DeviceCapabilities( la_Printer[ ln_Row, 1 ], ;
			la_Printer[ ln_Row, 2 ], DC_PAPERNAMES, @lc_Buffer, 0 )
		For ln_I = 0 To ln_Result-1
			lc_PaperName = Upper( Substr( lc_Buffer, (ln_I * DC_PAPERNAMES_Size )+1, ;
				DC_PAPERNAMES_Size ))
			If (lc_FindPaperName $ lc_PaperName)
				ln_Index = ln_I
				Exit
			Endif
		Next
		If (ln_Index != -1)
** Paper Name found
** Get PaperSize ID
			ln_Result = DeviceCapabilities( la_Printer[ ln_Row, 1 ], ;
				la_Printer[ ln_Row, 2 ], DC_PAPERS, 0, 0 )
			If (ln_Result > 0)
				lc_Buffer = Replicate( Chr(0), ln_Result * DC_PAPERS_Size )
				ln_Result = DeviceCapabilities( la_Printer[ ln_Row, 1 ], ;
					la_Printer[ ln_Row, 2 ], DC_PAPERS, @lc_Buffer, 0 )
				lc_PaperSizeID = Substr( lc_Buffer, (ln_Index * DC_PAPERS_Size )+1, DC_PAPERS_Size )
*!*					WAIT WINDOW CTOBIN( lc_PaperSizeID, '2rs' ) NOWAIT
*!*				WAIT WINDOW  'PaperSize ID for "' + ALLTRIM(lc_FindPaperName) + '" is' + ( lc_PaperSizeID) NOWAIT
			Endif
		Endif
	Endif

	Return Iif(Empty(lc_PaperSizeID),"0",Alltrim(Str(CToBin(lc_PaperSizeID, '2rs' ))))
Endproc


*****************************************
Function WinApiErrMsg
	Lparameters tnErrorCode
	#Define FORMAT_MESSAGE_FROM_SYSTEM 0x1000
	Declare Long FormatMessage In kernel32 ;
		Long dwFlags, Long lpSource, Long dwMessageId, ;
		Long dwLanguageId, String  @lpBuffer, ;
		Long nSize, Long Arguments

	Local lcErrBuffer, lnNewErr, lnFlag, lcErrorMessage
	lnFlag = FORMAT_MESSAGE_FROM_SYSTEM
	lcErrBuffer = Repl(Chr(0),1000)
	lnNewErr = FormatMessage(lnFlag, 0, tnErrorCode, 0, @lcErrBuffer,500,0)
	lcErrorMessage = Transform(tnErrorCode) + "    " + Left(lcErrBuffer, At(Chr(0),lcErrBuffer)- 1 )
	Return lcErrorMessage

