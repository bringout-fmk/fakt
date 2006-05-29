#include "\dev\fmk\fakt\fakt.ch"

/*
 * ----------------------------------------------------------------
 *                                     Copyright Sigma-com software 
 * ----------------------------------------------------------------
 */
 

/*! \file fmk/fakt/ostalo/1g/ostalo.prg
 */


function FaAsistent()
*{
local nEntera

nEntera:=30
for iSekv:=1 to int(RecCount2()/15)+1
cSekv:=chr(K_CTRL_A)
	for nKekk:=1 to min(reccount2(),15)*20
		cSekv+=cEnter
	next
	keyboard csekv
next
return
*}

