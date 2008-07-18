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

