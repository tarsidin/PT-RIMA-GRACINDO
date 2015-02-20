PROCEDURE fnBulanRomawi(dTanggal)
cRoma = 'I   II  III IV  V   VI  VII VIIIIX  X   XI  XII '  
cRoma = ALLTRIM(SUBSTR(cRoma,(MONTH(dTanggal)-1)*4,4))
RETURN cRoma
ENDPROC

PROCEDURE fnNomorBeli(npajak,njenis,dtanggal,nNomor,cELKM)
		cpajak = IIF(npajak =1 ,"PAP","PAH")				  
		cBulan = fnBulanRomawi(dtanggal)
		cJenis = ICASE(njenis = 1 ,"PO",;
					   njenis = 2 ,"SJ",;
					   njenis = 3 ,"BJ",;
					   njenis = 4 ,"BP",;
					   njenis = 5 ,"SP")
					   
		c3Digit = SUBSTR(nNomor,4,4)
		cTahun  = SUBSTR(ALLTRIM(STR(YEAR(dTanggal))),3,2)
		
	  	cHasil = c3Digit+"/"+cjenis+"-"+cpajak+'/EL/'+cBulan+'/'+cTahun	  	
	RETURN chasil  
ENDPROC 

PROCEDURE fnSjalan(npajak,dtanggal,nNomor,cELKM)
		cBulan = fnBulanRomawi(dtanggal)
		cTahun  = SUBSTR(ALLTRIM(STR(YEAR(dTanggal))),3,2)
		IF(nPajak=1)
			cpajak= "/ELP/"
			c4Digit = SUBSTR(nNomor,6,4)
		ELSE
			cpajak= "/"
			c4Digit = SUBSTR(nNomor,4,6)
		ENDIF
	  	cHasil = c4Digit+cpajak+cBulan+'/'+cTahun	  	
	RETURN chasil  
ENDPROC 

PROCEDURE fnno_faktur(npajak,dtanggal,nNomor,cELKM)
		cBulan = fnBulanRomawi(dtanggal)
		cTahun  = SUBSTR(ALLTRIM(STR(YEAR(dTanggal))),3,2)
		IF(nPajak=1)
			cpajak= "EL/PAP"
			c4Digit = SUBSTR(nNomor,6,4)
		ELSE
			cpajak= "PAP"
			c4Digit = SUBSTR(nNomor,6,4)
		ENDIF
	  	cHasil = cpajak+"/"+cTahun+"/"+cBulan+"/"+c4Digit 	  	
	RETURN chasil  
ENDPROC 
*!*	c3Digit = SUBSTR(nNomor,6,3)
*!*			cTahun  = SUBSTR(ALLTRIM(STR(YEAR(dTanggal))),3,2)
