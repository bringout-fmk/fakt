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

 
function GDokInv(cIdRj)
local cIdRoba
local cBrDok
local nUl
local nIzl
local nRezerv
local nRevers
local nRbr
local lFoundUPripremi

O_DOKS
O_ROBA
O_TARIFA
O_PRIPR
SET ORDER TO TAG "3"

O_FAKT
MsgO("scaniram tabelu fakt")
nRbr:=0

GO TOP
cBrDok:=FaNoviBroj(cIdRj, "IM") 
do while !EOF()
	if (field->idFirma<>cIdRj)
		SKIP
		loop
	endif
	SELECT pripr
	cIdRoba:=fakt->idRoba
	// vidi imali ovo u pripremi; ako ima stavka je obradjena
	SEEK cIdRj+cIdRoba
	lFoundUPripremi:=FOUND()
	SELECT fakt
	PushWa()
	if !(lFoundUPripremi)
		FaStanje(cIdRj, cIdroba, @nUl, @nIzl, @nRezerv, @nRevers, .t.)
		if (nUl-nIzl-nRevers)<>0
			SELECT pripr
			nRbr++
			ShowKorner(nRbr, 10)
			cRbr:=RedniBroj(nRbr)
			ApndInvItem(cIdRj, cIdRoba, cBrDok, nUl-nIzl-nRevers, cRbr)
		endif
	endif
	PopWa()
	SKIP
enddo
MsgC()

CLOSE ALL
return
*}

static function ApndInvItem(cIdRj, cIdRoba, cBrDok, nKolicina, cRbr)
*{

APPEND BLANK
REPLACE idFirma WITH cIdRj
REPLACE idRoba  WITH cIdRoba
REPLACE datDok  WITH DATE()
REPLACE idTipDok WITH "IM"
REPLACE serBr   WITH STR(nKolicina, 15, 4)
REPLACE kolicina WITH nKolicina
REPLACE rBr WITH cRbr

if VAL(cRbr)==1
	cTxt:=""
	AddTxt(@cTxt, "")
	AddTxt(@cTxt, "")
	AddTxt(@cTxt, gNFirma)
	AddTxt(@cTxt, "RJ:"+cIdRj)
	AddTxt(@cTxt, gMjStr)
	REPLACE txt WITH cTxt
endif

REPLACE brDok WITH cBrDok
REPLACE dinDem WITH ValDomaca()
SELECT roba
SEEK cIdRoba
SELECT pripr
REPLACE cijena WITH roba->vpc
return
*}

static function AddTxt(cTxt, cStr)
*{
cTxt:=cTxt+Chr(16)+cStr+Chr(17)
return nil
*}




/*! \fn GDokInvManjak(cIdRj, cBrDok)
 *  \param cIdRj - oznaka firme dokumenta IM na osnovu kojeg se generise dok.19
 *  \param cBrDok - broj dokumenta IM na osnovu kojeg se generise dok.19
 *  \brief Generacija dokumenta 19 tj. otpreme iz mag na osnovu dok. IM
 */
function GDokInvManjak(cIdRj, cBrDok)
*{
local nRBr
local nRazlikaKol
local cRBr
local cNoviBrDok
nRBr:=0
O_FAKT
O_PRIPR
O_ROBA
cNoviBrDok:=FaNoviBroj(cIdRj, "19")
SELECT fakt
SET ORDER TO TAG "1"
HSEEK cIdRj+"IM"+cBrDok
do while (!eof() .and. cIdRj+"IM"+cBrDok==fakt->(idFirma+idTipDok+brDok))
	nRazlikaKol:=VAL(fakt->serBr)-fakt->kolicina
	if (ROUND(nRazlikaKol,5)>0)
	        SELECT roba
		HSEEK fakt->idRoba
		SELECT pripr
		nRBr++
		cRBr:=RedniBroj(nRBr)
		ApndInvMItem(cIdRj, fakt->idRoba, cNoviBrDok, nRazlikaKol, cRBr)
	endif
	SELECT fakt
	skip 1
enddo
if (nRBr>0)
	MsgBeep("U pripremu je izgenerisan dokument otpreme manjka "+cIdRj+"-19-"+cNoviBrDok)
else
	MsgBeep("Inventurom nije evidentiran manjak pa nije generisan nikakav dokument!")
endif
CLOSE ALL
return
*}



/*! \fn ApndInvMItem(cIdRj, cIdRoba, cBrDok, nKolicina, cRbr)
 *  \param cIdRj - oznaka firme dokumenta
 *  \param cIdRoba - sifra robe
 *  \param cBrDok - broj dokumenta
 *  \param nKolicina - kolicina tj.manjak
 *  \param cRbr - redni broj stavke
 *  \brief Dodavanje stavke dokumenta 19 za evidentiranje manjka po osnovu inventure
 */
 
static function ApndInvMItem(cIdRj, cIdRoba, cBrDok, nKolicina, cRbr)
*{
APPEND BLANK
REPLACE idFirma WITH cIdRj
REPLACE idRoba  WITH cIdRoba
REPLACE datDok  WITH DATE()
REPLACE idTipDok WITH "19"
REPLACE serBr   WITH ""
REPLACE kolicina WITH nKolicina
REPLACE rBr WITH cRbr

if (VAL(cRbr)==1)
	cTxt:=""
	AddTxt(@cTxt, "")
	AddTxt(@cTxt, "")
	AddTxt(@cTxt, gNFirma)
	AddTxt(@cTxt, "RJ:"+cIdRj)
	AddTxt(@cTxt, gMjStr)
	REPLACE txt WITH cTxt
endif

REPLACE brDok WITH cBrDok
REPLACE dinDem WITH ValDomaca()
REPLACE cijena WITH roba->vpc
return
*}




/*! \fn GDokInvVisak(cIdRj, cBrDok)
 *  \param cIdRj - oznaka firme dokumenta IM na osnovu kojeg se generise dok.19
 *  \param cBrDok - broj dokumenta IM na osnovu kojeg se generise dok.19
 *  \brief Generacija dokumenta 01 tj.primke u magacin na osnovu dok. IM
 */
function GDokInvVisak(cIdRj, cBrDok)
*{
local nRBr
local nRazlikaKol
local cRBr
local cNoviBrDok
nRBr:=0
O_FAKT
O_PRIPR
O_ROBA
cNoviBrDok:=FaNoviBroj(cIdRj, "01")
SELECT fakt
SET ORDER TO TAG "1"
HSEEK cIdRj+"IM"+cBrDok
do while (!eof() .and. cIdRj+"IM"+cBrDok==fakt->(idFirma+idTipDok+brDok))
	nRazlikaKol:=VAL(fakt->serBr)-fakt->kolicina
	if (ROUND(nRazlikaKol,5)<0)
	        SELECT roba
		HSEEK fakt->idRoba
		SELECT pripr
		nRBr++
		cRBr:=RedniBroj(nRBr)
		ApndInvVItem(cIdRj, fakt->idRoba, cNoviBrDok, -nRazlikaKol, cRBr)
	endif
	SELECT fakt
	skip 1
enddo
if (nRBr>0)
	MsgBeep("U pripremu je izgenerisan dokument dopreme viska "+cIdRj+"-01-"+cNoviBrDok)
else
	MsgBeep("Inventurom nije evidentiran visak pa nije generisan nikakav dokument!")
endif
CLOSE ALL
return
*}




/*! \fn ApndInvVItem(cIdRj, cIdRoba, cBrDok, nKolicina, cRbr)
 *  \param cIdRj - oznaka firme dokumenta
 *  \param cIdRoba - sifra robe
 *  \param cBrDok - broj dokumenta
 *  \param nKolicina - kolicina tj.visak
 *  \param cRbr - redni broj stavke
 *  \brief Dodavanje stavke dokumenta 01 za evidentiranje viska po osnovu inventure
 */

static function ApndInvVItem(cIdRj, cIdRoba, cBrDok, nKolicina, cRbr)
*{
APPEND BLANK
REPLACE idFirma WITH cIdRj
REPLACE idRoba  WITH cIdRoba
REPLACE datDok  WITH DATE()
REPLACE idTipDok WITH "01"
REPLACE serBr   WITH ""
REPLACE kolicina WITH nKolicina
REPLACE rBr WITH cRbr

if (VAL(cRbr)==1)
	cTxt:=""
	AddTxt(@cTxt, "")
	AddTxt(@cTxt, "")
	AddTxt(@cTxt, gNFirma)
	AddTxt(@cTxt, "RJ:"+cIdRj)
	AddTxt(@cTxt, gMjStr)
	REPLACE txt WITH cTxt
endif

REPLACE brDok WITH cBrDok
REPLACE dinDem WITH ValDomaca()
REPLACE cijena WITH roba->vpc
return
*}



// ----------------------------------------------
// pretvaranje otpremnice u fakturu
// ----------------------------------------------
function Iz20u10()
local nOrder
local cBrDok := ""
local cIdTipDok := ""
local lSumirati := .t.
local _vp_mp := 1
local _n_tip_dok := "10"
local _ctrl_firma, _ctrl_broj, _ctrl_tip
local _old_broj

select pripr
use

O_PRIPR

go top

if reccount2() == 0

   select doks
   set order to tag "2"

   // idfirma+idtipdok+partner

   ImeKol:={}
   // browsuj tip dokumenta
   AADD(ImeKol,{ "TD",     {|| IdTipdok}               })
   AADD(ImeKol,{ "Broj",   {|| BrDok}                  })
   AADD(ImeKol,{ "Datdok",  {|| DatDok}                })
   AADD(ImeKol,{ "Partner", {|| left(partner,20)}      })
   AADD(ImeKol,{ "Iznos",  {|| str(iznos,11,2)}        })
   AADD(ImeKol,{ "Marker",  {|| M1 }                   })
   Kol:={}
   for i:=1 to len(ImeKol); AADD(Kol,i); next

   cIdrj:=gFirma
   nSuma:=0
   cPartner:=space(20)
   Box(,20,75)
    @ m_x+1,m_y+2 SAY "PREGLED OTPREMNICA:"
    @ m_x+3,m_y+2 SAY "Radna jedinica" GET  cIdRj pict "@!"
    @ m_x+3,col()+2 SAY "Naziv partnera - kljucni dio:" GET cPartner pict "@!"
    read
    cPartner:=trim(cPartner)
    seek cidrj+"12"
    do while !eof() .and. IdFirma + IdTipdok = cidrj + "12"
      IF m1 <> "Z"
        replace m1 with " "
      EndIF
      skip
    enddo

    seek cIdRj + "12"
    
    BrowseKey(m_x+5,m_y+1,m_x+19,m_y+73,ImeKol,{|Ch| EdOtpr(Ch)},"IdFirma+idtipdok=cIdrj+'12'",;
              cIdRj + "12",2,,,{|| partner=cPartner} )
   BoxC()

   if Pitanje(,"Formirati fakturu na osnovu gornjih otpremnica ?","N")=="D"
     
      lSumirati := Pitanje(,"Sumirati stavke fakture (D/N)","D") == "D"

      Box(, 5, 50)
      	@ m_x + 1, m_y + 2 SAY "Formirati: " 
	@ m_x + 3, m_y + 2 SAY " (1) racun veleprodaje "
	@ m_x + 4, m_y + 2 SAY " (2) racun maloprodaje " 
	@ m_x + 5, m_y + 2 SAY "                   ----> " ;
		GET _vp_mp ;
		PICT "9" ;
		VALID _vp_mp > 0 .and. _vp_mp < 3
      	read
      BoxC()

      // nadji sljedeci broj 10-ke ili 11-ke
      if _vp_mp == 1
	  _n_tip_dok := "10"
      else
          _n_tip_dok := "11"
      endif
          
      cVezOtpr := ""
      
      select pripr

      select doks
      go top
      
      // order 2 !!!
      seek cIdRj + "12" + cPartner

      dNajnoviji := CTOD("")
      
      do while !eof() .and. IdFirma + IdTipdok = cIdrj + "12" ;
               .and. UPPER( doks->Partner ) = UPPER( cPartner )
         
	 skip

	 nTrec0 := RECNO()
	 
	 skip -1
         
	 if m1 = "*"

	    cIdPart := doks->idpartner
	    
	    if dNajnoviji < doks->datdok
		    dNajnoviji := doks->datdok
	    endif
      
            nOldIznos := iznos   
            
	    // prvo cemo napraviti kontrolu broja dokumenta
	    _ctrl_firma := doks->idfirma 
	    _ctrl_tip := "22" 
	    _ctrl_broj := doks->brdok
	    _count := 0

	    do while .t.
	        
		++ _count

		select fakt
	    	set order to tag "1"
	    	go top
	    	seek _ctrl_firma + _ctrl_tip + _ctrl_broj

	    	if FOUND()
	       	    	// hjuston, imamo problem
			// uvecaj broj
			_ctrl_broj := PADR( ALLTRIM( _ctrl_broj ), gNumDio ) + "-" + ALLTRIM(STR( _count ))
			_ctrl_broj := PADR( _ctrl_broj, 8 )
	    	else
			exit
		endif

	    enddo

	    select doks

            // napravi zamjenu
            _old_broj := doks->brdok
	    
	    replace idfirma with _ctrl_firma
	    replace brdok with _ctrl_broj
            replace idtipdok with _ctrl_tip      
	    replace m1 with " "       
            
            dxIdFirma := doks->idfirma    
	    dxBrDok   := doks->brdok
            
            cVezOtpr += TRIM(doks->brdok) + ", "
            
	    // odmah napravi promjenu 12-ki i u fakt tabeli
	    select fakt
	    set order to tag "1"
	    go top
	    seek dxIdFirma + "12" + _old_broj
	    do while !EOF() .and. field->idfirma + field->idtipdok + field->brdok == dxIdFirma + "12" + _old_broj
	    	skip
		_t_rec := RECNO()
		skip -1
		replace field->brdok with _ctrl_broj
		go ( _t_rec )
	    enddo

	    select DOKS 
	    set order to tag "1"
           
	    IF gMreznoNum == "N"
               
	       dbseek( dxidfirma + _n_tip_dok + "�", .t. )
               
	       skip -1
               
	       if _n_tip_dok <> idtipdok
                  cBrDok := UBrojDok( 1, gNumDio, "" )
               else
                  cBrDok := UBrojDok( val(left(brdok,gNumDio))+1, ;
                                    gNumDio, ;
                                    right(brdok,len(brdok)-gNumDio) ;
                                  )
               endif
            ELSE
	    	// ostavi prazno za mreznu numeraciju
               	cBrDok := SPACE(LEN(brdok))
            ENDIF
            
	    SELECT FAKT
            seek dxIdFirma + "12" + dxBrDok
            
	    do while !eof() .and. ( dxIdFirma + "12" + dxBrDok ) == ;
	    	(idfirma+idtipdok+brdok)
               
	       skip
	       nTrec:=recno()
	       skip -1
               
	       Scatter()
               
	       replace IdTipDok WITH "22"
               
	       if gMreznoNum == "N"
                  _Brdok := cBrdok
               else
                  _Brdok := SPACE(LEN( BrDok ))
               endif

               _datdok := date()
               _m1:="X"
               _idtipdok := _n_tip_dok
            
	       if _vp_mp == 2
		     // ako je maloprodaja, setuj cijenu sa PDV-om
		     _cijena :=ROUND( _uk_sa_pdv( field->idtipdok, field->idpartner, field->cijena ), 2 )
	       endif

               select pripr
               
	       locate for idroba==fakt->idroba

	       if found() .and. lSumirati == .t. ;
	       		.and. pripr->cijena = fakt->cijena

                 	 _kolicina:=pripr->kolicina+fakt->kolicina

               else
		  	 // append blank
                         appblank2( .t., .f. )
               endif
               
	       Gather2()

               select fakt
               go nTrec
            
	    enddo
         endif
         select doks
	 set order to 2
         go nTrec0
      enddo 

      IF !Empty (cVezOtpr)
         cVezOtpr := "Racun formiran na osnovu otpremnica: " + ;
              LEFT (cVezOtpr, LEN (cVezOtpr)-2) + "."     
		// skine ", "
      ENDIF
      
      select pripr
      
      RenumPripr( cVezOtpr, dNajnoviji )

      select doks
      set order to 1

   endif // formirati

else // stara varijanta

if  idtipdok $ "12#20#13#01#27"

  if idtipdok="27"
     cNoviTip:="11"
  elseif idtipdok="01"
     cNoviTip:="19"
  else
     cNoviTip:="10"
  endif

  if Pitanje(,"Zelite li dokument pretvoriti u "+cNoviTip,"D")=="D"
     Box(,5,60)
     cIdTipDok:=idtipdok
     ccBrDok := BrDok
     IF gMreznoNum == "N"
        @ m_x+1,m_y+2 SAY "Dokument: "; ?? idfirma+"-"+idtipdok+"-"+brdok,"   ", Datdok
        // select FAKT; go top
        select DOKS; go top
        seek pripr->idfirma+cNoviTip+"�"
        skip -1
        if  cNoviTip<>idtipdok
         cBrDok:=UBrojDok(1,gNumDio,"")
        else
         cBrDok:=UBrojDok( val(left(brdok,gNumDio))+1, ;
                           gNumDio, ;
                           right(brdok,len(brdok)-gNumDio) ;
                         )
        endif
        cBrDok:=padr(cbrdok,8)
     ELSE
        cBrDok:=SPACE (LEN (BrDok))
     ENDIF
     select PRIPR; PushWa()

     go top
     nTrecc:=0
     do while !eof()
      skip; nTrecc:=recno(); skip -1
      replace  brdok with cbrdok, idtipdok with cNoviTip, datdok with date()
      if cidtipdok=="12"  // otpremnica u racun
         replace serbr with "*"
      endif
      if cidtipdok=="13"  //
         replace kolicina with -kolicina
      endif
      go nTRecc
     enddo
     PopWa()
     IF gMreznoNum == "N"
        @ m_x+3,m_y+2 SAY "Dokument: "
        ?? idfirma+"-"+idtipdok+"-"+brdok,"   ", Datdok
     ELSE
        @ m_x+3,m_y+2 SAY "Dokument: "
        ?? idfirma+"-"+cidtipdok+"-"+ccBrDok,"   ", Datdok, "- PREBACEN"
     ENDIF
     inkey(0)
     BoxC()
  endif


  IsprUzorTxt()
else
   Msg("Ova opcija je za promjenu 20,12,13 -> 10 i 27 -> 11")
   return .f.
endif

endif

close all
O_Edit()

select pripr
return .t.
*}


function Iz22u10()
*{
local cIdFirma:=gFirma
local cVDok:="22"
local cBrojDokumenta:=SPACE(8)
local cPFirma
local cPVDok
local cPBrDok
local nRbr
local cEditYN:="N"

Box(,5,60)
	@ m_x+1, m_y+2 SAY "Prebaci iz 22 u 10:"
	@ m_x+2, m_y+2 SAY "----------------------------"
	@ m_x+3, m_y+2 SAY "Dokument:" GET cIdFirma 
	@ m_x+3, m_y+14 SAY "-" GET cVDok
	@ m_x+3, m_y+19 SAY "-" GET cBrojDokumenta
	@ m_x+5, m_y+2 SAY "Pitaj prije ispravke stavke (D/N)" GET cEditYN VALID cEditYN$"DN" PICT "@!"
	read
BoxC()


if LastKey()==K_ESC
	return .t.
endif

if (Empty(cIdFirma) .or. Empty(cVDok) .or. Empty(cBrojDokumenta))
	MsgBeep("Nisu popunjena sva polja !!!")
	return .t.
endif

select pripr
go bottom
nRbr:=VAL(field->rbr)+1

cPFirma:=field->idfirma
cPVDok:=field->idtipdok
cPBrDok:=field->brdok
dDatDok:=field->datdok
cIdPartn:=field->idpartner

O_FAKT
// prvo pogledaj da li dokument postoji u FAKT
select fakt
set order to tag "1"
seek cIdFirma+cVDok+cBrojDokumenta

if !Found()
	MsgBeep("Dokument: " + TRIM(cIdFirma)+"-"+TRIM(cPVDok)+"-"+TRIM(cPBrDok)+" ne postoji!!!")
	select pripr
	return .t.
else
	Box(,4,70)
	//brojaci dodatih i editovanih stavki
	nEdit:=0
	nAdd:=0
	// pocni popunjavati !!!
	do while !EOF() .and. field->idfirma=cIdFirma .and. field->idtipdok=cVDok .and. field->brdok=cBrojDokumenta
		cIdRoba:=field->idroba
		nKolicina:=field->kolicina
		@ m_x+1, m_y+2 SAY "Trazim artikal: " + TRIM(cIdRoba)
		select pripr
		go top
		set order to tag "3"
		seek cIdFirma+cIdRoba
		if Found()
			if (cEditYN=="D" .and. Pitanje("Ispraviti kolicinu za artikal " + TRIM(cIdRoba), "D")=="N")
				select fakt
				skip
				loop
			endif
			@ m_x+2, m_y+2 SAY "Status: Ispravljam stavku  "
			Scatter()
			_kolicina+=nKolicina
			Gather()
			nEdit++
			select fakt
			skip
		else
			@ m_x+2, m_y+2 SAY "Status: Dodajem novu stavku"
			append blank
			replace idfirma with cPFirma
			replace idtipdok with cPVDok
			replace brdok with cPBrDok
			replace rbr with RIGHT(STR(nRbr),3)
			replace idroba with fakt->idroba
			replace dindem with fakt->dindem
			replace zaokr with fakt->zaokr
			replace kolicina with fakt->kolicina
			replace cijena with fakt->cijena
			replace rabat with fakt->rabat
			replace porez with fakt->porez
			replace serbr with fakt->serbr
			replace idpartner with cIdPartn
			replace datdok with dDatdok
			nAdd++
			select fakt
			skip
		endif
		@ m_x+3, m_y+2 SAY "Ispravio stavki  :" + STR(nEdit)
		@ m_x+4, m_y+2 SAY "Dodao novi stavki:" + STR(nAdd)
	enddo
	BoxC()
endif

MsgBeep("Dodao: " + STR(nAdd) + ", ispravio: " + STR(nEdit) + " stavki")

select pripr
return .t.



