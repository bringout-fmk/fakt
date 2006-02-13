#include "\dev\fmk\fakt\fakt.ch"

// ----------------------------------------------
// napuni sifrarnik sifk  sa poljem za unos 
// podatka o PDV oslobadjanju 
// ---------------------------------------------
function fill_part()
local lFound
local cSeek
local cNaz
local cId


SELECT (F_SIFK)

if !used()
	O_SIFK
endif

SET ORDER TO TAG "ID"
//id+SORT+naz

cId := PADR("PARTN", 8) 
cNaz := PADR("PDV oslob. ZPDV", LEN(naz))
cSeek :=  cId + "08" + cNaz


SEEK cSeek   

if !FOUND()
	APPEND BLANK
	replace id with cId ,;
		naz with cNaz ,;
		oznaka with "PDVO" ,;
		sort with "08" ,;
		veza with "1" ,;
		tip with "C" ,;
		duzina with 3 ,;
		decimal with 0
endif

