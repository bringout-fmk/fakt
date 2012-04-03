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

 
function O_Edit(cVar2)
if glRadNal
	O_RNAL
endif

if glDistrib
	O_RELAC
  	O_VOZILA
  	O_KALPOS
endif

if goModul:lOpresaStampa
	O_POMGN
endif

if goModul:lVrstePlacanja
	O_VRSTEP
endif

if goModul:lOpcine
	O_OPS
endif

SELECT F_KONTO
if !used()
	O_KONTO
endif

SELECT F_SAST
if !used()
	O_SAST
endif

SELECT F_PARTN
if !used()
	O_PARTN
endif

SELECT F_ROBA
if !used()
	O_ROBA
endif

if (PCount()==0)

	SELECT F_PRIPR
	if !used()
		O_S_PRIPR
	endif
	
	SELECT F_FAKT
	if !used()
	 	O_FAKT
	endif
else
 	O_PFAKT
endif

O_FTXT
O_TARIFA
O_VALUTE

if goModul:lDoks2
	O_DOKS2
endif

O_DOKS
O_RJ
O_SIFK
O_SIFV


select pripr
set order to 1
go top
return nil


/*! \fn PovSvi()
 *  \brief Povrat dokumenta u pripremu sa zadanim kriterijem
 */

function PovSvi(qBrDok, qDatDok, qTipDok, cFirma )

local nRec
private qqBrDok:=SPACE(80)
private qqDatDok:=SPACE(80)
private qqTipdok:=SPACE(80)

if qBrDok <> nil
	qqBrDok := PADR(qBrDok, 80)
endif

if qDatDok <> nil
	qqDatDok := PADR(qDatDok, 80)
endif

if qTipDok <> nil
	qqTipDok := PADR(qTipDok, 80)
endif

if cFirma == nil
	cFirma := gFirma
endif

if (KLevel<>"0")
	Beep(2)
    	Msg("Nemate pristupa ovoj opciji !",4)
    	closeret
endif

O_FAKT

// obavezno exclusivno otvori
O_PRIPR
O_DOKS

lDoks2:=.f.

if goModul:lDoks2
	lDoks2:=.t.
  	O_DOKS2
endif

SELECT fakt
set order to 1

cIdFirma := cFirma
cIdTipDok := SPACE(2)
cBrDok := SPACE(8)
cIdF := cIdFirma

Box(,4,60)
	do while .t.
  		@ m_x+1,m_y+2 SAY "Rj               "  GEt cIdF pict "@!"
  		@ m_x+2,m_y+2 SAY "Vrste dokumenata "  GEt qqTipdok pict "@S40"
  		@ m_x+3,m_y+2 SAY "Broj dokumenata  "  GEt qqBrDok pict "@S40"
  		@ m_x+4,m_y+2 SAY "Datumi           "  GET qqDatDok pict "@S40"
  		read
  	
		private aUsl1:=Parsiraj(qqBrDok,"BrDok","C")
  		private aUsl2:=Parsiraj(qqDatDok,"DatDok","D")
  		private aUsl3:=Parsiraj(qqTipdok,"IdTipdok","C")

  		if (aUsl1<>nil .and. aUsl2<>nil .and. aUsl3<>nil)
    			exit
  		endif
 	enddo
Boxc()

if Pitanje("","Dokumente sa zadanim kriterijumom vratiti u pripremu ???","N")=="N"
	closeret
endif

Beep(6)

if Pitanje("","Jeste li sigurni ???","N")=="N"
	closeret
endif

select fakt

if !FLock()
	Msg("FAKT datoteka je zauzeta ",3)
	closeret
endif

if lDoks2
	select doks2
  	if !FLock()
		Msg("DOKS2 datoteka je zauzeta ",3)
		closeret
	endif
endif

select doks

if !FLock()
	Msg("DOKS datoteka je zauzeta ",3)
	closeret
endif

private cFilt:=aUsl1+".and."+aUsl2+".and."+aUsl3+if(EMPTY(cIdF),"",".and.IdFirma=="+cm2str(cIdF))

cFilt:=STRTRAN(cFilt,".t..and.","")

if cFilt==".t."
	set filter to
else
	set filter to &cFilt
endif

go top

do while !eof()
	cIdFirma := idfirma
	cIdTipDok:=idtipdok
	cBrDok:=brdok
	select fakt
	seek cIdFirma+cIdTipDok+cBrDok

	if !Found()
  		select doks
  		skip
		loop
	endif

	fRezerv:=.f.
	fPrenesi:=.f.
	do while !eof() .and. cIdFirma==idfirma .and. cIdTipDok==idtipdok .and. cBrDok==brdok
   		fPrenesi=.t.
   		select fakt
		Scatter()
   		if !fRezerv .and. _idtipdok$"20#27" .and. _Serbr="*" .and. Pitanje(,"Predracun je na rezervaciji - ukinuti je ?","D")=="D"
      			fRezerv:=.t.
   		endif
   		select pripr
   		append ncnl
   		if fRezerv .and. _idtipdok$"20#27"  
		// ako je bio na rezervaciji
      			_serbr:=""
   		endif
   		Gather2()
   		select fakt
   		skip
	enddo
	
	if fPrenesi
  		select doks
  		seek cIdFirma+cIdTipDok+cBrDok
  		do while !eof() .and. cIdFirma==idfirma .and. cIdTipDok==idtipdok .and. cBrDok==brdok
    			skip 1
			nRec:=RecNo()
			skip -1
    			DbDelete2()
    			go nRec
  		enddo
  		
		if lDoks2
    			select doks2
    			seek cIdFirma+cIdTipDok+cBrDok
    			do while !eof() .and. cIdFirma==idfirma .and. cIdTipDok==idtipdok .and. cBrDok==brdok
      				skip 1
				nRec:=RecNo()
				skip -1
      				DbDelete2()
      				go nRec
    			enddo
  		endif
  		select fakt
  		seek cIdFirma+cIdTipDok+cBrDok
  		do while !eof() .and. cIdFirma==idfirma .and. cIdTipDok==idtipdok .and. cBrDok==brdok
    			skip 1
			nRec:=RecNo()
			skip -1
    			DbDelete2()
    			go nRec
  		enddo
	endif // fprenesi

	select doks

enddo // eof
closeret


/*! \fn Povrat(fR,cIdFirma,cIdTipDok,cBrDok,lTest)
 *  \brief Povrat dokumenta u pripremu
 *  \param fR          - rezervacija
 *  \param cIdFirma
 *  \param cIdTipDok
 *  \param cBrDok
 *  \param lTest
 */

function Povrat
parameters fR, cIdFirma, cIdTipDok, cBrDok, lTest
local fBrisao:=.f.
local nRec
local cBrisiKum := " "

if lTest==nil
	lTest:=.f.
endif

if (PCount()==0)
	fR:=.f.
endif

if (KLevel>"1")  // Klevel <> "0"
	Beep(2)
    	Msg("Nemate pristupa ovoj opciji !",4)
    	close all
	return 0
endif


O_FAKT

// obavezno exclusivno otvori
O_PRIPR
O_DOKS

set filter to

lDoks2:=.f.

if goModul:lDoks2
	lDoks2:=.t.
 	O_DOKS2
endif

select fakt
set order to 1

cSifDok:="  "

if cIdFirma == nil  // bez parametara
	cIdFirma:=gFirma
  	if fR
    		if Pitanje(,"Prekinuti rezervaciju VP-20 ili MP-27 (V/M)?","V","VM")=="V"
      			cSifDok:="20"
    		else
      			cSifDok:="27"
    		endif
  	endif
  	
	cIdTipDok:=SPACE(2)
  	cBrDok:=SPACE(8)

  	Box("",1,35)
   		@ m_x+1,m_y+2 SAY "Dokument:"
   		@ m_x+1,col()+1 GET cIdFirma
   		@ m_x+1,col()+1 SAY "-"
   		
		if fR
     			cIdTipDok:=cSifDok
     			@ m_x+1,col()+1 SAY cIdTipDok
   		else
     			@ m_x+1,col()+1 GET cIdTipDok
   		endif
   		
		@ m_x+1,col()+1 SAY "-" GET cBrDok
   		read
		ESC_BCR
  	BoxC()

endif  // cidfirma=NIL

// provjeri pravila
if (ImaPravoPristupa(goModul:oDataBase:cName,"DOK","POVRATDOK" + cIdTipDok ))
	
   if (ImaPravoPristupa(goModul:oDataBase:cName,"DOK","POVRATDOKDATUM" + ;
   	cIdTipDok )) .and. gSecurity == "D"
	
	nTArea := SELECT()

	select fakt
  	hseek cIdFirma+cIdTipDok+cBrDok
	if FOUND()
		if fakt->datdok <> DATE()
			msgbeep("Datum dokumenta <> tekuci datum#Opcija onemogucena !")
			close all
			return 0
		endif
	endif
	
	select (nTArea)
   
   endif

else	
	msgbeep( cZabrana )	
	close all
	return 0
endif

// fiscal zabrana
// ako je fiskalni racun u vezi, ovo nema potrebe vracati
// samo uz lozinku

if gFc_use == "D" .and. cIdTipDok $ "10#11"

	nTArea := SELECT()
	
	select doks
	hseek cIdFirma+cIdTipDok+cBrDok
	
	if FOUND() .and. doks->fisc_rn <> 0
		
		// veza sa fisc_rn postoji
		
		msgbeep("Za ovaj dokument je izdat fiskalni racun.#Opcija povrata je onemogucena !!!")
		close all
		return 0
	endif
	
	select (nTArea)

endif

if ( !fR .and. !lTest )
	if Pitanje("","Dokument "+cIdFirma+"-"+cIdTipDok+"-"+cBrDok+" povuci u pripremu (D/N) ?","D")=="N"
   		close all
		return 0
 	endif
endif

select fakt

if !FLock()
	MsgBeep("FAKT datoteka je zauzeta ",10)
	close all
	return 0
endif

if lDoks2
	select doks2
  	if !FLock()
		Msg("DOKS2 datoteka je zauzeta ",10)
		close all
		return 0
	endif
endif

select doks

if !FLock()
	MsgBeep("DOKS datoteka je zauzeta ",10)
	close all
	return 0
endif

fBrisao:=.f.

if !fR
	select fakt
  	hseek cIdFirma+cIdTipDok+cBrDok
  	//NFOUND CRET
  	if (fakt->m1=="X")
    		// izgenerisani dokument
    		MsgBeep("Radi se o izgenerisanom dokumentu!!!")
    		if Pitanje(,"Zelite li nastaviti?!", "N")=="N"
      			close all
			return 0
    		endif
  	endif
	
  	fRezerv:=.f.
  	fBrisao:=.f.
  	do while !eof() .and. cIdFirma==idfirma .and. cIdTipDok==idtipdok .and. cBrDok==brdok
    		fBrisao:=.t.
    		select fakt
		Scatter()
    		if (!fRezerv .and. _idtipdok$"20#27" .and. _Serbr="*" .and. Pitanje(,"Predracun je na rezervaciji - ukinuti je ?","D")=="D")
       			fRezerv:=.t.
       			// potvrda da se ukine rezervacija
    		endif
    		
		select pripr
    		append ncnl
    		if (fRezerv .and. _idtipdok$"20#27")  
			// ako je bio na rezervaciji
       			_serbr:=""
    		endif
    		
		if IsRabati()
			select doks
			hseek cIdFirma+cIdTipDok+cBrDok
			select pripr
			_tiprabat := doks->tiprabat
		endif
		
		Gather2()
    		select fakt
    		skip
  	enddo

  	// setuj varijablu fBrisao !!
  	select doks
  	hseek cIdFirma+cIdTipDok+cBrDok
  	do while !eof() .and. cIdFirma==idfirma .and. cIdTipDok==idtipdok .and. cBrDok==brdok
     		fBrisao:=.t.
     		skip
  	enddo

endif // !fr

if (fR .or. fRezerv)
	select fakt
 	seek cIdFirma+cIdTipDok+cBrDok
 	//NFOUND CRET
	fBrisao:=.f.
 	do while !eof() .and. cIdFirma==idfirma .and. cIdTipDok==idtipdok .and. cBrDok==brdok
    		select fakt
		Scatter()
    		_serbr:=""
    		Gather2()
    		select fakt
    		fBrisao:=.t.
    		skip
 	enddo
 	
	select doks
 	seek cIdFirma+cIdTipDok+cBrDok
 	//NFOUND CRET
 	do while !eof() .and. cIdFirma==idfirma .and. cIdTipDok==idtipdok .and. cBrDok==brdok
    		select doks
		Scatter()
    		_rezerv:=""  // ukini rezervaciju
    		Gather2()
    		select fakt
    		fBrisao:=.t.
    		skip
 	enddo
 	Beep(1)
endif

if !fR
	if !fBrisao
    		MsgBeep("Ne postoji zadani dokument ")
    		close all
		return 0
  	endif
  	if lTest
    		cBrisiKum:="D"
  	else
    		cBrisiKum:=Pitanje("","Zelite li izbrisati dokument iz datoteke kumulativa (D/N)?","N")
  	endif
  	
	if (cBrisiKum=="D")
    		if lDoks2
      			select doks2
      			seek cIdFirma+cIdTipDok+cBrDok
      			do while !eof() .and. cIdFirma==idfirma .and. cIdTipDok==idtipdok .and. cBrDok==brdok
        			skip 1
				nRec:=RecNo()
				skip -1
        			DbDelete2()
        			go nRec
      			enddo
    		endif
    		
		select doks
    		seek cIdFirma+cIdTipDok+cBrDok
    		do while !eof() .and. cIdFirma==idfirma .and. cIdTipDok==idtipdok .and. cBrDok==brdok
      			skip 1
			nRec:=RecNo()
			skip -1
      			DbDelete2()
      			go nRec
    		enddo
	
		select fakt
    		seek cIdFirma+cIdTipDok+cBrDok

    		do while !eof() .and. cIdFirma==idfirma .and. cIdTipDok==idtipdok .and. cBrDok==brdok
      			skip 1
			nRec:=RecNo()
			skip -1
      			
			DbDelete2()
      			go nRec
    		enddo
    		
  	endif
endif // !fr

if (cBrisiKum=="N")
	// u PRIPR resetujem flagove generacije, jer mi je dokument ostao u kumul.
	select pripr
  	set order to 1
  	hseek cIdFirma+cIdTipDok+cBrDok
  	
	while !eof() .and. pripr->(idfirma+idtipdok+brdok)==(cIdFirma+cIdTipDok+cBrDok)
    		if (pripr->m1=="X")
      			replace m1 WITH " "
    		endif
    		skip
  	enddo
endif


if Logirati(goModul:oDataBase:cName,"DOK","POVRAT")
	
	EventLog(nUser,goModul:oDataBase:cName,"DOK","POVRAT",nil,nil,nil,nil,"","","dokument: " + cIdFirma+"-"+cIdTipDok+"-"+cBrDok,Date(),Date(),"","Povrat dokumenta u pripremu")

endif
		
close all
return 1



/*! \fn SpojiDuple()
 *  \brief Spajanje duplih artikala unutar jednog dokumenta
 */

function SpojiDuple()
local cIdRoba
local nCnt 
local nKolicina
local cSpojiti 
local nTrec

select pripr

cSpojiti:="N"

if gOcitBarkod
	set order to tag "3"
 	go top
 	do while !eof()
    		nCnt:=0
    		cIdRoba:=idroba
    		nKolicina:=0
    		do while !eof() .and. idroba==cIdRoba
      			nKolicina+=kolicina
      			nCnt++
      			skip
    		enddo
    		
		if (nCnt>1) // imamo duple!!!
       			if cSpojiti=="N"
          			if Pitanje(,"Spojiti duple artikle ?","N")=="D"
             				cSpojiti:="D"
          			else
             				cSpojiti:="0"
          			endif
       			endif
       			
			if cSpojiti=="D"
         			seek _idfirma + cIdRoba // idi na prvu stavku
         			replace kolicina with nKolicina
         			skip
         			do while !eof() .and. idroba==cIdRoba
           				replace kolicina with 0  
					// ostale stavke imaju kolicinu 0
           				skip
         			enddo
       			endif

    		endif
	enddo
endif

if cSpojiti="D"
	select pripr
	go top
  	do while !eof()
      		skip
      		nTrec:=RecNo()
      		skip -1
      		
		// markirano za brisanje
		if (field->kolicina=0)  
         		delete
      		endif
      		go nTrec
  	enddo
endif

select pripr
set order to tag "1"
go top
return




/*! \fn SrediRbr()
 *  \brief Sredi redni broj
 */
function SrediRbr()
local _t_rec
local _firma, _broj, _tdok
local _cnt

O_S_PRIPR
set order to tag "1"
go top

do while !eof()
	
	_firma := field->idfirma
	_tdok := field->idtipdok
	_broj := field->brdok
	_cnt := 0

	do while !EOF() .and. field->idfirma == _firma ;
			.and. field->idtipdok == _tdok ;
			.and. field->brdok == _broj
			
		
		skip 1
		
		_t_rec := RECNO()

		skip -1

		replace field->rbr with PADL( ALLTRIM(STR( ++_cnt )), 3 )
	
		go ( _t_rec )
	
	enddo

enddo

close all

return 0


// -----------------------------------
// Azur(lSilent)
// Azuriranje stavki u pripremi
// lSilent
 
function Azur(lSilent)
local fRobaIDJ:=.f.
local cKontrolBroj:=""
local nPom1
local nPom2
local nPom3
local nHPid
local cType
// koristi se za informacije o dokumentu
local aFD_data := {}
local nTime

cType:=TYPE("lVrsteP")

if (cType<>"L")
	lVrsteP:=.f.
endif

if (lSilent==nil)
	lSilent:=.f.
endif

if (!lSilent .and. Pitanje( ,"Sigurno zelite izvrsiti azuriranje (D/N)?","N")=="N")
	return
endif

O_Edit()

// otvori exclusivno
select pripr
USE
O_PRIPR

go bottom

cPom:=idfirma+idtipdok+brdok

go top

lViseDok :=! (cPom==idfirma+idtipdok+brdok)

aOstaju:={}

if Empty(NarBrDok())
	closeret
endif

nHPid:=0

lDoks2:=goModul:lDoks2

//if (!lDoks2 .and. !(fakt->(FLock()) .and. doks->(FLock())) .or. lDoks2 .and. !(fakt->(FLock()) .and. doks->(FLock()) .and. doks2->(FLock())))
//	Beep(4)
//  	Msg("Azuriranje NE moze vrsiti vise korisnika istovremeno !", 15)
//  	closeret
//endif

fRobaIDJ:=goModul:lId_J

fProtu:=.f.

if (gProtu13=="D" .and. pripr->idtipdok=="13" .and. Pitanje(,"Napraviti protu-dokument zaduzenja prodavnice","D")=="D")
	if (gVar13=="2" .and. gVarNum=="1")
      		cPRj:=RJIzKonta(pripr->idpartner+" ")
    	else
      		O_RJ
      		Box(,2,50)
       			cPRj:=IzFMKIni("FAKT","ProtuDokument13kiIdeNaRJ","P1",KUMPATH)
       			@ m_x+1,m_y+2 SAY "RJ - objekat:" GET cPRj valid P_RJ(@cPRJ) pict "@!"
       			read
      		BoxC()
      		select rj
		use
    	endif
    	
	lVecPostoji:=.f.
    	// prvo da provjerimo ima li isti broj dokumenta u DOKS
    	cKontrol2Broj:=pripr->(cPRJ+"01"+TRIM(brdok)+"/13")
    	select DOKS
	seek cKontrol2Broj
    	
	if Found()
      		lVecPostoji:=.t.
    	else
      		// ako nema u DOKS, 
		// provjerimo ima li isti broj dokumenta u FAKT
      		select fakt
		seek cKontrol2Broj
      		if Found()
			lVecPostoji:=.t.
		endif
    	endif
    	
	if lVecPostoji
      		Msg("Vec postoji dokument pod brojem "+pripr->(cPRJ+"-01-"+TRIM(brdok)+"/13"),4)
      		closeret
    	endif
    	fProtu:=.t.
endif

fRobaIDJ:=goModul:lId_J

select roba
set order to tag "ID"

select pripr
go top

// lock-uj tabele prilikom azuriranja...
if !( fakt->(flock()) .and. doks->(flock()) ) 
    
	if gAzurTimeOut == nil
		nTime := 150
	else
	       	nTime := gAzurTimeOut
	endif
	   
	Box(,1, 60)

	    // daj mu vremena...
	    do while nTime > 0
	
		    -- nTime

		    @ m_x + 1, m_y + 2 SAY "Baza je trenutno zauzeta... " + ALLTRIM(STR(nTime))
		
		    if ( fakt->(flock()) .and. doks->(flock()) ) 
			    exit
		    endif
	    
		    sleep(1)

	    enddo
	    
    	BoxC()

	if nTime = 0 .and. !( fakt->(flock()) .and. doks->(flock()) )
	
	    Beep(4) 
 	    BoxC() 
 	    Msg("Timeout za azuriranje istekao!#Ne mogu azuriranti dokument...") 
 	    close all
            return nil 
	
	endif

endif 

// ako je vise dokumenata u pripremi provjeri duple stavke
if lViseDok

	if prov_duple_stavke() == 1
        	return nil
	endif

else

	// ako je samo jedan dokument provjeri da li je u dupli
	cKontrolBroj:=pripr->(idfirma+idtipdok+brdok)

	if dupli_dokument(cKontrolBroj)
		Beep(4)
  		Msg("Dokument "+pripr->(idfirma+"-"+idtipdok+"-"+brdok)+" vec postoji pod istim brojem!",4)
        	return nil
	endif

endif

select pripr
go top

// 0. napuni matricu sa brojem dokumenta
AADD( aFD_data, { pripr->idfirma, pripr->idtipdok, pripr->brdok } )

// 1. azuriranje u bazu FAKT

Box("#Proces azuriranja u toku",3,60)

do while !eof()

      	if lViseDok

    		cPom := idfirma + idtipdok + brdok

    		select doks
    		seek cPom

    		if Found() .and. ( gMreznoNum=="N" .or. M1 <> "Z" )
      			AADD(aOstaju,cPom)
      			select pripr
      			do while !eof() .and. cPom==idfirma+idtipdok+brdok
        			skip 1
      			enddo
      			loop
    		else
      			cKontrolBroj := cPom
      			@ m_x+2, m_y+2 SAY "Azuriram dokument " + pripr->( idfirma + "-" + idtipdok + "-" + brdok )
    		endif

  	    endif

  	    select pripr

  	    Scatter()

  	    select fakt

  	    // nemoj brisati i nemoj otkljucavati
	    AppBlank2(.f.,.f.)   
  	
	    if fRobaIDJ  
		    // nafiluj polje IDROBA_J u prometu
   		    select roba
		    hseek _idroba
   		    _idroba_j:=roba->id_j
   		    select fakt
  	    endif
       
            // opet nemoj otkljucavati
	    Gather2()

  	    if (fProtu .and. idtipdok=="13")
     		AppBlank2(.f.,.f.) 
     		_idfirma:=cPRJ
     		_idtipdok:="01"
     		_brdok:=TRIM(_brdok)+"/13"
     		// gather()
     		Gather2()
  	    endif

  	    select pripr
  	    skip

enddo


// 2. azuriranje u bazu DOKS
select pripr
go top

do while !eof()
	
	if (lViseDok .and. ASCAN(aOstaju,cPom:=idfirma+idtipdok+brdok)<>0)
    		do while !eof() .and. cPom==idfirma+idtipdok+brdok
      			skip 1
    		enddo
    		loop
  	endif

  	select doks
  	set order to 1
  	
	hseek pripr->idfirma+pripr->idtipdok+pripr->brdok
  	
	if !Found()
     		AppBlank2(.f.,.f.)
  	endif
  	
	if lDoks2
    		select doks2
    		set order to 1
    		hseek pripr->idfirma+pripr->idtipdok+pripr->brdok
    		if !Found()
       			AppBlank2(.f.,.f.)
    		endif
  	endif
  	
	select pripr

  	cIdFirma:=idfirma
  	private cBrDok:=brdok
	private cIdTipDok:=idtipdok
	private dDatDok:=datdok

	if IsRabati()
		private cTipRabat:=tiprabat
	endif
	
  	aMemo:=ParsMemo(txt)
	if (LEN(aMemo)>=5)
    		cTxt:=TRIM(aMemo[3])+" "+TRIM(aMemo[4])+","+TRIM(aMemo[5])
  	else
    		cTxt:=""
  	endif
  	
	cTxt:=PadR(cTxt,30)
  	cDinDem:=dindem
  	cRezerv:=" "
  	
	if (cIdTipDok$"10#20#27" .and. Serbr="*")
     		cRezerv:="*"
  	endif
  	
	select doks
  	
	_field->IdFirma   := cIdFirma
  	_field->BrDok     := cBrDok
  	_field->Rezerv    := cRezerv
  	_field->DatDok    := dDatDok
  	_field->IdTipDok  := cIdTipDok
  	_field->Partner   := cTxt
  	_field->dindem    := cDinDem
  	_field->IdPartner := pripr->idpartner
	_field->idpm      := pripr->idpm
	
	if doks->(FIELDPOS("dok_veza")) <> 0
		_field->dok_veza := pripr->dok_veza
	endif

	if doks->(FIELDPOS("oper_id")) <> 0 .and. gSecurity == "D"
		_field->oper_id := GetUserID()
	endif
  	
	if doks->(FIELDPOS("fisc_rn")) <> 0 .and. gFc_use == "D" 
		_field->fisc_rn := pripr->fisc_rn
	endif
  
  	// datum isporuke, otpremnice, valute
	if doks->(FIELDPOS("dat_isp")) <> 0 
   		_field->dat_isp:=if(LEN(aMemo)>=7,CToD(aMemo[7]),CToD(""))
   		_field->dat_otpr:=if(LEN(aMemo)>=7,CToD(aMemo[7]),CToD(""))
   		_field->dat_val:=if(LEN(aMemo)>=9,CToD(aMemo[9]),CToD(""))
	endif

	if IsRabati()
		if (cIdTipDok $ gcRabDok)
			_field->idrabat := PADR(gcRabDef, 10)
			_field->tiprabat := PADR(cTipRabat, 10)
  		endif
	endif
	
   	_field->IdVrsteP := pripr->idvrstep
  	
	if (FieldPos("DATPL")>0)
   		_field->DatPl:=if(LEN(aMemo)>=9,CToD(aMemo[9]),CToD(""))
  	endif
  	
	if (doks->m1=="Z")
    		// skidam zauzece i dobijam normalan dokument
    		// REPLACE m1 WITH " " -- isto kao i gore
    		_field->m1 := " "
  	endif
  	
	if (FieldPos("SIFRA")<>0)
     		// replace sifra with sifrakorisn
     		_field->sifra:=SifraKorisn
  	endif
  	
	if lDoks2
    		select doks2
    		_field->idfirma:=cIdFirma
    		_field->brdok:=cBrDok
    		_field->idtipdok:=cIdTipDok
    		_field->k1:=if(LEN(aMemo)>=11,aMemo[11],"")
    		_field->k2:=if(LEN(aMemo)>=12,aMemo[12],"")
    		_field->k3:=if(LEN(aMemo)>=13,aMemo[13],"")
    		_field->k4:=if(LEN(aMemo)>=14,aMemo[14],"")
    		_field->k5:=if(LEN(aMemo)>=15,aMemo[15],"")
    		_field->n1:=if(LEN(aMemo)>=16,VAL(ALLTRIM(aMemo[16])),0)
    		_field->n2:=if(LEN(aMemo)>=17,VAL(ALLTRIM(aMemo[17])),0)
  	endif
  	
	select pripr
  	
	nDug:=0
	nRab:=0
  	nDugD:=0
	nRabD:=0
  
	do while !eof() .and. cIdFirma==idfirma .and. cIdTipdok==idtipdok .and. cBrDok==brdok
    		if cDinDem==LEFT(ValBazna(),3)
        		nPom1:=Round(kolicina*Cijena*PrerCij()*(1-Rabat/100),ZAOKRUZENJE)
        		// npom1 - cijena sa porezom i uracunatim rabatom
        		nPom2:=ROUND( kolicina*Cijena*PrerCij()*Rabat/100 , ZAOKRUZENJE)
        		// rabat za stavku
        		nPom3:=ROUND(nPom1*Porez/100, ZAOKRUZENJE)
        		nDug+= nPom1 + nPom3
        		// nDug je iznos ukupne fakture, ali bez izbijenog rabata !!!
        		nRab+= nPom2
    		else
        		//nPom1:=round( Cijena*kolicina*PrerCij()/UBaznuValutu(datdok)*(1+Porez/100), ZAOKRUZENJE)
        		// greska kada imamo porez  !!
        		nPom1 := round( kolicina*Cijena*PrerCij()*(1-Rabat/100), ZAOKRUZENJE)
        		// npom1 - cijena sa porezom i uracunatim rabatom
        		nPom2:=ROUND( kolicina*Cijena*PrerCij()*Rabat/100 , ZAOKRUZENJE)
        		// rabat za stavku
        		nPom3:=ROUND(nPom1*Porez/100, ZAOKRUZENJE)
        		nDugD+= nPom1 + nPom3
        		nRabD+= nPom2
    		endif
    		skip
  	enddo
  
  	select doks
  
	if (cDinDem==LEFT(ValBazna(),3))
   		_field->Iznos:=nDug 
		// iznos sadrzi umanjenje za rabat
   		_field->Rabat:=nRab
  	else
   		_field->Iznos := nDugD 
   		_field->Rabat := nRabD
 	endif

	// protu dokument
  	if (idtipdok=="13" .and. fProtu)
    		Scatter()
    		AppBlank2(.f.,.f.)
    		_idtipdok:="01"
    		_idfirma:=cPRJ
    		_BrDok:=TRIM(_brdok)+"/13"
    		Gather2()
    		Beep(1)
    		Msg("Izgenerisan je dokument pod brojem "+_idfirma+"-01-"+_brdok,4)
    		if lDoks2
      			SELECT DOKS2
      			Scatter()
      			AppBlank2(.f.,.f.)
      			_idtipdok:="01"
      			_idfirma:=cPRJ
      			_brdok:=TRIM(_brdok)+"/13"
      			Gather2()
    		endif
	endif

	if Logirati(goModul:oDataBase:cName,"DOK","AZUR")
		EventLog(nUser,goModul:oDataBase:cName,"DOK","AZUR",nil,nil,nil,nil,"","","dokument: " + cIdFirma+"-"+cIdTipDok+"-"+cBrDok,dDatDok,Date(),"","Azuriranje dokumenta")
	endif
	
	// ponovo odradi lock tabele DOKS
	if !(doks->(FLock()))
		
		Beep(4)
  		Msg( "Azuriranje NE moze vrsiti vise korisnika istovremeno !", 15 )
  		close all
        return

	endif

  	select pripr

enddo

PrModem()

lAzurOK:=.t.

select doks
go top

seek cKontrolBroj

if Found()
	select fakt
	go top
  	seek cKontrolBroj
  	if !Found()
    		lAzurOK:=.f.
  	elseif lDoks2
    		select doks2
		go top
    		seek cKontrolBroj
    		if !Found()
      			lAzurOK:=.f.
    		endif
  	endif
else
	lAzurOK:=.f.
endif

if !lAzurOK
	MsgBeep("Neuspjelo azuriranje! Priprema nije izbrisana!# 1) Izvrsite reindeksiranje# 2) Promijenite broj dokumenta u pripremi# 3) Izvrsite povrat dokumenta pod brojem koji ste prvi put zadali# 4) Izbrisite u pripremi stavke koje su vracene# 5) Vratite broj dokumenta na prvobitni i ponovo pokusajte azuriranje")
else
	select pripr
  	if (lViseDok .and. LEN(aOstaju)>0)
    	    // izbrisi samo azurirane
    		go top
    		do while !eof()
      		    skip 1
			    nRecNo:=RecNo()
			    skip -1
      			if (ASCAN(aOstaju,idfirma+idtipdok+brdok)=0)
        			delete
      			endif
      			go (nRecNo)
    		enddo
    		
		    __dbpack()
    		
		    MsgBeep("U pripremi su ostali dokumenti koji izgleda da vec postoje medju azuriranim!")
  	else
    		ZAP
  	endif
endif

BoxC()

close all

return aFD_data



// provjeri duple stavke u pripremi za vise dokumenata
function prov_duple_stavke() 
local cSeekDok
local lDocExist:=.f.

select pripr
go top

// provjeri duple dokumente
do while !EOF()
	cSeekDok := pripr->(idfirma + idtipdok + brdok)
	if dupli_dokument(cSeekDok)
		lDocExist := .t.
		exit
	endif
	select pripr
	skip
enddo

// postoje dokumenti dupli
if lDocExist
	MsgBeep("U pripremi su se pojavili dupli dokumenti!")
	if Pitanje(,"Pobrisati duple dokumente (D/N)?", "D")=="N"
		MsgBeep("Dupli dokumenti ostavljeni u tabeli pripreme!#Prekidam operaciju azuriranja!")
		return 1
	else
		Box(,1,60)
			cKumPripr := "P"
			@ m_x+1, m_y+2 SAY "Zelite brisati stavke iz kumulativa ili pripreme (K/P)" GET cKumPripr VALID !Empty(cKumPripr) .or. cKumPripr $ "KP" PICT "@!"
			read
		BoxC()
		
		if cKumPripr == "P"
			// brisi pripremu
			return prip_brisi_duple()
		else
			// brisi kumulativ
			return kum_brisi_duple()
		endif
	endif
endif

return 0



// lokovanje tabela fakt i doks
function fakt_lock()

if !SigmaSif("LOCK")
	return
endif

O_FAKT
O_DOKS

if Pitanje(, "Zakljucaj baze ?", "N") == "D"
    if !(fakt->(FLOCK()))
        msgbeep("Ne mogu lokovati FAKT !")
    endif

    if !(doks->(FLOCK()))
        msgbeep("Ne mogu lokovati DOKS !")
    endif
endif

if Pitanje(, "Otkljucaj baze", "N" ) == "D"
    close all
endif

return





// brisi stavke iz pripreme koje se vec nalaze u kumulativu
function prip_brisi_duple()
local cSeek
select pripr
go top

do while !EOF()
	cSeek := pripr->(idfirma + idtipdok + brdok)
	
	if dupli_dokument(cSeek)
		// pobrisi stavku
		select pripr
		delete
	endif
	
	select pripr
	skip
enddo

return 0


// brisi stavke iz kumulativa koje se vec nalaze u pripremi
function kum_brisi_duple()
local cSeek
select pripr
go top

cKontrola := "XXX"

do while !EOF()
	
	cSeek := pripr->(idfirma + idtipdok + brdok)
	
	if cSeek == cKontrola
		skip
		loop
	endif
	
	if dupli_dokument(cSeek)
		
		// provjeri da li je tabela zakljucana
		select doks
		
		if !FLock()
			Msg("DOKS datoteka je zauzeta ", 3)
			return 1
		endif
		
		MsgO("Brisem stavke iz kumulativa ... sacekajte trenutak!")
		// brisi doks
		set order to 1
		go top
		seek cSeek
		if Found()
			do while !eof() .and. doks->(idfirma+idtipdok+brdok) == cSeek
      				skip 1
				nRec:=RecNo()
				skip -1
      				DbDelete2()
      				go nRec
    			enddo
    		endif
		
		// brisi iz fakt
		select fakt
		set order to 1
		go top
		seek cSeek
		if Found()
			do while !EOF() .and. fakt->(idfirma + idtipdok + brdok) == cSeek
				
				skip 1
				nRec:=RecNo()
				skip -1
				DbDelete2()
				go nRec
			enddo
		endif
		MsgC()
	endif
	
	cKontrola := cSeek
	
	select pripr
	skip
enddo

return 0


// ------------------------------------------
// ------------------------------------------
function dupli_dokument(cSeek)
select doks
set order to 1
go top
seek cSeek
if Found()
	if gMreznoNum == "D"
		if m1 == "Z"
			return .f.
		endif
	endif
	return .t.
endif
select fakt
set order to 1
go top
seek cSeek
if Found()
	return .t.
endif
return .f.


// --------------------------------------------------
// pretraga broja dokumenta sa prefiksom
// --------------------------------------------------
static function po_prefix( _firma, _tip_dok )
local _broj := ""
local _prefix
local _srch_tag

_prefix := PADL( ALLTRIM( STR( GetUserId() ) ), 2, "0" )

// pretraga po prefiksu
if gSecurity == "D" .and. _idtipdok $ "12#22" .and. !EMPTY( _prefix )
    
    	_srch_tag := _prefix + "/"

	seek _idfirma +_idtipdok + _srch_tag + "�"
 	skip -1
    
   	if field->idfirma == _idfirma .and. field->idtipdok == _idtipdok .and. LEFT( field->brdok, 3 ) == _srch_tag
    
        	_broj := UBrojDok( VAL( RIGHT( ALLTRIM( field->brdok ), 5 ) ) + 1, gNumDio, "" )
        

    	else
		_broj := UBrojDok( 1, gNumDio, "" )
	endif 

        _broj := PADR( _srch_tag + _broj, 8 )

endif

return _broj



// --------------------------------------
// OdrediNBroj(_idfirma,_idtipdok)
// ---------------------------------------- 
function OdrediNbroj( _idfirma, _idtipdok )
local cNBrDok := ""
local _ret

select DOKS
set order to tag "1"
go top

if gPoPrefiks == "D"
	_ret := po_prefix( _idfirma, _idtipdok )
	if !EMPTY( _ret )
		return _ret
	endif
endif

if (gVarNum=="2".and._idtipdok=="13")
	seek _idfirma+_idtipdok+PADL(ALLTRIM(STR(VAL(ALLTRIM(SUBSTR(_idpartner,4))))),2,"0")+CHR(238)
 	skip -1
 	do while !bof() .and. _idfirma==idfirma.and._idtipdok==idtipdok.and.LEFT(_idpartner,6)==LEFT(idpartner,6).and.SUBSTR(brdok,6,2)!=PADL(ALLTRIM(STR(MONTH(_datdok))),2,"0")
   		skip -1
 	enddo
else
	seek _idfirma+_idtipdok+"�"
 	skip -1

 	if (_idtipdok $ "10#11" .and. ;
		!EMPTY(SUBSTR(brdok,gNumDio+1)) .and. ;
		( IzFmkIni("FAKT","Brojac11BezEkstenzije","N",KUMPATH)=="D" ;
		.or. gFc_use == "D" ))

   		do while !bof() .and. _idfirma==idfirma .and. _idtipdok==idtipdok .and. !Empty(SUBSTR(brdok,gNumDio+1))
     			skip -1
   		enddo

 	endif
endif

if (_idtipdok<>idtipdok .or. _idfirma<>idfirma .or. LEFT(_idpartner,6)<>LEFT(idpartner,6) .and. (gVarNum=="2" .and. _idtipdok=="13"))
	if (gVarNum=="2".and._idtipdok=="13")
    		cNBrDok:=PADL(ALLTRIM(STR(VAL(ALLTRIM(SUBSTR(_idpartner,4))))),2,"0")+"01/"+PADL(ALLTRIM(STR(MONTH(_datdok))),2,"0")
  	else
    		cNBrDok:=UBrojDok(1, gNumDio,"")
  	endif
else
	if (gVarNum=="2".and._idtipdok=="13")
    		cNBrDok:=SljBrDok13(brdok,MONTH(_datdok),_idpartner)
  	else
    		cNBrDok:=UBrojDok( val(left(brdok,gNumDio))+1, gNumDio, right(brdok,len(brdok)-gNumDio))
  	endif
endif

cNBrDok:=padr(cNBrDok, 8)

return cNBrDok

// -------------------------------------------------------
//  FaNoviBroj(cIdFirma, cIdTiDdok)
//  Odredi novi broj Fakt-dokumenta 
//  Ne pokriva specif. slucajeve "a-la" Nijagara ...
// ------------------------------------------------------- 
function FaNovibroj(cIdFirma, cIdTipDok)
local cBrdok
local cPom
local cDesniDio
local nPom
local nDesniDio

cBrDok:=""

select doks
set order to 1
go top

seek cIdFirma+cIdTipDok+CHR(254)
skip -1

if ( (field->idtipdok) <> cIdTipDok ) .or. ((field->idfirma) <> cIdFirma )
	cBrDok:=UBrojDok(1,gNumDio,"")
	return cBrDok
endif

cPom:=LEFT(field->brDok,gNumDio)
nPom:=VAL(cPom)+1
nDesniDio:=LEN(field->brDok)-gNumDio
cDesniDio:=RIGHT(field->brDok, nDesniDio)
cBrDok:= UBrojDok( nPom, gNumDio, cDesniDio)

return cBrDok



// ------------------------------------------------
// ------------------------------------------------
function BrisiPripr()

cSecur:=SecurR(KLevel,"BRISIGENDOK")

// pripr->m1
if (m1="X" .and. ImaSlovo("X",cSecur))   
	Beep(1)
  	Msg("Dokument izgenerisan, ne smije se brisati !!",0)
  	return DE_CONT
endif

if !(ImaPravoPristupa(goModul:oDataBase:cName,"DOK","BRISANJE" ))
	MsgBeep(cZabrana)
	return DE_CONT
endif

if Pitanje(, "Zelite li izbrisati pripremu !!????","N")=="D"
	
   if gcF9usmece == "D"

  	select pripr
	go top
	
	cIdFirma:=IdFirma
	cIdTipDok:=IdTipDok
	cBrDok:=BrDok
      
	// baci dokument u smece umjesto da ga 
	// trajno izbrises
	// lSilent = .t.

	azur_smece( .t. )
	
	select pripr

   else
	
	
	SELECT F_DOKS
	if !used()
		O_DOKS
	endif
	select pripr
   	go top
   	
	cIdFirma := ""
	cIdTipDok := ""
	cBrDok := ""

	do while !eof()
      		cIdFirma:=IdFirma
      		cIdTipDok:=IdTipDok
      		cBrDok:=BrDok
      		select doks
      		hseek pripr->IdFirma+pripr->IdTipDok+pripr->BrDok
      		if (Found() .and. (doks->M1=="Z"))
	 		// dokument zapisan samo u DOKS-u
	 		delete
      		endif
      		select pripr
      		skip
      		do while !eof() .and. (idfirma==cIdFirma) .and. (idtipdok==cIdTipDok) .and. (BrDok==cBrDok)
			skip
      		enddo
   	enddo

   	select pripr
   	zap

   endif


   // logiraj ako je potrebno brisanje dokumenta iz pripreme !
   if Logirati(goModul:oDataBase:cName,"DOK","BRISANJE")
	
	cOpis := "dokument: " + cIdFirma + "-" + cIdTipDok + "-" + ALLTRIM(cBrDok)

	EventLog(nUser, goModul:oDataBase:cName, "DOK", "BRISANJE", ;
		nil, nil, nil, nil, ;
		"","", cOpis, DATE(), DATE(), "", ;
		"Brisanje kompletnog dokumenta iz pripreme")
   endif

endif

return


/*! \fn KomIznosFakt()
 *  \brief Kompletiranje iznosa fakture pomocu usluga
 */
 
function KomIznosFakt()
*{
local nIznos:=0
local cIdRoba

O_SIFK
O_SIFV
O_S_PRIPR
O_TARIFA
O_ROBA

cIdRoba:=SPACE(LEN(id))

Box("#KOMPLETIRANJE IZNOSA FAKTURE POMOCU USLUGA",5,75)
	@ m_x+2, m_y+2 SAY "Sifra usluge:" GET cIdRoba VALID P_Roba(@cIdRoba) PICT "@!"
	@ m_x+3, m_y+2 SAY "Zeljeni iznos fakture:" GET nIznos PICT picdem
	read
	ESC_BCR
BoxC()

select roba
hseek cIdRoba
select tarifa
hseek roba->idtarifa
select pripr

nDug2:=0
nRab2:=0
nPor2:=0

KonZbira(.f.)

go bottom

Scatter()

append blank

_idroba:=cIdRoba
_kolicina:=IF(nDug2-nRab2+nPor2>nIznos,-1,1)
_rbr:=STR(RbrUnum(_Rbr)+1,3)
_cijena:=ABS(nDug2-nRab2+nPor2-nIznos)
_rabat:=0 
_porez:=0

if !(_idtipdok $ "11#15#27")
	_porez:=if( ROBA->tip=="U",tarifa->ppp,tarifa->opp)
	_cijena:=_cijena/(1+_porez/100)
endif

_txt:=Chr(16)+ROBA->naz+Chr(17)

Gather()

MsgBeep("Formirana je dodatna stavka. Vratite se tipkom <Esc> u pripremu"+"#i prekontrolisite fakturu!")

CLOSERET


// ---------------------------------------------------
// generisi storno dokument u pripremi
// ---------------------------------------------------
function storno_dok( cIdFirma, cIdTipDok, cBrDok )
local cNoviBroj 

if Pitanje(,"Formirati storno dokument ?","D") == "N"
	return
endif

O_PRIPR
select pripr

if pripr->(RECCOUNT2()) <> 0
	msgbeep("Priprema nije prazna !!!")
	return
endif


O_FAKT
O_DOKS
O_ROBA
O_PARTN

cNoviBroj := ALLTRIM(cBrDok) + "/S"

if LEN( ALLTRIM( cNoviBroj ) ) > 8
	
	// otkini prva dva karaktera
	// da moze stati "/S"
	cNoviBroj := RIGHT( ALLTRIM( cBrDok ), 6 ) + "/S"

endif

nCnt := 0

select doks
set order to tag "1"
go top
seek cIdFirma + cIdTipDok + cBrDok

nFiscal := 0
if gFc_use == "D"
	nFiscal := field->fisc_rn
endif

select fakt
set order to tag "1"
go top
seek cIdFirma + cIdTipDok + cBrDok

do while !EOF() .and. field->idfirma == cIdFirma ;
		.and. field->idtipdok == cIdTipDok ;
		.and. field->brdok == cBrDok
	
	
	scatter()

	select pripr
	append blank
	
	gather()

	replace field->kolicina with ( field->kolicina * -1 )
	replace field->brdok with cNoviBroj
	replace field->datdok with DATE()
	
	if gFc_use == "D"
		replace field->fisc_rn with nFiscal
	endif

	select fakt
	skip

	++ nCnt

enddo

if nCnt > 0
	msgbeep("Formiran je dokument " + cIdFirma + "-" + ;
		cIdTipDok + "-" + ALLTRIM(cNoviBroj) + ;
		" u pripremi !")
endif

return





