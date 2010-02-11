#include "fakt.ch"

// ------------------------------------------------------------
// glavni menij izvjestaja
// ------------------------------------------------------------
function Izvj()
private opc:={}
private opcexe:={}
private Izbor:=1

// PTXT compatibility  sa ver < 1.52
gPtxtC50 := .t.

AADD(opc,"1. stanje robe                               ")
AADD(opcexe,{|| StanjeRobe()})
AADD(opc,"2. lager lista - specifikacija   ")
AADD(opcexe,{|| Lager()})
AADD(opc,"3. kartica")
AADD(opcexe,{|| Kartica()})
AADD(opc,"4. uporedna lager lista fakt1 <-> fakt2")
AADD(opcexe,{|| Fakt_Kalk(.t.)})
AADD(opc,"5. uporedna lager lista fakt <-> kalk")
AADD(opcexe,{|| Fakt_Kalk(.f.)})
AADD(opc,"6. realizacija kumulativno po partnerima")
AADD(opcexe,{|| RealPartn()})
AADD(opc,"7. specifikacija prodaje")
AADD(opcexe,{|| RealKol()})
AADD(opc,"8. specifikacija prodaje po parternima ")
AADD(opcexe,{|| spec_kol_partn()})
AADD(opc,"9. realizacija maloprodaje ")
AADD(opcexe,{|| real_mp()})

if IsRudnik() 
	AADD(opc,"R. rudnik")
	AADD(opcexe,{|| MnuRudnik()})
endif
	
if IsStampa()
	AADD(opc,"S. stampa")
	AADD(opcexe,{|| MnuStampa()})
endif

if IsKonsig()
	AADD(opc,"K. konsignacija")
	AADD(opcexe,{|| KarticaKons()})
endif    	


private fID_J:=.f.
if IzFmkIni('SifRoba','ID_J','N')=="D"
	private fId_J:=.t.
  	AADD(opc,"C. osvjezi promjene sifarskog sistema u prometu")
	AADD(opcexe,{|| OsvjeziIdJ()})
endif

Menu_SC("izvj")

return
*}

