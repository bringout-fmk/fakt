VERZIJA=CDX
MODUL=fa_1srg
MMODUL=fakt

include /sclib/Makefile_clipper

SRCDOSROOT=c:\\dev\\fmk\\$(MMODUL)\\specif\\ramag\\1g\\

PRGS=rn_sdim.prg rn_db.prg tc_rn.prg

CS=
ASMS=

OBJS=$(OBJPRGS) $(OBJCS) $(OBJASMS)

all: $(OBJS)
	rm -f $(MODUL).lib 
	$(LIBEXE) $(MODUL) $(LIBCMD) ,,
	cp $(MODUL).lib $(LIB_DEST)

	
clean:
	rm -f *~
	rm -f *.xref
	rm -f *.xrefs
	rm -f *.html
	rm -f *.OBJ *.obj
	rm -f xref_files
	rm -f $(OBJS) *.bak *.BAK


