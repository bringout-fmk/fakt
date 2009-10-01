#include "fakt.ch"

/*
 * ----------------------------------------------------------------
 *                                     Copyright Sigma-com software 
 * ----------------------------------------------------------------
 */

function MnuAdmin()
private opc
private opcexe
private Izbor

opc:={}
opcexe:={}
Izbor:=1

AADD(opc, "1. instalacija db-a              ")
AADD(opcexe, {|| goModul:oDatabase:install()}) 
AADD(opc, "2. skip speed db-a")
AADD(opcexe, {|| SpeedSkip()}) 
AADD(opc, "3. security")
AADD(opcexe, {|| MnuSecMain()})
AADD(opc, "4. regeneracija fakt memo polja")
AADD(opcexe, {|| fa_memo_regen()})
AADD(opc, "5. regeneracija polja fakt->rbr")
AADD(opcexe, {|| fa_rbr_regen()})
AADD(opc, "6. regeneracija polja idpartner")
AADD(opcexe, {|| fa_part_regen()})
AADD(opc, "7. fakt export (r_exp) ")
AADD(opcexe, {|| fkt_export()})

Menu_SC("fain")

return

// regeneracija rednih brojeva u tabeli fakt
function fa_rbr_regen()
local nCounter
local cOldRbr
local cNewRbr
local nTotRecord

if !SigmaSif("RBRREG")
	return
endif

if Pitanje(,"Izvrsiti regeneraciju rednih brojeva (D/N)","N") == "N"
	return
endif

O_FAKT

select fakt
set order to tag 0

Box(,3,60)
@ m_x+1, m_y+2 SAY "Vrsim regeneraciju rednih brojeva fakt..."

nCounter := 0
nTotRecord := RecCount()

@ m_x+2, m_y+2 SAY "ukupni broj zapisa: " + ALLTRIM(STR(nTotRecord)) 

do while !EOF()

	cOldRbr := field->rbr
	cNewRbr := PADL(ALLTRIM(cOldRbr), 3)

	Scatter()
	_rbr := cNewRbr
	Gather()

	++nCounter

	@ m_x+3, m_y+2 SAY "obradjeno zapisa: " + ALLTRIM(STR(nCounter))
	
	skip
enddo

BoxC()

return


// ---------------------------------------
// regeneracija polja FAKT-TXT
// ---------------------------------------
function fa_memo_regen()
local cRbr
local cPartn
local dDatPl

if !SigmaSif("MEMREG")
	return 
endif

if Pitanje(,"Izvrsiti regeneraciju (D/N)?","N") == "N"
	return
endif

O_FAKT
O_DOKS
O_PARTN

select fakt
set order to tag "1"
go top

// interesuju nas samo prvi zapisi pod rbr = '  1'
cRbr := PADL("1", 3)
nCounter:=0

Box(,3, 60)
@ 1+m_x, 2+m_y SAY "regeneracija memo polja u toku..."

do while !EOF()
	
	// provjeri prvo polje rbr
	if ( field->rbr <> cRbr )
		skip
		loop
	endif
	
	// provjeri i LEN txt polja, ako je > 10 onda je ok
	if LEN(field->txt) > 10
		skip
		loop
	endif
	
	cPartn := fakt->idpartner
	dDatDok := fakt->datdok
	
	// pozicioniraj se na partnera
	select partn
	hseek cPartn

	// prebaci se na doks radi datuma placanja
	select doks
	set order to tag "1"
	hseek fakt->idfirma + fakt->idtipdok + fakt->brdok
	dDatPl := doks->datpl
	
	select fakt
	
	// odradi regeneraciju polja
	Scatter()

	// roba // ovo je za roba U
	_txt := Chr(16) + Chr(17)
        // dodatni tekst fakture // nemamo ga
	_txt += Chr(16) + Chr(17)
	_txt += Chr(16) + ALLTRIM(partn->naz) + Chr(17)
	_txt += Chr(16) + ALLTRIM(partn->adresa) + ", Tel:" + ALLTRIM(partn->telefon) + Chr(17) 
	_txt += Chr(16) + ALLTRIM(partn->ptt) + " " + ALLTRIM(partn->mjesto) + Chr(17)
        // broj otpremnice - nemamo ga
	_txt += Chr(16) + Chr(17) 
        // datum otpremnice
	_txt += Chr(16) + DToC(dDatDok) + Chr(17)
        // broj narudzbenice - nemamo ga
	_txt += Chr(16) + Chr(17)
	_txt += Chr(16) + DToC(dDatPl) + Chr(17)
	_txt += Chr(16) + Chr(17)
	_txt += Chr(16) + Chr(17)
	_txt += Chr(16) + Chr(17)
	_txt += Chr(16) + Chr(17)
	_txt += Chr(16) + Chr(17)
	_txt += Chr(16) + Chr(17)
	_txt += Chr(16) + Chr(17)
	_txt += Chr(16) + Chr(17)
	_txt += Chr(16) + Chr(17)
	
	Gather()
	
	++nCounter

	@ 3+m_x, 2+m_y SAY "odradjeno zapisa " + ALLTRIM(STR(nCounter)) 

	skip

enddo

BoxC()

return


// ------------------------------------------------------------
// regeneracija / popunjavanje polja idpartner u tabeli fakt
// ------------------------------------------------------------
function fa_part_regen()
local nCount
local cIdFirma
local cIdTipDok
local cBrDok
local cPartn
local cMsg
local lFaktOverwrite := .f.

if !SigmaSif("PARREG")
	return
endif

cMsg := "Prije pokretanja ove opcije#!!! OBAVEZNO !!! napraviti backup podataka"

msgbeep(cMsg)

if Pitanje(,"Izvrsiti popunjavanje partnera u dokumentima (D/N)","N") == "N"
	return
endif


if Pitanje(,"Prepisati vrijednosti u tabeli FAKT (D/N)", "N") == "D"
	lFaktOverwrite := .t.
endif

O_DOKS
O_FAKT

select fakt
set order to tag "1"
go top

Box(,3,60)

@ m_x+1, m_y+2 SAY "Vrsim popunjavanje partnera..."

nCount := 0

do while !EOF()
	
	cIdFirma := field->idfirma
	cIdTipDok := field->idtipdok
	cBrDok := field->brdok
	cPartn := field->idpartner

	if lFaktOverwrite == .t. .or. EMPTY( cPartn )
		
		// pokusaj naci u DOKS
		select doks
		set order to tag "1"
		seek cIdFirma + cIdTipDok + cBrDok

		if FOUND()
			if !EMPTY( field->idpartner )
				
				cPartn := field->idpartner
			
				@ m_x+2, m_y+2 SAY "*** uzeo iz DOKS -> " + cPartn
	
			endif
		endif
			
		select fakt
			
	endif

	do while !EOF() .and. field->idfirma == cIdFirma ;
			.and. field->idtipdok == cIdTipDok ;
			.and. field->brdok == cBrDok
	
		
		if (lFaktOverwrite == .t. .or. EMPTY( field->idpartner )) .and. !EMPTY( cPartn )
		
			++ nCount
			
			// upisi partnera
			replace idpartner with cPartn

			@ m_x+3, m_y+2 SAY "dok-> " + cIdFirma + "-" + ;
				cIdTipDok + "-" + ALLTRIM(cBrDok)
	
		endif
		
		skip
	enddo
	
enddo

BoxC()

if nCount > 0
	msgbeep("Odradjeno " + ALLTRIM(STR(nCount)) + " zapisa !")
endif

return



