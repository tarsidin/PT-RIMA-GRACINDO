
** 120628 - Procedure untuk pengecekan suhu Processor
Procedure fnSuhu
	wbemServices=Getobject("winmgmts:" + "\\localhost\root\wmi")
	wbemObjectSet=wbemServices.InstancesOf("MSAcpi_ThermalZoneTemperature")
	For Each Item In wbemObjectSet
		iSuhu = (Item.CurrentTemperature - 2732) / 10
	Endfor
	Return iSuhu
Endproc

** 120628 - Procedure untuk pengecekan usage Processor
Procedure fnProcName
	objWMIService = Getobject("winmgmts:" ;
		+ "{impersonationLevel=impersonate}!\\" + "."+ "\root\cimv2")
	colItems  =  objWMIService.ExecQuery( ;
		"Select  *  from  Win32_Processor")
	For  Each  objItem  In  colItems
		cName = objItem.Name
	Endfor
Endproc

** 120628 - Procedure untuk print screen
Procedure fnPrintScreen
	cFile=Getfile("Bitmap Image:bmp","Nama Gambar", ;
		"&Simpan",0,"Simpan Gambar Hasil Capture")
	If(Empty(cFile))
		Return .F.
	Endif
	Declare Integer formtobmp In "PCT_DLL.dll" Integer HWnd, ;
		String bmpFileName
	retVal = formtobmp(0,cFile)
	If retVal = 0
		Messagebox("Capture Screen Berhasil!")
	Else
		Messagebox("Capture Screen Gagal!")
	Endif
Endproc

** 120628 - Procedure untuk pengecekan koneksi internet
Procedure fnKoneksiInternet
	Declare Long InternetCheckConnection In Wininet.Dll String Url,;
		Long dwFlags, Long Reserved
	**lcUrl = "http://www.google.com"
	lcUrl = "192.168.10.15"
	Return Iif(InternetCheckConnection(lcUrl, 1, 0) <> 0,.T.,.F.)
Endproc

** 120628 - Procedure untuk pengecekan serial Hardisk
Procedure fnSerialHd
	Local lnparms, lcroot, lcvolumename, lnvolumesize, lnserialno,;
		lncomplen, lnsysflags, lcsysname, lnnamesize

	Store 0 To lnserialno, lncomplen, lnsysflags
	Store Space(260) To lcvolname, lcsysname
	Store Len(lcvolname) To lnvolsize, lnnamesize

	* Declare windows API
	Declare SHORT GetVolumeInformation In Win32API;
		STRING @lpRootPathName, String @lpVolumeNameBuffer,;
		INTEGER nVolumeNameSize, Integer @lpVolumeSerialNumber,;
		INTEGER @lpMaximumComponentLength, Integer @lpFileSystemFlags,;
		STRING @lpFileSystemNameBuffer, Integer nFileSystemNameSize

	lcroot = Sys(5)
	lcolddec = Set('DECIMALS')
	Set Decimals To 0

	*-- Get the volume information and return the number or false
	If GetVolumeInformation(@lcroot, @lcvolname, lnvolsize, @lnserialno,;
			@lncomplen, @lnsysflags, @lcsysname, lnnamesize) # 0
		Do Case
			Case lnserialno < 0 And lnserialno > -4294967296
				lnserialno = Val(Transform(-lnserialno, '@O'))

			Case lnserialno > 0 And lnserialno < 4294967296
				lnserialno = Val(Transform(lnserialno, '@O'))

		Endcase
		Set Decimals To lcolddec
		*!*		THIS.nserialnumber = lnserialno
		lcMess = Alltrim(Str(lnserialno))

	Else
		Set Decimals To lcolddec
		*!*		THIS.nserialnumber =
		lcMess = [555556789]

	Endif
	Return lcMess
Endproc

** 120628 - Procedure untuk pengecekan Nilai di Registry
Procedure fnCekRegistry
	Lparameters cRegi, cName
	=fnDeclareReg()
	#Define HKEY_LOCAL_MACHINE	-2147483646
	#Define KEY_QUERY_VALUE		1
	#Define ErrControler		0

	Local lcBuffer, lnBufferSize,lcRetVal, lnReserved, lnResult, lnError, lnType, lcKey, lcHasil
	lnError=RegOpenKeyEx(HKEY_LOCAL_MACHINE, cRegi, lnReserved, KEY_QUERY_VALUE, @lnResult)
	If lnError = ErrControler
		lnType 		= 0
		lcBuffer 	= Space(128)
		lnBufferSize= Len(lcBuffer)
		lnError = RegQueryValueEx(lnResult, cName, lnReserved, @lnType, @lcBuffer, @lnBufferSize)
		If lnError = ErrControler And lcBuffer <> Chr(0)
			lcHasil = Left(lcBuffer, lnBufferSize - 1)
		Endif
	Endif
	Return lcHasil
Endproc

** 120628 - Procedure untuk setting nilai di Registry
Procedure fnSetRegistry
	Lparameters cRegi, cName, cStatus
	=fnDeclareReg()
	#Define HKEY_LOCAL_MACHINE	-2147483646

	Local lcBuffer, lnBufferSize,lcRetVal, lnReserved, lnResult, lnError, lnType, lcKey, lcHasil
	Store 0 To lnReserved, lnResult, lnType
	lcBuffer 	= Space(128)
	lnBufferSize= Len(lcBuffer)
	lnLen 		= Len(cStatus)
	lnError=RegCreateKey(HKEY_LOCAL_MACHINE,cRegi,@lnResult)
	If lnError = ErrControler
		=RegSetValueEx(lnResult,cName,0,KEY_QUERY_VALUE,cStatus,lnLen)
	Endif
Endproc

** 120706 - Cek Validasi Program
Procedure fnLisensi
*!*		Wait Window Sys(16,0)+Sys(16,1)+Sys(16,2)
	LOCAL cRegApp
	STORE '' TO cRegApp
	
	LOCAL cApp	
	cApp = JUSTSTEM(fnProgramExe())
		
	** 120706 - Cek Nama Aplikasi yang terdaftar di registry
	cRegApp = fnCekRegistry("SOFTWARE\AppRC\"+LEFT(PADL(PROPER(cApp),3,'0'),3),"AppName")
	IF EMPTY(cRegApp)
		=fnSetRegistry("SOFTWARE\AppRC\"+LEFT(PADL(PROPER(cApp),3,'0'),3),"AppName",cApp)
	ENDIF 
	
	IF !EMPTY(cRegApp) AND cRegApp <> cApp
		=MESSAGEBOX("Nama Aplikasi TIDAK SESUAI dengan yang terdaftar di LISENSI."+CHR(13)+;
			"Aplikasi TIDAK dapat diJalankan....",32,ATT_CAPTION)
		RETURN .F.
	ENDIF
	RETURN .T. 
Endproc


** 120706 - Default Program
PROCEDURE fnProgramExe
	LOCAL cFile
	
	cFile = JUSTSTEM(SYS(16,1))
	RETURN IIF(UPPER(LEFT(cFile,1)) = 'U',SYS(16,2),SYS(16,1))	
ENDPROC 

** 120612 - Procedure Cek Versi Exe
PROCEDURE fnVersi
	LOCAL cFile, cVersi
	STORE fnProgramExe() TO cFile
	IF FILE(cFile)
		STORE TTOC(FDATE(cFile,1),1) TO cVersi
		RETURN IIF(!EMPTY(cVersi),SUBSTR(cVersi,1,8)+"-"+SUBSTR(cVersi,9,2)+"."+SUBSTR(cVersi,11,2),"")
	ENDIF 
ENDPROC 

** 120612 - Procedure Cek Versi Command
PROCEDURE fnVersiC
	LOCAL cFile, cVersi
	STORE "DATA\Command.ini" TO cFile
	IF FILE(cFile)
		STORE TTOC(FDATE(cFile,1),1) TO cVersi
		RETURN IIF(!EMPTY(cVersi),SUBSTR(cVersi,1,8)+"-"+SUBSTR(cVersi,9,2)+"."+SUBSTR(cVersi,11,2),"")
	ENDIF 
ENDPROC 


Procedure fnDeclareReg
	Declare Integer RegOpenKeyEx In Win32API ;
		integer nKey, String @cSubKey, Integer nReserved, Integer nAccessMask, Integer @nResult
	Declare Integer RegQueryValueEx In Win32API ;
		Integer nHKey, String lpszValueName, Integer dwReserved, Integer @lpdwType, String @lpbData, Integer @lpcbData
	Declare Integer RegCreateKey In Win32API Integer nHKey, String @cSubKey, Integer @nResult
	Declare Integer RegSetValueEx In Win32API Integer hKey, String lpszValueName, Integer dwReserved, Integer fdwType, String lpbData, Integer cbData
Endproc