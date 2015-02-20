*!*	SELECT p.kode, p.nama, j.kode, p.induk_id, p.produk_id, i.nama as kategori, p.urutan ;
*!*		FROM produk p ;
*!*	LEFT JOIN pJenis j ON p.pJenis_Id = j.pJenis_Id ;
*!*			LEFT JOIN produk i ON p.induk_id = i.produk_id ;
*!*		WHERE p.urutan > 0 ;
*!*			AND p.pJenis_Id = 1 ;
*!*		ORDER BY p.induk_id, p.produk_id","_tPKategori")