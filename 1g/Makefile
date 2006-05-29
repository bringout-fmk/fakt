VERZIJA=CDX
MODUL=FAKT

PRGS=e.prg
CS=
ASMS=

FMK_LIBS=fmk_roba.lib fmk_svi.lib fmk_pi.lib fmk_evn.lib fmk_sec.lib fmk_mes.lib fmk_rab.lib fmk_rn.lib fmk_lok.lib

SCLIB_LIBS=sc1g_arh.lib sc1g_ba.lib sc1g_cui.lib sc1g_db.lib sc1g_os.lib sc1g_ost.lib sc1g_par.lib sc1g_pr.lib sc1g_sif.lib sc1g_sql.lib sc1g_ut.lib sc2g_app.lib sc2g_db.lib sc1g_rpt.lib sc2g_cui.lib sc1g_key.lib ka_s1pf.lib

MODUL_LIBS=fa_1ma.lib fa_2ma.lib fa_2db.lib fa_1db.lib fa_1upl.lib fa_1ugo.lib fa_1dok.lib fa_1sif.lib fa_1rof.lib fa_1rdb.lib fa_1ost.lib fa_1svi.lib fa_1rpt.lib fa_1smk.lib fa_1par.lib fa_1sta.lib fa_1kon.lib fa_2dok.lib fa_1gdo.lib fa_1rud.lib fa_1srg.lib

include $(SC_BUILD_HOME_DIR)/sclib/Makefile_clipper

LIBEXE:=@echo pokrenute make exe  !
CPLIB:=@echo pokrenuti make exe !
RMLIB:=@echo pokrenuti make exe !
e.obj : $(SC_BUILD_HOME_DIR)/sclib/sc.ch $(SC_BUILD_HOME_DIR)/sclib/std_cdx.ch ../fakt.ch


lib: exe
