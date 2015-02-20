**S 131009 -- Informasikan user jika lebih dari satu instance
IF FILE(ADDBS(SYS(2023)) + "req_id.sys")        
	TRY         
		USE (ADDBS(SYS(2023)) + "req_id.sys") EXCLUSIVE IN 0
	CATCH TO oUseErr                
		IF oUseErr.ERRORNO = 1705
			=MESSAGEBOX("Aplikasi yang sama, sedang dijalankan.",16, "Error", 5000)                        
			QUIT
		ENDIF
	ENDTRY
ELSE        
	CREATE TABLE (ADDBS(SYS(2023)) + "req_id.sys") ;
		(prog_id C(10))       
	INSERT INTO req_id (prog_id) VALUES (SYS(2015))
ENDIF


** Tutup semua menu
_SCREEN.Caption = "RC Electronic, Hand Made Software, @Copyright 2013"
PUSH MENU _MSYSMENU
_SCREEN.ControlBox = .T.
_SCREEN.Closable = .T.
_SCREEN.MaxButton = .T.
_SCREEN.MinButton = .T.
_SCREEN.WindowState = 2
_SCREEN.Icon='GRAPHICS\ICON.ico'


ON SHUTDOWN QUIT()

** Jalankan Init Program
DO progs\init.prg
_SCREEN.Caption = SPACE(5) + gcCompany + SPACE(5) + fnVersi()


************************************************
*!*	** 120706 - Cek Lisensi Program
*!*	IF !fnLisensi()
*!*		DO progs\cleanup.prg
*!*		RETURN .F.
*!*	ENDIF 
************************************************

*** Form Login
LOCAL objfrmCetak
SET CLASSLIB TO libs\profile

objFrmCetak = CREATEOBJECT("profile.login")
objFrmCetak.Show(1)
*** End of Form

DO FORM forms\utils\_level.scx
ON KEY LABEL F2 ACTIVATE WINDOW calculator


** 120127 - Menu Berdasarkan data di conn
LOCAL cModul
cModul = fnRead('menu','modul','DATA\conn.kon')

** 'ADM'
*Menu Utama
DO menus\menuprm.mpr
*!*	IF cModul = 'ADM'
*!*		DO menus\menu.mpr
*!*	ELSE 
*!*		LOCAL cMenu
*!*		=fnRequery("Select Kode, Nama From Gudang "+;
*!*			"Where Aktif = 1 And kode = '"+ALLTRIM(NVL(cModul,''))+"'","tMenu")
*!*		cMenu = "DO menus\menu"+ALLTRIM(NVL(kode,''))+".mpr"
*!*		&cMenu
*!*	ENDIF

*!*	DO progs\menu.prg 
DO menus\menustd.mpr

READ EVENTS