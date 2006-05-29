#include "\dev\fmk\fakt\fakt.ch"

/*
 * ----------------------------------------------------------------
 *                         Copyright Sigma-com software 1996-2006 
 * ----------------------------------------------------------------
 */

/*! \file fmk/fakt/main/1g/e.prg
 *  \brief
 */


EXTERNAL RIGHT,LEFT,FIELDPOS

#ifdef LIB
function Main(cKorisn, cSifra, p3,p4,p5,p6,p7)
*{
	MainFakt(cKorisn, cSifra, p3,p4,p5,p6,p7)
return
*}
#endif



/*! \fn MainFAKT(cKorisn,cSifra,p3,p4,p5,p6,p7)
 *  \brief
 *  \param cKorisn
 *  \param cSifra
 *  \param p3
 *  \param p4
 *  \param p5
 *  \param p6
 *  \param p7
 */
 
function MainFAKT(cKorisn, cSifra, p3, p4, p5, p6, p7)
*{
local oFakt

oFakt:=TFaktModNew()
cModul:="FAKT"

PUBLIC goModul

goModul:=oFakt
oFakt:init(NIL, cModul, D_FA_VERZIJA, D_FA_PERIOD , cKorisn, cSifra, p3,p4,p5,p6,p7)

oFakt:run()

return 
*}


