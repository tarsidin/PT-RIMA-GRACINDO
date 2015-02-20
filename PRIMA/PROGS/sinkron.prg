Lparameters lCommand, lImport, lExport
If lCommand = .T.
	**S 130304 -- Informasikan kepada User, Bahwa Proses Import sedang dijalankan
	If lImport = .T.
		Wait Window "Proses Import Data..." Nowait
	Endif

	**S 130304 -- Informasikan kepada User, Bahwa Proses Export sedang dijalankan
	If lExport = .T.
		Wait Window "Proses Export Data..." Nowait
	Endif

	**S 130304 -- Jalankan fungsi Sinkronisasi
	=fnSinkron(lImport, lExport)
Endif




**S 130304 -- Transfer Data ke Mesin Absensi
Procedure fnSinkron
	Lparameters lImport, lExport

	**S 130319 -- Deklarasi Variabel Filter
	Public pdTglAwalSinkronMaster, pdTglAwalSinkron, pdTglAkhirSinkron
	Store Ctot(Dtoc(Date()-30)+' 00:00:00') To pdTglAwalSinkronMaster
	Store Ctot(Dtoc(Date()-3)+' 00:00:00') To pdTglAwalSinkron
	Store Ctot(Dtoc(Date())+' 23:59:59') To pdTglAkhirSinkron

	Local lError, cOnError
	**S 130304 -- Siapkan dulu error
	cOnError = On("ERROR")
	On Error lError = .T.

	**S 130304 -- Buat Koneksi ke Database
	Local nConn, nTConn
	=SQLSetprop(0,"DispLogin",3)
	Store Sqlstringconnect(_Screen.pConnection_Name) To nConn
	If nConn < 0
		Wait Window "Gagal Koneksi ke Database..." Timeout 2
		=fnDisConnect(nConn)
		Return .F.
	Endif



	**S 130304 -- Siapin Progressbarnya...
	Set Classlib To libs\_therm.vcx Additive
	oProgBar = Createobject("_Thermometer")
	oProgBar.Show()

	**S 130304 -- Check Pusat
	Set Procedure To "PROGS\gudang.prg" Additive
	Local lPusat
	lPusat = Iif(fnGudangID()=0, .T., .F.)

	**S 130319 -- Set Variabel Query
	Local cUpdate, cInsert, cSelect, cWhere, cWhereMaster

	**S 130319 -- Set cWhereMaster
	cWhereMaster = "WHERE IFNULL(mt.date_ch, mt.date_add) BETWEEN ?pdTglAwalSinkronMaster AND ?pdTglAkhirSinkron "

	**S 130304 -- Set cWhere
	cWhere = "WHERE IFNULL(mt.date_ch, mt.date_add) BETWEEN ?pdTglAwalSinkron AND ?pdTglAkhirSinkron "

	**S 130304 -- Proses untuk Setiap Gudang
	=fnRequery("SELECT s.sinkron_id, IFNULL(g.kode,'PST') as kode, IFNULL(g.nama,'Pusat') as nama, "+;
		"s.db_server, s.db_nama, s.db_user, s.db_password "+;
		"FROM sinkron s "+;
		"LEFT JOIN gudang g ON g.gudang_id = s.gudang_id "+;
		"WHERE IFNULL(s.pusat,0) = "+Iif(lPusat, "0", "1")+" "+;
		"ORDER BY g.kode", "tSinkron", nConn)

	Select "tSinkron"
	Go Top In "tSinkron"
	Scan All
		**S 130304 -- Buka Koneksi Database ke Gudang
		=SQLSetprop(0,"DispLogin",3)
		Store Sqlstringconnect(fnConnType("3", Alltrim(tSinkron.db_server), Alltrim(tSinkron.db_user), Alltrim(tSinkron.db_password), Alltrim(tSinkron.db_nama))) To nTConn
		If nTConn < 0
			Wait Window "Gagal Koneksi ke Database "+Alltrim(tSinkron.kode)+"..." Timeout 2
			=fnDisConnect(nTConn)
			Loop
		Endif

		**S 130304 -- Tulis ke File Log
		cFileTxt = "Transfer_"+Alltrim(Str(Year(Date())))+Padl(Alltrim(Str(Month(Date()))),2,'0')+".Txt"
		=fnTextFile("", cFileTxt, .F.)


		**S 130304 -- Jika Import
		If lImport

			**S 130304 -- Jika program Pusat
			If lPusat
				**S 130304 -- Import Data Header Transaksi Pemakaian Barang dari Gudang
				=fnRequery("SELECT mt.* FROM pakai mt "+cWhere,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Pakai
				cInsert = fnInsertSQL("pakai")
				cUpdate = fnUpdateSQL("pakai")
				cSelect = fnSelectSQL("pakai")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Header Transaksi Pemakaian Barang dari Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Import Data Detail Transaksi Pemakaian Barang dari Gudang
				=fnRequery("SELECT dt.* FROM pakai mt "+;
					"LEFT JOIN pakai_detail dt ON dt.pakai_no = mt.pakai_no "+cWhere,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Detail Pemakaian Barang
				cInsert = fnInsertSQL("pakai_detail")
				cUpdate = fnUpdateSQL("pakai_detail")
				cSelect = fnSelectSQL("pakai_detail")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Detail Transaksi Pemakaian Barang dari Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In tCek
				Endscan
				Use In "tT"


				**S 130304 -- Import Data Header Transaksi Retur dari Gudang
				=fnRequery("SELECT mt.* FROM retur mt "+cWhere,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Retur
				cInsert = fnInsertSQL("retur")
				cUpdate = fnUpdateSQL("retur")
				cSelect = fnSelectSQL("retur")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Header Transaksi Retur dari Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Import Data Detail Transaksi Retur dari Gudang
				=fnRequery("SELECT dt.* FROM retur mt "+;
					"LEFT JOIN retur_detail dt ON dt.retur_no = mt.retur_no "+cWhere,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Detail Retur
				cInsert = fnInsertSQL("retur_detail")
				cUpdate = fnUpdateSQL("retur_detail")
				cSelect = fnSelectSQL("retur_detail")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Detail Transaksi Retur dari Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In tCek
				Endscan
				Use In "tT"


				**S 130304 -- Import Data Header Transaksi Penerimaan Barang dari Gudang
				=fnRequery("SELECT mt.* FROM terima mt "+cWhere,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Penerimaan Barang
				cInsert = fnInsertSQL("terima")
				cUpdate = fnUpdateSQL("terima")
				cSelect = fnSelectSQL("terima")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Header Transaksi Penerimaan Barang dari Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Import Data Detail Transaksi Penerimaan Barang dari Gudang
				=fnRequery("SELECT dt.* FROM terima mt "+;
					"LEFT JOIN terima_detail dt ON dt.terima_no = mt.terima_no "+cWhere,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Detail Penerimaan Barang
				cInsert = fnInsertSQL("terima_detail")
				cUpdate = fnUpdateSQL("terima_detail")
				cSelect = fnSelectSQL("terima_detail")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Detail Transaksi Penerimaan Barang dari Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In tCek
				Endscan
				Use In "tT"


				**S 130304 -- Jika program Cabang
			Else

				**S 1303019 -- Import Data Master Sinkronisasi dari Pusat
				=fnRequery("SELECT mt.* FROM sinkron mt "+cWhereMaster,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Sinkronisasi
				cInsert = fnInsertSQL("sinkron")
				cUpdate = fnUpdateSQL("sinkron")
				cSelect = fnSelectSQL("sinkron")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Master Sinkronisasi dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Import Data Master Gudang dari Pusat
				=fnRequery("SELECT mt.* FROM gudang mt "+cWhereMaster,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Gudang
				cInsert = fnInsertSQL("gudang")
				cUpdate = fnUpdateSQL("gudang")
				cSelect = fnSelectSQL("gudang")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Master Gudang dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Import Data Master Konsumen dari Pusat
				=fnRequery("SELECT mt.* FROM konsumen mt "+cWhereMaster,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Konsumen
				cInsert = fnInsertSQL("konsumen")
				cUpdate = fnUpdateSQL("konsumen")
				cSelect = fnSelectSQL("konsumen")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Master Konsumen dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Import Data Master Mesin dari Pusat
				=fnRequery("SELECT mt.* FROM mesin mt "+cWhereMaster,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Mesin
				cInsert = fnInsertSQL("mesin")
				cUpdate = fnUpdateSQL("mesin")
				cSelect = fnSelectSQL("mesin")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Master Mesin dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Import Data Master Operator dari Pusat
				=fnRequery("SELECT mt.* FROM operator mt "+cWhereMaster,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Operator
				cInsert = fnInsertSQL("operator")
				cUpdate = fnUpdateSQL("operator")
				cSelect = fnSelectSQL("operator")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Master Operator dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Import Data Master Pemakai dari Pusat
				=fnRequery("SELECT mt.* FROM pemakai mt "+cWhereMaster,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Pemakai
				cInsert = fnInsertSQL("pemakai")
				cUpdate = fnUpdateSQL("pemakai")
				cSelect = fnSelectSQL("pemakai")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Master Pemakai dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Import Data Master Pemasok dari Pusat
				=fnRequery("SELECT mt.* FROM pemasok mt "+cWhereMaster,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Pemasok
				cInsert = fnInsertSQL("pemasok")
				cUpdate = fnUpdateSQL("pemasok")
				cSelect = fnSelectSQL("pemasok")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Master Pemasok dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Import Data Master Produk dari Pusat
				=fnRequery("SELECT mt.* FROM produk mt "+cWhereMaster,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Produk
				cInsert = fnInsertSQL("produk")
				cUpdate = fnUpdateSQL("produk")
				cSelect = fnSelectSQL("produk")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Master Produk dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Import Data Master Sales dari Pusat
				=fnRequery("SELECT mt.* FROM sales mt "+cWhereMaster,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Sales
				cInsert = fnInsertSQL("sales")
				cUpdate = fnUpdateSQL("sales")
				cSelect = fnSelectSQL("sales")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Master Sales dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Import Data Master Satuan dari Pusat
				=fnRequery("SELECT mt.* FROM satuan mt "+cWhereMaster,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Satuan
				cInsert = fnInsertSQL("satuan")
				cUpdate = fnUpdateSQL("satuan")
				cSelect = fnSelectSQL("satuan")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Master Satuan ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Import Data Header Transaksi Pembelian dari Pusat
				=fnRequery("SELECT mt.* FROM beli mt "+cWhere,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Beli
				cInsert = fnInsertSQL("beli")
				cUpdate = fnUpdateSQL("beli")
				cSelect = fnSelectSQL("beli")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Imprt Data Header Transaksi Pembelian dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Import Data Detail Transaksi Pembelian dari Pusat
				=fnRequery("SELECT dt.* FROM beli mt "+;
					"LEFT JOIN beli_detail dt ON dt.beli_no = mt.beli_no "+cWhere,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Beli
				cInsert = fnInsertSQL("beli_detail")
				cUpdate = fnUpdateSQL("beli_detail")
				cSelect = fnSelectSQL("beli_detail")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Detail Transaksi Pembelian dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Import Data Header Transaksi Penjualan dari Pusat
				=fnRequery("SELECT mt.* FROM jual mt "+cWhere,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Jual
				cInsert = fnInsertSQL("jual")
				cUpdate = fnUpdateSQL("jual")
				cSelect = fnSelectSQL("jual")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Header Transaksi Penjualan dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Import Data Detail Transaksi Penjualan dari Pusat
				=fnRequery("SELECT dt.* FROM jual mt "+;
					"LEFT JOIN jual_detail dt ON dt.jual_no = mt.jual_no "+cWhere,"tT",nTConn)

				**S 130304 -- Generate Query Tabel Jual
				cInsert = fnInsertSQL("jual_detail")
				cUpdate = fnUpdateSQL("jual_detail")
				cSelect = fnSelectSQL("jual_detail")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Detail Transaksi Pembelian dari " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nConn)
					Else
						=fnRequery(cInsert,"",nConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"

			Endif

		Endif



		**S 130304 -- Jika Export
		If lExport

			**S 130304 -- Jika program Pusat
			If lPusat

				**S 130319 -- Ekspor Data Master Sinkronisasi ke Gudang
				=fnRequery("SELECT mt.* FROM sinkron mt "+cWhereMaster,"tT",nConn)

				**S 130304 -- Generate Query Tabel Sinkronisasi
				cInsert = fnInsertSQL("sinkron")
				cUpdate = fnUpdateSQL("sinkron")
				cSelect = fnSelectSQL("sinkron")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Master Sinkronisasi ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Ekspor Data Master Gudang ke Gudang
				=fnRequery("SELECT mt.* FROM gudang mt "+cWhereMaster,"tT",nConn)

				**S 130304 -- Generate Query Tabel Gudang
				cInsert = fnInsertSQL("gudang")
				cUpdate = fnUpdateSQL("gudang")
				cSelect = fnSelectSQL("gudang")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Master Gudang ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Ekspor Data Master Konsumen ke Gudang
				=fnRequery("SELECT mt.* FROM konsumen mt "+cWhereMaster,"tT",nConn)

				**S 130304 -- Generate Query Tabel Konsumen
				cInsert = fnInsertSQL("konsumen")
				cUpdate = fnUpdateSQL("konsumen")
				cSelect = fnSelectSQL("konsumen")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Master Konsumen ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Ekspor Data Master Mesin ke Gudang
				=fnRequery("SELECT mt.* FROM mesin mt "+cWhereMaster,"tT",nConn)

				**S 130304 -- Generate Query Tabel Mesin
				cInsert = fnInsertSQL("mesin")
				cUpdate = fnUpdateSQL("mesin")
				cSelect = fnSelectSQL("mesin")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Master Mesin ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Ekspor Data Master Operator ke Gudang
				=fnRequery("SELECT mt.* FROM operator mt "+cWhereMaster,"tT",nConn)

				**S 130304 -- Generate Query Tabel Operator
				cInsert = fnInsertSQL("operator")
				cUpdate = fnUpdateSQL("operator")
				cSelect = fnSelectSQL("operator")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Master Operator ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Ekspor Data Master Pemakai ke Gudang
				=fnRequery("SELECT mt.* FROM pemakai mt "+cWhereMaster,"tT",nConn)

				**S 130304 -- Generate Query Tabel Pemakai
				cInsert = fnInsertSQL("pemakai")
				cUpdate = fnUpdateSQL("pemakai")
				cSelect = fnSelectSQL("pemakai")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Master Pemakai ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Ekspor Data Master Pemasok ke Gudang
				=fnRequery("SELECT mt.* FROM pemasok mt "+cWhereMaster,"tT",nConn)

				**S 130304 -- Generate Query Tabel Pemasok
				cInsert = fnInsertSQL("pemasok")
				cUpdate = fnUpdateSQL("pemasok")
				cSelect = fnSelectSQL("pemasok")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Master Pemasok ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Ekspor Data Master Produk ke Gudang
				=fnRequery("SELECT mt.* FROM produk mt "+cWhereMaster,"tT",nConn)

				**S 130304 -- Generate Query Tabel Produk
				cInsert = fnInsertSQL("produk")
				cUpdate = fnUpdateSQL("produk")
				cSelect = fnSelectSQL("produk")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Master Produk ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Ekspor Data Master Sales ke Gudang
				=fnRequery("SELECT mt.* FROM sales mt "+cWhereMaster,"tT",nConn)

				**S 130304 -- Generate Query Tabel Sales
				cInsert = fnInsertSQL("sales")
				cUpdate = fnUpdateSQL("sales")
				cSelect = fnSelectSQL("sales")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Master Sales ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130319 -- Ekspor Data Master Satuan ke Gudang
				=fnRequery("SELECT mt.* FROM satuan mt "+cWhereMaster,"tT",nConn)

				**S 130304 -- Generate Query Tabel Satuan
				cInsert = fnInsertSQL("satuan")
				cUpdate = fnUpdateSQL("satuan")
				cSelect = fnSelectSQL("satuan")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Master Satuan ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Ekspor Data Header Transaksi Pembelian ke Gudang
				=fnRequery("SELECT mt.* FROM beli mt "+cWhere,"tT",nConn)

				**S 130304 -- Generate Query Tabel Beli
				cInsert = fnInsertSQL("beli")
				cUpdate = fnUpdateSQL("beli")
				cSelect = fnSelectSQL("beli")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Header Transaksi Pembelian ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Ekspor Data Detail Transaksi Pembelian ke Gudang
				=fnRequery("SELECT dt.* FROM beli mt "+;
					"LEFT JOIN beli_detail dt ON dt.beli_no = mt.beli_no "+cWhere,"tT",nConn)

				**S 130304 -- Generate Query Tabel Beli
				cInsert = fnInsertSQL("beli_detail")
				cUpdate = fnUpdateSQL("beli_detail")
				cSelect = fnSelectSQL("beli_detail")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Detail Transaksi Pembelian ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Ekspor Data Header Transaksi Penjualan ke Gudang
				=fnRequery("SELECT mt.* FROM jual mt "+cWhere,"tT",nConn)

				**S 130304 -- Generate Query Tabel Jual
				cInsert = fnInsertSQL("jual")
				cUpdate = fnUpdateSQL("jual")
				cSelect = fnSelectSQL("jual")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Header Transaksi Penjualan ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Ekspor Data Detail Transaksi Penjualan ke Gudang
				=fnRequery("SELECT dt.* FROM jual mt "+;
					"LEFT JOIN jual_detail dt ON dt.jual_no = mt.jual_no "+cWhere,"tT",nConn)

				**S 130304 -- Generate Query Tabel Jual
				cInsert = fnInsertSQL("jual_detail")
				cUpdate = fnUpdateSQL("jual_detail")
				cSelect = fnSelectSQL("jual_detail")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Ekspor Data Detail Transaksi Penjualan ke Gudang " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Jika program Cabang
			Else

				**S 130304 -- Eksport Data Header Transaksi Pemakaian Barang ke Pusat
				=fnRequery("SELECT mt.* FROM pakai mt "+cWhere,"tT",nConn)

				**S 130304 -- Generate Query Tabel Pakai
				cInsert = fnInsertSQL("pakai")
				cUpdate = fnUpdateSQL("pakai")
				cSelect = fnSelectSQL("pakai")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Eksport Data Header Transaksi Pemakaian Barang ke " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Eksport Data Detail Transaksi Pemakaian Barang ke Pusat
				=fnRequery("SELECT dt.* FROM pakai mt "+;
					"LEFT JOIN pakai_detail dt ON dt.pakai_no = mt.pakai_no "+cWhere,"tT",nConn)

				**S 130304 -- Generate Query Tabel Detail Pemakaian Barang
				cInsert = fnInsertSQL("pakai_detail")
				cUpdate = fnUpdateSQL("pakai_detail")
				cSelect = fnSelectSQL("pakai_detail")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Import Data Detail Transaksi Pemakaian Barang ke " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In tCek
				Endscan
				Use In "tT"


				**S 130304 -- Eksport Data Header Transaksi Retur ke Pusat
				=fnRequery("SELECT mt.* FROM retur mt "+cWhere,"tT",nConn)

				**S 130304 -- Generate Query Tabel Retur
				cInsert = fnInsertSQL("retur")
				cUpdate = fnUpdateSQL("retur")
				cSelect = fnSelectSQL("retur")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Eksport Data Header Transaksi Retur ke " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Eksport Data Detail Transaksi Retur ke Pusat
				=fnRequery("SELECT dt.* FROM retur mt "+;
					"LEFT JOIN retur_detail dt ON dt.retur_no = mt.retur_no "+cWhere,"tT",nConn)

				**S 130304 -- Generate Query Tabel Detail Retur
				cInsert = fnInsertSQL("retur_detail")
				cUpdate = fnUpdateSQL("retur_detail")
				cSelect = fnSelectSQL("retur_detail")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Eksport Data Detail Transaksi Retur ke " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In tCek
				Endscan
				Use In "tT"


				**S 130304 -- Eksport Data Header Transaksi Penerimaan Barang ke Pusat
				=fnRequery("SELECT mt.* FROM terima mt "+cWhere,"tT",nConn)

				**S 130304 -- Generate Query Tabel Penerimaan Barang
				cInsert = fnInsertSQL("terima")
				cUpdate = fnUpdateSQL("terima")
				cSelect = fnSelectSQL("terima")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Eksport Data Header Transaksi Penerimaan Barang ke " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In "tCek"
				Endscan
				Use In "tT"


				**S 130304 -- Eksport Data Detail Transaksi Penerimaan Barang ke Pusat
				=fnRequery("SELECT dt.* FROM terima mt "+;
					"LEFT JOIN terima_detail dt ON dt.terima_no = mt.terima_no "+cWhere,"tT",nConn)

				**S 130304 -- Generate Query Tabel Detail Penerimaan Barang
				cInsert = fnInsertSQL("terima_detail")
				cUpdate = fnUpdateSQL("terima_detail")
				cSelect = fnSelectSQL("terima_detail")

				Select "tT"
				Go Top
				Scan All
					**S 130304 -- Yang dilakukan selama proses....
					oProgBar.Update(Recno("tT")/Reccount("tT") * 100,;
						"Eksport Data Detail Transaksi Penerimaan Barang ke " + Alltrim(tSinkron.nama) + "... " +;
						ALLTRIM(Str(Recno("tT"))) + "/" + Alltrim(Str(Reccount("tT"))))

					**S 130304 -- Cari data, apakah sudah ada
					=fnRequery(cSelect,"tCek",nTConn)

					**S 130304 -- Jika Data
					If Reccount("tCek") <> 0
						=fnRequery(cUpdate,"",nTConn)
					Else
						=fnRequery(cInsert,"",nTConn)
					Endif
					Use In tCek
				Endscan
				Use In "tT"

			Endif

		Endif


		**S 130304 -- Tutup Koneksi ke Database Tujuan
		If nTConn <> 0
			=fnDisConnect(nTConn)
			Loop
		Endif
	Endscan


	**S 130304 -- Tutup Kursor Sinkronisasi
	Use In "tSinkron"

	**S 130304 -- Tutup Koneksinya dan buang progressbarnya....
	oProgBar.Release()

	**S 130304 -- Release Variabel Public
	Release pdTglAwalSinkron
	Release pdTglAkhirSinkron

	**S 130304 -- Informasikan Proses Selesai
	Wait Window "Proses Sinkronisasi SELESAI...."  Nowait
Endproc




Procedure fnInsertSQL
	Lparameters cTable

	Select tT
	Local nKolom, nCount, cCommand, cField, cValue
	nKolom = Afields(aKolom)

	Store "" To cCommand, cField, cValue
	For nCount = 1 To nKolom
		cField = cField + Iif(!Empty(cField),", ","") +;
			LOWER(aKolom(nCount,1))
		cValue = cValue + Iif(!Empty(cValue),", ","") +;
			"?tT."+Lower(aKolom(nCount,1))
	Endfor
	cCommand =;
		"INSERT INTO "+Alltrim(cTable)+;
		" ( "+cField+" ) "+;
		"VALUES ( "+cValue+" ) "

	Return cCommand
Endproc

Procedure fnUpdateSQL
	Lparameters cTable

	Select tT
	Local nKolom, nCount, cCommand, cWhere, cValue
	nKolom = Afields(aKolom)

	Store "" To cCommand, cValue, cWhere
	For nCount = 1 To nKolom
		If nCount = 1
			cWhere = "WHERE "+Lower(aKolom(nCount,1)) + " = ?tT."+Lower(aKolom(nCount,1))
		Endif
		cValue = cValue + Iif(!Empty(cValue),", ","") +;
			LOWER(aKolom(nCount,1)) + " = ?tT."+Lower(aKolom(nCount,1))
	Endfor
	cCommand =;
		"UPDATE "+Alltrim(cTable)+;
		" SET "+cValue+" "+;
		cWhere

	Return cCommand
Endproc

Procedure fnSelectSQL
	Lparameters cTable

	Select tT
	Local nKolom, nCount, cCommand, cWhere, cValue
	nKolom = Afields(aKolom)

	Store "" To cCommand, cValue, cWhere
	cWhere =;
		"WHERE "+Lower(aKolom(1,1)) + " = ?tT."+Lower(aKolom(1,1))

	cCommand =;
		"SELECT "+Lower(aKolom(1,1))+" "+;
		"FROM "+Alltrim(cTable)+" "+;
		cWhere

	Return cCommand
Endproc
