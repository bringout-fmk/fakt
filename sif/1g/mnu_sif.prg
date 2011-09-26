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
 *                          Copyright Sigma-com software 1996-2006 
 * ----------------------------------------------------------------
 */

/*! \file fmk/fakt/sif/1g/mnu_sif.prg
 *  \brief Menij sifrarnika
 */

/*! \fn Sifre()
 *  \brief Menij sifrarnika
 */
 
function Sifre()
*{
private opc:={}
private opcexe:={}
private Izbor:=1

AADD(opc,"1. opci sifrarnici              ")
if (ImaPravoPristupa(goModul:oDataBase:cName,"SIF","OPCISIFOPEN"))
	AADD(opcexe,{|| SifFMKSvi()})
else
	AADD(opcexe,{|| MsgBeep(cZabrana)})
endif

AADD(opc,"2. robno-materijalno poslovanje ")
if (ImaPravoPristupa(goModul:oDataBase:cName,"SIF","ROBMATSIFOPEN"))
	AADD(opcexe,{|| SifFMKRoba()})
else
	AADD(opcexe,{|| MsgBeep(cZabrana)})
endif

AADD(opc,"3. fakt->txt")
if (ImaPravoPristupa(goModul:oDataBase:cName,"SIF","FTXTSIFOPEN"))
	AADD(opcexe,{|| OSifFtxt(), P_FTxt()} )
else
	AADD(opcexe,{|| MsgBeep(cZabrana)})
endif

if IsRabati()
	AADD(opc,"R. rabatne skale")
	AADD(opcexe,{|| P_Rabat() })
endif

if IsUgovori()
	AADD(opc,"U. ugovori")
	AADD(opcexe,{|| o_ugov(), SifUgovori()})
endif

if gFc_use == "D" .and. ALLTRIM(gFc_type) == "FLINK"
	AADD(opc,"I. fiscal : inicijalizacija")
	AADD(opcexe,{|| ffisc_init() })
endif


Menu_SC("fsif")
return
*}

