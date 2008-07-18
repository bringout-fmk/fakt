#include "fakt.ch"

// ----------------------------------------------------------------
//                        Copyright Sigma-com software 1998-2006 
// ----------------------------------------------------------------

EXTERNAL RIGHT,LEFT,FIELDPOS

#ifdef LIB
function Main(cKorisn, cSifra, p3,p4,p5,p6,p7)
	MainFakt(cKorisn, cSifra, p3,p4,p5,p6,p7)
return
#endif



// ------------------------------------------------------
// MainFAKT(cKorisn, cSifra, p3, p4, p5, p6, p7)
// ------------------------------------------------------ 
function MainFAKT(cKorisn, cSifra, p3, p4, p5, p6, p7)
local oFakt

oFakt:=TFaktModNew()
cModul:="FAKT"

PUBLIC goModul

goModul:=oFakt
oFakt:init(NIL, cModul, D_FA_VERZIJA, D_FA_PERIOD , cKorisn, cSifra, p3,p4,p5,p6,p7)

oFakt:run()

return 


