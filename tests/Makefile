# This is BSD Makefile
#    BSD       GNU
# ${.TARGET}    $@
# ${.ALLSRC}    $^
# ${.IMPSRC}    $<

.SUFFIXES: .Mod .m .k

all: ACompile

###

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

###

Oberon.k: Texts.k Display.k

Texts.k: OFiles.k Reals.k Display.k

###

.Mod.m:
	./o2txt.py ${.IMPSRC} | sed 's/SHORTINT/BYTEE/g;s/INTEGER/SHORTINT/g;s/LONGINT/INTEGER/g;s/HUGEINT/LONGINT/g;s/ IN Oberon;/;/g;s/, Files;/, Files:=OFiles;/g' > ${.TARGET}

.m.k:
	obc -c ${.IMPSRC}

clean:
	rm -f *.k *.tmp AP* AS* ACompile* *.core
