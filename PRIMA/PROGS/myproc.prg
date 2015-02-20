* Procedure untuk passing parameter ke form lain
* parameter = namaform,passparam  =>  string,string
PROCEDURE fnPassprm
	LPARAMETERS oNmClass, vCommand
	* nama class, perintah [param1, param2,...]
	LOCAL cntClass
	FOR cntClass = 1 TO _SCREEN.FORMCOUNT
		IF _SCREEN.FORMS[cntClass].BASECLASS = "Form" ;
				AND UPPER(_SCREEN.FORMS[cntClass].NAME) ;
				== UPPER(oNmClass)
			_SCREEN.FORMS[cntClass].&vCommand.
			EXIT
		ENDIF
	ENDFOR
ENDPROC

* Procedure Declare DLL Baca / Tulis *.txt
PROCEDURE fnDeclare
	DECLARE integer GetPrivateProfileString in Win32API  as GetPrivStr ;
		string cSection, string cKey, string cDefault, string @cBuffer, ;
		integer nBufferSize, string cINIFile

	DECLARE integer WritePrivateProfileString in Win32API as WritePrivStr ;
		string cSection, string cKey, string cValue, string cINIFile
ENDPROC 

* Procedure untuk Baca *.txt File
PROCEDURE fnRead
	LPARAMETERS cLabel, cKey, cDirectory
	LOCAL cHasil, cBuffer, lError, cError
	cHasil = ''
	cBuffer = SPACE(1000) + CHR(0)
	cError = ON('ERROR')
	
	** Declare Win32 AP
	=fnDeclare()
	
	** Ambil data dari File
	IF GetPrivStr(cLabel, cKey, "", ;
	               @cBuffer, LEN(cBuffer), CURDIR() + cDirectory) > 0 
		** Cek Error
	  	ON ERROR lError = .T.	  
	  	
	  	** Simpan Hasil	
		cHasil = ALLTRIM(CHRTRAN(cBuffer,CHR(0),""))
	  	ON ERROR &cError
	  	
	  	** Jika Error, Reset Variable hasil
	  	IF lError
	  		cHasil = ''
	  	ENDIF
	ENDIF
	RETURN cHasil
ENDPROC 

* Procedure untuk Tulis *.txt File
PROCEDURE fnWrite
	LPARAMETERS cLabel, cKey, cData, cDirectory
	LOCAL lError, cError
	cError = ON('ERROR')
	
	** Declare Win32 API
	=fnDeclare()	
	
	** Tulis Data ke File
	IF WritePrivStr(cLabel, cKey, cData, CURDIR() + cDirectory) > 0 	
	 	ON ERROR &cError
	  	IF lError
	  		RETURN .F.
	  	ENDIF
	ENDIF
ENDPROC 

* 081105 - Procedure Untuk Tipe Connection
PROCEDURE fnConnType
	LPARAMETERS cType, cServer, cUser, cPass, cDatabase
	DO CASE
	CASE cType = "1"
		cConn = "DRIVER=SQL Server;SERVER=&cServer.;UID=&cUser.;PWD=&cPass.;APP=Microsoft Visual FoxPro;DATABASE=&cDatabase.;Network=DBMSLPCN,.T."
	CASE cType = "2"
		cConn = "DRIVER={SQL Server Native Client 10.0};SERVER=&cServer.;UID=&cUser.;PWD=&cPass.;APP=Microsoft Visual FoxPro;DATABASE=&cDatabase.;"
	CASE cType = "3"
		cConn = "DRIVER={Microsoft Visual FoxPro Driver};SourceType=&cServer.;SourceDB=&cDatabase.;Exclusive=No;NULL=YES;Collate=Machine;BACKGROUNDFETCH=NO;DELETED=YES"
	CASE cType = "4"
		cConn = "DRIVER={MySQL ODBC 5.1 Driver};DESC=;DATABASE=&cDatabase.;SERVER=&cServer.;UID=&cUser.;PASSWORD=&cPass.;PORT=3306;OPTION=3;STMT=;"
	CASE cType = "5"
		cConn = "DRIVER={Microsoft Access Driver (*.mdb)};DBQ=&cDatabase.;PWD=&cPass;"
		OTHERWISE
		cConn = ""
	ENDCASE
	RETURN cConn
ENDPROC 

* 081105 - Procedure Untuk Buat Koneksi
PROCEDURE fnConnection
	LPARAMETERS cType, cServer, cUser, cPass, cDatabase
	STORE SQLSTRINGCONNECT(fnConnType(cType, cServer, cUser, cPass, cDatabase)) TO nConn
	IF nConn > 0
		=SQLSETPROP(nConn,"DispLogin",3)
*!*			=SQLSETPROP(nConn,"Transactions",2)
	ELSE 
		_MsgErrorConnection()
 		=fnTextFile("Error No.   : 102 -- fnConnection, " + CHR(13) + "Error Message : Tidak Dapat Koneksi", "ErrLog.Txt", .T.)
  	ENDIF 
	RETURN nConn
ENDPROC 

* 081105 - Procedure Untuk Requery Table ke DATABASE
PROCEDURE fnRequery
 	LPARAMETERS cCommand, oCursor, nConn	
 	
	** 081112 - Buat Koneksi Baru, Jika nConn <> .F.	
	LOCAL nConn, lKoneksi
	IF EMPTY(nConn)
		STORE SQLSTRINGCONNECT(_SCREEN.pConnection_Name) TO nConn
		lKoneksi = .T.
	ENDIF 
	
	** 081105 - Cek, Koneksi yang dibuat berhasil
 	IF nConn <= 0
 		_MsgErrorConnection()
 		=fnTextFile("Error No.   : 101 -- fnRequery , " + CHR(13) + "Error Message : Tidak Dapat Koneksi", "ErrLog.Txt", .T.)
  		RETURN .F.
  	ENDIF  		 	
 				
	** Command menghasilkan Cursor
	IF TYPE("oCursor") <> "L" 	
		IF SQLEXEC(nConn,cCommand,oCursor) < 0
			** Tampilkan Error Message
			_MsgErrorQuery()
			=fnDisConnect(nConn)
			RETURN .F.
		ENDIF 		
	ELSE 
		IF SQLEXEC(nConn,cCommand) < 0
			** Tampilkan Error Message
			_MsgErrorQuery()
			=fnDisConnect(nConn)
			RETURN .F.
		ENDIF 
	ENDIF 
	
	** 081112 - Bukan Manual Koneksi
	IF lKoneksi
		=fnDisConnect(nConn)
	ENDIF 
	RETURN .T. 
ENDPROC   

* 081105 - Procedure Untuk TUTUP Aktif Koneksi
PROCEDURE fnDisConnect
	LPARAMETERS nConn
	
	** Cek, ADA Koneksi 
	IF nConn > 0
		** Tutup Koneksi	
		=SQLDISCONNECT(nConn)
	ENDIF 	
	RETURN .T.
ENDPROC 

** 081105 - Procedure Commit Transaction
PROCEDURE fnCommit
	LPARAMETERS nConn
	LOCAL lCommit
	WAIT WINDOW "Commit Transaction" NOWAIT 
	** 081105 - Coba Commit sebanyak 5 kali
	FOR i = 1 TO 5		
		IF SQLCOMMIT(nConn) = 1
			lCommit = .T.
			EXIT 
		ENDIF 
		i = i + 1
	ENDFOR 
	
	** 081105 - Jika Gagal
	IF !lCommit
		=fnTextFile("Error No.   : 001, " + CHR(13) + "Error Message : Tidak Dapat Commit Transaksi", "ErrLog.Txt", .T.)
		SQLROLLBACK(nConn)
	ENDIF 
	RETURN .T.
ENDPROC 
 	
* Fungsi Buka Document Sesuai dengan Asosiasi Program filenya
PROCEDURE fnBukaDok(oDocument)
	LOCAL nReturn

	DECLARE INTEGER ShellExecute ;
		IN SHELL32.dll ;
		INTEGER nWinHandle, ;
		STRING cOperation, ;
		STRING cFileName, ;
		STRING cParameters, ;
		STRING cDirectory, ;
		INTEGER nShowWindow

	*Proses Kembali ke window utama VFP (Proses ini di pakai oleh ShellExecute)
	DECLARE INTEGER FindWindow ;
		IN WIN32API ;
		STRING cNull, ;
		STRING cWinName

	nReturn=ShellExecute(FindWindow( 0, _SCREEN.caption), "Open", oDocument, "", SYS(2023), 1)

	*Pesan Error Jika Nilai return < 32
	IF nReturn < 32
		DO CASE
		CASE nReturn=2
			Wait wind "Asosiasi File Dokumen atau URL salah."
		CASE nReturn=31
			Wait wind "Asosiasi '."+JUSTEXT(oDocument)+"' tidak ada."
		CASE nReturn=29
			Wait wind "Program Aplikasi tidak bisa dipanggil."
		CASE nReturn=30
			Wait wind "Program Aplikasi telah dibuka."
		ENDCASE
	ENDIF
ENDPROC 

* Procedure untuk mendapatkan nomor transaksi terakhir berdasarkan jenis transaksi dan ketentuan penomorannya
PROCEDURE fnGetNumber
	LPARAMETERS cCode, cType
	LOCAL nNumber, nConn, lExist
 	
 	** 081112 - Jika Ada Koneksi Aktif
	IF _SCREEN.pConnection > 0
		nConn = _SCREEN.pConnection 
	ELSE 
		STORE SQLSTRINGCONNECT(_SCREEN.pConnection_Name) TO nConn
		** 081105 - Cek, Koneksi yang dibuat berhasil
	 	IF nConn <= 0
	 		_MsgErrorConnection()
	 		=fnTextFile("Error No.   : 103 -- fnGetNumber , " + CHR(13) + "Error Message : Tidak Dapat Koneksi", "ErrLog.Txt", .T.)
	  		RETURN .F.
	  	ENDIF 
	ENDIF 
		
 	IF SQLEXEC(nConn,"SELECT nomor FROM hitung "+;
 		"WHERE kode = '"+ALLTRIM(cCode)+"' "+;
 			"AND tipe = '"+ALLTRIM(cType)+"' ","_tMyNomor") < 1
		** Tampilkan Error Message
		_MsgErrorQuery()
		
		** 081112 - Tutup Koneksi, jika Sudah ADA koneksi, batalkan seua Koneksi
		=fnDisConnect(nConn)
		IF _SCREEN.pConnection > 0
			_SCREEN.pConnection = 0
		ENDIF 
	ENDIF 
	
	** Cek Cursor Hasil
	IF RECCOUNT("_tMyNomor") = 0		&& Jika tidak ada Hasil
		** Insert Record Baru
		IF SQLEXEC(nConn,"INSERT INTO hitung (kode, tipe, nomor) "+;
				"VALUES ('"+ALLTRIM(cCode)+"', '"+ALLTRIM(cType)+"', 1 )") < 1
			_MsgErrorQuery()
		ENDIF 
		nNumber = 1
	ELSE 								&& Jika ada Hasil
		** Update Record
		nNumber = _tMyNomor.nomor + 1
		IF SQLEXEC(nConn,"UPDATE hitung "+;
				"SET nomor = ?VAL(LTRIM(STR(_tMyNomor.nomor+1))) "+;
				"WHERE kode = '"+ALLTRIM(cCode)+"' "+;
					"AND tipe = '"+ALLTRIM(cType)+"' ") < 1
			_MsgErrorQuery()
		ENDIF 
	ENDIF 	
	
	** 081112 - Tutup Koneksi, jika Koneksi dibuat sekarang
	IF _SCREEN.pConnection = 0
		=fnDisConnect(nConn)
	ENDIF 
	
	** Use Cursor Aktif
	USE IN _tMyNomor
	RETURN nNumber
ENDPROC 

* Procedure untuk mendapatkan nomor transaksi / kode dengan panjang yang sama
PROCEDURE fnNumber
	LPARAMETERS cType, cName, nPrefix, dDate
	LOCAL cNoPrefix, cNumber, nNumber
	
	** Set Jenis Reset Nomor
    DO CASE
    CASE cType = 'Tahun'
		cNoPrefix = fnDateToYear(dDate)
	CASE cType = 'Bulan'
		cNoPrefix = fnDateToPeriode(dDate)
    OTHERWISE
		cNoPrefix = ''
    ENDCASE
    
    ** Ambil DATA Nomor terakhir
	nNumber = fnGetNumber(cName,cNoPrefix)
	
	** Set Return Value
	IF EMPTY(cType)
		cNumber = IIF(!EMPTY(cNoPrefix),cNoPrefix+'.','')+PADL(LTRIM(STR(nNumber)),nPrefix,'0')
    ELSE 
    	cNumber = IIF(!EMPTY(cNoPrefix),cNoPrefix+'.','')+PADL(LTRIM(STR(nNumber)),nPrefix,'0')
    ENDIF 
    RETURN cNumber  
ENDPROC 

* Procedure tulis ke Text file...
PROCEDURE fnTextFile
LPARAMETERS cString, cFileName, lID
   IF TYPE("lID") <> "L" THEN
      lID = .T.
   ENDIF
   
   SET CONSOLE OFF 
   SET PRINTER TO (cFileName) ADDITIVE
   SET PRINTER ON
   IF lID THEN 
      ?TTOC(DATETIME()) + " - User ID : " + ALLTRIM(IIF(TYPE("gcUser") <> "C", "---",gcUser)) + " - " + cString
   ELSE
      ? cString
   ENDIF
   SET PRINTER OFF
   SET PRINTER TO
ENDFUNC

* Procedure Report Windows
PROCEDURE fnReportWindow	
	LPARAMETERS cFormName, cCaptionFom, cReport, nType	
	
	LOCAL oReportForm AS FORM
	oReportForm = CREATEOBJECT("Form")
	WITH oReportForm
		.CAPTION = cCaptionFom
		.NAME = cFormName
		.WIDTH = _SCREEN.Width - 15
		.HEIGHT = _SCREEN.Height - 50
		.AUTOCENTER= .T.
		.MAXBUTTON=.F.
		.ALWAYSONTOP=.T.
		.HALFHEIGHTCAPTION=.T.		
	ENDWITH
	DO CASE
		CASE nType = 1		
		&& -> TO PRINTER Langsung
			REPORT FORM &cReport. TO PRINTER PROMPT
		CASE nType = 2
		&& -> TO PRINTER PREVIEW
			REPORT FORM &cReport. TO PRINTER PROMPT PREVIEW WINDOW &cFormName.
		CASE nType = 3
		&& -> PREVIEW NOWAIT
			REPORT FORM &cReport. PREVIEW WINDOW &cFormName. NOWAIT
		CASE nType = 4
		&& -> PREVIEW WAIT
			REPORT FORM &cReport. PREVIEW WINDOW &cFormName.
	ENDCASE
	
	** Set Preview Toolbar di DOCK position
	IF WEXIST("Print Preview")
		MOVE WINDOW "Print Preview" TO 10,10
		MOUSE DBLCLICK AT 11,11
	ENDIF
	RELEASE oReportForm
	
	
ENDPROC

* Procedure Random Character
PROCEDURE fnRandom
	LPARAMETERS cChar, nLength	
	LOCAL cReturn
	
	=RAND(-1)
	cReturn= ""
	FOR i = 1 TO nLength
		cReturn= cReturn + CHR(RAND()*200+15)
	NEXT 
	RETURN cReturn + cChar
ENDFUNC 

* Procedure ENKRIP
PROCEDURE fnEnkrip
	LPARAMETERS cEncrip
	LOCAL cTemp, i
	IF LEN(cEncrip) > 0 
		cTemp = ""
		FOR i = 1 TO LEN(cEncrip)
	    	cTemp = cTemp + CHR(ASC(SUBSTR(cEncrip,i,1)) + 14 + i)
		ENDFOR
	ELSE 
	  cTemp = cEncrip
	ENDIF 
	RETURN cTemp
ENDPROC 

**Procedure DEKRIP
PROCEDURE fnDekrip
	LPARAMETERS cDecrip
	LOCAL cTemp, i
	IF LEN(ALLTRIM(cDecrip)) > 0
		cTemp = ""
		FOR i = 1 TO LEN(ALLTRIM(cDecrip))
	    	cTemp = cTemp + CHR(ASC(SUBSTR(cDecrip,i,1)) - 14 - i)
		ENDFOR 
	ELSE 
		cTemp = cDecrip
	ENDIF 
	RETURN cTemp
ENDPROC 

* -- Fungsi untuk menghitung selisih jam...
* -- Syntax : fnSelisihJam(Jam_Awal, Jam_Akhir, nMode)
* --          Jam_Awal  : Jam mulai perhitungan
* --          Jam_Akhir : Jam Perhitungan sampai jam berapa
* --          nMode     : 1 - Hasil dalam Jam, 2 - Hasil dalam menit
FUNCTION fnSelisihJam
LPARAMETERS tTime1, tTime2, nMode
LOCAL nTmp
   IF PARAMETERS() < 3 THEN
      nMode = 1
   ENDIF
   
   IF tTime2 < tTime1 THEN
      MESSAGEBOX("Jam awal tidak boleh setelah jam akhir...", 64, "Peringatan")
      RETURN -1
   ENDIF
   
   nTmp = tTime2 - tTime1
   IF nMode = 1 THEN
      RETURN (nTmp/(60*60))
   ELSE
      RETURN (nTmp/60)
   ENDIF 
ENDFUNC

* Procedure untuk ngecek, jam yang dimasukkan bener apa nggak....
PROCEDURE fnIsTime
LPARAMETERS cTime
LOCAL tTmp
   * -- Cek parameternya cocok nggak...
   IF TYPE("cTime") <> "C" THEN
      MESSAGEBOX("Parameternya harus string....", 64, ATT_CAPTION)
      RETURN .F.
   ENDIF
   
   tTmp = CTOT(DTOC(DATE()) + " " + ALLTRIM(cTime))
   IF EMPTY(tTmp) THEN
      RETURN .F.
   ELSE
      RETURN .T.
   ENDIF   
ENDPROC 

FUNCTION fnSQLSeek
LPARAMETERS cExp, cTableName, cIndex, cCursor
LOCAL cSQLCmd

   * -- Cek Parametersnya....
   IF TYPE("cCursor") <> "C" THEN
      cCursor = "xTmp"
   ENDIF
   
   cExp = STRTRAN(cExp, "'", "''")
   
   * -- Lakukan pencarian....
   cSQLCmd = "SELECT * FROM " + cTableName + " WHERE " + cIndex + ;
      IIF(AT("%", cExp) <> 0, " LIKE '" + cExp, " = '" + cExp) + "'"
   IF fnRequery(cSQLCmd, cCursor) = .F. THEN
      MESSAGEBOX("Error melakukan pencarian data ke SQL Servernya... ", 64, "SQL Seek")
      RETURN -1
   ENDIF
   
   * -- Cek, ada datanya apa nggak..
   IF RECCOUNT(cCursor) > 0 THEN
      RETURN 1
   ELSE
      RETURN 0
   ENDIF   
ENDFUNC

* Procedure Angka2Text
PROCEDURE fnTerbilang
	LPARAMETERS nValue
	LOCAL nLength, cValue, cDigit
	
	nValue = TRANSFORM(nValue,"999999999999999999.99")
	nLength = LEN(ALLTRIM(nValue))
	
	cValue = ''
	** Jika, length Value TIDAK SAMA dengan 0
	DO WHILE nLength >= 1
		** Set Value per Character
		cDigit = SUBSTR(ALLTRIM(nValue),nLength,1)
		
		** Jika Value Angka
		IF ASC(cDigit) >= 48 AND ASC(cDigit) <= 57
			cValue = cValue + cDigit
			ELSE 
			EXIT 
		ENDIF 
		nLength = nLength - 1
	ENDDO 

	** 
	nValue = SUBSTR(ALLTRIM(nValue),1,nLength-1)
	SET DECIMALS TO 0
	nValue = SUBSTR(PADL(VAL(nValue),18,'#'),1,18)
	SET DECIMALS TO 2
	
	DECLARE cSatuan(1,5)
	cSatuan(1) =' '
	cSatuan(2) =' ribu '
	cSatuan(3) =' juta '
	cSatuan(4) =' milyar '
	cSatuan(5) =' trilyun ' 	

	DECLARE cBilang(1,5)
	cBilang(1)=Right(nValue,3)
	cBilang(2)=SUBSTR(Right(nValue,6),1,3)
	cBilang(3)=SUBSTR(Right(nValue,9),1,3)
	cBilang(4)=SUBSTR(Right(nValue,12),1,3)
	cBilang(5)=SUBSTR(Right(nValue,15),1,3)

	FOR i = 1 TO 5 STEP 1
		If SUBSTR(cBilang(i),3,1) ='#'
			i = i - 1
			EXIT
		ELSE 
			IF SUBSTR(cBilang(i),2,1) ='#' OR SUBSTR(cBilang(i),1,1) ='#' 
				cBilang(i) = STRTRAN(cBilang(i),'#','0') 
				EXIT
			ENDIF
		ENDIF		
	ENDFOR

	FOR j = 1 TO i
		IF !ISNULL(cBilang(j))
			cBilang(j) = fnHuruf(cBilang(j)) + cSatuan(j)
		ENDIF		
	ENDFOR

	IF ISNULL(cBilang(1))
		cBilang(1)= cSatuan(1) 
	ENDIF

	FOR j = 1 TO ( i - 1 )
		IF !ISNULL(cBilang( j + 1 ))
			cBilang( j + 1 ) = cBilang( j + 1 ) + cBilang(j)
		ELSE
			cBilang( j + 1 ) = cBilang(j)
		ENDIF
	ENDFOR
	IF fnDecimal(cValue)='00'
		cAngkaText = cBilang(i)
	ELSE 
		cAngkaText = cBilang(i) + ' point '+ fnDecimal(cValue)
	ENDIF 
	RETURN cAngkaText
ENDPROC 

FUNCTION fnDecimal
	LPARAMETERS cDecimal
	LOCAL cDecimal1, cDecimal2
	
	cDecimal1 = SUBSTR(cDecimal,2,1)
	cDecimal2 = SUBSTR(cDecimal,1,1)
	DO CASE 
		CASE cDecimal1 = '0'
			IF cDecimal2 = '0'
				cDecimal1 = '00'
			ELSE 
				cDecimal1 = 'nol '+ fnAngka(cDecimal2)
			ENDIF 
		CASE cDecimal1 = '1'
			IF cDecimal2 = '0'
				cDecimal1 = 'sepuluh'
			ELSE 
				cDecimal1 = fnAngka(cDecimal2) + 'belas'
			ENDIF 
		OTHERWISE 
			IF cDecimal2 = '0'
				cDecimal1 = fnAngka(cDecimal1) + ' puluh'
			ELSE 
				cDecimal1 = fnAngka(cDecimal1) + ' puluh ' + fnAngka(cDecimal2)
			ENDIF 
	ENDCASE 
	RETURN cDecimal1
ENDFUNC 

FUNCTION fnHuruf
	LPARAMETERS cValue
	LOCAL cNilai1, cNilai2, cNilai3
	
	cNilai1 = SUBSTR(cValue,1,1)
	cNilai2 = SUBSTR(cValue,2,1)
	cNilai3 = SUBSTR(cValue,3,1)
	DO CASE
		CASE cNilai2 = '0'
			IF cNilai3 = '0'
				cNilai2 = NULL
			ELSE
				cNilai2 = fnAngka(cNilai3)
			ENDIF
		CASE cNilai2 = '1'
			DO cASE
			CASE cNilai3 = '0'
				cNilai2 = 'sepuluh '
			CASE cNilai3 = '1'
				cNilai2 = 'sebelas '
			OTHER
				cNilai2 = fnAngka(cNilai3) + 'belas'
			ENDCASE
		OTHER
			IF cNilai3 = '0'
				cNilai2 = fnAngka(cNilai2) + ' puluh'
			ELSE
				cNilai2 = fnAngka(cNilai2) + ' puluh ' + fnAngka(cNilai3)
			ENDIF
	ENDCASE
	
	DO CASE
		CASE cNilai1 = '0'
			cNilai1 = cNilai2
		CASE cNilai1 = '1'
			IF !ISNULL(cNilai2)
				cNilai1 = 'seratus ' + cNilai2
			ELSE
				cNilai1 = 'seratus'
			ENDIF
		OTHER
			IF !ISNULL(cNilai2)
				cNilai1 = fnAngka(cNilai1) + ' ratus ' + cNilai2
			ELSE
				cNilai1 = fnAngka(cNilai1) + ' ratus'
			ENDIF
	ENDCASE
	RETURN cNilai1
ENDFUNC
FUNCTION fnAngka
	LPARAMETERS cValue
	DO CASE 
		CASE cValue = '1'
			RETURN 'satu' 
		CASE cValue = '2'
			RETURN 'dua' 
		CASE cValue = '3'
			RETURN 'tiga' 
		CASE cValue = '4'
			RETURN 'empat' 
		CASE cValue = '5'
			RETURN 'lima' 
		CASE cValue = '6'
			RETURN 'enam' 
		CASE cValue = '7'
			RETURN 'tujuh' 
		CASE cValue = '8'
			RETURN 'delapan' 
		CASE cValue = '9'
			RETURN 'sembilan'
		OTHER 
	ENDCASE
ENDPROC 



* -- Fungsi untuk mendapatkan nama hari dari suatu tanggal.....
FUNCTION fnNamaHari
LPARAMETERS dTgl
LOCAL nDOW   
   DO CASE
      CASE (TYPE("dTgl") = "D") .OR. (TYPE("dTgl") = "T")
         nDOW = DOW(dTgl, 1)
         
      CASE TYPE("dTgl") = "N"
         nDOW = dTgl
         
      OTHERWISE
         RETURN ""
         
   ENDCASE
   
   DO CASE 
      CASE nDow = 1 
         RETURN "Minggu"
      
      CASE nDow = 2
         RETURN "Senin"

      CASE nDow = 3 
         RETURN "Selasa"

      CASE nDow = 4 
         RETURN "Rabu"

      CASE nDow = 5 
         RETURN "Kamis"

      CASE nDow = 6
         RETURN "Jum'at"

      CASE nDow = 7
         RETURN "Sabtu"
      
      OTHERWISE
         RETURN ""
   ENDCASE
ENDFUNC

* Procedure Tanggal ke Tahun Bulan
PROCEDURE fnDateToPeriode(dDate)
	RETURN RIGHT(STR(YEAR(dDate)),2)+PADL(ALLTRIM(STR(MONTH(dDate))),2,'0')
ENDPROC

* Procedure Tanggal ke Tahun
PROCEDURE fnDateToYear(dDate)
	RETURN RIGHT(ALLTRIM(STR(YEAR(DATE()))),2)
ENDPROC 

* Procedure Selisih berapa bulan antara   01/12/98   dg   04/08/2000 ? hasilnya=20 bulan
PROCEDURE fnMtoM(dDate_Start,dDate_Finish)
	RETURN ABS( ((YEAR(dDate_Start)-1)*12+MONTH(dDate_Start))-;
		((YEAR(dDate_Finish)-1)*12+MONTH(dDate_Finish)) )
ENDPROC 

* Procedure untuk mendapatkan tanggal awal bulan
PROCEDURE fnBoM(dDate)		&& Begin of Month
	RETURN CTOD('01/'+STR(MONTH(dDate))+'/'+STR(YEAR(dDate)))
ENDPROC 

* Procedure untuk mendapatkan tanggal akhir bulan
PROCEDURE fnEoM(dDate)   	&& End of Month
	LOCAL dMonth
	dMonth = GOMONTH(dDate,1)
	RETURN CTOD('01/'+STR(MONTH(dMonth))+'/'+STR(YEAR(dMonth))) - 1
ENDPROC 

* Procedure untuk hari dan bulan
PROCEDURE fnDayMonth(dDate)
	RETURN PADL(ALLTRIM(STR(MONTH(dDate))),2,'0')+'\'+;
		PADL(ALLTRIM(STR(DAY(dDate))),2,'0')
ENDPROC 

*!*	* Procedure Nama Tanggal dalam Indonesia
*!*	PROCEDURE  fnDate_Ind(dMonth)
*!*		cMonth = 'Jan Feb Mar Apr Mei Jun Jul Agt Sep Okt Nov Des'
*!*		cMonth = ALLTRIM(SUBSTR(cMonth,MONTH(dMonth)*4-3,3))
*!*		RETURN cMonth
*!*	ENDPROC 

* Procedure Nama Bulan dalam Indonesia
PROCEDURE  fnMonth_Ind(dMonth)
	cMonth = 'Jan Feb Mar Apr Mei Jun Jul Agt Sep Okt Nov Des'
	cMonth = ALLTRIM(SUBSTR(cMonth,MONTH(dMonth)*4-3,3))
*!*		cMonth = 'Januari  Pebruari Maret    April    Mei      Juni     Juli     Agustus  September Oktober  November Desember'
*!*		cMonth = ALLTRIM(SUBSTR(cMonth,MONTH(dMonth)*9-8,9))
	RETURN cMonth
ENDPROC 

* Procedure Nama Hari dalam Indonesia
PROCEDURE  fnDay_Ind(dDay)
	cDay = 'Minggu Senin  Selasa Rabu   Kamis  Jumat  Sabtu  '
	cDay = ALLTRIM(SUBSTR(cDay,DOW(dDay)*7-6,7))
	RETURN cDay
ENDPROC 

* Procedure Tanggal dalam Indonesia
PROCEDURE  fnDate_Ind(dDate)
	cDate = fnMonth_Ind(dDate)
	cDate = ALLTRIM(STR(DAY(dDate)))+' - '+cDate+' - '+ALLTRIM(STR(YEAR(dDate)))
	RETURN cDate
ENDPROC 

* Procedure Tanggal Format Day , dd/mm/yy 
PROCEDURE fnDate_DayAndInd2DigitYear(dDate)
	cDate = fnDay_Ind(dDate)  +  ', ' + PADL(ALLTRIM(STR(DAY(dDate))),2,'0') + '/'+  PADL(ALLTRIM(STR(MONTH(dDate))),2,'0') + '/' + RIGHT(ALLTRIM(STR(YEAR(dDate))),2) 
	RETURN cDate
ENDPROC

* Procedure Periode
PROCEDURE fnPeriode
	LPARAMETERS cPeriode
	cBulan = 'Januari  Febuari  Maret    April    Mai      Juni     Juli     Agustus September Oktober  November Desember'
	cPeriode = ALLTRIM(SUBSTR(cBulan,VAL(SUBSTR(cPeriode,5,2))*9-8,9)) + " " + ALLTRIM(SUBSTR(cPeriode,1,4))
	RETURN cPeriode
ENDPROC 


*2014/11/27 Fungsi untuk direktori error server
*!*	FUNCTION fnDirErrorServer
*!*		LOCAL cDirTxtserver, cDirserver, cFileTxtserver
*!*		=fnRequery("SELECT cNilai FROM Aturan WHERE Kode = 'Errlog_server'", "tAturan")
*!*		cDirTxtserver = ALLTRIM(tAturan.cNilai)
*!*		USE IN "tAturan"
*!*		cDirserver = JUSTPATH(cDirTxtserver)
*!*		
*!*		cFileTxtserver = IIF(!EMPTY(cDirTxtserver),""+ALLTRIM(cDirTxtserver),"")+;
*!*			"ErrLogServer"+;
*!*			ALLTRIM(STR(YEAR(DATE()))) +;
*!*			PADL(ALLTRIM(STR(WEEK(DATE()))),2,'0')+".Txt"
*!*		RETURN cFileTxtserver
*!*	ENDFUNC

* Fungsi Untuk Error Query
FUNCTION fnError		
	LPARAMETERS nError, cError, cLine, cProg, nLineNo
	LOCAL cErr
	*tambah buat 
	LOCAL cFileTxt, cFileTxt2
	cFileTxt = fnDirError()
	cFileTxt2 = fnDirErrorServer()
				
	cErr = LEFT("Error No.  : " + LTRIM(STR(nError)) + ", " + CHR(13) +;
			"Error Mssg : " + cError + ", " + CHR(13) +;
			"Line Code  : " + cLine + " on line number : " + LTRIM(STR(nLineNo)) + ", " + CHR(13) +;
			"Program    : " + cProg,250)
	WAIT WINDOW cErr TIMEOUT 5	
*!*	    _SCREEN.pError = .T.
    **tadi ini di coment yang pertama
*!*		=fnTextFile(cErr, cFileTxt, .T.)
	=fnTextFile(cErr, cFileTxt2, .T.)
	 RETURN .T.
ENDFUNC 

* Fungsi Untuk Direktori Error Query
FUNCTION fnDirError	
	LOCAL cDirTxt, cDir, cFileTxt	
	cDirTxt = SYS(5) + SYS(2003) + "\ERR\"
	cDir = JUSTPATH(cDirTxt)
	IF !DIRECTORY(cDir)
		cDir = "'"+cDir+"'"
		MD &cDir
	ENDIF 
	
	cFileTxt = IIF(!EMPTY(cDirTxt),""+ALLTRIM(cDirTxt),"")+;
			"ErrLog"+;				
				Alltrim(Str(YEAR(DATE())))+;
				Padl(Alltrim(Str(MONTH(DATE()))),2,'0')+".Txt"
	RETURN cFileTxt
ENDFUNC 

*A 14-12-10 Fungsi untuk Direktori ambil dari dropbox server (tes)
FUNCTION fnDirErrorServer
	LOCAL cDirTxt2, cDir2, cFileTxt2
	cDirTxt2 = fnRead('Update','direktori','DATA\conn.kon') + "ERR\"
*!*		cDirTxt2 = SYS(5) + "\\Winxp\UPdate$\ERR\"
	cDir2 = JUSTPATH(cDirTxt2)
	IF !DIRECTORY(cDir2)
		cDir2 = "'"+cDir2+"'"
*!*			MD &cDir2
	ENDIF
	IF DAY(DATE()) < 15
			cFileTxt2 = IIF(!EMPTY(cDirTxt2),""+ALLTRIM(cDirTxt2),"")+;
				"ErrLogServer"+;
				ALLTRIM(STR(YEAR(DATE()))) +;
				PADL(ALLTRIM(STR(DAY(DATE()))),2,'0')+"A"+".Txt"
		ELSE
			cFileTxt2 = IIF(!EMPTY(cDirTxt2),""+ALLTRIM(cDirTxt2),"")+;
				"ErrLogServer"+;
				ALLTRIM(STR(YEAR(DATE()))) +;
				PADL(ALLTRIM(STR(DAY(DATE()))),2,'0')+"B"+".Txt"
	ENDIF
	RETURN cFileTxt2
ENDFUNC


* Fungsi untuk Error Connection
FUNCTION _MsgErrorConnection
    MESSAGEBOX('Koneksi ke database terputus, HUBUNGI Administrator !!!',48,''+ATT_CAPTION+'',gnSec)
ENDFUNC 


* Fungsi Untuk Error Query / perubahan disini 14-12-10
FUNCTION _MsgErrorQuery		
	LPARAMETERS nError, cError, cLine, cProg, nLineNo
	LOCAL cFileTxt, cFileTxt2
	cFileTxt = fnDirError()
	cFileTxt2 = fnDirErrorServer()
	
	AERROR(arrErr)
	=MESSAGEBOX("Tidak bisa Akses ke DATABASE, HUBUNGI Administrator !!!"+CHR(13)+;
			"Error : " + ArrErr(2),48,''+ATT_CAPTION+'',gnSec)
	=fnTextFile("Error No.   : " + STR(ArrErr(1)) + ", " + CHR(13) + "Error Message : " + ArrErr(2), cFileTxt, .T.)
	=fnTextFile("Error No.   : " + STR(ArrErr(1)) + ", " + CHR(13) + "Error Message : " + ArrErr(2), cFileTxt2, .T.)
ENDFUNC 

* Fungsi Untuk Error Set Connection
FUNCTION _MsgErrorSet
    MESSAGEBOX('Koneksi TIDAK bisa diSET, Transaksi diBATALkan'+CHR(13)+;
    'Hubungi Administrator !!!',48,''+ATT_CAPTION+'',gnSec)
ENDFUNC 

* Fungsi Untuk Error Save
FUNCTION _MsgErrorSave
	MESSAGEBOX('Data TIDAK dapat DISIMPAN...!!!',48,''+ATT_CAPTION+'',gnSec)	
	LOCAL cFileTxt
	cFileTxt = fnDirError()
	
	AERROR(ArrErr)	
	
	=fnTextFile("Error No.   : " + STR(ArrErr(1)) + ", " + CHR(13) + "Error Message : " + ArrErr(2), cFileTxt , .T.)
ENDFUNC 

* Fungsi Untuk Error Edit
FUNCTION _MsgErrorEdit
	LPARAMETERS ATT_NILAI
	IF TYPE("ATT_NILAI") <> "C"
		ATT_NILAI = ALLTRIM(STR(ATT_NILAI))
	ENDIF 
    MESSAGEBOX('Data '+ALLTRIM(UPPER(ATT_NILAI))+' TIDAK dapat DIUBAH',16,''+ATT_CAPTION+'',gnSec)
ENDFUNC 

* Fungsi Untuk Error Delete
FUNCTION _MsgErrorDelete
	LPARAMETERS ATT_NILAI
	IF TYPE("ATT_NILAI") <> "C"
		ATT_NILAI = ALLTRIM(STR(ATT_NILAI))
	ENDIF 
    MESSAGEBOX('Data '+ALLTRIM(UPPER(ATT_NILAI))+' TIDAK dapat DIHAPUS',16,''+ATT_CAPTION+'',gnSec)
ENDFUNC 

* Fungsi Untuk Error Delete, karena DATA ada di Table Lain
FUNCTION _MsgDeleteTable
	LPARAMETERS ATT_NILAI, ATT_TABLE
	IF TYPE("ATT_NILAI") <> "C"
		ATT_NILAI = ALLTRIM(STR(ATT_NILAI))
	ENDIF 
    MESSAGEBOX('Data '+ALLTRIM(UPPER(ATT_NILAI))+' TIDAK dapat DIHAPUS, DATA terdapat pada Tabel '+ALLTRIM(UPPER(ATT_TABLE)),16,''+ATT_CAPTION+'',gnSec)
ENDFUNC 

* Fungsi Untuk Delete
FUNCTION _MsgDelete
	PARAMETERS ATT_TARGET, ATT_NILAI
	IF TYPE("ATT_NILAI") <> "C"
		ATT_NILAI = ALLTRIM(STR(ATT_NILAI))
	ENDIF 
	IF MESSAGEBOX('HAPUS data '+UPPER(ALLTRIM(ATT_TARGET))+' dengan nilai '+UPPER(ALLTRIM(ATT_NILAI))+' ini?',36,''+ATT_CAPTION+'')=6
		ATT_EXECH='ya'
	ELSE
		ATT_EXECH='tdk'
	ENDIF
	RETURN ATT_EXECH
ENDFUNC 

* Fungsi Untuk Empty
FUNCTION _MsgEmpty
	PARAMETERS ATT_TEXT
	MESSAGEBOX('Data '+UPPER(ATT_TEXT)+' masih KOSONG...!!!',48,''+ATT_CAPTION+'',gnSec)
ENDFUNC 

* Fungsi Untuk Data sudah ADA
FUNCTION _MsgFull
	PARAMETERS ATT_TEXT
	MESSAGEBOX('Data '+UPPER(ATT_TEXT)+' sudah ADA...!!!',48,''+ATT_CAPTION+'',gnSec)
ENDFUNC 

* Fungsi Untuk Data TIDAK ADA
FUNCTION _MsgNull
	PARAMETERS ATT_TEXT
	MESSAGEBOX('Data '+ALLTRIM(ATT_TEXT)+' TIDAK ADA...!!!',48,''+ATT_CAPTION+'',gnSec)
ENDFUNC 

* Fungsi Untuk Cek Qty
FUNCTION _MsgLack
	PARAMETERS ATT_TEXT, ATT_QTY
	MESSAGEBOX('Qty '+UPPER(ALLTRIM(ATT_TEXT))+' TIDAK mencukupi permintaan'+CHR(13)+;
	'Qty yang TERSEDIA adalah '+ALLTRIM(STR(ATT_QTY)),48,''+ATT_CAPTION+'',gnSec)
ENDFUNC 

* Fungsi Tanggal
FUNCTION _MsgDate
	PARAMETERS ATT_DATE
	IF MESSAGEBOX('Anda INPUT tanggal '+DTOC(ATT_DATE)+' ?',36,''+ATT_CAPTION+'') = 6
		ATT_EXECH='ya'
	ELSE
		ATT_EXECH='tdk'
	ENDIF
	RETURN ATT_EXECH
ENDFUNC 
