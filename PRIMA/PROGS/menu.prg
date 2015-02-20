**S 110712 -- Deklarasi Variabel
LOCAL cMenu, nMenu, cNamaMenu
LOCAL nSubMenu, cNamaSubMenu
LOCAL nUlang
LOCAL cCommand

**S 110712 -- Jumlah Menu
STORE "_MSYSMENU" TO cMenu
STORE CNTBAR(cMenu) TO nMenu

FOR nUlang=1 TO nMenu STEP 1
	**S 110712 -- Jumlah SubMenu
	STORE PRMBAR(cMenu, GETBAR(cMenu, nUlang)) TO cNamaMenu
	STORE CNTBAR(ALLTRIM(cNamaMenu)) TO nSubMenu		
	FOR J=1 TO nSubMenu STEP 1
		cCommand = ""
		STORE PRMBAR(ALLTRIM(cNamaMenu), GETBAR(ALLTRIM(cNamaMenu), J)) TO cNamaSubMenu
		**S 110712 -- Ambil Aturan ke Tabel Pemakai_Detail
		=fnRequery("SELECT formpass FROM pemakai_detail "+;
						"WHERE pemakai_id = " + ALLTRIM(STR(gnIDUser)) + " "+;
							"AND UPPER(menu) = '" + UPPER(ALLTRIM(cNamaSubMenu)) + "' ","tPeriksa")
		SELECT "tPeriksa"
		IF RECCOUNT("tPeriksa") > 0
			IF tPeriksa.formpass = 0 
				cCommand = "SET SKIP OF BAR " + ALLTRIM(STR(J)) + " OF " + ALLTRIM(cNamaMenu) + " .T."
				&cCommand
			ENDIF
		ENDIF
		USE IN "tPeriksa"
	ENDFOR
ENDFOR




