/*
 * ----------------------------------------------------------------
 *                         Copyright Sigma-com software 1998-2006
 * ----------------------------------------------------------------
 */
 
#ifndef SC_DEFINED
	#include "sc.ch"
#endif

#define D_FA_VERZIJA "02.86"
#define D_FA_PERIOD  "11.94-16.05.07"

#ifndef FMK_DEFINED
	#include "\dev\fmk\AF\cl-AF\fmk.ch"
#endif

#include "\dev\fmk\fakt\cdx\fakt.ch"

#define I_ID 1

#command POCNI STAMPU   => if !lSSIP99 .and. !StartPrint()       ;
                           ;close all             ;
                           ;return                ;
                           ;endif

#command ZAVRSI STAMPU  => if !lSSIP99; EndPrint(); endif

#define  ZAOKRUZENJE    2

#define NL  chr(13)+chr(10)
