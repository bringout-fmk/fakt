
liball: 	
	make -C main/1g
	make -C main/2g
	make -C db/1g
	make -C db/2g
	make -C uplate/1g
	make -C dok/1g
	make -C sif/1g
	make -C razoff/1g
	make -C razdb/1g
	make -C ostalo/1g
	make -C specif/vindija/1g
	make -C rpt/1g
	make -C param/1g
	make -C specif/rudnik/1g
	make -C stampa/1g
	make -C konsig/1g
	make -C dok/2g
	make -C gendok/1g
	make -C 1g exe

cleanall:		
	make -C main/1g clean
	make -C main/2g clean
	make -C db/1g clean
	make -C db/2g clean
	make -C uplate/1g clean
	make -C dok/1g clean
	make -C sif/1g clean
	make -C razoff/1g clean
	make -C razdb/1g clean
	make -C ostalo/1g clean
	make -C specif/rudnik/1g clean
	make -C specif/vindija/1g clean
	make -C rpt/1g clean
	make -C stampa/1g clean
	make -C konsig/1g clean
	make -C param/1g clean
	make -C dok/2g clean
	make -C gendok/1g clean
	make -C 1g clean

fakt:   cleanall liball
