#include "\dev\fmk\fakt\fakt.ch"

/*! \file fmk/fakt/specif/ramag/1g/rn_db.prg
 *  \brief Radni nalozi dataaccess sloj
 */

/*! \fn RnDB_Cre() 
 *  \brief Kreiranje tabele
 */
function SDimDB_Cre()
*{
if !IsRamaGlas()
	return
endif
aColl:={}
AADD(aColl, {"IDFIRMA", "C",  2, 0})
AADD(aColl, {"IDTIPDOK","C",  2, 0})
AADD(aColl, {"BRDOK",   "C",  8, 0})
AADD(aColl, {"IDROBA",  "C", 13, 0})
AADD(aColl, {"KOM",     "N",  6, 0})
AADD(aColl, {"DIMA",    "N",  6, 2})
AADD(aColl, {"DIMB",    "N",  6, 2})
AADD(aColl, {"DIMAZ",   "N",  6, 2})
AADD(aColl, {"DIMBZ",   "N",  6, 2})
AADD(aColl, {"UKUP",    "N",  8, 2})
AADD(aColl, {"UKUPZ",   "N",  8, 2})

if !File(KUMPATH + "SDIM.DBF")
	DbCreate2(KUMPATH + "SDIM.DBF", aColl)
endif
if !File(PRIVPATH + "_SDIM.DBF")
	DbCreate2(PRIVPATH + "_SDIM.DBF", aColl)
endif

CREATE_INDEX("1", "IDFIRMA+IDTIPDOK+BRDOK+IDROBA", KUMPATH+"SDIM")	
CREATE_INDEX("1", "IDFIRMA+IDTIPDOK+BRDOK+IDROBA", PRIVPATH+"_SDIM")	

return
*}

/*! \fn O_SDimDB()
 *  \brief Otvara tabelu SDIM
 */
function O_SDimDB()
*{
O_SDIM
return
*}


/*! \fn AzurSDim()
 *  \brief Azuriranje Dimenzija stakla
 */
function AzurSDim()
*{
Scatter()
_idfirma := doks->idfirma
_idvd := doks->idfirma
_brdok := doks->brdok

Gather()

return
*}



