#include "\dev\fmk\fakt\fakt.ch"


function stdokpdv(cIdFirma, cIdTipDok, cBrDok)
*{
local lSamoKol:=.f. // samo kolicine

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

if PCount()==0
	select pripr
endif

cIdFirma:=IdFirma
cBrDok:=BrDok
dDatDok:=DatDok
cIdTipDok:=IdTipDok

// prikaz samo kolicine
if cIdTipDok $ "01#00#12#19#21#26"
	if (gPSamoKol == "0" .and. Pitanje(,"Prikazati samo kolicine (D/N)", "N") == "D") .or. gPSamoKol == "D"
		lSamoKol:=.t.
	endif
endif

if VAL(podbr)=0 .and. VAL(rbr)==1
else
	Beep(2)
  	Msg("Prva stavka mora biti  '1.'  ili '1 ' !",4)
  	return
endif

fill_porfakt_data(cIdFirma, cIdTipDok, cBrDok, lPBarKod, lSamoKol)

if cIdTipDok == "13"
	omp_print()
else
	pf_a4_print()
endif

return
*}



function fill_porfakt_data(cIdFirma, cIdTipDok, cBrDok, lBarKod, lSamoKol)
*{
local cTxt1,cTxt2,cTxt3,cTxt4,cTxt5
local cIdPartner
local dDatDok
local cDestinacija
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
local nPopNaTeretProdavca:=0
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
local nVPopNaTeretProdavca:=0
local nUkPDV:=0
local nUkPopNaTeretProdavca:=0
local cTime:=""
local cDinDem
local nRec
local nZaokr
local nFZaokr:=0
local nDrnZaokr:=0
local cDokNaz
local nUkKol:=0
local lIno:=.f.
local cPdvOslobadjanje:=""
local nPom1
local nPom2
local nPom3
local nPom4
local nPom5

// ako je kupac pdv obveznik, ova varijable je .t.
local lPdvObveznik := .f.
local lKomisionar := .f.

local nDx1 := 0
local nDx2 := 0
local nDx3 := 0
local nSw1 := 72
local nSw2 := 1
local nSw3 := 72
local nSw4 := 31
local nSw5 := 1

// radi citanja parametara
private cSection:="F"
private cHistory:=" "
private aHistory:={}

SELECT F_PARAMS
if !used()
	O_PARAMS
endif
RPar("x1", @nDx1)
RPar("x2", @nDx2)
RPar("x3", @nDx3)

RPar("x4", @nSw1)
RPar("x5", @nSw2)
RPar("x6", @nSw3)
RPar("x7", @nSw4)
// ovaj switch se koristi za poziv ptxt-a ... u principu
// ovdje mi i ne treba
RPar("x8", @nSw5)


// napuni firmine podatke
fill_firm_data()

select pripr

// napuni podatke partnera

lPdvObveznik := .f.
fill_part_data(idpartner, @lPdvObveznik)

select pripr

// vrati naziv dokumenta
get_dok_naz(@cDokNaz, idtipdok, lSamoKol)

select pripr

dDatDok := datdok
dDatVal := dDatDok
dDatIsp := dDatDok
cDinDem := dindem

nRec:=RecNO()

// ukupna kolicina
nUkKol := 0

DEC_CIJENA(ZAO_CIJENA())
DEC_VRIJEDNOST(ZAO_VRIJEDNOST())

lIno:=.f.
do while !EOF() .and. idfirma==cIdFirma .and. idtipdok==cIdTipDok .and. brdok==cBrDok
	// Nastimaj (hseek) Sifr.Robe Na Pripr->IdRoba
	NSRNPIdRoba()   
	
	// nastimaj i tarifu
	select tarifa
	hseek roba->idtarifa
	select pripr

		
     	aMemo:=ParsMemo(txt)
	cIdRoba := field->idroba
	
	if roba->tip="U"
		cRobaNaz:=aMemo[1]
	else
		cRobaNaz:=ALLTRIM(roba->naz)
		if lBarKod
			cRobaNaz:=cRobaNaz + " (BK: " + roba->barkod + ")"
		endif
	endif

	// dodaj i vrijednost iz polja SERBR
	if !EMPTY(ALLTRIM(pripr->serbr))
		cRobaNaz := cRobaNaz + ", " + ALLTRIM(pripr->serbr) 
	endif

	//resetuj varijable sa cijenama
	nCjPDV := 0
	nCj2PDV := 0
	nCjBPDV := 0
	nCj2BPDV := 0
	nVPopust := 0
	
	cRbr := rbr
	cPodBr := podbr
	cJmj := roba->jmj

	// procenat pdv-a
	nPPDV := tarifa->opp
	
	cIdPartner = pripr->IdPartner
	
	// rn Veleprodaje
	if cIdTipDok == "10"
		// ino faktura
		if IsIno(cIdPartner)
			nPPDV:=0
			lIno:=.t.
		endif

		// ako je po nekom clanu PDV-a partner oslobodjenj
		// placanja PDV-a
		cPdvOslobadjanje := PdvOslobadjanje(cIdPartner)
		if !EMPTY(cPdvOslobadjanje)
			nPPDV:=0
		endif
	endif

	if cIdTipDok == "12"
		if IsProfil(cIdPartner, "KMS")
			// radi se o komisionaru
			lKomisionar := .t.
			nPPDV := 0
		endif
	endif

	// kolicina
	nKol := field->kolicina
	nRCijen := field->cijena

	
	if LEFT(pripr->DINDEM, 3) <> LEFT(ValBazna(), 3) 
		// preracunaj u EUR
		// omjer EUR / KM
      		nRCijen:= nRCijen / OmjerVal( ValBazna(), pripr->DINDEM, pripr->datdok)
		nRCijen:=ROUND(nRCijen, DEC_CIJENA() )
   	endif


	// zasticena cijena, za krajnjeg kupca
	if RobaZastCijena(tarifa->id)  .and. !lPdvObveznik
		// krajnji potrosac
	   	// roba sa zasticenom cijenom
	   	nPopNaTeretProdavca := field->rabat
	   	nPopust := 0
	else
	    	// rabat - popust
	    	nPopust := field->rabat
	    	nPopNaTeretProdavca := 0
	endif
	
	// ako je 13-ka ili 27-ca
	// cijena bez pdv se utvrdjuje unazad 
	if (field->idtipdok == "13" .and. glCij13Mpc) .or. (field->idtipdok $ "11#27" .and. gMP $ "1234567") 
		// cjena bez pdv-a
		nCjPDV:= nRCijen	
		nCjBPDV := (nRCijen / (1 + nPPDV/100))
	else
		// cjena bez pdv-a
		nCjBPDV:= nRCijen
		nCjPDV := (nRCijen * (1 + nPPDV/100))
	endif
	
	// izracunaj vrijednost popusta
	if Round(nPopust,4) <> 0
		// vrijednost popusta
		nVPopust := (nCjBPDV * (nPopust/100))
	endif
	
	// izacunaj vrijednost popusta na teret prodavca
	if Round(nPopNaTeretProdavca, 4) <> 0
		// vrijednost popusta
		nVPopNaTeretProdavca := (nCjBPDV * (nPopNaTeretProdavca/100))
	endif

	
	// cijena sa popustom bez pdv-a
	nCj2BPDV := (nCjBPDV - nVPopust)
	// izracuna PDV na cijenu sa popustom
	nCj2PDV := (nCj2BPDV * (1 + nPPDV/100))
	
	// ukupno stavka
	nUkStavka := nKol * nCj2PDV
	nUkStavke := ROUND(nUkStavka, ZAO_VRIJEDNOST() + IIF(idtipdok=="13", 4, 0) )

	nPom1 := nKol * nCjBPDV 
	nPom1 := ROUND(nPom1, ZAO_VRIJEDNOST() + IIF(idtipdok=="13", 4, 0) )
	// ukupno bez pdv
	nUkBPDV += nPom1 
	

	// ukupno popusta za stavku
	nPom2 := nKol * nVPopust
	nPom2 := ROUND(nPom2, ZAO_VRIJEDNOST() + IIF(idtipdok=="13", 4, 0) )
	nUkVPop += nPom2

	// preracunaj VPDV sa popustom
	nVPDV := (nCj2BPDV * (nPPDV/100))


	//  ukupno vrijednost bez pdva sa uracunatim poputstom
	nPom3 := nPom1 - nPom2 
	nPom3 := ROUND(nPom3, ZAO_VRIJEDNOST() + IIF(idtipdok=="13", 4, 0))
	nUkBPDVPop += nPom3
	

	// ukupno PDV za stavku = (ukupno bez pdv - ukupno popust) * stopa
	nPom4 := nPom3 * nPPDV/100
	// povecaj preciznost
	nPom4 := ROUND(nPom4, ZAO_VRIJEDNOST() + IIF(idtipdok=="13", 4, 2))
	nUkPDV += nPom4
	
	// ukupno za stavku sa pdv-om
	nTotal +=  nPom3 + nPom4

	nPom5 := nKol * nVPopNaTeretProdavca
	nPom5 := ROUND(nPom5, ZAO_VRIJEDNOST())
	nUkPopNaTeretProdavca += nPom5

	++ nCSum
	
	// planika treba sumarne kolicine na dokumentu
	if IsPlanika()
	  if roba->k2 <> "X"
	  	nUkkol += nKol
	  endif
	endif
	
	
	add_rn(cBrDok, cRbr, cPodBr, cIdRoba, cRobaNaz, cJmj, nKol, nCjPDV, nCjBPDV, nCj2PDV, nCj2BPDV, nPopust, nPPDV, nVPDV, nUkStavka, nPopNaTeretProdavca, nVPopNaTeretProdavca )

	select pripr
	skip
enddo	

// zaokruzi pdv na zao_vrijednost()
nUkPDV := ROUND( nUkPDV, ZAO_VRIJEDNOST() ) 

nTotal := (nUkBPDVPop + nUkPDV)

// zaokruzenje
nFZaokr := ROUND(nTotal, ZAO_VRIJEDNOST()) - ROUND2(ROUND(nTotal, ZAO_VRIJEDNOST()), gFZaok)
if (gFZaok <> 9 .and. ROUND(nFZaokr, 4) <> 0)
	nDrnZaokr := nFZaokr
endif

nTotal := ROUND(nTotal - nDrnZaokr, ZAO_VRIJEDNOST())

nUkPopNaTeretProdavca := ROUND(nUkPopNaTeretProdavca, ZAO_VRIJEDNOST())
nUkBPDV := ROUND( nUkBPDV, ZAO_VRIJEDNOST() )
nUkVPop := ROUND( nUkVPop, ZAO_VRIJEDNOST() )

select pripr
go (nRec)

// nafiluj ostale podatke vazne za sam dokument
aMemo := ParsMemo(txt)
dDatDok := datdok

if LEN(aMemo) <= 5
	dDatVal := dDatDok
	dDatIsp := dDatDok
	cBrOtpr := ""
	cBrNar  := ""
else
	dDatVal := CToD(aMemo[9])
	dDatIsp := CToD(aMemo[7])
	cBrOtpr := aMemo[6]
	cBrNar  := aMemo[8]
endif


if LEN(aMemo) >= 18
	cDestinacija := aMemo[18]
else
	cDestinacija := ""
endif

// mjesto
add_drntext("D01", gMjStr)
// naziv dokumenta
add_drntext("D02", cDokNaz )

// Destinacija
add_drntext("D09", cIdTipDok)

// slovima iznos fakture
add_drntext("D04", Slovima( nTotal - nUkPopNaTeretProdavca , cDinDem))

// broj otpremnice
add_drntext("D05", cBrOtpr)

// broj narudzbenice
add_drntext("D06", cBrNar)

// DM/EURO
add_drntext("D07", cDinDem)

// Destinacija
add_drntext("D08", cDestinacija)

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

do case

 case cIdTipDok == "12" .and. lKomisionar
 	add_drntext("P11", "KOMISION")

 case lIno
 	// ino faktura
 	add_drntext("P11", "INO" )

 case !EMPTY(cPdvOslobadjanje)
 	add_drntext("P11", cPdvOslobadjanje)
	
 otherwise
 	// domaca faktura
 	add_drntext("P11", "DOMACA" )

endcase

// redova iznad "kupac"
add_drntext("X01", STR( nDx1, 2, 0) )
// redova ispod "kupac"
add_drntext("X02", STR( nDx2, 2, 0) )
// redova izmedju broja narudbze i tabele
add_drntext("X03", STR( nDx3, 2, 0) )


add_drntext("X04", STR( nSw1, 2, 0) )
add_drntext("X05", STR( nSw2, 2, 0) )
add_drntext("X06", STR( nSw3, 2, 0) )
add_drntext("X07", STR( nSw4, 2, 0) )
add_drntext("X08", STR( nSw5, 2, 0) )

do case
	case nSw5 == 0
		gPtxtSw := "/noline /s /l /p"
	case nSw5 == 1
		gPtxtSw := "/p"
	otherwise
		// citaj ini fajl
		gPtxtSw := nil
endcase


// dodaj total u DRN
add_drn(cBrDok, dDatDok, dDatVal, dDatIsp, cTime, nUkBPDV, nUkVPop, nUkBPDVPop, nUkPDV, nTotal, nCSum, nUkPopNaTeretProdavca, nDrnZaokr, nUkKol)

return
*}


function fill_potpis(cIdVD)
*{
local cPom
local cPotpis



if (cIdVd $ "01#00") 
	cPotpis := REPLICATE(" ", 12) + "Odobrio" + REPLICATE(" ", 25) + "Primio"

elseif cIdVd $ "19"
	cPotpis := REPLICATE(" ", 12) + "Odobrio" + REPLICATE(" ", 25) + "Predao"
else
   	cPom:="G"+cIdVD+"STR2T"
   	cPotpis := &cPom
endif

// potpis 
add_drntext("F10", cPotpis)

return
*}


// daj naziv dokumenta iz parametara
function get_dok_naz(cNaz, cIdVd, lSamoKol)
*{
local cPom
local cSamoKol

if (cIdVd == "01")
	cNaz := "Prijem robe u magacin br."
elseif (cIdVd == "00")
	cNaz := "Pocetno stanje br."
elseif (cIdVD == "19")
	cNaz := "Izlaz po ostalim osnovama br."
else
 	cPom:="G" + cIdVd + "STR"
 	cNaz := &cPom
endif

// ako je lSamoKol := .t. onda je prikaz samo kolicina
cSamoKol := "N"
if lSamoKol
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
	add_drntext("F" + ALLTRIM(STR(nFId)), aLines[i])
	++ nFId
	++ nCnt
next

// dodaj i parametar koliko ima linija texta
add_drntext("P02", ALLTRIM(STR(nCnt)))

return
*}


function fill_part_data(cId, lPdvObveznik)
*{
local cIdBroj:=""
local cPorBroj:=""
local cBrRjes:=""
local cBrUpisa:=""
local cPartNaziv:=""
local cPartAdres:=""
local cPartMjesto:=""
local cPartTel:=""
local cPartFax:=""
local cPartPTT:=""
local aMemo:={}
local lFromMemo:=.f.

if Empty(ALLTRIM(cID))
	// ako je prazan partner uzmi iz memo polja
	aMemo:=ParsMemo(txt)
	lFromMemo := .t.
else
	O_PARTN
	select partn
	set order to tag "ID"
	hseek cId
endif

if !lFromMemo .and. partn->id == cId
	// uzmi podatke iz SIFK
	cIdBroj := IzSifK("PARTN", "REGB", cId, .f.)
	cPorBroj := IzSifK("PARTN", "PORB", cId, .f.)
	cBrRjes := IzSifK("PARTN", "BRJS", cId, .f.)
	cBrUpisa := IzSifK("PARTN", "BRUP", cId, .f.)
	cPartNaziv := partn->naz
	cPartAdres := partn->adresa
	cPartMjesto := partn->mjesto
	cPartPtt := partn->ptt
	cPartTel := partn->telefon
	cPartFax := partn->fax
else
	if LEN(aMemo) == 0
		cPartNaziv := ""
		cPartAdres := ""
		cPartMjesto := ""
	else
		cPartNaziv := aMemo[3]
		cPartAdres := aMemo[4]
		cPartMjesto := aMemo[5]
	endif
endif

// naziv
add_drntext("K01", cPartNaziv)
// adresa
add_drntext("K02", cPartAdres)
// mjesto
add_drntext("K10", cPartMjesto)
// ptt
add_drntext("K11", cPartPTT)
// idbroj
add_drntext("K03", cIdBroj)
// porbroj
add_drntext("K05", cPorBroj)

// tel
add_drntext("K13", cPartTel)
// fax
add_drntext("K14", cPartFax)

if !EMPTY(cIdBroj) 
	if LEN(ALLTRIM(cIdBroj)) == 12
		lPdvObveznik := .t.
	else
		lPdvObveznik := .f.
	endif
else
	lPdvObveznik := .f.
endif
	
// brrjes
add_drntext("K06", cBrRjes)
// brupisa
add_drntext("K07", cBrUpisa)

return
*}

function fill_firm_data()
*{
local i
local cBanke
local cPom
local lPrazno
// opci podaci
add_drntext("I01", gFNaziv)
add_drntext("I02", gFAdresa)
add_drntext("I03", gFIdBroj)
// 4. se koristi za id prod.mjesto u pos
add_drntext("I10", ALLTRIM(gFTelefon))
add_drntext("I11", ALLTRIM(gFEmailWeb))

// banke
cBanke:=""
lPrazno:=.t.

for i:=1 to 5
  if i==1
    cPom:=ALLTRIM(gFBanka1)
  elseif i==2
    cPom:=ALLTRIM(gFBanka2)
  elseif i==3
    cPom:=ALLTRIM(gFBanka3)
  elseif i==4
    cPom:=ALLTRIM(gFBanka4)
  elseif i==5
    cPom:=ALLTRIM(gFBanka5)
  endif
  if !empty(cPom)
	if !lPrazno
		cBanke += ", "
	endif
	cBanke += cPom
	lPrazno := .f.
  endif
next


add_drntext("I09", cBanke )

// dodatni redovi
add_drntext("I12", ALLTRIM(gFText1))
add_drntext("I13", ALLTRIM(gFText2))
add_drntext("I14", ALLTRIM(gFText3))

return
*}


// ------------------------------------
// ------------------------------------
static function ZAO_VRIJEDNOST()
local nPos
local nLen

// 999.99
nPos := AT(".", PicDem)
// = 4
nLen := LEN(PicDEM) 
// = 6

if nPos == 0
	nPos := nLen
endif

return nLen - nPos


// ------------------------------------
// ------------------------------------
static function ZAO_CIJENA()
local nPos
local nLen

altd()
// 999.99
nPos := AT(".", PicCDem)
// = 4
nLen := LEN(PicDEM) 
// = 6

if nPos == 0
	nPos := nLen
endif

return nLen - nPos

