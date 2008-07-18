#include "fakt.ch"

/*
 * ----------------------------------------------------------------
 *                                     Copyright Sigma-com software 
 * ----------------------------------------------------------------
 *
 */
 

/*! \file fmk/fakt/razdb/1g/mnu_raz.prg
 *  \brief Centralni meni opcija za prenos podataka FAKT<->ostali moduli
 */


/*! \fn ModRazmjena()
 *  \brief Centralni meni opcija za prenos podataka FAKT<->ostali moduli
 */

function ModRazmjena()
*{
private Opc:={}
private opcexe:={}

AADD(opc,"1. kalk <-> fakt      ")
AADD(opcexe,{|| KaFak()})
AADD(opc,"2. kalk->fakt (modem)")
AADD(opcexe,{|| PovModem()})

private Izbor:=1
Menu_SC("rpod")

CLOSERET

return
*}
