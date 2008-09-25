#include "fakt.ch"

// -------------------------------------
// opcija pregleda smeca
// -------------------------------------

function Pripr9View()

private aUslFirma := gFirma
private aUslDok := SPACE(50)
private dDat1 := CToD("")
private dDat2 := DATE()

Box(,10, 60)
	@ 1+m_x, 2+m_y SAY "Uslovi pregleda smeca:" COLOR "I"
	@ 3+m_x, 2+m_y SAY "Firma (prazno-sve)" GET aUslFirma PICT "@S40"
	@ 4+m_x, 2+m_y SAY "Vrste dokumenta (prazno-sve)" GET aUslDok PICT "@S20"
	@ 5+m_x, 2+m_y SAY "Datum od" GET dDat1 
	@ 5+m_x, 20+m_y SAY "do" GET dDat2 
	read
BoxC()

if LastKey()==K_ESC
	return
endif

// postavi filter
P9SetFilter(aUslFirma, aUslDok, dDat1, dDat2)

private gVarijanta:="2"

private PicV:="99999999.9"
ImeKol:={ ;
    { "F."        , {|| IdFirma                  }, "IdFirma"     } ,;
    { "VD"        , {|| IdTipDok                 }, "IdTipDok"    } ,;
    { "BrDok"     , {|| BrDok                    }, "BrDok"       } ,;
    { "Dat.dok"   , {|| DatDok                   }, "DatDok"      } ,;
    { "Partner"   , {|| PADR(_get_partner(idpartner),50)  }, "idpartner" } ;
        }

Kol:={}
for i:=1 to LEN(ImeKol)
	AADD(Kol,i)
next

Box(,20,77)
@ m_x+17,m_y+2 SAY "<c-T>  Brisi stavku                              "
@ m_x+18,m_y+2 SAY "<c-F9> Brisi sve     "
@ m_x+19,m_y+2 SAY "<P> Povrat dokumenta u pripremu "
@ m_x+20,m_y+2 SAY "               "

ObjDbedit("PRIPR9",20,77,{|| EdPr9()},"<P>-povrat dokumenta u pripremu","Pregled smeca...", , , , ,4)
BoxC()

return


function EdPr9()
do case
	case Ch==K_CTRL_T 
		// brisanje dokumenta iz pripr9
		bris_smece(idfirma, idtipdok, brdok)
      		return DE_REFRESH
	case Ch==K_CTRL_F9 
		// brisanje kompletnog pripr9
		bris_svo_smece()
		return DE_REFRESH
	case chr(Ch) $ "pP" // povrat dokumenta u pripremu
		PovPr9()
		P9SetFilter(aUslFirma, aUslDok, dDat1, dDat2)
		return DE_REFRESH
endcase
return DE_CONT

return


function PovPr9()
local nArr
nArr:=SELECT()

povrat_smece(idfirma, idtipdok, brdok)

select (nArr)

return DE_CONT


static function P9SetFilter(aUslFirma, aUslDok, dDat1, dDat2)
O_PRIPR9
set order to tag "1"

// obavezno postavi filter po rbr
cFilter:="rbr = '  1'"

if !Empty(aUslFirma)
	cFilter += " .and. idfirma='" + aUslFirma + "'"
endif

if !Empty(aUslDok)
	aUslDok := Parsiraj(aUslDok, "idtipdok")
	cFilter += " .and. " + aUslDok
endif

if !Empty(dDat1)
	cFilter += " .and. datdok >= " + Cm2Str(dDat1)
endif

if !Empty(dDat2)
	cFilter += " .and. datdok <= " + Cm2Str(dDat2)
endif

set filter to &cFilter

go top

return


static function _get_partner(cIdPartner)
local nTArea
local cPartner
nTArea := SELECT()
select partn
go top
seek cIdPartner

if Found()
	cPartner := field->naz
else
	cPartner := "????????"
endif

select (nTArea)
return cPartner



// -------------------------------------------------
// brisi dokument iz smeca
// -------------------------------------------------
function bris_smece(cIdF, cIdTipDok, cBrDok)

if Pitanje(,"Sigurno zelite izbrisati dokument?","N")=="N"
	return
endif

select PRIPR9
seek cIdF+cIdTipDok+cBrDok

do while !eof() .and. cIdF==IdFirma .and. cIdTipDok==Idtipdok .and. cBrDok==BrDok
	skip 1
	nRec:=RecNo()
	skip -1
   	dbdelete2()
   	go nRec
enddo

return

// -------------------------------------------
// brisi sve iz smeca
// -------------------------------------------
function bris_svo_smece()

if Pitanje(,"Sigurno zelite izbrisati sve zapise?","N")=="N"
	return
endif

select PRIPR9
go top
zap

return

// -------------------------------------------------------
// opcija azuriranja dokumenta u smece
// -------------------------------------------------------
function azur_smece()

if Pitanje("p1", "Zelice li dokument prebaciti u smece (D/N) ?", "D" ) == "N"
	return
endif

O_PRIPR9
O_PRIPR

do while !EOF()

	cIdfirma := idfirma
	cIdTipDok := idtipdok
	cBrDok := brdok

	do while !EOF() .and. idfirma == cIdFirma ;
			.and. idtipdok == cIdtipdok ;
			.and. brdok == cBrDok
		skip
	enddo

	select pripr9
	seek cIdFirma+cIdtipdok+cBrDok

	if found()
		beep(1)
		msg("U smecu se vec nalazi dokument " + ;
			cIdFirma + "-" + cIdtipdok + "-" + ALLTRIM(cBrDok) )
		closeret
	endif

	select pripr
enddo

select pripr
go top

select pripr9
append from pripr

select pripr
zap

closeret
return


// ---------------------------------------------------
// povrat dokumenta iz smeca
// ---------------------------------------------------
function povrat_smece( cIdFirma, cIdtipdok, cBrDok )
local nRec

lSilent := .t.

O_PRIPR9
O_PRIPR

select pripr9
set order to tag 1

// ako nema parametara funkcije
if (PCount() == 0)
	lSilent := .f.
endif

if !lSilent
   cIdFirma := gFirma
   cIdtipdok := SPACE(LEN(field->idtipdok))
   cBrDok := SPACE(LEN(field->brdok))
endif

if !lSilent
   Box("",1,40)
     @ m_x + 1, m_y + 2 SAY "Dokument:"
     @ m_x + 1, col() + 1 GET cIdFirma
     @ m_x + 1, col() + 1 SAY "-" GET cIdtipdok
     @ m_x + 1, col() + 1 SAY "-" GET cBrdok
     read
     ESC_BCR
   BoxC()
endif

if Pitanje("","Iz smeca "+cIdFirma+"-"+cIdtipdok+"-"+ALLTRIM(cBrDok)+" povuci u pripremu (D/N) ?","D")=="N"
	
	if !lSilent
		CLOSERET
	else
		return
	endif

endif

select PRIPR9

hseek cIdFirma+cIdtipdok+cBrDok

MsgO("PRIPREMA")
do while !eof() .and. cIdFirma==IdFirma .and. cIdtipdok==Idtipdok .and. cBrDok==BrDok
   select PRIPR9
   Scatter()
   select PRIPR
   append blank
   _ERROR:=""
   Gather2()
   select PRIPR9
   skip
enddo

select PRIPR9
seek cIdFirma+cIdTipDok+cBrDok
do while !eof() .and. cIdFirma==IdFirma .and. cIdtipdok==Idtipdok .and. cBrDok==BrDok
   skip 1
   nRec:=recno()
   skip -1
   dbdelete2()
   go nRec
enddo

use

MsgC()

if !lSilent
	closeret
endif

O_PRIPR9
select pripr9

return


