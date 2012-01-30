# This is BSD Makefile
#    BSD       GNU
# ${.TARGET}    $@
# ${.ALLSRC}    $^
# ${.IMPSRC}    $<

.SUFFIXES: .Mod .m .k

all: Oberon0Compile

###

Oberon0Compile: OFiles.k Reals.k Display.k Texts.k Oberon.k Oberon0S.k OSS.k RISC1.k OSG.k Oberon0P.k Oberon0Compile.k
	obc -j0 -o ${.TARGET} ${.ALLSRC}

Oberon0Compile.k: Oberon0S.k Oberon0P.k OSG.k Texts.k Oberon.k

Oberon0P.k: Oberon0S.k OSG.k OSS.k Texts.k Oberon.k

OSG.k: OSS.k RISC1.k

OSS.k: Oberon0S.k Texts.k Oberon.k

RISC1.k: Texts.k Oberon.k

Oberon0P.Mod: Oberon0.ATG
	./CocoCompile ${.ALLSRC}

Oberon0S.Mod: Oberon0.ATG
	./CocoCompile ${.ALLSRC}

Oberon0Compile.Mod: Oberon0.ATG
	./CocoCompile ${.ALLSRC}

###

Oberon.k: Texts.k Display.k

Texts.k: OFiles.k Reals.k Display.k

###

OSG.m: OSG.Mod
	./o2txt.py ${.IMPSRC} | sed 's/SHORTINT/BYTEE/g;s/INTEGER/SHORTINT/g;s/LONGINT/INTEGER/g;s/HUGEINT/LONGINT/g;s/ IN Oberon;/;/g;s/IMPORT Files,/IMPORT/g;s/, RISC, /, RISC:=RISC1, /g;s/"SHORTINT"/"INTEGER"/g;s/0FFFFFFC0H/-64/g' > ${.TARGET}

.Mod.m:
	./o2txt.py ${.IMPSRC} | sed 's/SHORTINT/BYTEE/g;s/INTEGER/SHORTINT/g;s/LONGINT/INTEGER/g;s/HUGEINT/LONGINT/g;s/ IN Oberon;/;/g;s/, Files;/, Files:=OFiles;/g;s/"SHORTINT"/"INTEGER"/g' > ${.TARGET}

.m.k:
	obc -c ${.IMPSRC}

clean:
	rm -f *.k *.tmp Oberon0S* Oberon0P* Oberon0Compile* OSG.m *.core
