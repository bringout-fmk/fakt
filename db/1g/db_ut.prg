#include "\dev\fmk\fakt\fakt.ch"

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

nArea:=SELECT()
select DOKS
set order to tag "1"
HSEEK cIdFirma+cIdTipDok+cBrDok
if FOUND()
	lRet:=.t.
endif
SELECT(nArea)
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


