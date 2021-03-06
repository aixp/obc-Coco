This is Coco/R (http://ssw.jku.at/Coco/) for Oberon

Based on implementation taken from A2 (Coco/R V2.2)

Modifications based on current C# version (Apr 19, 2011)

Usage
=====

	echo '*' > par

	./CocoCompile file.ATG

Modifications done
==================

- most important:

	- IF (LL(1)-resolver):

		- CR.ATG: Resolver introduced (based on C# Coco.atg); Coco.Error updated

		- CRT: Resolver introduced (based on C# Tab.cs)

		- CRX: Resolver introduced (based on C# ParserGen.cs)

			TODO?:

				- what is correct 2nd arg of GenCond in case of CRT.opt in GenCode ?

				- CRT.any case in GenCode: implementation differs from C# version

	- CRT.LL1Test: LL1Error(4) added, based on C# Tab.cs CheckLL1(); DelSubGraph() introduced

	- literals:

		- CRX: new procedure: GenTokens

		- CR.ATG: modified

		- CRDriver.FRM: semantic error 27 introduced ("token string declared twice")

		- CRDriver.FRM: semantic error 28 introduced ("undefined string in production")

		- CRT: new procedures: NewLit, FindLit

	- Driver generation:

		- CRX.GenCompiler: modified

		- Driver.FRM: created

		- Coco.Mod renamed to CRDriver.FRM and modified

	- CR.ATG.FixString: "literal tokens must not contain blanks" semantic check inserted

- CRA.GenComment.GenBody: "ch = r.eot" -> "ch = EOF"

- CR.ATG: SHORT inserted in 2 places in SimSet production

- input ATG linesep related:

	- CR.ATG: eol -> lf, cr

	- Scanner.FRM: "EOL = 0DX" -> "EOL = 0AX"

- unused:

	- CRT: unused import of SYSTEM removed

	- Scanner.FRM: unused import of SYSTEM commented

	- CR.ATG: name variable commented in SetDDT (it not used)

	- CR.ATG: "gn: CRT.GraphNode" commented in CR production (it not used)

	- CR.ATG: c variable commented in Factor production (it not used)

- optimizations:

	- CRT.Length: s -> CONST s

	- CRA.Length: s -> CONST s

	- CRX.Length: s -> CONST s

- typos:

	- spaces:

		- Scanner.FRM: extra space removed in first line "(*  scanner module..."

		- redundant spaces removed in some places

Features candidates
===================

+----------------------+-----------------------+
|IF() LL(1)-resolver   |implemented            |
+----------------------+-----------------------+
|multi-symbol lookahead|I will not implement it|
+----------------------+-----------------------+
|literals              |implemented            |
+----------------------+-----------------------+

Notes
=====

- line separators:

	- generated code:

		Texts.WriteLn always emits CR

		CRA.GenLiterals: CHR(13)

	- input ATG:

		CR.ATG: eol token

		Scanner.FRM: EOL (line counter)

	- CRX.EOL: 0DX

- lookahead-related:

	+-------+-----------------------------------------+---------------------------------------------------+
	|new    |old                                      |comment                                            |
	+=======+=========================================+===================================================+
	|la.kind|sym                                      |often used                                         |
	+-------+-----------------------------------------+---------------------------------------------------+
	|la.val |S.GetName(S.nextPos, S.nextLen, nextName)|                                                   |
	+-------+-----------------------------------------+---------------------------------------------------+
	|t.kind |???                                      |rarely used? may be easy implemented in Parser.FRM?|
	+-------+-----------------------------------------+---------------------------------------------------+
	|t.val  |S.GetName(S.pos, S.len, name)            |often used                                         |
	+-------+-----------------------------------------+---------------------------------------------------+

- it is possible to write: (. IF ... THEN .) ... (. END .) :)

TODO
====

- do Coco regression tests

	TestResOK (EOF related)

- number of reported errors does not correspond to number of displayed errors

- trace:

	does not work now

	literals
