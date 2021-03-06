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

/*
 * ----------------------------------------------------------------
 *                                     Copyright Sigma-com software 
 * ----------------------------------------------------------------
 * $Source: c:/cvsroot/cl/sigma/fmk/fakt/specif/rudnik/1g/mnu_izvj.prg,v $
 * $Author: sasa $ 
 * $Revision: 1.1 $
 * $Log: mnu_izvj.prg,v $
 * Revision 1.1  2002/07/05 14:16:49  sasa
 * napravljen direktorij \1g nije ga bilo
 *
 * Revision 1.1  2002/07/05 14:11:04  sasa
 * novi prg mnu_izvj.prg
 *
 *
 */


/*! \file fmk/specif/rudnik/mnu_izvj.prg
 *  \brief Izvjestaji rudnik
 */
 
/*! \fn MnuRudnik()
 *  \brief menij izvjestaja rudnika
 */
 
function MnuRudnik()
*{
private opc:={}
private opcexe:={}
private Izbor:=1

AADD(opc,"1. isporuceni asortiman po kupcima")
AADD(opcexe,{|| Pregled1()})
AADD(opc,"2. fakture asortimana za kupca")
AADD(opcexe,{|| Pregled2()})
AADD(opc,"3. isporuceni asortiman za kupca po pogonima")
AADD(opcexe,{|| Pregled3()})
AADD(opc,"4. pregled faktura usluga za kupca")
AADD(opcexe,{|| Pregled4()})
AADD(opc,"5. pregled poreza")
AADD(opcexe,{|| Pregled5()})

Menu_SC("rizv")

return
*}

