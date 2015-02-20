**S 130304 -- Procedure untuk penamaan Gudang dari table aturan
PROCEDURE fnNamaGudang
	LOCAL cNilai
	**S 130304 -- Ambil Data Kode di table Aturan
	=fnRequery("SELECT cNilai AS Kode FROM Aturan WHERE Kode = 'Kode'","tKode")
	=fnRequery("SELECT cNilai AS Nama FROM Aturan WHERE Kode = 'Nama'","tNama")
	
	**S 130304 -- Cek, jika Ada Datanya 
	IF RECCOUNT('tKode') <> 0 OR RECCOUNT('tNama') <> 0
		**S 130304 -- tidak Kosong
		IF EMPTY(NVL(tKode.Kode,'')) OR EMPTY(NVL(tNama.Nama,''))
			**S 130304 -- Buka Form Aturan
*!*				DO FORM forms\utils\aturan_toko.scx
			cNilai = ''
		ELSE 
			**S 130304 -- jika ada Isi
			cNilai = ALLTRIM(tKode.Kode)+" ("+ALLTRIM(tNama.Nama)+")"
		ENDIF 		
	ENDIF 
	USE IN tKode
	USE IN tNama
	
	RETURN cNilai
ENDPROC 


PROCEDURE fnGudang
	LOCAL cNilai
	STORE "" TO cNilai
	**S 130304 -- Ambil Data Kode di table Aturan
	=fnRequery("SELECT cNilai AS cNilai FROM Aturan WHERE Kode = 'Kode'","tCek")
	
	**S 130304 -- Cek, jika Ada Datanya 
	IF RECCOUNT('tCek') <> 0
		**S 130304 -- tidak Kosong
		IF EMPTY(NVL(tCek.cNilai,''))
			**S 130304 -- Buka Form Aturan
*!*				DO FORM forms\utils\aturan_toko.scx
			cNilai = ''
		ELSE 
			**S 130304 -- jika ada Isi
			cNilai = tCek.cNilai
		ENDIF 		
	ENDIF 
	USE IN tCek	
	RETURN cNilai
ENDPROC 


PROCEDURE fnGudangID
	LOCAL nNilai
	STORE 0 TO nNilai
	=fnRequery("SELECT cNilai AS cNilai FROM Aturan WHERE Kode = 'Kode'","tCek")
	IF RECCOUNT("tCek") <> 0
		**S 130304 -- Ambil Data Kode di table Aturan
		=fnRequery("SELECT g.gudang_id "+;
				"FROM Aturan a "+;
					"JOIN Gudang g ON a.cNilai = g.kode "+;
				"WHERE a.Kode = 'Kode'","tCek")
		
		**S 130304 -- Cek, jika Ada Datanya 
		IF RECCOUNT('tCek') <> 0
			**S 130304 -- tidak Kosong
			IF EMPTY(NVL(tCek.gudang_id,0))
				**S 130304 -- Buka Form Aturan
*!*					DO FORM forms\utils\aturan_toko.scx
				nNilai = 0
			ELSE 
				**S 130304 -- jika ada Isi
				nNilai = tCek.gudang_id
			ENDIF 		
		ENDIF 
	ENDIF 
	USE IN tCek	
	RETURN nNilai
ENDPROC 


**S 130304 -- Prosedur untuk Mendapatkan Kode Transaksi Berdasarkan Gudang
PROCEDURE fnCabangTr
	LPARAMETERS nCabang_ID
	LOCAL cNilai
	STORE "" TO cNilai
	=fnRequery("SELECT Kode AS kode FROM Cabang WHERE cabang_id = "+ALLTRIM(STR(nCabang_ID))+" ","tCek")
	IF RECCOUNT("tCek") <> 0	
		**S 130304 -- jika ada Isi
		cNilai = tCek.kode	
	ENDIF 
	USE IN tCek	
	RETURN cNilai
ENDPROC 