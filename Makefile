# This is BSD Makefile
#    BSD       GNU
# ${.TARGET}    $@
# ${.ALLSRC}    $^
# ${.IMPSRC}    $<

.SUFFIXES: .Mod .m .k

all: CocoCompile ACompile Oberon07Compile

CocoCompile: OFiles.k Reals.k Display.k Texts.k Sets.k Oberon.k CRS.k CRT.k CRA.k CRX.k CRP.k Coco.k CocoCompile.k
	obc -j0 -o ${.TARGET} ${.ALLSRC}

##

ACompile: OFiles.k Reals.k Display.k Texts.k Oberon.k AS.k AP.k ACompile.k
	obc -j0 -o ${.TARGET} ${.ALLSRC}

ACompile.k: AS.k AP.k Texts.k Oberon.k

AP.k: AS.k

AP.Mod: A.ATG
	./CocoCompile ${.ALLSRC}

AS.Mod: A.ATG
	./CocoCompile ${.ALLSRC}

ACompile.Mod: A.ATG
	./CocoCompile ${.ALLSRC}

##

Oberon07Compile: OFiles.k Reals.k Display.k Texts.k Oberon.k Oberon07S.k Oberon07P.k Oberon07Compile.k
	obc -j0 -o ${.TARGET} ${.ALLSRC}

Oberon07Compile.k: Oberon07S.k Oberon07P.k Texts.k Oberon.k

Oberon07P.k: Oberon07S.k

Oberon07P.Mod: Oberon07.ATG
	./CocoCompile ${.ALLSRC}

Oberon07S.Mod: Oberon07.ATG
	./CocoCompile ${.ALLSRC}

Oberon07Compile.Mod: Oberon07.ATG
	./CocoCompile ${.ALLSRC}

###

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
	rm -f *.k CocoCompile *.tmp AP* AS* ACompile* Oberon07S* Oberon07P* Oberon07Compile* *.core
