/* 
 * This file is part of the bring.out FMK, a free and open source 
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the 
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "fakt.ch"


function MBrDoks()
private opc:={}
private opcexe:={}
private Izbor:=1

AADD(opc,"1. stampa azuriranog dokumenta              ")
AADD(opcexe, {|| StAzFakt()})
AADD(opc,"2. stampa liste dokumenata")
AADD(opcexe, {|| StDatn()})
AADD(opc,"3. stampa dokumenata od broja do broja      ")
AADD(opcexe, {|| StAzPeriod()})

if IsUgovori()
	AADD(opc,"U. stampa fakt.na osnovu ugovora od-do")
	AADD(opcexe, {|| ug_za_period()})
endif

// ako koristimo fiskalne funkcije
if gFc_use == "D"
	AADD(opc,"F. stampa fiskalnih racuna od-do")
	AADD(opcexe, {|| st_fisc_per()})
endif

Menu_SC("stfak")

CLOSERET

return .f.

/*! \fn MAzurDoks()
 *  \brief Ostale operacije nad podacima
 */
 
function MAzurDoks()
private opc:={}
private opcexe:={}
private Izbor:=1

AADD(opc,"1. povrat dokumenta u pripremu       ")
AADD(opcexe,{|| Povrat()})
AADD(opc,"2. povrat dokumenata prema kriteriju ")
AADD(opcexe,{|| if(SigmaSif(), PovSvi(), nil)})
AADD(opc,"3. prekid rezervacije")
AADD(opcexe,{|| Povrat(.t.)})
AADD(opc,"4. evidentiranje uplata")
AADD(opcexe,{|| Uplate()})
AADD(opc,"5. lista salda kupaca")
AADD(opcexe,{|| SaldaKupaca()})
AADD(opc,"6. pocetno stanje za evidenciju uplata")
AADD(opcexe,{|| GPSUplata()})
AADD(opc,"7. stampa narudzbenice")
AADD(opcexe,{|| Mnu_Narudzbenica()})

Menu_SC("ostop")
return .f.
*}
