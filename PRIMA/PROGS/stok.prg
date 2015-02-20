** 120801 - Tutup Buku Stok
PROCEDURE fnTutupStok
	LPARAMETERS cPeriode, cProduk
	
	LOCAL cCommand, cWhere, nConn
	LOCAL dTanggalAwal, dTanggalAkhir, cPeriodeAkhir
	
	
	dTanggalAwal = DTOT(DATE(VAL(SUBSTR(cPeriode,1,4)),VAL(SUBSTR(cPeriode,5,2)),1))
	dTanggalAkhir = DTOT(GOMONTH(TTOD(dTanggalAwal),1) - 1)
	cPeriodeAkhir = LEFT(DTOC(TTOD(dTanggalAkhir) + 1,1),6)
	
	STORE SQLSTRINGCONNECT(_SCREEN.pConnection_name) TO nConn
	IF nConn < 0
		=MESSAGEBOX("Tidak Dapat Koneksi ke DATABASE",64,ATT_CAPTION)
		RETURN .F.
	ENDIF 
	
	
	STORE "" TO cCommand, cWhere
	
	** 120801 - Cek Saldo Stok untuk periode berjalan
	=fnRequery("SELECT distinct CONVERT(CHAR(20),Periode) as Periode, validasi "+;
		"FROM saldo "+;
		"WHERE periode = '"+ALLTRIM(cPeriode)+"'","tPeriode",nConn)
	
	
*!*		** 120801 - Cek Validasi, jika belum, ditolak
*!*		IF !EMPTY(NVL(tPeriode.validasi,1)) = 0
*!*			=MESSAGEBOX("DATA pada Periode "+fnPeriode(cPeriode)+" Belum divalidasi"+CHR(13)+;
*!*				"Silahkan Validasi periode tersebut, sebelum melanjutkan PROSES"+CHR(13)+;
*!*				"Proses dibatalkan...",64,ATT_CAPTION)
*!*			RETURN .F.
*!*		ENDIF 
	
	
	** 120801 - Untuk periode Awal
	IF !EMPTY(tPeriode.periode) <> ''
		=fnRequery("DELETE FROM temp_saldo","",nConn)
		
		cCommand =;
			"INSERT INTO temp_saldo (produk_id, jumlah, jenis) "+;
			"SELECT dt.produk_id, SUM(dt.g1_masuk - dt.g1_keluar) as jumlah, 1 "+;
				"FROM t_stokg1 dt  "+;
				"WHERE dt.g1_tgl < '"+ALLTRIM(LEFT(TTOC(dTanggalAwal,3),10))+"' "+;
				"GROUP BY dt.produk_id "
		=fnRequery(cCommand,"",nConn)
		
		
	ENDIF 
	
	** 120801 - Data Produk di Table Saldo
	=fnRequery("DELETE FROM saldo WHERE periode = '"+cPeriodeAkhir+"' ","",nConn)
	cCommand =;
		"INSERT INTO saldo (produk_id, harga, jenis, periode) "+;
		"SELECT dt.produk_id, IFNULL(dt.harga,0) "+;
		 			"*(100 - IFNULL(dt.disc1,0))/100 "+;
		 			"*(100 - IFNULL(dt.disc2,0))/100 "+;
		 			"*(100 - IFNULL(dt.disc3,0))/100), 1, '"+cPeriodeAkhir+"' "+;
			"FROM t_produk dt  "
	=fnRequery(cCommand,"",nConn)
		
	=fnDisConnect(nConn)
ENDPROC 