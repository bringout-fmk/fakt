#include "\dev\fmk\fakt\fakt.ch"
/*
 * ----------------------------------------------------------------
 *                           Copyright Sigma-com software 2000-2006
 * ----------------------------------------------------------------
 *
 */


/*! \file fmk/fakt/ugov/1g/mnu_ugov.prg
 *  \brief Ugovori
 */

/*! \fn MnuUgovori()
 *  \brief Menij ugovora
 */
 
function SifUgovori()
private opc:={}
private opcexe:={}
private Izbor:=1

AADD(opc,"1. ugovori                  ")
AADD(opcexe,{|| P_Ugov()})
AADD(opc,"2. ugovori - tekuce postavke")
AADD(opcexe,{|| DFTParUg()})

Menu_SC("sugov")
return

