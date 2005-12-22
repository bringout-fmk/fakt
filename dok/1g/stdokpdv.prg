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

altd()

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

if PCount()==0
	select pripr
endif

cIdFirma:=IdFirma
cBrDok:=BrDok
dDatDok:=DatDok
cIdTipDok:=IdTipDok

if VAL(podbr)=0 .and. VAL(rbr)==1
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
local cDinDem
local nRec
local nZaokr
local cDokNaz

// napuni firmine podatke
fill_firm_data()

select pripr

// napuni podatke partnera
fill_part_data(idpartner)

select pripr

// vrati naziv dokumenta
get_dok_naz(@cDokNaz, idtipdok)

select pripr

dDatDok := datdok
dDatVal := dDatDok
dDatIsp := dDatDok
cDinDem := dindem
nZaokr := zaokr

nRec:=RecNO()

altd()

do while !EOF() .and. idfirma==cIdFirma .and. idtipdok==cIdTipDok .and. brdok==cBrDok
	NSRNPIdRoba()   // Nastimaj (hseek) Sifr.Robe Na Pripr->IdRoba
	
	// nastimaj i tarifu
	select tarifa
	hseek roba->idtarifa
	select pripr
	
     	aMemo:=ParsMemo(txt)
	
	altd()
	
	cIdRoba := field->idroba
	
	if roba->tip="U"
		cRobaNaz:=padr(aMemo[1],40) // roba
   	else
		cRobaNaz:=ALLTRIM(roba->naz)
		if lBarKod
			cRobaNaz:=cRobaNaz + "(" + roba->barkod + ")"
		endif
	endif
	
	//resetuj varijable sa cijenama
	nCjPDV := 0
	nCj2PDV := 0
	nCjBPDV := 0
	nCj2BPDV := 0
	nVPopust := 0
	
	cRbr := field->rbr
	cPodBr := field->podbr
	cJmj := roba->jmj

	// procenat pdv-a
	nPPDV := tarifa->opp
	
	// kolicina
	nKol := field->kolicina
	nRCijen := field->cijena

	// rabat - popust
	nPopust := field->rabat
	
	// cjena bez pdv-a
	nCjBPDV:= nRCijen
	nCjPDV := (nRCijen * (1 + nPPDV/100))
	
	// izracunaj vrijednost popusta
	if Round(nPopust,4) <> 0
		// vrijednost popusta
		nVPopust := (nCjBPDV * (nPopust/100))
	endif
	
	// cijena sa popustom bez pdv-a
	nCj2BPDV := (nCjBPDV - nVPopust)
	// izracuna PDV na cijenu sa popustom
	nCj2PDV := (nCj2BPDV * (1 + nPPDV/100))
	// preracunaj VPDV sa popustom
	nVPDV := (nCj2BPDV * (nPPDV/100))
	// ukupno stavka
	nUkStavka := nKol * (nCj2PDV)

	// sumiraj vrijednosti
	nUkVPop += nVPopust
	nUkPDV += nKol * nVPDV
	nUkBPDV += nKol * nCjBPDV
	nUkBPDVPop += nKol * nCj2BPDV
	nTotal += (nKol * nCj2BPDV) + nVPDV

	++ nCSum
	
	add_rn(cBrDok, cRbr, cPodBr, cIdRoba, cRobaNaz, cJmj, nKol, nCjPDV, nCjBPDV, nCj2PDV, nCj2BPDV, nPopust, nPPDV, nVPDV, nUkStavka)

	select pripr
	skip
enddo	

select pripr
go (nRec)

// nafiluj ostale podatke vazne za sam dokument
aMemo := ParsMemo(txt)
dDatDok := datdok
dDatVal := CToD(aMemo[9])
dDatIsp := CToD(aMemo[7])
cBrOtpr := aMemo[6]
cBrNar  := aMemo[8]

// mjesto
add_drntext("D01", gMjStr)
// naziv dokumenta
add_drntext("D02", cDokNaz)
// slovima iznos fakture
add_drntext("D04", Slovima(ROUND(nTotal, nZaokr), cDinDem))
// broj otpremnice
add_drntext("D05", cBrOtpr)
// broj narudzbenice
add_drntext("D06", cBrNar)
// DM/EURO
add_drntext("D07", cDinDem)

// tekst na kraju fakture F04, F05, F06
fill_dod_text(aMemo[2])
// potpis na kraju
fill_potpis(cIdTipDok)

// parametri generalni za stampu dokuemnta
// lijeva margina
add_drntext("P01", ALLTRIM(STR(gnLMarg)) )
// zaglavlje na svakoj stranici
add_drntext("P04", if(gZagl == "1", "D", "N"))
// prikaz dodatnih podataka 
add_drntext("P05", if(gDodPar == "1", "D", "N"))
// dodati redovi po listu 
add_drntext("P06", ALLTRIM(STR(gERedova)) )
// gornja margina
add_drntext("P07", ALLTRIM(STR(gnTMarg)) )
// da li se formira automatsko zaglavlje
add_drntext("P10", gStZagl )

// dodaj total u DRN
add_drn(cBrDok, dDatDok, dDatVal, dDatIsp, cTime, nUkBPDV, nUkVPop, nUkBPDVPop, nUkPDV, nTotal, nCSum)

return
*}


function fill_potpis(cIdVD)
*{
local cPom
local cPotpis

cPom:="G"+cIdVD+"STR2T"
cPotpis := &cPom

// potpis 
add_drntext("F10", cPotpis)

return
*}


// daj naziv dokumenta iz parametara
function get_dok_naz(cNaz, cIdVd)
*{
local cPom
local cSamoKol

cPom:="G" + cIdVd + "STR"
cNaz := &cPom

// da li se na dokumentu prikazju samo kolicine
cSamoKol := "N"
// za sljedece dokumente samo KOLICINE
if cIdVD $ "12#19#21#26"
	cSamoKol := "D"
endif

add_drntext("P03", cSamoKol)

return
*}

// filovanje dodatnog teksta
function fill_dod_text(cTxt)
*{
local aLines // matrica sa linijama teksta
local nFId // polje Fnn counter od 20 pa nadalje
local nCnt // counter upisa u DRNTEXT

// slobodni tekst se upisuje u DRNTEXT od F20 -- F50

cTxt := STRTRAN(cTxt, "" + Chr(10), "")
// daj mi matricu sa tekstom line1, line2 itd...
aLines := TokToNiz(cTxt, Chr(13) + Chr(10)) 

nFId := 20
nCnt := 0

for i:=1 to LEN(aLines)
	add_drntext("F" + ALLTRIM(STR(nFId)), aLines[i] + " ")
	++ nFId
	++ nCnt
next

// dodaj i parametar koliko ima linija texta
add_drntext("P02", ALLTRIM(STR(nCnt)))

return
*}


function fill_part_data(cId)
*{
local cIdBroj
local cPorBroj
local cBrRjes
local cBrUpisa

O_PARTN
select partn
set order to tag "ID"
hseek cId

if partn->id == cId
	// uzmi podatke iz SIFK
	cIdBroj := IzSifK("PARTN", "REGB", cId, .f.)
	cPorBroj := IzSifK("PARTN", "PORB", cId, .f.)
	cBrRjes := IzSifK("PARTN", "BRJS", cId, .f.)
	cBrUpisa := IzSifK("PARTN", "BRUP", cId, .f.)

	// naziv
	add_drntext("K01", partn->naz)
	// adresa
	add_drntext("K02", partn->adresa)
	// mjesto
	add_drntext("K10", partn->mjesto)
	// ptt
	add_drntext("K11", partn->ptt)
	// idbroj
	add_drntext("K03", cIdBroj)
	// porbroj
	add_drntext("K05", cPorBroj)
	// brrjes
	add_drntext("K06", cBrRjes)
	// brupisa
	add_drntext("K07", cBrUpisa)
endif

return
*}

function fill_firm_data()
*{
add_drntext("I01", gFNaziv)
add_drntext("I02", gFAdresa)
add_drntext("I03", gFIdBroj)
// 4. se koristi za id prod.mjesto u pos
add_drntext("I05", gFPorBroj)
add_drntext("I06", gFBrSudRjes)
add_drntext("I07", gFBrUpisa)
add_drntext("I08", gFUstanova)
// banke
add_drntext("I09", ALLTRIM(gFBanka1) + "; " + ALLTRIM(gFBanka2) + ";" + ALLTRIM(gFBanka3))

return
*}

