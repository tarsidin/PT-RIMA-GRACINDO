CLOSE TABLES ALL 
LOCAL cKode

USE data\material.dbf
SELECT material
SCAN WHILE !EOF()
	IF EMPTY(material_no)
		cKode = fnNumber("Tahun","Material",5,DATE())
		REPLACE material_no WITH cKode IN material		
	ENDIF 
ENDSCAN 
CLOSE TABLES ALL 