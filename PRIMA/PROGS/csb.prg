**Y 20131228 - Update stok di produk
PROCEDURE fnHitungUlangStok
	LPARAMETERS nCabang_id
	** 130315 - Panggil Kartu Stok
	=fnRequery("exec dbo.sp_rekapKoreksi "+;
		"@dTanggalAwal = ?pdTanggalAwal,"+;
		"@dTanggalAkhir = ?pdTanggalAkhir,"+;
		"@nProduk_Id = 0, "+;
		"@nCabang_Id = ?pnCabang_id, "+;
		"@nKondisi= 0 ","_tKartuStok")
		
		WAIT WINDOW "Mulai Transfer Data..." Nowait	
		LOCAL cCommand, cField
		LOCAL nConn, oProgBar
		STORE SQLSTRINGCONNECT(_SCREEN.pConnection_Name) TO nConn
		
		IF nConn < 0
			WAIT WINDOW "Tidak Dapat Koneksi ke Database" TIMEOUT 2 
			RETURN .F.
		ENDIF 
		
		SET CLASSLIB TO libs\_therm.vcx ADDITIVE 
	    oProgBar = CREATEOBJECT("_Thermometer")       
		oProgBar.Show()
		
	SELECT _tKartuStok
	GO TOP IN _tKartuStok
	SCAN ALL
	oProgBar.Update(RECNO("_tKartuStok")/RECCOUNT("_tKartuStok")*100,"Import Saldo...   "+ALLTRIM(STR(RECNO("_tKartuStok")))+" dari "+ALLTRIM(STR(RECCOUNT("_tKartuStok"))))
	
	WAIT WINDOW "Hitung Ulang Stok...."+ALLTRIM(STR(RECNO("_tKartuStok")))+" of "+ALLTRIM(STR(RECCOUNT("_tKartuStok"))) NOWAIT
	
	=fnRequery("UPDATE produk_cabang SET kuantitas=?_tKartuStok.akhir_sat WHERE produk_id=?_tKartuStok.produk_id AND cabang_id=?pnCabang_id ")
	
	ENDSCAN 
ENDPROC


*!*	PROCEDURE fnAturJadwal
*!*	LPARAMETERS nRange, dProduksi
*!*		LOCAL nMinggu, nHasil
*!*		nMinggu=FLOOR((nRange+DOW(dProduksi))/7)
*!*		nHasil=dProduksi+nRange+nMinggu
*!*	RETURN nHasil
*!*	ENDPROC

PROCEDURE fnAturJadwal
LPARAMETERS nRange, dProduksi
	LOCAL nMinggu, nHasil
	nMinggu=FLOOR((nRange+DOW(dProduksi))/7)
	nHasil=dProduksi+((nRange+nMinggu)*3600*24)
RETURN nHasil
ENDPROC


