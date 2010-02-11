#include "fakt.ch"


// --------------------------------------------
// realizacija maloprodaje fakt
// --------------------------------------------
function real_mp()
local nOperater
local cFirma
local dD_from
local dD_to
local cDocType
local nVar
local nT_uk := 0
local nT_pdv := 0
local nT_osn := 0

// uslovi izvjestaja
if g_vars( @cFirma, @dD_from, @dD_to, @cDocType, @nOperater, @nVar ) == 0
	return
endif

// generisi pomocnu tabelu
_cre_tbl()

// generisi promet u pomocnu tabelu
_gen_rek( cFirma, dD_from, dD_to, cDocType, nOperater )

// ima li podataka za prikaz ?
select r_export
if reccount2() == 0
	
	msgbeep("Nema podataka za prikaz !")
	close all
	return

endif

START PRINT CRET

?
? "REALIZACIJA PRODAJE na dan: " + DTOC( dD_to )
? "-----------------------------------------------"
? "Period od:" + DTOC( dD_from ) + " do:" + DTOC( dD_to )
?

P_COND

// stampaj po operateru
_st_mp_oper()

?

if nVar = 1
	// odstampaj po robi
	_st_mp_roba( @nT_osn, @nT_pdv, @nT_uk )
else
	// odstampaj po dokumentima
	_st_mp_dok( @nT_osn, @nT_pdv, @nT_uk )
endif

?

// rekapitulacija
P_10CPI

? "REKAPITULACIJA:"
? "---------------------------"
? "1) ukupno bez pdv-a:", STR( nT_osn, 12, 2 )
? "2) vrijednost pdv-a:", STR( nT_pdv, 12, 2 )
? "3)    ukupno sa pdv:", STR( nT_uk, 12, 2 )

FF
END PRINT

return


// --------------------------------------------
// uslovi izvjestaja
// --------------------------------------------
static function g_vars( cFirma, dD_from, dD_to, cDokType, nOperater, nVar )
local nRet := 1
local nX := 1

cFirma := SPACE(50)
dD_from := DATE()
dD_to := DATE()
cDokType := PADR( "11;", 50 )
nOperater := 0
nVar := 1

Box( , 10, 66)

	@ m_x + nX, m_y + 2 SAY "**** REALIZACIJA PRODAJE ****"

	++ nX
	++ nX
	
	@ m_x + nX, m_y + 2 SAY "Firma (prazno-sve):" GET cFirma ;
		PICT "@S20"
	
	++ nX

	@ m_x + nX, m_y + 2 SAY "Obuhvatiti period od:" GET dD_from
	@ m_x + nX, col() + 1 SAY "do:" GET dD_to

	++ nX

	@ m_x + nX, m_y + 2 SAY "Vrste dokumenata:" GET cDokType ;
		PICT "@S30"

	++ nX

	@ m_x + nX, m_y + 2 SAY "Operater (0-svi):" GET nOperater ;
		PICT "999"

	++ nX
	++ nX
	
	@ m_x + nX, m_y + 2 SAY "Varijanta prikaza 1-po robi 2-po dokumentima" ;
		GET nVar PICT "9"
	
	read
BoxC()

if LastKey() == K_ESC
	nRet := 0
endif

return nRet


// --------------------------------------------------
// generisi u pomocnu tabelu podatke iz FAKT-a
// --------------------------------------------------
static function _gen_rek( cFirma, dD_from, dD_to, cDocType, nOperater )
// prenesi sve iz FAKT u pomocnu tabelu

local cFilter := ""
local cF_firma 
local cF_tipdok
local cF_brdok

O_DOKS
O_FAKT
O_ROBA
O_SIFV
O_SIFK
O_TARIFA
O_PARTN

if !EMPTY( cFirma )
	cFilter += Parsiraj( ALLTRIM( cFirma ), "idfirma" )
endif

if nOperater <> 0
	
	if !EMPTY( cFilter )
		cFilter += ".and."
	endif
	
	cFilter += "oper_id = " + cm2str( nOperater )
endif

if !EMPTY( cDocType )
	
	if !EMPTY( cFilter )
		cFilter += ".and."
	endif

	cFilter += Parsiraj( ALLTRIM( cDocType ), "idtipdok" )
endif


if !EMPTY( DTOS(dD_from) )
	
	if !EMPTY( cFilter )
		cFilter += ".and."
	endif

	cFilter += "datdok >=" + cm2str( dD_from )
endif

if !EMPTY( DTOS(dD_from) )
	
	if !EMPTY( cFilter )
		cFilter += ".and."
	endif

	cFilter += "datdok <=" + cm2str( dD_to )
endif

msgo("generisem podatke ...")

select doks
set filter to &cFilter
go top

do while !EOF()

	cF_firma := field->idfirma
	cF_tipdok := field->idtipdok
	cF_brdok := field->brdok
	
	nOperater := 0

	if doks->(FIELDPOS( "oper_id" )) <> 0
		nOperater := field->oper_id
	endif

	select fakt
	go top
	seek cF_firma + cF_tipdok + cF_brdok

	do while !EOF() .and. field->idfirma == cF_firma ;
		.and. field->idtipdok == cF_tipdok ;
		.and. field->brdok == cF_brdok
		
		cRoba_id := field->idroba
		cPart_id := field->idpartner
		
		select roba
		seek cRoba_id

		select tarifa
		seek roba->idtarifa

		select partn
		seek cPart_id

		select fakt

		nCjPDV := 0
		nCj2PDV := 0
		nCjBPDV := 0
		nCj2BPDV := 0
		nVPopust := 0
	
		// procenat pdv-a
		nPPDV := tarifa->opp

		// kolicina
		nKol := field->kolicina
		nRCijen := field->cijena

	
		if LEFT(field->dindem, 3) <> LEFT(ValBazna(), 3) 
			// preracunaj u EUR
			// omjer EUR / KM
      			nRCijen := nRCijen / OmjerVal( ValBazna(), ;
				field->dindem, field->datdok )
			nRCijen := ROUND( nRCijen, DEC_CIJENA() )
   		endif

	    	// rabat - popust
	    	nPopust := field->rabat
	
		// ako je 13-ka ili 27-ca
		// cijena bez pdv se utvrdjuje unazad 
		if ( field->idtipdok == "13" .and. glCij13Mpc ) .or. ;
			(field->idtipdok $ "11#27" .and. gMP $ "1234567") 
			// cjena bez pdv-a
			nCjPDV := nRCijen	
			nCjBPDV := (nRCijen / (1 + nPPDV/100))
		else
			// cjena bez pdv-a
			nCjBPDV := nRCijen
			nCjPDV := (nRCijen * (1 + nPPDV/100))
		endif
	
		// izracunaj vrijednost popusta
		if Round(nPopust,4) <> 0
			// vrijednost popusta
			nVPopust := (nCjBPDV * (nPopust/100))
		endif
	
		// cijena sa popustom bez pdv-a
		nCj2BPDV := (nCjBPDV - nVPopust)
		
		// izracuna PDV na cijenu sa popustom
		nCj2PDV := (nCj2BPDV * (1 + nPPDV/100))
	
		// ukupno stavka
		nUkStavka := nKol * nCj2PDV
		nUkStavke := ROUND(nUkStavka, ZAO_VRIJEDNOST() + ;
			IIF(field->idtipdok=="13", 4, 0) )

		nPom1 := nKol * nCjBPDV 
		nPom1 := ROUND(nPom1, ZAO_VRIJEDNOST() + ;
			IIF(field->idtipdok=="13", 4, 0) )
		
		// ukupno bez pdv
		nUkBPDV := nPom1 
	
		// ukupno popusta za stavku
		nPom2 := nKol * nVPopust
		nPom2 := ROUND(nPom2, ZAO_VRIJEDNOST() + ;
			IIF(field->idtipdok=="13", 4, 0) )
		
		nUkVPop := nPom2

		// preracunaj VPDV sa popustom
		nVPDV := (nCj2BPDV * (nPPDV/100))

		//  ukupno vrijednost bez pdva sa uracunatim poputstom
		nPom3 := nPom1 - nPom2 
		nPom3 := ROUND(nPom3, ZAO_VRIJEDNOST() + ;
			IIF(idtipdok=="13", 4, 0))
		
		nUkBPDVPop := nPom3
	
		// ukupno PDV za stavku = (ukupno bez pdv - ukupno popust) 
		// * stopa

		nPom4 := nPom3 * nPPDV/100
		// povecaj preciznost
		nPom4 := ROUND(nPom4, ZAO_VRIJEDNOST() + ;
			IIF(idtipdok=="13", 4, 2))
		nUkPDV := nPom4
	
		// ukupno za stavku sa pdv-om
		nTotal :=  nPom3 + nPom4

		select r_export
		append blank

		replace field->idfirma with fakt->idfirma
		replace field->idtipdok with fakt->idtipdok
		replace field->brdok with fakt->brdok
		replace field->datdok with fakt->datdok
		replace field->operater with nOperater
		replace field->part_id with fakt->idpartner
		replace field->part_naz with ALLTRIM( partn->naz )
		replace field->roba_id with fakt->idroba
		replace field->roba_naz with ALLTRIM( roba->naz )
		replace field->kolicina with fakt->kolicina
		replace field->cijena with fakt->cijena
		replace field->rabat with nUkVPop
		replace field->osnovica with nUkBPDV
		replace field->pdv with nUkPDV
		replace field->ukupno with nTotal
	
		select fakt
		skip
	enddo

	select doks
	skip

enddo

msgc()

return


// -------------------------------------------
// kreiranje pomocne tabele izvjestaja
// -------------------------------------------
static function _cre_tbl()
local aDbf := {}

AADD( aDbf, { "idfirma", "C", 2, 0 } )
AADD( aDbf, { "idtipdok", "C", 2, 0 } )
AADD( aDbf, { "brdok", "C", 10, 0 } )
AADD( aDbf, { "datdok", "D", 8, 0 } )
AADD( aDbf, { "operater", "N", 3, 0 } )
AADD( aDbf, { "part_id", "C", 6, 0 } )
AADD( aDbf, { "part_naz", "C", 100, 0 } )
AADD( aDbf, { "roba_id", "C", 10, 0 } )
AADD( aDbf, { "roba_naz", "C", 100, 0 } )
AADD( aDbf, { "kolicina", "N", 12, 2 } )
AADD( aDbf, { "cijena", "N", 12, 2 } )
AADD( aDbf, { "rabat", "N", 12, 2 } )
AADD( aDbf, { "osnovica", "N", 12, 2 } )
AADD( aDbf, { "pdv", "N", 12, 2 } )
AADD( aDbf, { "ukupno", "N", 12, 2 } )

t_exp_create( aDbf )
O_R_EXP

index on idfirma + idtipdok + brdok tag "1"
index on roba_id tag "2"
index on STR( operater, 3 ) tag "3"

return



// ---------------------------------------------
// stampa rekapitulacije
// varijanta po dokumentima
// ---------------------------------------------
static function _st_mp_dok( nT_osnovica, nT_pdv, nT_ukupno )
local nOsnovica
local nPDV
local nUkupno
local nRbr := 0
local nRow := 35
local cLine := ""

nT_osnovica := 0
nT_pdv := 0
nT_ukupno := 0

// vraca liniju
g_l_mpdok( @cLine )

// zaglavlje pregled po robi
s_z_mpdok( cLine )

select r_export
// po dokumentima
set order to tag "1"
go top

do while !EOF()

	cIdFirma := field->idfirma
	cIdTipDok := field->idtipdok
	cBrDok := field->brdok
	cPart_id := field->part_id
	cPart_naz := field->part_naz

	nOsnovica := 0
	nPDV := 0
	nUkupno := 0

	do while !EOF() .and. field->idfirma + field->idtipdok + ;
		field->brdok == cIdFirma + cIdTipDok + cBrDok
		
		nOsnovica += field->osnovica
		nPDV += field->pdv
		nUkupno += field->ukupno

		skip
	enddo

	// pa ispisi tu stavku

	// rbr
	? PADL( ALLTRIM( STR( ++nRbr ) ), 4 ) + "."

	// dokument
	@ prow(), pcol()+1 SAY PADR( ALLTRIM( cIdFirma + "-" + ;
		cIdTipDok + "-" + cBrDok ), 16 )

	// partner
	@ prow(), pcol()+1 SAY PADR( ALLTRIM( cPart_id ) + "-" + ;
		ALLTRIM( cPart_naz ), 40 )
	
	// osnovica
	@ prow(), nRow := pcol()+1 SAY STR( nOsnovica, 12, 2 )

	// pdv
	@ prow(), pcol()+1 SAY STR( nPDV, 12, 2 ) 

	// ukupno
	@ prow(), pcol()+1 SAY STR( nUkupno, 12, 2 ) 

	// dodaj na total

	nT_ukupno += nUkupno
	nT_osnovica += nOsnovica
	nT_pdv += nPDV

enddo

// ispisi sada total
? cLine

? "UKUPNO:"
@ prow(), nRow SAY STR( nT_osnovica, 12, 2 )
@ prow(), pcol()+1 SAY STR( nT_pdv, 12, 2 )
@ prow(), pcol()+1 SAY STR( nT_ukupno, 12, 2 )

? cLine

return


// ---------------------------------------------
// stampa rekapitulacije
// varijanta po operaterima
// ---------------------------------------------
static function _st_mp_oper( nT_osnovica, nT_pdv, nT_ukupno )
local nOperater
local cOper_naz
local nOsnovica
local nPDV
local nUkupno
local nRbr := 0
local nRow := 35
local cLine := ""

nT_osnovica := 0
nT_pdv := 0
nT_ukupno := 0

// vraca liniju
g_l_mpop( @cLine )

// zaglavlje pregled po robi
s_z_mpop( cLine )

select r_export
// po operaterima
set order to tag "3"
go top

do while !EOF()

	nOperater := field->operater
	cOper_naz := ""

	// ako postoji operater
	if nOperater <> 0
		nTArea := SELECT()
		cOper_naz := GetFullUserName( nOperater )
		select (nTArea)
	endif

	nOsnovica := 0
	nPDV := 0
	nUkupno := 0

	do while !EOF() .and. field->operater == nOperater
		
		nOsnovica += field->osnovica
		nPDV += field->pdv
		nUkupno += field->ukupno

		skip
	enddo

	// pa ispisi tu stavku

	// rbr
	? PADL( ALLTRIM( STR( ++nRbr ) ), 4 ) + "."

	// operater
	@ prow(), pcol()+1 SAY PADR( ALLTRIM( cOper_naz ), 40 )
	
	// osnovica
	@ prow(), nRow := pcol()+1 SAY STR( nOsnovica, 12, 2 ) 

	// pdv
	@ prow(), pcol()+1 SAY STR( nPDV, 12, 2 ) 

	// ukupno
	@ prow(), pcol()+1 SAY STR( nUkupno, 12, 2 ) 

	// dodaj na total

	nT_ukupno += nUkupno
	nT_osnovica += nOsnovica
	nT_pdv += nPDV

enddo

// ispisi sada total
? cLine

? "UKUPNO:"
@ prow(), nRow SAY STR( nT_osnovica, 12, 2 )
@ prow(), pcol()+1 SAY STR( nT_pdv, 12, 2 )
@ prow(), pcol()+1 SAY STR( nT_ukupno, 12, 2 )

? cLine

return


// ---------------------------------------------
// stampa rekapitulacije
// varijanta po robama
// ---------------------------------------------
static function _st_mp_roba( nT_osnovica, nT_pdv, nT_ukupno )
local cRoba_id 
local nOsnovica
local nPDV
local nUkupno
local nKolicina
local nT_kolicina := 0
local nRbr := 0
local nRow := 35
local cLine := ""

nT_osnovica := 0
nT_pdv := 0
nT_ukupno := 0

// vraca liniju
g_l_mproba( @cLine )

// zaglavlje pregled po robi
s_z_mproba( cLine )

select r_export
set order to tag "2"
go top

do while !EOF()

	cRoba_id := field->roba_id
	cRoba_naz := field->roba_naz

	nOsnovica := 0
	nPDV := 0
	nUkupno := 0
	nKolicina := 0

	do while !EOF() .and. field->roba_id == cRoba_id
		
		nOsnovica += field->osnovica
		nPDV += field->pdv
		nUkupno += field->ukupno
		nKolicina += field->kolicina

		skip
	enddo

	// pa ispisi tu stavku

	? PADL( ALLTRIM( STR( ++nRbr ) ), 4 ) + "."

	@ prow(), pcol()+1 SAY PADR( ALLTRIM( cRoba_id ) + ;
		"-" + ALLTRIM( cRoba_naz ), 50 )
	
	@ prow(), nRow := pcol()+1 SAY STR( nKolicina, 12, 2 )

	@ prow(), pcol()+1 SAY STR( nOsnovica, 12, 2 ) 

	@ prow(), pcol()+1 SAY STR( nPDV, 12, 2 ) 

	@ prow(), pcol()+1 SAY STR( nUkupno, 12, 2 ) 

	// dodaj na total

	nT_ukupno += nUkupno
	nT_osnovica += nOsnovica
	nT_pdv += nPDV
	nT_kolicina += nKolicina

enddo

// ispisi sada total
? cLine

? "UKUPNO:"
@ prow(), nRow SAY STR( nT_kolicina, 12, 2 )
@ prow(), pcol()+1 SAY STR( nT_osnovica, 12, 2 )
@ prow(), pcol()+1 SAY STR( nT_pdv, 12, 2 )
@ prow(), pcol()+1 SAY STR( nT_ukupno, 12, 2 )

? cLine

return


// -----------------------------------------
// vraca liniju za pregled po robi
// -----------------------------------------
static function g_l_mproba( cLine )

cLine := ""

cLine += REPLICATE("-", 5)
cLine += SPACE(1)
cLine += REPLICATE("-", 50)
cLine += SPACE(1)
cLine += REPLICATE("-", 12)
cLine += SPACE(1)
cLine += REPLICATE("-", 12)
cLine += SPACE(1)
cLine += REPLICATE("-", 12)
cLine += SPACE(1)
cLine += REPLICATE("-", 12)

return


// -----------------------------------------
// zaglavlje za pregled po robama
// -----------------------------------------
static function s_z_mproba( cLine )

cTxt := ""

cTxt += PADR("r.br", 5)
cTxt += SPACE(1)
cTxt += PADR("roba (id/naziv)", 50)
cTxt += SPACE(1)
cTxt += PADR("kolicina", 12)
cTxt += SPACE(1)
cTxt += PADR("osnovica", 12)
cTxt += SPACE(1)
cTxt += PADR("pdv", 12)
cTxt += SPACE(1)
cTxt += PADR("ukupno", 12)

? "Realizacija po robi:"
? cLine
? cTxt
? cLine

return


// -----------------------------------------
// vraca liniju za pregled po robi
// -----------------------------------------
static function g_l_mpop( cLine )

cLine := ""

cLine += REPLICATE("-", 5)
cLine += SPACE(1)
cLine += REPLICATE("-", 40)
cLine += SPACE(1)
cLine += REPLICATE("-", 12)
cLine += SPACE(1)
cLine += REPLICATE("-", 12)
cLine += SPACE(1)
cLine += REPLICATE("-", 12)

return


// -----------------------------------------
// zaglavlje za pregled po robama
// -----------------------------------------
static function s_z_mpop( cLine )

cTxt := ""

cTxt += PADR("r.br", 5)
cTxt += SPACE(1)
cTxt += PADR("operater (id/naziv)", 40)
cTxt += SPACE(1)
cTxt += PADR("osnovica", 12)
cTxt += SPACE(1)
cTxt += PADR("pdv", 12)
cTxt += SPACE(1)
cTxt += PADR("ukupno", 12)

? "Realizacija po opearterima:"
? cLine
? cTxt
? cLine

return


// -----------------------------------------
// vraca liniju za pregled po dokumentima
// -----------------------------------------
static function g_l_mpdok( cLine )

cLine := ""

cLine += REPLICATE("-", 5)
cLine += SPACE(1)
cLine += REPLICATE("-", 16)
cLine += SPACE(1)
cLine += REPLICATE("-", 40)
cLine += SPACE(1)
cLine += REPLICATE("-", 12)
cLine += SPACE(1)
cLine += REPLICATE("-", 12)
cLine += SPACE(1)
cLine += REPLICATE("-", 12)

return


// -----------------------------------------
// zaglavlje za pregled po robama
// -----------------------------------------
static function s_z_mpdok( cLine )

cTxt := ""

cTxt += PADR("r.br", 5)
cTxt += SPACE(1)
cTxt += PADR("dokument", 16)
cTxt += SPACE(1)
cTxt += PADR("partner (id/naziv)", 40)
cTxt += SPACE(1)
cTxt += PADR("osnovica", 12)
cTxt += SPACE(1)
cTxt += PADR("pdv", 12)
cTxt += SPACE(1)
cTxt += PADR("ukupno", 12)

? "Realizacija po dokumentima:"
? cLine
? cTxt
? cLine

return



