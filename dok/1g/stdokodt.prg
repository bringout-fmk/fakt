#include "fakt.ch"


// ------------------------------------------------
// stampa dokumenta u odt formatu
// ------------------------------------------------
function stdokodt( cIdf, cIdVd, cBrDok )
local cPath := "c:\"
local cFilter := "f*.odt"
local cTemplate := ""

// samo napuni pomocne tabele
stdokpdv( cIdF, cIdVd, cBrDok, .t. )

// generisi xml fajl
_gen_xml()

// uzmi template koji ces koristiti
g_afile( cPath, cFilter, @cTemplate, .t. )

// pozovi odt stampu
_odt_print( cPath, cTemplate )

return


// ---------------------------------------------
// generisi xml sa podacima
// ---------------------------------------------
static function _gen_xml()
local cXML := "c:\data.xml"
local i
local cTmpTxt := ""


// DRN
// brdok, datdok, datval, datisp, vrijeme, zaokr, ukbezpdv, ukpopust
// ukpoptp, ukbpdvpop, ukpdv, ukupno, ukkol, csumrn

open_xml( cXml )
xml_head()
xml_subnode("invoice", .f.)

select drn
go top

// totali
xml_node("u_bpdv", ALLTRIM( STR( field->ukbezpdv, 12, 2 ) ) )
xml_node("u_pop", ALLTRIM( STR( field->ukpopust, 12, 2 ) ) )
xml_node("u_poptp", ALLTRIM( STR( field->ukpoptp, 12, 2 ) ) )
xml_node("u_bpdvpop", ALLTRIM( STR( field->ukbpdvpop, 12, 2 ) ) )
xml_node("u_pdv", ALLTRIM( STR( field->ukpdv, 12, 2 ) ) )
xml_node("u_kol", ALLTRIM( STR( field->ukupno, 12, 2 ) ) )
xml_node("u_total", ALLTRIM( STR( field->ukkol, 12, 2) ) )

// dokument iz tabele
xml_node("dbr", ALLTRIM( field->brdok ) )
xml_node("ddat", DTOC( field->datdok ) )
xml_node("ddval", DTOC( field->datval ) )
xml_node("ddisp", DTOC( field->datisp ) )
xml_node("dvr", ALLTRIM( field->vrijeme ) )

// dokument iz teksta
cTmp := ALLTRIM(get_dtxt_opis("D01"))
xml_node("dmj", strkzn(cTmp, "8", "U"))
cTmp := ALLTRIM(get_dtxt_opis("D02"))
xml_node("ddok", strkzn(cTmp,"8","U"))
cTmp := ALLTRIM(get_dtxt_opis("D04"))
xml_node("dslovo", strkzn(cTmp,"8","U"))
xml_node("dotpr", ALLTRIM(get_dtxt_opis("D05")) )
xml_node("dnar", ALLTRIM(get_dtxt_opis("D06")) )
xml_node("ddin", ALLTRIM(get_dtxt_opis("D07")) )
cTmp := ALLTRIM(get_dtxt_opis("D08"))
xml_node("ddest", strkzn(cTmp,"8","U"))
xml_node("dtdok", ALLTRIM(get_dtxt_opis("D09")) )
xml_node("drj", ALLTRIM(get_dtxt_opis("D10")) )
xml_node("didpm", ALLTRIM(get_dtxt_opis("D11")) )
cTmp := ALLTRIM(get_dtxt_opis("F10"))
xml_node("dsign", strkzn(cTmp,"8","U"))

// zaglavlje
cTmp := ALLTRIM(get_dtxt_opis("I01"))
xml_node("fnaz", strkzn(cTmp,"8","U"))
cTmp := ALLTRIM(get_dtxt_opis("I02"))
xml_node("fadr", strkzn(cTmp,"8","U"))
xml_node("fid", ALLTRIM(get_dtxt_opis("I03")) )
xml_node("ftel", ALLTRIM(get_dtxt_opis("I10")) )
xml_node("feml", ALLTRIM(get_dtxt_opis("I11")) )
xml_node("fbnk", ALLTRIM(get_dtxt_opis("I09")) )
cTmp := ALLTRIM(get_dtxt_opis("I12"))
xml_node("fdt1", strkzn(cTmp,"8","U"))
cTmp := ALLTRIM(get_dtxt_opis("I13"))
xml_node("fdt2", strkzn(cTmp,"8","U"))
cTmp := ALLTRIM(get_dtxt_opis("I14"))
xml_node("fdt3", strkzn(cTmp,"8","U"))

// partner
xml_node("knaz", strkzn(ALLTRIM(get_dtxt_opis("K01")),"8","U") )
xml_node("kadr", strkzn(ALLTRIM(get_dtxt_opis("K02")),"8","U") )
xml_node("kid", ALLTRIM(get_dtxt_opis("K03")) )
xml_node("kpbr", ALLTRIM(get_dtxt_opis("K05")) )
xml_node("kmj", strkzn(ALLTRIM(get_dtxt_opis("K10")),"8","U") )
xml_node("kptt", ALLTRIM(get_dtxt_opis("K11")) )
xml_node("ktel", ALLTRIM(get_dtxt_opis("K13")) )
xml_node("kfax", ALLTRIM(get_dtxt_opis("K14")) )


// dodatni tekst na fakturi....
// koliko ima redova ?
nTxtR := VAL( get_dtxt_opis("P02") )

for i := 20 to ( 20 + nTxtR )
	
	cTmp := "F" + ALLTRIM( STR(i) )
	cTmpTxt := ALLTRIM( get_dtxt_opis(cTmp) )

	xml_subnode("text", .f.)
	xml_node("row", strkzn(cTmpTxt,"8","U") )
	xml_subnode("text", .t.)

next


// RN
// brdok, rbr, podbr, idroba, robanaz, jmj, kolicina, cjenpdv, cjenbpdv
// cjen2pdv, cjen2bpdv, popust, ppdv, vpdv, ukupno, poptp, vpoptp
// c1, c2, c3, opis

// predji sada na stavke fakture
select rn
go top

do while !EOF()
	
	xml_subnode( "item", .f. )
	
	xml_node( "rbr", ALLTRIM( field->rbr ) )
	xml_node( "pbr", ALLTRIM( field->podbr ) )
	xml_node( "id", ALLTRIM( field->idroba ) )
	xml_node( "naz", strkzn(ALLTRIM( field->robanaz ),"8","U" ))
	xml_node( "jmj", ALLTRIM( field->jmj ) )
	xml_node( "kol", ALLTRIM( STR( field->kolicina, 12, 2 ) ) )
	xml_node( "cpdv", ALLTRIM( STR( field->cjenpdv, 12, 2 ) ) )
	xml_node( "cbpdv", ALLTRIM( STR( field->cjenbpdv, 12, 2 ) ) )
	xml_node( "c2pdv", ALLTRIM( STR( field->cjen2pdv, 12, 2 ) ) )
	xml_node( "c2bpdv", ALLTRIM( STR( field->cjen2bpdv, 12, 2 ) ) )
	xml_node( "pop", ALLTRIM( STR( field->popust, 12, 2 ) ) )
	xml_node( "ppdv", ALLTRIM( STR( field->ppdv, 12, 2 ) ) )
	xml_node( "vpdv", ALLTRIM( STR( field->vpdv, 12, 2 ) ) )
	xml_node( "uk", ALLTRIM( STR( field->ukupno, 12, 2 ) ) )
	xml_node( "ptp", ALLTRIM( STR( field->poptp, 12, 2 ) ) )
	xml_node( "vtp", ALLTRIM( STR( field->vpoptp, 12, 2 ) ) )
	xml_node( "c1", ALLTRIM( field->c1 ) )
	xml_node( "c2", ALLTRIM( field->c2 ) )
	xml_node( "c3", ALLTRIM( field->c3 ) )
	xml_node( "opis", ALLTRIM( field->opis ) )

	xml_subnode( "item", .t. )
	
	skip

enddo

xml_subnode("invoice", .t.)
close_xml()

return


// ----------------------------------------------
// printaj odt dokument
// ----------------------------------------------
static function _odt_print( cPath, cTemplate, lDirectPrint )
local cJodPath 
local cOOPath
local cOOParams := ""

private cCmdLine

if lDirectPrint == nil
	lDirectPrint := .f.
endif

cJodPath := EXEPATH + "java\jodrep.jar"
cOOPath := '"c:\Program Files\OpenOffice.org 3\program\swriter.exe"'

cCmdLine := "java -jar " + cJodPath + " " + cPath + cTemplate + ;
	" c:\data.xml c:\out.odt" 

save screen to cScreen
run &cCmdLine
restore screen from cScreen

if lDirectPrint == .t.
	cOOParams := " -pt "
endif

cCmdLine := "start " + cOOPath + " " + cOOParams + " c:\out.odt"
run &cCmdLine

return


