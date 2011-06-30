#include "fakt.ch"


// ---------------------------------------------------------
// centralna funkcija za poziv stampe fiskalnog racuna
// ---------------------------------------------------------
function fisc_rn( cFirma, cTipDok, cBrDok )
local nErr := 0
local nDevice

// listaj mi uredjaje koje imam
nDevice := list_device( cTipDok )

if nDevice > 0
	// setuj parametre za dati uredjaj
	fdev_params( nDevice )
endif

do case
	case ALLTRIM( gFc_type ) == "TRING"
		// tring funkcije
		nErr := rn_to_tfp( cFirma, cTipDok, cBrDok )
	case ALLTRIM( gFc_type ) == "FLINK"
		// flink funkcije
        	nErr := rn_to_flink( cFirma, cTipDok, cBrDok )
	case ALLTRIM( gFc_type ) == "HCP"
		// hcp funkcije
        	nErr := rn_to_hcp( cFirma, cTipDok, cBrDok )
	case ALLTRIM( gFc_type ) == "TREMOL"
		// tremol funkcije
        	nErr := rn_to_trm( cFirma, cTipDok, cBrDok )
	case ALLTRIM( gFc_type ) == "FPRINT"
		// fprint funkcije
        	nErr := rn_to_fprint( cFirma, cTipDok, cBrDok )

endcase

if gFC_error == "D" .and. nErr > 0
	
	if ALLTRIM( gFc_type ) == "TREMOL"
		
		// posalji drugi put za ponistavanje komande racuna
		// parametar continue = 2
		nErr := rn_to_trm( cFirma, cTipDok, cBrDok, "2" )

		if nErr > 0
			msgbeep("Problem sa stampanjem na fiskalni stampac !!!")
		endif
	//else
		// ima greska
		//msgbeep("Problem sa stampanjem na fiskalni stampac !!!")
	endif

endif

return nErr


// ------------------------------------------------
// vraca sifru dobavljaca
// ------------------------------------------------
static function _g_sdob( cIdRoba )
local nRet := 0
local nTArea := SELECT()
select roba
seek cIdRoba

if FOUND()
	nRet := VAL( ALLTRIM( field->sifradob ) )
endif

select (nTArea)
return nRet


// ------------------------------------------------
// vraca sifru partnera
// ------------------------------------------------
static function _g_spart( cIdPartn )
local nRet := 0
local cTmp

cTmp := RIGHT( ALLTRIM( cIdPartn ), 5 )
nRet := VAL( cTmp )

return nRet


// ------------------------------------------------------
// posalji nivelaciju na fiskalni stampac
// ------------------------------------------------------
function ni_to_fiscal( cFirma, cTipDok, cBrDok )
local aItems := {}
local aSem_data := {}

// ako se ne koristi opcija fiscal, izadji !
if gFc_use == "N"
	return
endif

select doks
seek cFirma+cTipDok+cBrDok

nBrDok := VAL(ALLTRIM(field->brdok))
nSemCmd := 3

select fakt
seek cFirma+cTipDok+cBrDok

// upisi u [items] stavke
do while !EOF() .and. field->idfirma == cFirma ;
	.and. field->idtipdok == cTipDok ;
	.and. field->brdok == cBrDok

	// nastimaj se na robu ...
	select roba
	seek fakt->idroba
	
	select fakt

	nSifRoba := _g_sdob( field->idroba )
	cNazRoba := ALLTRIM( konvznwin( roba->naz, gFc_Konv) )
	cBarKod := ALLTRIM( roba->barkod )
	nGrRoba := 1
	nPorStopa := 0
	nR_cijena := ABS( field->cijena )

	AADD( aItems, { nBrDok , ;
			nSifRoba, ;
			cNazRoba, ;
			cBarKod, ;
			nGrRoba, ;
			nPorStopa, ;
			nR_cijena } )

	skip
enddo

// broj reklamnog racuna
nRekl_rn := 0
// print memo od - do
nPrMemoOd := 0
nPrMemoDo := 0
nPartnId := 0

// upisi stavke za [semafor]
AADD( aSem_data, { nBrDok, ;
		nSemCmd, ;
		nPrMemoOd, ;
		nPrMemoDo, ;
		nPartnId, ;
		nRekl_rn })

// nivelacija
// posalji na fiskalni stampac...
	
fisc_nivel( gFC_path, aItems, aSem_data )

return



// -------------------------------------------------------------
// izdavanje fiskalnog isjecka na TREMOL uredjaj
// -------------------------------------------------------------
static function rn_to_trm( cFirma, cTipDok, cBrDok, cContinue )
local cError := ""
local lStorno := .t.
local aStavke := {}
local aKupac := {}
local nNRekRn := 0
local cPartnId := ""
local cVr_placanja := "0"
local nErr := 0
local nFisc_no := 0
local cJibPartn := ""
local lIno := .f.
local cPOslob := ""
local cNF_txt := cFirma + "-" + cTipDok + "-" + ALLTRIM( cBrDok )

if cContinue == nil
	cContinue := "0"
endif

O_DOKS
O_FAKT
O_ROBA
O_SIFK
O_SIFV

// ako se ne koristi opcija fiscal, izadji !
if gFc_use == "N"
	return
endif

select doks
seek ( cFirma + cTipDok + cBrDok )

nBrDok := VAL(ALLTRIM(field->brdok))
nTotal := field->iznos
dDatRn := field->datdok
nNRekRn := field->fisc_rn

select fakt
seek ( cFirma + cTipDok + cBrDok )

nTRec := RECNO()

// da li se radi o storno racunu ?
do while !EOF() .and. field->idfirma == cFirma ;
	.and. field->idtipdok == cTipDok ;
	.and. field->brdok == cBrDok

	if field->kolicina > 0
		lStorno := .f.
		exit
	endif
	
	skip
enddo

// koji je broj racuna koji storniramo
if lStorno 
	Box(,1,60)
		@ m_x + 1, m_y + 2 SAY "Reklamiramo fisk.racun:" ;
			GET nNRekRn PICT "999999999" VALID ( nNRekRn > 0 )
		read
	BoxC()
endif

// kupac
// 1 - id broj kupca
// 2 - naziv
// 3 - adresa
// 4 - ptt
// 5 - grad

if cTipDok $ "10#"

	// uzmi kupca i setuj placanje

	// daj mi partnera za ovu fakturu
	cPartnId := doks->idpartner
	cVr_Placanja := "3"

endif

if !EMPTY( cPartnId )

	cJibPartn := ALLTRIM( IzSifK( "PARTN" , "REGB", cPartnId, .f. ) )
	cPOslob := ALLTRIM( IzSifK( "PARTN" , "PDVO", cPartnId, .f. ) )

	if LEN(cJibPartn) < 12 .or. !EMPTY( cPOslob )
		
		lIno := .t.
	
	elseif LEN( cJibPartn ) = 12

		// ako je pdv obveznik
		// dodaj "4" ispred id broja
		
		cJibPartn := "4" + ALLTRIM( cJibPartn )
		
		lIno := .f.

	endif

	// ako nije INO, onda setuj partnera

	if lIno = .f.
		
		nTarea := SELECT()
	
		select partn
		seek cPartnId

		select (nTArea)

		// provjeri podatke partnera
		lPEmpty := .f.
		lPEmpty := EMPTY( cJibPartn )
		if !lPEmpty
			lPEmpty := EMPTY( partn->naz )
		endif
		if !lPEmpty
			lPEmpty := EMPTY( partn->adresa )
		endif
		if !lPEmpty
			lPEmpty := EMPTY( partn->ptt )
		endif
		if !lPEmpty
			lPEmpty := EMPTY( partn->mjesto )
		endif
		if lPEmpty
			msgbeep("!!! Podaci partnera nisu kompletirani !!!#Prekidam operaciju")
			return 0
		endif
	
		// ubaci u matricu podatke o partneru
		AADD( aKupac, { cJibPartn, partn->naz, partn->adresa, ;
			partn->ptt, partn->mjesto } )
	
	endif

endif

// i total sracunaj sa pdv
// upisat cemo ga u svaku stavku matrice
nTotal := _uk_sa_pdv( cTipDok, cPartnId, nTotal )

// vrati se opet na pocetak
go (nTRec)
select fakt

// upisi u matricu stavke
do while !EOF() .and. field->idfirma == cFirma ;
	.and. field->idtipdok == cTipDok ;
	.and. field->brdok == cBrDok

	// nastimaj se na robu ...
	select roba
	seek fakt->idroba

	if roba->(fieldpos("FISC_PLU")) = 0
		msgbeep("Odraditi modifikaciju struktura, nema FISC_PLU !")
		return 0
	endif

	select fakt

	// storno identifikator
	nSt_Id := 0

	if ( field->kolicina < 0 ) .and. lStorno == .f.
		nSt_id := 1
	endif
	
	cF_brrn := fakt->brdok
	cF_rbr := fakt->rbr
	
	cF_idart := fakt->idroba
	
	cF_barkod := ""
	if roba->(fieldpos("BARKOD")) <> 0
		cF_barkod := ALLTRIM( roba->barkod )
	endif

	nF_plu := 0
	
	if roba->(fieldpos("FISC_PLU")) <> 0
		nF_plu := roba->fisc_plu
	endif

	if gFC_acd == "D"
		// generisanje inkrementalnog PLU kod-a
		nF_plu := auto_plu()
	endif

	nF_pprice := roba->mpc

	cF_artnaz := ALLTRIM( roba->naz )
	cF_artjmj := ALLTRIM( roba->jmj )

	nF_cijena := ABS ( field->cijena )
	
	if cTipDok $ "10#"
		// moramo uzeti cijenu sa pdv-om
		nF_cijena := ABS( _uk_sa_pdv( cTipDok, cPartnId, ;
			field->cijena ) )
		// vrsta placanja je virman
		cVr_placanja := "3"

	endif
	
	nF_kolicina := ABS ( field->kolicina )
	nF_rabat := ABS ( field->rabat ) 

	cF_tarifa := ALLTRIM( roba->idtarifa )

	// ako je za ino kupca onda ide nulta stopa
	// oslobodi ga poreza
	if lIno = .t.
		cF_tarifa := "PDV0"
	endif

	cF_st_rn := ""

	if nNRekRn > 0
		// ovo ce biti racun koji reklamiramo !
		cF_st_rn := ALLTRIM( STR( nNRekRn ))
	endif
	
	// 1 - broj racuna
	// 2 - redni broj
	// 3 - id roba
	// 4 - roba naziv
	// 5 - cijena
	// 6 - kolicina
	// 7 - tarifa
	// 8 - broj racuna za storniranje
	// 9 - roba plu
	// 10 - plu cijena
	// 11 - popust
	// 12 - barkod
	// 13 - vrsta placanja
	// 14 - total racuna
	// 15 - datum racuna
	// 16 - roba jmj

	AADD( aStavke, { cF_brrn , ;
			cF_rbr, ;
			cF_idart, ;
			cF_artnaz, ;
			nF_cijena, ;
			nF_kolicina, ;
			cF_tarifa, ;
			cF_st_rn, ;
			nF_plu, ;
			nF_cijena, ;
			nF_rabat, ;
			cF_barkod, ;
			cVr_placanja, ;
			nTotal, ;
			dDatRn, ;
			cF_artjmj } )

	skip
enddo

if cTipDok $ "10"
	
	// tremol, zbirni racun
	// samo za veleprodaju

	fp_zbirni( @aStavke )

endif

// provjeri prije stampe stavke kolicina, cijena
if trm_check( @aStavke ) < 0
	return 1	
endif

// stampaj racun !
nErr := fc_trm_rn( ALLTRIM( gFC_path ), ;
		ALLTRIM(gFC_name), ;
		aStavke, aKupac, lStorno, ; 
		gFc_error, cContinue )


// pogledati kako obraditi gresku...
if gFc_error == "D"
	
	// provjeri greske...
	// nErr := ...

	cFName := trm_filename( cF_brrn )

	if trm_read_out( ALLTRIM(gFc_path), ALLTRIM(cFName) )
		
		// procitaj poruku greske
		nErr := trm_r_error( ALLTRIM(gFc_path), ALLTRIM(cFName), ;
			gFc_tout, @nFisc_no ) 
		
	else
		nErr := -99
	endif

endif

if nErr = 0 .and. lStorno = .f. .and. cContinue <> "2"

	// vrati broj fiskalnog racuna
	if nFisc_no > 0
		
		msgbeep("Kreiran fiskalni racun broj: " + ;
				ALLTRIM(STR(nFisc_No)))

		// ubaci broj fiskalnog racuna u fakturu
		fisc_to_fakt( cFirma, cTipDok, cBrDok, nFisc_no )
	
	endif

endif

return nErr




// -------------------------------------------------------------
// izdavanje fiskalnog isjecka na HCP uredjaj
// -------------------------------------------------------------
static function rn_to_hcp( cFirma, cTipDok, cBrDok )
local cError := ""
local lStorno := .t.
local aStavke := {}
local aKupac := {}
local nNRekRn := 0
local cPartnId := ""
local cVr_placanja := "0"
local nErr := 0
local nFisc_no := 0
local cJibPartn := ""
local lIno := .f.
local cPOslob := ""
local cNF_txt := cFirma + "-" + cTipDok + "-" + ALLTRIM( cBrDok )
local nU_total

O_DOKS
O_FAKT
O_ROBA
O_SIFK
O_SIFV

// ako se ne koristi opcija fiscal, izadji !
if gFc_use == "N"
	return
endif

select doks
seek ( cFirma + cTipDok + cBrDok )

nBrDok := VAL(ALLTRIM(field->brdok))
nTotal := field->iznos
dDatRn := field->datdok
nNRekRn := field->fisc_rn

select fakt
seek ( cFirma + cTipDok + cBrDok )

nTRec := RECNO()

// da li se radi o storno racunu ?
do while !EOF() .and. field->idfirma == cFirma ;
	.and. field->idtipdok == cTipDok ;
	.and. field->brdok == cBrDok

	if field->kolicina > 0
		lStorno := .f.
		exit
	endif
	
	skip
enddo

// koji je broj racuna koji storniramo
if lStorno 
	Box(,1,60)
		@ m_x + 1, m_y + 2 SAY "Reklamiramo fisk.racun:" ;
			GET nNRekRn PICT "999999999" VALID ( nNRekRn > 0 )
		read
	BoxC()
endif

// kupac
// 1 - id broj kupca
// 2 - naziv
// 3 - adresa
// 4 - ptt
// 5 - grad

if cTipDok $ "10#"

	// uzmi kupca i setuj placanje

	// daj mi partnera za ovu fakturu
	cPartnId := doks->idpartner
	cVr_Placanja := "3"

endif

if !EMPTY( cPartnId )

	cJibPartn := ALLTRIM( IzSifK( "PARTN" , "REGB", cPartnId, .f. ) )
	cPOslob := ALLTRIM( IzSifK( "PARTN" , "PDVO", cPartnId, .f. ) )

	if LEN(cJibPartn) < 12 .or. !EMPTY( cPOslob )
		
		lIno := .t.
	
	elseif LEN( cJibPartn ) = 12

		// ako je pdv obveznik
		// dodaj "4" ispred id broja
		
		cJibPartn := "4" + ALLTRIM( cJibPartn )
		
		lIno := .f.

	endif

	// ako nije INO, onda setuj partnera

	if lIno = .f.
		
		nTarea := SELECT()
	
		select partn
		seek cPartnId

		select (nTArea)

		// provjeri podatke partnera
		lPEmpty := .f.
		lPEmpty := EMPTY( cJibPartn )
		if !lPEmpty
			lPEmpty := EMPTY( partn->naz )
		endif
		if !lPEmpty
			lPEmpty := EMPTY( partn->adresa )
		endif
		if !lPEmpty
			lPEmpty := EMPTY( partn->ptt )
		endif
		if !lPEmpty
			lPEmpty := EMPTY( partn->mjesto )
		endif
		if lPEmpty
			msgbeep("!!! Podaci partnera nisu kompletirani !!!#Prekidam operaciju")
			return 0
		endif
	
		// ubaci u matricu podatke o partneru
		AADD( aKupac, { cJibPartn, partn->naz, partn->adresa, ;
			partn->ptt, partn->mjesto } )
	
	endif

endif

// vrati se opet na pocetak
go (nTRec)

// i total sracunaj sa pdv
// upisat cemo ga u svaku stavku matrice
nTotal := _uk_sa_pdv( cTipDok, cPartnId, nTotal )

// upisi u matricu stavke
do while !EOF() .and. field->idfirma == cFirma ;
	.and. field->idtipdok == cTipDok ;
	.and. field->brdok == cBrDok

	// nastimaj se na robu ...
	select roba
	seek fakt->idroba

	if roba->(fieldpos("FISC_PLU")) = 0
		msgbeep("Odraditi modifikaciju struktura, nema FISC_PLU !")
		return 0
	endif

	select fakt

	// storno identifikator
	nSt_Id := 0

	if ( field->kolicina < 0 ) .and. lStorno == .f.
		nSt_id := 1
	endif
	
	cF_brrn := fakt->brdok
	cF_rbr := fakt->rbr
	
	cF_idart := fakt->idroba
	
	cF_barkod := ""
	if roba->(fieldpos("BARKOD")) <> 0
		cF_barkod := ALLTRIM( roba->barkod )
	endif

	nF_plu := 0
	
	if roba->(fieldpos("FISC_PLU")) <> 0
		nF_plu := roba->fisc_plu
	endif

	if gFC_acd == "D"
		// generisanje inkrementalnog PLU kod-a
		nF_plu := auto_plu()
	endif

	nF_pprice := roba->mpc

	cF_artnaz := ALLTRIM( roba->naz )
	cF_artjmj := ALLTRIM( roba->jmj )

	nF_cijena := ABS ( field->cijena )
	
	if cTipDok $ "10#"
		// moramo uzeti cijenu sa pdv-om
		nF_cijena := ABS( _uk_sa_pdv( cTipDok, cPartnId, ;
			field->cijena ) )
		// vrsta placanja je virman
		cVr_placanja := "3"

	endif
	
	nF_kolicina := ABS ( field->kolicina )
	nF_rabat := ABS ( field->rabat ) 

	cF_tarifa := ALLTRIM( roba->idtarifa )

	// ako je za ino kupca onda ide nulta stopa
	// oslobodi ga poreza
	if lIno = .t.
		cF_tarifa := "PDV0"
	endif

	cF_st_rn := ""

	if nNRekRn > 0
		// ovo ce biti racun koji reklamiramo !
		cF_st_rn := ALLTRIM( STR( nNRekRn ))
	endif
	
	// 1 - broj racuna
	// 2 - redni broj
	// 3 - id roba
	// 4 - roba naziv
	// 5 - cijena
	// 6 - kolicina
	// 7 - tarifa
	// 8 - broj racuna za storniranje
	// 9 - roba plu
	// 10 - plu cijena
	// 11 - popust
	// 12 - barkod
	// 13 - vrsta placanja
	// 14 - total racuna
	// 15 - datum racuna
	// 16 - roba jmj

	AADD( aStavke, { cF_brrn , ;
			cF_rbr, ;
			cF_idart, ;
			cF_artnaz, ;
			nF_cijena, ;
			nF_kolicina, ;
			cF_tarifa, ;
			cF_st_rn, ;
			nF_plu, ;
			nF_cijena, ;
			nF_rabat, ;
			cF_barkod, ;
			cVr_placanja, ;
			nTotal, ;
			dDatRn, ;
			cF_artjmj } )

	skip
enddo

if cTipDok $ "10"
	
	// hcp, zbirni racun
	// samo za veleprodaju

	fp_zbirni( @aStavke )

endif

// provjeri prije stampe stavke kolicina, cijena
if hcp_check( @aStavke ) < 0
	return 1	
endif

// stampaj racun !
nErr := fc_hcp_rn( ALLTRIM( gFC_path ), ;
		ALLTRIM(gFC_name), ;
		aStavke, aKupac, lStorno, ; 
		gFc_error, nTotal )

if nErr = 0 .and. lStorno = .f.

	// vrati broj fiskalnog racuna
	
	nFisc_no := hcp_fisc_no( ALLTRIM(gFc_path), ;
		ALLTRIM(gFc_name), gFc_error )

	if nFisc_no > 0
		
		msgbeep("Kreiran fiskalni racun broj: " + ;
				ALLTRIM(STR(nFisc_No)))

		// ubaci broj fiskalnog racuna u fakturu
		fisc_to_fakt( cFirma, cTipDok, cBrDok, nFisc_no )
	
	endif

endif

return nErr



// -------------------------------------------------------------
// izdavanje fiskalnog isjecka na FPRINT uredjaj
// -------------------------------------------------------------
static function rn_to_fprint( cFirma, cTipDok, cBrDok )
local cError := ""
local lStorno := .t.
local aStavke := {}
local aKupac := {}
local nNRekRn := 0
local cPartnId := ""
local cVr_placanja := "0"
local nErr := 0
local nFisc_no := 0
local cJibPartn := ""
local lIno := .f.
local cPOslob := ""
local cNF_txt := cFirma + "-" + cTipDok + "-" + ALLTRIM( cBrDok )

O_DOKS
O_FAKT
O_ROBA
O_SIFK
O_SIFV

// ako se ne koristi opcija fiscal, izadji !
if gFc_use == "N"
	return
endif

select doks
seek ( cFirma + cTipDok + cBrDok )

nBrDok := VAL(ALLTRIM(field->brdok))
nTotal := field->iznos
dDatRn := field->datdok
nNRekRn := field->fisc_rn

select fakt
seek ( cFirma + cTipDok + cBrDok )

nTRec := RECNO()

// da li se radi o storno racunu ?
do while !EOF() .and. field->idfirma == cFirma ;
	.and. field->idtipdok == cTipDok ;
	.and. field->brdok == cBrDok

	if field->kolicina > 0
		lStorno := .f.
		exit
	endif
	
	skip
enddo

// koji je broj racuna koji storniramo
if lStorno 
	Box(,1,60)
		@ m_x + 1, m_y + 2 SAY "Reklamiramo fisk.racun:" ;
			GET nNRekRn PICT "999999999" VALID ( nNRekRn > 0 )
		read
	BoxC()
endif

// kupac
// 1 - id broj kupca
// 2 - naziv
// 3 - adresa
// 4 - ptt
// 5 - grad

if cTipDok $ "10#"

	// uzmi kupca i setuj placanje

	// daj mi partnera za ovu fakturu
	cPartnId := doks->idpartner
	cVr_Placanja := "3"

endif

if !EMPTY( cPartnId )

	cJibPartn := ALLTRIM( IzSifK( "PARTN" , "REGB", cPartnId, .f. ) )
	cPOslob := ALLTRIM( IzSifK( "PARTN" , "PDVO", cPartnId, .f. ) )

	if LEN(cJibPartn) < 12 .or. !EMPTY( cPOslob )
		
		// ovo je ino partner
		// uzmi podatak iz deviznog ziro racuna

		// medjutim sada necu setovati partnera uopste 
		// ovdje imam problem sa uredjajem
		
		//nTArea := SELECT()
		
		//select partn
		//seek cPartnId

		//select (nTArea)

		//cJibPartn := PADL( ALLTRIM( partn->dziror ), 13, "A" )

		lIno := .t.
	
	elseif LEN( cJibPartn ) = 12

		// ako je pdv obveznik
		// dodaj "4" ispred id broja
		
		cJibPartn := "4" + ALLTRIM( cJibPartn )
		
		lIno := .f.

	endif

	// ako nije INO, onda setuj partnera

	if lIno = .f.
		
		nTarea := SELECT()
	
		select partn
		seek cPartnId

		select (nTArea)

		// provjeri podatke partnera
		lPEmpty := .f.
		lPEmpty := EMPTY( cJibPartn )
		if !lPEmpty
			lPEmpty := EMPTY( partn->naz )
		endif
		if !lPEmpty
			lPEmpty := EMPTY( partn->adresa )
		endif
		if !lPEmpty
			lPEmpty := EMPTY( partn->ptt )
		endif
		if !lPEmpty
			lPEmpty := EMPTY( partn->mjesto )
		endif
		if lPEmpty
			msgbeep("!!! Podaci partnera nisu kompletirani !!!#Prekidam operaciju")
			return 0
		endif
	
		// ubaci u matricu podatke o partneru
		AADD( aKupac, { cJibPartn, partn->naz, partn->adresa, ;
			partn->ptt, partn->mjesto } )
	
	endif

endif

// vrati se opet na pocetak
go (nTRec)

// i total sracunaj sa pdv
// upisat cemo ga u svaku stavku matrice
nTotal := _uk_sa_pdv( cTipDok, cPartnId, nTotal )

// upisi u matricu stavke
do while !EOF() .and. field->idfirma == cFirma ;
	.and. field->idtipdok == cTipDok ;
	.and. field->brdok == cBrDok

	// nastimaj se na robu ...
	select roba
	seek fakt->idroba

	if roba->(fieldpos("FISC_PLU")) = 0
		msgbeep("Odraditi modifikaciju struktura, nema FISC_PLU !")
		return 0
	endif

	select fakt

	// storno identifikator
	nSt_Id := 0

	if ( field->kolicina < 0 ) .and. lStorno == .f.
		nSt_id := 1
	endif
	
	cF_brrn := fakt->brdok
	cF_rbr := fakt->rbr
	
	cF_idart := fakt->idroba
	
	cF_barkod := ""
	if roba->(fieldpos("BARKOD")) <> 0
		cF_barkod := ALLTRIM( roba->barkod )
	endif

	nF_plu := 0
	
	if roba->(fieldpos("FISC_PLU")) <> 0
		nF_plu := roba->fisc_plu
	endif

	if gFC_acd == "D" .and. gFc_zbir <> 1
		// generisanje inkrementalnog PLU kod-a
		// ako je opcija zbirnog racuna 1 - onda nece generisati
		nF_plu := auto_plu()
	endif

	nF_pprice := roba->mpc

	cF_artnaz := ALLTRIM( konvznwin( roba->naz, gFc_konv) )
	cF_artjmj := ALLTRIM( roba->jmj )

	nF_cijena := ABS ( field->cijena )
	
	if cTipDok $ "10#"
		// moramo uzeti cijenu sa pdv-om
		nF_cijena := ABS( _uk_sa_pdv( cTipDok, cPartnId, ;
			field->cijena ) )

	endif
	
	nF_kolicina := ABS ( field->kolicina )
	nF_rabat := ABS ( field->rabat ) 

	cF_tarifa := ALLTRIM( roba->idtarifa )

	// ako je za ino kupca onda ide nulta stopa
	// oslobodi ga poreza
	if lIno = .t.
		cF_tarifa := "PDV0"
	endif

	cF_st_rn := ""

	if nNRekRn > 0
		// ovo ce biti racun koji reklamiramo !
		cF_st_rn := ALLTRIM( STR( nNRekRn ))
	endif
	
	// 1 - broj racuna
	// 2 - redni broj
	// 3 - id roba
	// 4 - roba naziv
	// 5 - cijena
	// 6 - kolicina
	// 7 - tarifa
	// 8 - broj racuna za storniranje
	// 9 - roba plu
	// 10 - plu cijena
	// 11 - popust
	// 12 - barkod
	// 13 - vrsta placanja
	// 14 - total racuna
	// 15 - datum racuna
	// 16 - roba jmj

	AADD( aStavke, { cF_brrn , ;
			cF_rbr, ;
			cF_idart, ;
			cF_artnaz, ;
			nF_cijena, ;
			nF_kolicina, ;
			cF_tarifa, ;
			cF_st_rn, ;
			nF_plu, ;
			nF_cijena, ;
			nF_rabat, ;
			cF_barkod, ;
			cVr_placanja, ;
			nTotal, ;
			dDatRn, ;
			cF_artjmj } )

	skip
enddo

if cTipDok $ "10"
	
	// fprint, zbirni racun
	// samo za veleprodaju

	fp_zbirni( @aStavke )

endif

// provjeri prije stampe stavke kolicina, cijena
if fp_check( @aStavke, lStorno ) < 0
	return 1	
endif

// pobrisi answer fajl
fp_d_answer( ALLTRIM(gFc_path) )

// ispisi racun
fp_pos_rn( ALLTRIM( gFC_path ), ;
	ALLTRIM( gFC_name ), aStavke, aKupac, lStorno, cError  )


// procitaj gresku!
nErr := fp_r_error( ALLTRIM( gFC_path ), gFc_tout, @nFisc_no )

if nFisc_no <= 0
	nErr := 1
endif

if nErr <> 0
	
	msgbeep("Postoji greska sa stampanjem !!!")

	// vrati dokument u pripremu...
	// to do

else
	
	if gFC_nftxt == "D"
		// printaj non-fiscal txt
		// u ovom slucaju broj racuna iz fakt
		fp_nf_txt( ALLTRIM( gFC_path ), ;
			ALLTRIM( gFC_name ), cNF_txt )
	endif

	msgbeep("Kreiran fiskalni racun broj: " + ALLTRIM(STR(nFisc_No)))

	// ubaci broj fiskalnog racuna u fakturu
	fisc_to_fakt( cFirma, cTipDok, cBrDok, nFisc_no )

endif

return nErr


// --------------------------------------------------
// napravi zbirni racun ako je potrebno
// --------------------------------------------------
static function fp_zbirni( aData )
local aTmp := {}
local nTotal := 0
local nKolicina := 1
local cArt_naz := ""
local nDataLen := LEN( aData )

if gFc_zbir < 1 .or. gFc_acd == "P" .or. ( gFc_zbir > 1 .and. gFc_zbir < nDataLen )
	// ova opcija se ne koristi
	// ako je iskljucena opcija
	// ili ako je sifra artikla genericki PLU
	// ili ako je zadato da ide iznad neke vrijednosti stavki na racunu
	return
endif

cArt_naz := "Stavke racuna"

if ALLTRIM( gFc_type ) $ "#FPRINT#HCP#"
	cArt_naz += " " + ALLTRIM( aData[1, 1] )
endif

// ukupna vrijednost racuna za sve stavke matrice je ista popunjena
nTotal := ROUND2( aData[1, 14], 2 )

if !EMPTY( aData[1, 8] )
	// ako je storno racun
	// napravi korekciju da je iznos pozitivan
	nTotal := ABS( nTotal )
endif

// dodaj u aTmp zbirnu stavku...
AADD( aTmp, { aData[1, 1] , ;
	aData[1, 2], ;
	"", ;
	cArt_naz, ;
	nTotal, ;
	nKolicina, ;
	aData[1, 7], ;
	aData[1, 8], ;
	auto_plu(), ;
	nTotal, ;
	0, ;
	"", ;
	aData[1, 13], ;
	nTotal, ;
	aData[1, 15], ;
	aData[1, 16] } )


// proslijedi u aData
aData := aTmp

return



// -------------------------------------------------------------
// setovanje broja fiskalnog racuna u dokumentu 
// -------------------------------------------------------------
static function fisc_to_fakt( cFirma, cTD, cBroj, nFiscal )
local nTArea := SELECT()

select doks
set order to tag "1"
seek cFirma + cTD + cBroj

replace field->fisc_rn with nFiscal

select (nTArea)
return




// -------------------------------------------------------------
// izdavanje fiskalnog isjecka na TFP uredjaj - tring
// -------------------------------------------------------------
static function rn_to_tfp( cFirma, cTipDok, cBrDok )
local cError := ""
local lStorno := .t.
local aStavke := {}
local aKupac := {}
local nReklRn := 0
local nTipRn := 0
local nPartnId := 0

// ako se ne koristi opcija fiscal, izadji !
if gFc_use == "N"
	return
endif

select doks
seek ( cFirma + cTipDok + cBrDok )

nBrDok := VAL(ALLTRIM(field->brdok))
nTotal := field->iznos
nNRekRn := 0

if nReklRn <> 0
	Box(,1,60)
		@ m_x + 1, m_y + 2 SAY "Broj rekl.fiskalnog racuna:" ;
			GET nNRekRn PICT "99999" VALID ( nNRekRn > 0 )
		read
	BoxC()
endif

select fakt
seek ( cFirma + cTipDok + cBrDok )

nTRec := RECNO()

// da li se radi o storno racunu ?
do while !EOF() .and. field->idfirma == cFirma ;
	.and. field->idtipdok == cTipDok ;
	.and. field->brdok == cBrDok

	if field->kolicina > 0
		lStorno := .f.
		exit
	endif
	
	skip
enddo

nPartnId := 0

if cTipDok $ "10#"

	// veleprodajni racun

	nTipRn := 2
	
	// daj mi partnera za ovu fakturu
	nPartnId := _g_spart( doks->idpartner )
	
elseif cTipDok $ "11#"
	
	// maloprodajni racun

	nTipRn := 1

	// nema parnera
	nPartnId := 0

endif

// vrati se opet na pocetak
go (nTRec)

// upisi u matricu stavke
do while !EOF() .and. field->idfirma == cFirma ;
	.and. field->idtipdok == cTipDok ;
	.and. field->brdok == cBrDok

	// nastimaj se na robu ...
	select roba
	seek fakt->idroba
	
	select fakt

	// storno identifikator
	nSt_Id := 0

	if ( field->kolicina < 0 ) .and. lStorno == .f.
		nSt_id := 1
	endif
	
	cF_brrn := fakt->brdok
	cF_rbr := fakt->rbr
	
	cF_idart := fakt->idroba
	cF_barkod := ALLTRIM( roba->barkod )

	cF_artnaz := ALLTRIM( konvznwin( roba->naz, gFC_konv) )
	cF_artjmj := ALLTRIM( roba->jmj )

	nF_cijena := ABS ( field->cijena )
	nF_kolicina := ABS ( field->kolicina )
	nF_rabat := ABS ( field->rabat ) 

	cF_tarifa := roba->idtarifa
	cF_st_rn := ""
	
	dF_datum := fakt->datdok

	AADD( aStavke, { cF_brrn , ;
			cF_rbr, ;
			cF_idart, ;
			cF_artnaz, ;
			nF_cijena, ;
			nF_rabat, ;
			nF_kolicina, ;
			cF_tarifa, ;
			cF_st_rn, ;
			dF_datum, ;
			cF_artjmj } )

	skip
enddo

// ispisi racun
fc_trng_rn( ALLTRIM( gFC_path ), ;
	ALLTRIM( gFC_name ), aStavke, aKupac, lStorno, cError  )

return



// ------------------------------------------------------
// posalji racun na fiskalni stampac
// ------------------------------------------------------
static function rn_to_flink( cFirma, cTipDok, cBrDok )
local aItems := {}
local aTxt := {}
local aPla_data := {}
local aSem_data := {}
local lStorno := .t.
local aMemo := {}
local nBrDok
local nReklRn := 0
local cStPatt := "/S"
local GetList := {}

// ako se ne koristi opcija fiscal, izadji !
if gFc_use == "N"
	return
endif

select doks
seek cFirma+cTipDok+cBrDok

// ako je storno racun ...
if cStPatt $ ALLTRIM(field->brdok)
	nReklRn := VAL( STRTRAN( ALLTRIM(field->brdok), cStPatt, "" ))	
endif

nBrDok := VAL(ALLTRIM(field->brdok))
nTotal := field->iznos
nNRekRn := 0

if nReklRn <> 0
	Box(,1,60)
		@ m_x + 1, m_y + 2 SAY "Broj rekl.fiskalnog racuna:" ;
			GET nNRekRn PICT "99999" VALID ( nNRekRn > 0 )
		read
	BoxC()
endif

select fakt
seek cFirma+cTipDok+cBrDok

nTRec := RECNO()

// da li se radi o storno racunu ?
do while !EOF() .and. field->idfirma == cFirma ;
	.and. field->idtipdok == cTipDok ;
	.and. field->brdok == cBrDok

	if field->kolicina > 0
		lStorno := .f.
		exit
	endif
	
	skip

enddo

// nTipRac = 1 - maloprodaja
// nTipRac = 2 - veleprodaja

// nSemCmd = semafor komanda
//           0 - stampa mp racuna
//           1 - stampa storno mp racuna
//           20 - stampa vp racuna
//           21 - stampa storno vp racuna

nSemCmd := 0
nPartnId := 0

if cTipDok $ "10#"

	// veleprodajni racun

	nTipRac := 2
	
	// daj mi partnera za ovu fakturu
	nPartnId := _g_spart( doks->idpartner )
	
	// stampa vp racuna
	nSemCmd := 20

	if lStorno == .t.
		// stampa storno vp racuna
		nSemCmd := 21
	endif

elseif cTipDok $ "11#"
	
	// maloprodajni racun

	nTipRac := 1

	// nema parnera
	nPartnId := 0

	// stampa mp racuna
	nSemCmd := 0

	if lStorno == .t.
		// stampa storno mp racuna
		nSemCmd := 1
	endif

endif

// vrati se opet na pocetak
go (nTRec)

// upisi u [items] stavke
do while !EOF() .and. field->idfirma == cFirma ;
	.and. field->idtipdok == cTipDok ;
	.and. field->brdok == cBrDok

	// nastimaj se na robu ...
	select roba
	seek fakt->idroba
	
	select fakt

	// storno identifikator
	nSt_Id := 0

	if ( field->kolicina < 0 ) .and. lStorno == .f.
		nSt_id := 1
	endif
	
	nSifRoba := _g_sdob( field->idroba )
	cNazRoba := ALLTRIM( konvznwin( roba->naz, gFC_konv) )
	cBarKod := ALLTRIM( roba->barkod )
	nGrRoba := 1
	nPorStopa := 1
	nR_cijena := ABS( field->cijena )
	nR_kolicina := ABS( field->kolicina )

	AADD( aItems, { nBrDok , ;
			nTipRac, ;
			nSt_id, ;
			nSifRoba, ;
			cNazRoba, ;
			cBarKod, ;
			nGrRoba, ;
			nPorStopa, ;
			nR_cijena, ;
			nR_kolicina } )

	skip
enddo

// tip placanja
// --------------------
// 0 - gotovina
// 1 - cek
// 2 - kartica
// 3 - virman

nTipPla := 0

if lStorno == .f.
	// povrat novca
	nPovrat := 0	
	// uplaceno novca
	nUplaceno := nTotal
else
	// povrat novca
	nPovrat := nTotal	
	// uplaceno novca
	nUplaceno := 0
endif

// upisi u [pla_data] stavke
AADD( aPla_data, { nBrDok, ;
		nTipRac, ;
		nTipPla, ;
		ABS(nUplaceno), ;
		ABS(nTotal), ;
		ABS(nPovrat) })

// RACUN.MEM data
AADD( aTxt, { "fakt: " + cTipDok + "-" + cBrDok } )

// reklamni racun uzmi sa box-a
nReklRn := nNRekRn
// print memo od - do
nPrMemoOd := 1
nPrMemoDo := 1

// upisi stavke za [semafor]
AADD( aSem_data, { nBrDok, ;
		nSemCmd, ;
		nPrMemoOd, ;
		nPrMemoDo, ;
		nPartnId, ;
		nReklRn })


if nTipRac = 2
	
	// veleprodaja
	// posalji na fiskalni stampac...
	
	fisc_v_rn( gFC_path, aItems, aTxt, aPla_data, aSem_data )

elseif nTipRac = 1
	
	// maloprodaja
	// posalji na fiskalni stampac
	
	fisc_m_rn( gFC_path, aItems, aTxt, aPla_data, aSem_data )

endif

return


// --------------------------------------------------------
// vraca broj fiskalnog isjecka
// --------------------------------------------------------
function fisc_isjecak( cFirma, cTipDok, cBrDok )
local nTArea := SELECT()
local nFisc_no := 0

select doks
go top
seek cFirma + cTipDok + cBrDok

if doks->(FIELDPOS("FISC_RN")) <> 0 .and. FOUND() .and. field->fisc_rn <> 0
	nFisc_no := field->fisc_rn
endif

select (nTArea)
return ALLTRIM( STR( nFisc_no ) )



