VERZIJA=CDX
MODUL=fa_1sif
MMODUL=fakt

include /sclib/Makefile_clipper

SRCDOSROOT=c:\\dev\\fmk\\$(MMODUL)\\sif\\1g\\

PRGS=sifre.prg mnu_sif.prg

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


