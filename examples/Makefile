# This is BSD Makefile
#    BSD       GNU
# ${.TARGET}    $@
# ${.ALLSRC}    $^
# ${.IMPSRC}    $<

.SUFFIXES: .Mod .m .k

all: Oberon07Compile

###

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

Oberon.k: Texts.k Display.k

Texts.k: OFiles.k Reals.k Display.k

###

.Mod.m:
	./o2txt.py ${.IMPSRC} | sed 's/SHORTINT/BYTEE/g;s/INTEGER/SHORTINT/g;s/LONGINT/INTEGER/g;s/HUGEINT/LONGINT/g;s/ IN Oberon;/;/g;s/, Files;/, Files:=OFiles;/g' > ${.TARGET}

.m.k:
	obc -c ${.IMPSRC}

clean:
	rm -f *.k *.tmp Oberon07S* Oberon07P* Oberon07Compile* *.core
