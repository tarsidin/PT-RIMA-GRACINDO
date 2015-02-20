CREATE CURSOR tHasil (;
	so_no			char(20) null,;
	produk			char(250) null,;
	ukuran_id		int null,;
	qty_order		float(18,2) null,;
	tempkuantitas 	float(18,2) null;
)
				
				
				
=fnRequery("SELECT dt.so_no, u.Nama as ukuran, p.ukuran_id, sum(dt.Qty_order) as qty_order, "+;
					"sum((dt.konversi*dt.kuantitas)+((mt.kuantitas-mt.kuantitas_pakai)*mt.konversi)) as tempKuantitas "+;
				"FROM Pakai_detail dt "+;
					"LEFT JOIN so_detail mt ON mt.so_detail = dt.so_detail "+;
					"LEFT JOIN produk p ON dt.produk_id = p.produk_id "+;
					"LEFT JOIN warna w on w.Warna_Id = p.warna_id "+; 
					"LEFT JOIN Ukuran u on u.Ukuran_Id = p.ukuran_id "+;
				"Where dt.so_no = 'JO1407.0001' "+;
				"group by dt.so_no, u.Nama, p.ukuran_id ", "tUkuran")
				
INSERT INTO tHasil;
	SELECT * FROM tUkuran
	
	

=fnRequery("SELECT dt.so_no, w.Nama as warna, p.ukuran_id "+;
				"FROM Pakai_detail dt "+;
					"LEFT JOIN so_detail mt ON mt.so_detail = dt.so_detail "+;
					"LEFT JOIN produk p ON dt.produk_id = p.produk_id "+;
					"LEFT JOIN warna w on w.Warna_Id = p.warna_id "+;
				"Where dt.so_no = 'JO1407.0001'" , "tWarna")
				
				
SELECT "tWarna"
GO TOP
SCAN ALL
	UPDATE tHasil SET produk = ALLTRIM(produk) + ", " + ALLTRIM(tWarna.warna);
		WHERE ukuran_id = tWarna.ukuran_id		
ENDSCAN