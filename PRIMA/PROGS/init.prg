Set Procedure To PROGS\MyProc.prg Additive
Set Procedure To PROGS\myprg.prg Additive
Set Procedure To PROGS\paperid.prg Additive
Set Procedure To PROGS\paperset.prg Additive
Set Procedure To PROGS\cabang.prg Additive
Set Classlib To libs\_therm.vcx Additive
Set Classlib To libs\rc.vcx Additive
SET PROCEDURE TO PROGS\csb.prg ADDITIVE

*!*	*******************************************************************************************************
*!*	SET CLASS TO libs\FOXRIBBON ADDITIVE
*!*	*!*	SET CLASS TO libs\MYDESIGNS ADDITIVE
*!*	DO SYSTEM.APP
*!*	if VarType(_Screen.oRibbon) == "O"
*!*		_Screen.RemoveObject("oRibbon")
*!*	endif
*!*	_Screen.NewObject("oRibbon", "RibbonSettings")
*!*	with _Screen.oRibbon
*!*		.Language = "English"
*!*		*--Calendar
*!*		.c_FirstDayWeek = 2
*!*		*--Week holidays
*!*		.c_1SunHoli = .T.
*!*		.c_2MonHoli = .F.
*!*		.c_3TueHoli = .F.
*!*		.c_4WedHoli = .F.
*!*		.c_5ThuHoli = .F.
*!*		.c_6FriHoli = .F.
*!*		.c_7SatHoli = .T.
*!*	endwith
*!*	*******************************************************************************************************






** Declare Variable
Public ATT_CAPTION
Public gcFileCommand
Public gcCompany, gcAddress, gcCity, gcPhone, gcNPWP
Public gcUser, gcSysUser, gnIDUser, gnLevel
Public gnTanggal_Periode
Public gcDateFormat
Public gnSec

** 081105 - Create Property Connection di _SCREEN
=AddProperty(_Screen,'pConnection',0)

** 081112 - Create Property Nama Connection di _SCREEN
=AddProperty(_Screen,'pConnection_Name',0)
=AddProperty(_Screen,'pError',.F.)

On Error Do fnError With Error( ), Message( ), Message(1), Program( ), Lineno( )

** Standar Variabel
gcUser = "SysAdmin"
gnIDUser = 1
gcFileCommand = 'DATA\command.ini'
gnTanggal_Periode = 15
gcDateFormat = "BRITISH"
gnSec = 3000
gnLevel = 1



** Baca Variabel Program
If !File('DATA\conn.kon')
	Messagebox('Init File Missing ...!',64,'File Missing')
	Do PROGS\cleanup.prg
Else
	**jika file ada lakukan pembacaan
	ATT_CAPTION = fnDekrip(fnRead('Variable','inisial','DATA\conn.kon'))
	gcCompany = fnDekrip(fnRead('Variable','company','DATA\conn.kon'))
	gcAddress = fnDekrip(fnRead('Variable','address','DATA\conn.kon'))
	gcCity = fnDekrip(fnRead('Variable','city','DATA\conn.kon'))
	gcPhone = fnDekrip(fnRead('Variable','phone','DATA\conn.kon'))
	gcFax = fnDekrip(fnRead('Variable','fax','DATA\conn.kon'))
	gcNPWP = fnDekrip(fnRead('Variable','NPWP','DATA\conn.kon'))
	

	**Cek Variabel
	If Type(gcCompany) = "L" Or Type( gcAddress) = "L" Or;
			TYPE(gcCity) = "L" Or Type(gcPhone) = "L" Or;
			TYPE(gcFax) = "L"
		=Messagebox('Variabel Missing ...!',64,'Variabel Missing')
		Do PROGS\cleanup.prg
	Endif

	** Baca Koneksi di File *.kon
	Local cType, cServer, cDatabase, cUser, cPass
	

	** Set Variable
	cType = fnDekrip(fnRead('Connection','type','DATA\conn.kon'))
	cServer = fnDekrip(fnRead('Connection','server','DATA\conn.kon'))
	cDatabase = fnDekrip(fnRead('Connection','database','DATA\conn.kon'))
	cUser = fnDekrip(fnRead('Connection','user','DATA\conn.kon'))
	cPass = fnDekrip(fnRead('Connection','pass','DATA\conn.kon'))
	
	** Jika ada Variable yang Kosong, aktifkan FORM SETUP
	If Empty(cType) Or Empty(cDatabase)
		Do Form Forms\utils\aturan.scx

		** 120627 - Setting Kertas Printer
		Set Procedure To PROGS\paperid.prg Additive
		=fnSetPaper("Faktur",8.5,5.5)

	Else
		** 081105 - Tutup Semua Koneksi
		=SQLDisconnect(0)

		** 081112 - Jika Koneksi Berhasil, Catat tipe Koneksi
		_Screen.pConnection_Name = fnConnType(cType, cServer, cUser, cPass, cDatabase)
		Store Sqlstringconnect(_Screen.pConnection_Name) To nConn

		** 081105 - Cek, ada aktif Koneksi
		If nConn <= 0
			_MsgErrorConnection()
			=fnTextFile("Error No.   : 001 -- Init, " + Chr(13) + "Error Message : Tidak Dapat Koneksi", "ErrLog.Txt", .T.)

			** Tutup Program
			Do PROGS\cleanup.prg
			Return .F.
		Endif

		

		** Ubah Default Language
	 	=fnRequery("EXEC sp_defaultlanguage '" + cUser + "', 'British English'")
 	
		** 081112 - Tutup Koneksi yang dibuat
		=fnDisConnect(nConn)

	Endif
Endif

**Ambil System (Windows) User
gcSysUser = Padr(Upper(Alltrim(Substr(Sys(0),Atc('#',Sys(0))+1))),8)

Set Bell On
Set Century On
Set Century To 19 ROLLOVER 80
Set Currency To 'Rp'
Set Date &gcDateFormat
Set Debug Off
Set Decimal To 2
Set Deleted On
Set Delimiter Off
Set Echo Off
Set Exact Off
Set Exclusive Off
Set Fixed Off
Set Keycomp To Windows
Set Memowidth To 61
Set Notify Off
Set Optimize On
Set Safe Off
Set Score Off
Set Status Bar On
Set Status Off
Set Talk Off

Set Exclusive Off
Set Multilocks On
Set NullDisplay To ' '
Set Sysmenu Off
Set Hours To 24
