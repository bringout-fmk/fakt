/* 
 * This file is part of the bring.out FMK, a free and open source 
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the 
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "fakt.ch"

// -------------------------------------------------------------------
// -------------------------------------------------------------------
function FaStanje(cIdRj, cIdroba, nUl, nIzl, nRezerv, nRevers, lSilent)

if (lSilent==nil)
	lSilent:=.f.
endif

select fakt

//"3","idroba+dtos(datDok)","FAKT"

set order to tag "3"

if (!lSilent)
	lBezMinusa:=(IzFMKIni("FAKT","NemaIzlazaBezUlaza","N",KUMPATH) == "D" )
endif

if (roba->tip=="U")
	return 0
endif

if (!lSilent)
	MsgO("Izracunavam trenutno stanje ...")
endif

seek cIdRoba

nUl:=0
nIzl:=0
nRezerv:=0
nRevers:=0

do while (!EOF() .and. cIdRoba==field->idRoba)
	if (fakt->idFirma<>cIdRj)
		SKIP
		loop
	endif
	if (LEFT(field->idTipDok,1)=="0")
		// ulaz
		nUl+=kolicina
	elseif (LEFT(field->idTipDok,1)=="1")   
		// izlaz faktura
		if !(left(field->serBr,1)=="*" .and. field->idTipDok=="10")  
			nIzl += field->kolicina
		endif
	elseif (field->idTipDok $ "20#27")
		if (LEFT(field->serBr,1)=="*")
			nRezerv += field->kolicina
		endif
	elseif (field->idTipDok=="21")
			nRevers += field->kolicina
	endif
	skip
enddo

if (!lSilent)
	MsgC()
endif

return

// -------------------------------------------------
// -------------------------------------------------
function IsDocExists(cIdFirma, cIdTipDok, cBrDok)
local nArea
local lRet

lRet:=.f.

PushWa()
nArea:=SELECT()
select DOKS
set order to tag "1"
HSEEK cIdFirma+cIdTipDok+cBrDok
if FOUND()
	lRet:=.t.
endif
SELECT(nArea)
PopWa()
return lRet

// -------------------------------------------------
// -------------------------------------------------
function SpeedSkip()

nSeconds:=SECONDS()

nKrugova:=1
Box(,3,50)
	@ m_x+1,m_y+2 SAY "Krugova:" GET nKrugova
	read
BoxC()


O_FAKT
set order to tag "1"

i:=0
for j:=1 to nKrugova
go top

? "krug broj", j
do while !eof()
	i=i+1
	if i % 150 = 0
		? j, i, recno(), idFirma, idTipDok, brDok, "SEC:", SECONDS()-nSeconds
	endif	

	OL_Yield()
	nKey:=INKEY()
	
	if (nKey==K_ESC)
		CLOSE ALL 
		RETURN
	endif

	SKIP
enddo
next

MsgBeep("Vrijeme izvrsenja:" + STR( SECONDS()-nSeconds ) )

return


// --------------------------------------------------
// inicijalizacija fiskalnih tabela - sifrarnika
// --------------------------------------------------
function ffisc_init()
local aRoba := {}
local aRobaGr := {}
local aPartn := {}
local aPor := {}
local aObj := {}
local aOper := {}

msgo("inicijalizacija u toku...")

// init - porez
aPor := _f_por_init()

// init - roba grupe
aRobaGr := _f_rg_init()

// init - roba
aRoba := _f_ro_init( .t. )

// init - partneri
aPartn := _f_pa_init()

// init - objekti
aObj := _f_ob_init()

// init - operater
aOper := _f_op_init()

// napravi inicijalizaciju u txt fajlove
fisc_init( gFC_path, aPor, aRoba, aRobaGr, aPartn, aObj, aOper )

msgc()

return



// -------------------------------------------
// operateri, inicijalizacija
// -------------------------------------------
function _f_op_init()
local aRet := {}

AADD( aRet, { 1, "operater 1", "" })

return aRet 



// -------------------------------------------
// objekti, inicijalizacija
// -------------------------------------------
function _f_ob_init()
local aRet := {}

AADD( aRet, { 1, "objekat 1", "", "", "", "" })

return aRet 


// -------------------------------------------
// grupe robe, inicijalizacija
// -------------------------------------------
function _f_rg_init()
local aRet := {}

AADD( aRet, { 1, "grupa 1" })

return aRet 


// -------------------------------------------
// poreske stope inicijalizacija
// -------------------------------------------
function _f_por_init()
local aRet := {}

AADD( aRet, { 0, "A", 00.00 })
AADD( aRet, { 1, "E", 17.00 })

return aRet 


// -----------------------------------------
// roba - inicijalizacija
// -----------------------------------------
function _f_ro_init( lSifDob )
local aRet := {}
local nTArea := SELECT()
local nRobaGr := 0
local nPorSt := 0
local cNaz

if lSifDob == nil
	lSifDob := .t.
endif

O_ROBA
select roba
go top
do while !EOF()
	
	if lSifDob == .t. .and. EMPTY(field->sifradob) 
		skip
		loop
	endif

	// ako mpc nije definisana - preskoci
	if field->mpc = 0
		skip
		loop
	endif
	
	nRobaGr := 1
	nPorSt := 1

	cNaz := konvznwin( field->naz, gFc_Konv )

	AADD( aRet, { ;
		VAL(ALLTRIM(field->sifradob)), ;
		ALLTRIM(cNaz), ;
		ALLTRIM(field->barkod), ;
		nRobaGr, ;
		nPorSt, ;
		field->mpc } )

	skip

enddo

select (nTArea)
return aRet 


// -----------------------------------------
// partn - inicijalizacija
// -----------------------------------------
function _f_pa_init()
local aRet := {}
local nTArea := SELECT()
local cAdr
local cNaz

O_PARTN
select partn
go top

do while !EOF()
	
	cPId := field->id

	cREGB := IzSifK("PARTN", "REGB", cPId )

	select partn
	
	cNaz := konvznwin( partn->naz, gFC_Konv )
	cAdr := konvznwin( partn->adresa, gFc_Konv )

	AADD( aRet, { ;
		VAL(cPid), ;
		ALLTRIM(cNaz), ;
		ALLTRIM(cAdr), ;
		"", ;
		"", ;
		cREGB } )

	skip

enddo

select (nTArea)
return aRet 



