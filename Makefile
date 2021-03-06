# This is BSD Makefile
#    BSD       GNU
# ${.TARGET}    $@
# ${.ALLSRC}    $^
# ${.IMPSRC}    $<

.SUFFIXES: .Mod .m .k

all: CocoCompile

###

CocoCompile: OFiles.k Reals.k Display.k Texts.k Sets.k Oberon.k CRS.k CRT.k CRA.k CRX.k CRP.k Coco.k CocoCompile.k
	obc -j0 -o ${.TARGET} ${.ALLSRC}

CocoCompile.k: Coco.k

Coco.k: Oberon.k Texts.k CRS.k CRP.k CRT.k

CRS.k: Texts.k

CRP.k: CRS.k CRT.k CRA.k CRX.k Sets.k Texts.k Oberon.k

CRA.k: Oberon.k Texts.k Sets.k CRS.k CRT.k OFiles.k

CRT.k: Texts.k Oberon.k Sets.k

CRX.k: Texts.k Oberon.k Sets.k CRS.k CRT.k CRA.k OFiles.k

##

Oberon.k: Texts.k Display.k

Texts.k: OFiles.k Reals.k Display.k

Sets.k: Texts.k

###

.Mod.m:
	./o2txt.py ${.IMPSRC} | sed 's/SHORTINT/BYTEE/g;s/INTEGER/SHORTINT/g;s/LONGINT/INTEGER/g;s/HUGEINT/LONGINT/g;s/ IN Oberon;/;/g;s/, Files;/, Files:=OFiles;/g' > ${.TARGET}

.m.k:
	obc -c ${.IMPSRC}

clean:
	rm -f CRP.m CRS.m Coco.m *.k CocoCompile *.tmp *.core
