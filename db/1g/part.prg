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

// ----------------------------------------------
// napuni sifrarnik sifk  sa poljem za unos 
// podatka o PDV oslobadjanju 
// ---------------------------------------------
function fill_part()
local lFound
local cSeek
local cNaz
local cId
local cOznaka

SELECT (F_SIFK)

if !used()
	O_SIFK
endif

SET ORDER TO TAG "ID"
//id+SORT+naz


cId := PADR("PARTN", 8) 
cNaz := PADR("PDV oslob. ZPDV", LEN(naz))
cRbr := "08"
cOznaka := "PDVO"
add_n_found(cId, cNaz, cRbr, cOznaka, 3)

cId := PADR("PARTN", 8) 
cNaz := PADR("Profil partn.", LEN(naz))
cRbr := "09"
cOznaka := "PROF"
add_n_found(cId, cNaz, cRbr, cOznaka, 25)


// -------------------------------------------
// -------------------------------------------
static function add_n_found(cId, cNaz, cRbr, cOznaka, nDuzina)
local cSeek

cSeek :=  cId + cRbr + cNaz
SEEK cSeek   

if !FOUND()
	APPEND BLANK
	replace id with cId ,;
		naz with cNaz ,;
		oznaka with cOznaka ,;
		sort with  cRbr,;
		veza with "1" ,;
		tip with "C" ,;
		duzina with nDuzina,;
		decimal with 0
endif

