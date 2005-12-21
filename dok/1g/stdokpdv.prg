#include "\dev\fmk\fakt\fakt.ch"


function stdokpdv(cIdFirma, cIdTipDok, cBrDok)
*{

drn_create()
drn_open()
drn_empty()

// otvori tabele
if PCount()==3
	O_Edit(.t.)
else
 	O_Edit()
endif

// barkod artikla
private cPombk := IzFmkIni("SifRoba","PBarkod","0",SIFPATH)
private lPBarkod:=.f.
if cPombk $ "12"  // pitanje, default "N"
	lPBarkod := ( Pitanje(,"Zelite li ispis barkodova ?",iif(cPombk=="1","N","D"))=="D")
endif

if PCount()==0
 	cIdTipdok:=idtipdok
	cIdFirma:=IdFirma
	cBrDok:=BrDok
endif

seek cIdFirma+cIdTipDok+cBrDok
NFOUND CRET

select pripr

cIdFirma:=IdFirma
cBrDok:=BrDok
dDatDok:=DatDok
cIdTipDok:=IdTipDok
cIdPartner:=IdPartner

// provjeri ispravnost dokumenta
if val(podbr)=0  .and. val(rbr)==1
	aMemo:=ParsMemo(txt)
   	if len(aMemo)>0
     		cTxt1:=padr(aMemo[1],40)
   	endif
   	if len(aMemo)>=5
      		cTxt2:=aMemo[2]
    		cTxt4:=aMemo[3]
    		cTxt5:=aMemo[4]
    		cTxt6:=aMemo[5]
   	endif
	if LEN(aMemo)>9
      		cOtpBroj:=aMemo[6]
		cOtpDatum:=CToD(aMemo[7])
		cNarBroj:=aMemo[8]
		cDatPl:=CToD(aMemo[9])
	endif
else
	Beep(2)
  	Msg("Prva stavka mora biti  '1.'  ili '1 ' !",4)
  	return
endif

fill_porfakt_data(cIdFirma, cIdTipDok, cBrDok, lPBarKod)

pf_a4_print()

return
*}



function fill_porfakt_data(cIdFirma, cIdTipDok, cBrDok, lBarKod)
*{
local cTxt1,cTxt2,cTxt3,cTxt4,cTxt5
local cIdPartner
local dDatDok
local dDatVal
local dDatIsp
local aMemo
local cIdRoba := ""
local cRobaNaz := ""
local cRbr := ""
local cPodBr := ""
local cJmj:=""
local nKol:=0
local nCjPDV:=0
local nCjBPDV:=0
local nPopust:=0 // proc popusta
local nVPDV:=0
local nCj2PDV:=0
local nCj2BPDV:=0
local nPPDV:=0
local nRCijen:=0
local nCSum:= 0
local nTotal:= 0
local nUkBPDV:= 0
local nUkBPDVPop:=0
local nUkVPop:=0
local nVPopust:=0
local nUkPDV:=0
local cTime:=""

go top

dDatDok := datdok
dDatVal := dDatDok
dDatIsp := dDatDok

do while !EOF() .and. idfirma==cIdFirma .and. idtipdok==cIdTipDok .and. brdok==cBrDok
	NSRNPIdRoba()   // Nastimaj (hseek) Sifr.Robe Na Pripr->IdRoba
	
	// nastimaj i tarifu
	select tarifa
	hseek roba->idtarifa
	select pripr
	
     	aMemo:=ParsMemo(txt)
	
	cIdRoba := field->idroba
	
	if roba->tip="U"
		cRobaNaz:=padr(aMemo[1],40) // roba
   	else
		cRobaNaz:=ALLTRIM(roba->naz)
		if lBarKod
			cRobaNaz:=cRobaNaz + "(" + roba->barkod + ")"
		endif
	endif
	
	cRbr := field->rbr
	cPodBr := field->podbr
	cJmj := roba->jmj

	// procenat pdv-a
	nPPDV := tarifa->opp
	
	// kolicina
	nKol := field->kolicina
	nRCijen := roba->vpc
	
	// rabat - popust
	nPopust := field->rabat
	
	// cjena bez pdv-a
	nCjBPDV:= nRCijen
	nCjPDV := (nRCijen * (1 + nPPDV/100))
	
	// izracunaj vrijednost popusta
	if Round(nPopust,4) <> 0
		// vrijednost popusta
		nVPopust := (nCjBPDV / (nPopust/100))
	endif
	
	// cijena sa popustom bez pdv-a
	nCj2BPDV := ((nCjBPDV - nVPopust) / (1 + nPopust/100))
	// izracuna PDV na cijenu sa popustom
	nCj2PDV := (nCj2BPDV * (1 + nPPDV/100))
	// preracunaj VPDV sa popustom
	nVPDV := nKol * (nCj2BPDV * (nPPDV/100))
	// ukupno stavka
	nUkStavka := nKol * (nCj2PDV)

	// sumiraj vrijednosti
	nUkVPop += nVPopust
	nUkPDV += nVPDV
	nUkBPDV += nKol * nCjBPDV
	nUkBPDVPop += nKol * nCj2BPDV
	nTotal += (nKol * nCj2BPDV) + nVPDV

	++ nCSum
	
	add_rn(cBrDok, cRbr, cPodBr, cIdRoba, cRobaNaz, cJmj, nKol, nCjPDV, nCjBPDV, nCj2PDV, nCj2BPDV, nPopust, nPPDV, nVPDV, nUkStavka)

	skip
enddo	

add_drn(cBrDok, dDatDok, dDatVal, dDatIsp, cTime, nUkBPDV, nUkVPop, nUkBPDVPop, nUkPDV, nTotal, nCSum)

return
*}


