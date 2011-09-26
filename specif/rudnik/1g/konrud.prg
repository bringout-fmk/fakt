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


p1                    idfirma
p2                    idroba
p4                    idtipdok
p6                    rbr
p8                    brdok
p9                    datdok
p11                   kolicina
p20                   idpartner
p21                   naüin formiranja cijene (1/2)
p22                   cijena
p23                   KJ/KG
p24                   rabat u %
p25                   idtarifa
p26                   por.na pu u %
p27                   otpremnica
p28                   datum otpremnice
p29                   dat.valutiranja
p31                   por.na pu u iznosu
p32                   iznos (cijena*kolicina*KJ/KG  ili  cijena*kolicina)
p33                   rabat u iznosu
p34                   por.na pp u iznosu
p35                   iznos - rabat
p37+p39+p41+p43+p45   tekst na kraju fakture uzima se samo sa stavki sa rednim
                      brojem 9999
select 1
use t:\rud\dem99\rpdp9
select 2
use t:\rud\fakt
go top
do while !eof()

  skip 1
enddo

