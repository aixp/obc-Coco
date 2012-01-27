MODULE CRP;	(** portable *)
IMPORT CRS, CRT, CRA, CRX, Sets, Texts, Oberon;

CONST
  maxT        = 38;
  nrSets = 18;

	setSize = 32;  nSets = (maxT DIV setSize) + 1;

TYPE
	SymbolSet = ARRAY nSets OF SET;

VAR
	sym:     SHORTINT;   (* current input symbol *)
	symSet:  ARRAY nrSets OF SymbolSet;

CONST
  ident = 0; string = 1; (*symbol kind*)

VAR
  str: ARRAY 32 OF CHAR;
  w:   Texts.Writer;
  genScanner: BOOLEAN;


PROCEDURE SemErr(nr: SHORTINT);
BEGIN
  CRS.Error(200+nr, CRS.pos);
END SemErr;

PROCEDURE MatchLiteral(sp: SHORTINT); (*store string either as token or as literal*)
  VAR sn, sn1: CRT.SymbolNode; matchedSp: SHORTINT;
BEGIN
  CRT.GetSym(sp, sn);
  CRA.MatchDFA(sn.name, sp, matchedSp);
  IF matchedSp # CRT.noSym THEN
    CRT.GetSym(matchedSp, sn1); sn1.struct := CRT.classLitToken; CRT.PutSym(matchedSp, sn1);
    sn.struct := CRT.litToken
  ELSE sn.struct := CRT.classToken;
  END ;
  CRT.PutSym(sp, sn)
END MatchLiteral;

PROCEDURE SetCtx(gp: SHORTINT); (*set transition code to CRT.contextTrans*)
  VAR gn: CRT.GraphNode;
BEGIN
  WHILE gp > 0 DO
    CRT.GetNode(gp, gn);
    IF gn.typ IN {CRT.char, CRT.class} THEN
        gn.p2 := CRT.contextTrans; CRT.PutNode(gp, gn)
    ELSIF gn.typ IN {CRT.opt, CRT.iter} THEN SetCtx(gn.p1)
    ELSIF gn.typ = CRT.alt THEN SetCtx(gn.p1); SetCtx(gn.p2)
    END ;
    gp := gn.next
  END
END SetCtx;

PROCEDURE SetDDT(s: ARRAY OF CHAR);
  VAR i: SHORTINT; ch: CHAR;
BEGIN
  i := 1;
  WHILE s[i] # 0X DO
    ch := s[i]; INC(i);
    IF (ch >= "0") & (ch <= "9") THEN CRT.ddt[ORD(ch)-ORD("0")] := TRUE END
  END
END SetDDT;

PROCEDURE FixString (VAR s: ARRAY OF CHAR; len: SHORTINT);
	VAR double: BOOLEAN; i: SHORTINT;
BEGIN
	double := FALSE;
	FOR i := 0 TO len-2 DO
		IF s[i] = '"' THEN double := TRUE ELSIF s[i] = " " THEN SemErr(24) END
	END ;
	IF ~ double THEN s[0] := '"'; s[len-1] := '"' END
END FixString;

(*-------------------------------------------------------------------------*)


PROCEDURE Error (n: SHORTINT);
BEGIN CRS.Error(n, CRS.nextPos)
END Error;

PROCEDURE Get;
BEGIN
	LOOP CRS.Get(sym);
    IF sym > maxT THEN
      IF sym = 39 THEN
         CRS.GetName(CRS.nextPos, CRS.nextLen, str); SetDDT(str)
      END ;
      CRS.nextPos := CRS.pos;
      CRS.nextCol := CRS.col;
      CRS.nextLine := CRS.line;
      CRS.nextLen := CRS.len;
    ELSE EXIT
    END
END

END Get;

PROCEDURE Expect(n: SHORTINT);
BEGIN IF sym = n THEN Get ELSE Error(n) END
END Expect;

PROCEDURE StartOf(s: SHORTINT): BOOLEAN;
BEGIN RETURN (sym MOD setSize) IN symSet[s, sym DIV setSize]
END StartOf;

PROCEDURE ExpectWeak(n, follow: SHORTINT);
BEGIN
	IF sym = n THEN Get
	ELSE Error(n); WHILE ~ StartOf(follow) DO Get END
	END
END ExpectWeak;

PROCEDURE WeakSeparator(n, syFol, repFol: SHORTINT): BOOLEAN;
	VAR s: SymbolSet; i: SHORTINT;
BEGIN
	IF sym = n THEN Get; RETURN TRUE
	ELSIF StartOf(repFol) THEN RETURN FALSE
	ELSE
		i := 0; WHILE i < nSets DO s[i] := symSet[syFol, i] + symSet[repFol, i] + symSet[0, i]; INC(i) END ;
		Error(n); WHILE ~ ((sym MOD setSize) IN s[sym DIV setSize]) DO Get END ;
		RETURN StartOf(syFol)
	END
END WeakSeparator;

PROCEDURE TokenFactor(VAR gL, gR: SHORTINT);
  VAR kind, c: SHORTINT; set: CRT.Set; name: CRT.Name;
BEGIN
  gL :=0; gR := 0 ;
  IF (sym = 1) OR (sym = 2) THEN
    Symbol(name, kind);
    IF kind = ident THEN
      c := CRT.ClassWithName(name);
      IF c < 0 THEN
        SemErr(15);
        Sets.Clear(set); c := CRT.NewClass(name, set)
      END ;
      gL := CRT.NewNode(CRT.class, c, 0); gR := gL
    ELSE (*string*)
      CRT.StrToGraph(name, gL, gR)
    END ;
  ELSIF (sym = 23) THEN
    Get;
    TokenExpr(gL, gR);
    Expect(24);
  ELSIF (sym = 28) THEN
    Get;
    TokenExpr(gL, gR);
    Expect(29);
    CRT.MakeOption(gL, gR) ;
  ELSIF (sym = 30) THEN
    Get;
    TokenExpr(gL, gR);
    Expect(31);
    CRT.MakeIteration(gL, gR) ;
  ELSE Error(39)
  END ;
END TokenFactor;

PROCEDURE TokenTerm(VAR gL, gR: SHORTINT);
  VAR gL2, gR2: SHORTINT;
BEGIN
  TokenFactor(gL, gR);
  WHILE StartOf(1)  DO
    TokenFactor(gL2, gR2);
    CRT.ConcatSeq(gL, gR, gL2, gR2) ;
  END ;
  IF (sym = 33) THEN
    Get;
    Expect(23);
    TokenExpr(gL2, gR2);
    SetCtx(gL2); CRT.ConcatSeq(gL, gR, gL2, gR2) ;
    Expect(24);
  END ;
END TokenTerm;

PROCEDURE Factor(VAR gL, gR: SHORTINT);
  VAR sp, kind: SHORTINT; name: CRT.Name;
      gn: CRT.GraphNode; sn: CRT.SymbolNode;
      set: CRT.Set;
      undef, weak: BOOLEAN;
      pos: CRT.Position;
BEGIN
  gL :=0; gR := 0; weak := FALSE ;
  CASE sym OF
  | 1,2,27:     IF (sym = 27) THEN
      Get;
      weak := TRUE ;
    END ;
    Symbol(name, kind);
    sp := CRT.FindSym(name); undef := sp = CRT.noSym;
    IF undef THEN
      IF kind = ident THEN  (*forward nt*)
        sp := CRT.NewSym(CRT.nt, name, 0)
      ELSE  (*undefined string in production*)
        sp := CRT.NewSym(CRT.t, name, CRS.line);
        MatchLiteral(sp)
      END
    END ;
    CRT.GetSym(sp, sn);
    IF ~(sn.typ IN {CRT.t,CRT.nt}) THEN SemErr(4) END ;
    IF weak THEN
      IF sn.typ = CRT.t THEN sn.typ := CRT.wt ELSE SemErr(23) END
    END ;
    gL := CRT.NewNode(sn.typ, sp, CRS.line); gR := gL ;
    IF (sym = 34) THEN
      Attribs(pos);
      CRT.GetNode(gL, gn); gn.pos := pos; CRT.PutNode(gL, gn);
      CRT.GetSym(sp, sn);
      IF undef THEN
        sn.attrPos := pos; CRT.PutSym(sp, sn)
      ELSIF sn.attrPos.beg < 0 THEN SemErr(5)
      END ;
      IF kind # ident THEN SemErr(3) END ;
    ELSIF StartOf(2)  THEN
      CRT.GetSym(sp, sn);
      IF sn.attrPos.beg >= 0 THEN SemErr(6) END ;
    ELSE Error(40)
    END ;
  | 23:     Get;
    Expression(gL, gR);
    Expect(24);
  | 28:     Get;
    Expression(gL, gR);
    Expect(29);
    CRT.MakeOption(gL, gR) ;
  | 30:     Get;
    Expression(gL, gR);
    Expect(31);
    CRT.MakeIteration(gL, gR) ;
  | 36:     SemText(pos);
    gL := CRT.NewNode(CRT.sem, 0, 0);
    gR := gL;
    CRT.GetNode(gL, gn); gn.pos := pos; CRT.PutNode(gL, gn) ;
  | 25:     Get;
    Sets.Fill(set); Sets.Excl(set, CRT.eofSy);
    gL := CRT.NewNode(CRT.any, CRT.NewSet(set), 0); gR := gL ;
  | 32:     Get;
    gL := CRT.NewNode(CRT.sync, 0, 0); gR := gL ;
  ELSE Error(41)
  END ;
END Factor;

PROCEDURE Term(VAR gL, gR: SHORTINT);
  VAR gL2, gR2: SHORTINT;
BEGIN
  gL := 0; gR := 0 ;
  IF StartOf(3)  THEN
    Factor(gL, gR);
    WHILE StartOf(3)  DO
      Factor(gL2, gR2);
      CRT.ConcatSeq(gL, gR, gL2, gR2) ;
    END ;
  ELSIF StartOf(4)  THEN
    gL := CRT.NewNode(CRT.eps, 0, 0); gR := gL ;
  ELSE Error(42)
  END ;
END Term;

PROCEDURE Symbol(VAR name: CRT.Name; VAR kind: SHORTINT);
BEGIN
  IF (sym = 1) THEN
    Get;
    kind := ident ;
  ELSIF (sym = 2) THEN
    Get;
    kind := string ;
  ELSE Error(43)
  END ;
  CRS.GetName(CRS.pos, CRS.len, name);
  IF kind = string THEN FixString(name, CRS.len) END ;
END Symbol;

PROCEDURE SimSet(VAR set: CRT.Set);
  VAR c, n, i: SHORTINT; name: CRT.Name; s: ARRAY 128 OF CHAR;
BEGIN
  IF (sym = 1) THEN
    Get;
    CRS.GetName(CRS.pos, CRS.len, name);
    c := CRT.ClassWithName(name);
    IF c < 0 THEN SemErr(15); Sets.Clear(set)
    ELSE CRT.GetClass(c, set)
    END ;
  ELSIF (sym = 2) THEN
    Get;
    CRS.GetName(CRS.pos, CRS.len, s);
    Sets.Clear(set); i := 1;
    WHILE s[i] # s[0] DO
      Sets.Incl(set, SHORT(ORD(s[i]))); INC(i)
    END ;
  ELSIF (sym = 22) THEN
    Get;
    Expect(23);
    Expect(3);
    CRS.GetName(CRS.pos, CRS.len, name);
    n := 0; i := 0;
    WHILE name[i] # 0X DO
      n := SHORT(10 * n + (ORD(name[i]) - ORD("0")));
      INC(i)
    END ;
    Sets.Clear(set); Sets.Incl(set, n) ;
    Expect(24);
  ELSIF (sym = 25) THEN
    Get;
    Sets.Fill(set) ;
  ELSE Error(44)
  END ;
END SimSet;

PROCEDURE Set(VAR set: CRT.Set);
  VAR set2: CRT.Set;
BEGIN
  SimSet(set);
  WHILE (sym = 20) OR (sym = 21) DO
    IF (sym = 20) THEN
      Get;
      SimSet(set2);
      Sets.Unite(set, set2) ;
    ELSE
      Get;
      SimSet(set2);
      Sets.Differ(set, set2) ;
    END ;
  END ;
END Set;

PROCEDURE TokenExpr(VAR gL, gR: SHORTINT);
  VAR gL2, gR2: SHORTINT; first: BOOLEAN;
BEGIN
  TokenTerm(gL, gR);
  first := TRUE ;
  WHILE WeakSeparator(26, 1, 5)  DO
    TokenTerm(gL2, gR2);
    IF first THEN
      CRT.MakeFirstAlt(gL, gR); first := FALSE
    END ;
    CRT.ConcatAlt(gL, gR, gL2, gR2) ;
  END ;
END TokenExpr;

PROCEDURE TokenDecl(typ: SHORTINT);
  VAR sp, kind, gL, gR: SHORTINT; sn: CRT.SymbolNode;
      pos: CRT.Position; name: CRT.Name;
BEGIN
  Symbol(name, kind);
  IF CRT.FindSym(name) # CRT.noSym THEN SemErr(7)
  ELSE
    sp := CRT.NewSym(typ, name, CRS.line);
    CRT.GetSym(sp, sn); sn.struct := CRT.classToken;
    CRT.PutSym(sp, sn)
  END ;
  WHILE ~( StartOf(6) ) DO Error(45); Get END ;
  IF (sym = 8) THEN
    Get;
    TokenExpr(gL, gR);
    Expect(9);
    IF kind # ident THEN SemErr(13) END ;
    CRT.CompleteGraph(gR);
    CRA.ConvertToStates(gL, sp) ;
  ELSIF StartOf(7)  THEN
    IF kind = ident THEN genScanner := FALSE
    ELSE MatchLiteral(sp)
    END ;
  ELSE Error(46)
  END ;
  IF (sym = 36) THEN
    SemText(pos);
    IF typ = CRT.t THEN SemErr(14) END ;
    CRT.GetSym(sp, sn); sn.semPos := pos; CRT.PutSym(sp, sn) ;
  END ;
END TokenDecl;

PROCEDURE SetDecl;
  VAR c: SHORTINT; set: CRT.Set; name: CRT.Name;
BEGIN
  Expect(1);
  CRS.GetName(CRS.pos, CRS.len, name);
  c := CRT.ClassWithName(name); IF c >= 0 THEN SemErr(7) END ;
  Expect(8);
  Set(set);
  c := CRT.NewClass(name, set) ;
  Expect(9);
END SetDecl;

PROCEDURE Expression(VAR gL, gR: SHORTINT);
  VAR gL2, gR2: SHORTINT; first: BOOLEAN;
BEGIN
  Term(gL, gR);
  first := TRUE ;
  WHILE WeakSeparator(26, 2, 8)  DO
    Term(gL2, gR2);
    IF first THEN
      CRT.MakeFirstAlt(gL, gR); first := FALSE
    END ;
    CRT.ConcatAlt(gL, gR, gL2, gR2) ;
  END ;
END Expression;

PROCEDURE SemText(VAR semPos: CRT.Position);
BEGIN
  Expect(36);
  semPos.beg := CRS.nextPos; semPos.col := CRS.nextCol ;
  WHILE StartOf(9)  DO
    Get;
  END ;
  Expect(37);
  semPos.len := CRS.pos - semPos.beg ;
END SemText;

PROCEDURE Attribs(VAR attrPos: CRT.Position);
BEGIN
  Expect(34);
  attrPos.beg := CRS.nextPos; attrPos.col := CRS.nextCol ;
  WHILE StartOf(10)  DO
    Get;
  END ;
  Expect(35);
  attrPos.len := CRS.pos - attrPos.beg ;
END Attribs;

PROCEDURE Declaration;
  VAR gL1, gR1, gL2, gR2: SHORTINT; nested: BOOLEAN;
BEGIN
  IF (sym = 11) THEN
    Get;
    WHILE (sym = 1) DO
      SetDecl;
    END ;
  ELSIF (sym = 12) THEN
    Get;
    WHILE (sym = 1) OR (sym = 2) DO
      TokenDecl(CRT.t);
    END ;
  ELSIF (sym = 13) THEN
    Get;
    WHILE (sym = 1) OR (sym = 2) DO
      TokenDecl(CRT.pr);
    END ;
  ELSIF (sym = 14) THEN
    Get;
    Expect(15);
    TokenExpr(gL1, gR1);
    Expect(16);
    TokenExpr(gL2, gR2);
    IF (sym = 17) THEN
      Get;
      nested := TRUE ;
    ELSIF StartOf(11)  THEN
      nested := FALSE ;
    ELSE Error(47)
    END ;
    CRA.NewComment(gL1, gL2, nested) ;
  ELSIF (sym = 18) THEN
    Get;
    IF (sym = 19) THEN
      Get;
      CRT.ignoreCase := TRUE ;
    ELSIF StartOf(12)  THEN
      Set(CRT.ignored);
    ELSE Error(48)
    END ;
  ELSE Error(49)
  END ;
END Declaration;

PROCEDURE CR;
  VAR undef, hasAttrs, ok, ok1: BOOLEAN; eofSy, gR: SHORTINT;
      gramLine, sp: SHORTINT;
      sn: CRT.SymbolNode;
      name, gramName: CRT.Name;
BEGIN
  Expect(4);
  Texts.OpenWriter(w);
  CRT.Init; CRX.Init; CRA.Init;
  gramLine := CRS.line;
  eofSy := CRT.NewSym(CRT.t, "EOF", 0);
  genScanner := TRUE;
  CRT.ignoreCase := FALSE;
  ok := TRUE;
  Sets.Clear(CRT.ignored) ;
  Expect(1);
  CRS.GetName(CRS.pos, CRS.len, gramName);
  CRT.semDeclPos.beg := CRS.nextPos; CRT.importPos.beg := -1;
  WHILE StartOf(13)  DO
    IF (sym = 5) THEN
      Get;
      CRT.importPos.beg := CRS.nextPos ;
      WHILE StartOf(14)  DO
        Get;
      END ;
      Expect(6);
      CRT.importPos.len := CRS.pos - CRT.importPos.beg;
      CRT.importPos.col := 0;
      CRT.semDeclPos.beg := CRS.nextPos ;
    ELSE
      Get;
    END ;
  END ;
  CRT.semDeclPos.len := CRS.nextPos - CRT.semDeclPos.beg;
  CRT.semDeclPos.col := 0 ;
  WHILE StartOf(15)  DO
    Declaration;
  END ;
  WHILE ~( (sym = 0) OR (sym = 7)) DO Error(50); Get END ;
  Expect(7);
  IF genScanner THEN CRA.MakeDeterministic(ok) END ;
  CRT.nNodes := 0 ;
  WHILE (sym = 1) DO
    Get;
    CRS.GetName(CRS.pos, CRS.len, name);
    sp := CRT.FindSym(name); undef := sp = CRT.noSym;
    IF undef THEN
      sp := CRT.NewSym(CRT.nt, name, CRS.line);
      CRT.GetSym(sp, sn);
    ELSE
      CRT.GetSym(sp, sn);
      IF sn.typ = CRT.nt THEN
        IF sn.struct > 0 THEN SemErr(7) END
      ELSE SemErr(8)
      END ;
      sn.line := CRS.line
    END ;
    hasAttrs := sn.attrPos.beg >= 0 ;
    IF (sym = 34) THEN
      Attribs(sn.attrPos);
      IF ~undef & ~hasAttrs THEN SemErr(9) END ;
      CRT.PutSym(sp, sn) ;
    ELSIF (sym = 8) OR (sym = 36) THEN
      IF ~undef & hasAttrs THEN SemErr(10) END ;
    ELSE Error(51)
    END ;
    IF (sym = 36) THEN
      SemText(sn.semPos);
    END ;
    ExpectWeak(8, 16);
    Expression(sn.struct, gR);
    CRT.CompleteGraph(gR); CRT.PutSym(sp, sn);
    IF CRT.ddt[2] THEN CRT.PrintGraph END ;
    ExpectWeak(9, 17);
  END ;
  sp := CRT.FindSym(gramName);
  IF sp = CRT.noSym THEN SemErr(11);
  ELSE
    CRT.GetSym(sp, sn);
    IF sn.attrPos.beg >= 0 THEN SemErr(12) END ;
    CRT.root := CRT.NewNode(CRT.nt, sp, gramLine);
  END ;
  Expect(10);
  Expect(1);
  CRS.GetName(CRS.pos, CRS.len, name);
  IF name # gramName THEN SemErr(17) END ;
  IF CRS.errors = 0 THEN
    Texts.WriteString(w, " checking"); Texts.Append(Oberon.Log, w.buf);
    CRT.CompSymbolSets;
    IF ok THEN CRT.TestCompleteness(ok) END ;
    IF ok THEN
      CRT.TestIfAllNtReached(ok1); CRT.FindCircularProductions(ok)
    END ;
    IF ok THEN CRT.TestIfNtToTerm(ok) END ;
    IF ok THEN CRT.LL1Test(ok1) END ;
    IF CRT.ddt[0] THEN CRA.PrintStates END ;
    IF CRT.ddt[7] THEN CRT.XRef END ;
    IF ok THEN
      Texts.WriteString(w, " +parser");
      Texts.Append(Oberon.Log, w.buf);
      CRX.GenCompiler;
      IF genScanner THEN
        Texts.WriteString(w, " +scanner");
        Texts.Append(Oberon.Log, w.buf);
        CRA.WriteScanner
      END ;
      IF CRT.ddt[8] THEN CRX.WriteStatistics END
    END
  ELSE ok := FALSE
  END ;
  IF CRT.ddt[6] THEN CRT.PrintSymbolTable END ;
  IF ok THEN Texts.WriteString(w, " done") END ;
  Texts.WriteLn(w); Texts.Append(Oberon.Log, w.buf) ;
  Expect(9);
END CR;



PROCEDURE Parse*;
BEGIN
	Get;
  CR;

END Parse;

BEGIN
  symSet[0, 0] := {0,1,2,7,8,11,12,13,14,18};
  symSet[0, 1] := {4};
  symSet[1, 0] := {1,2,23,28,30};
  symSet[1, 1] := {};
  symSet[2, 0] := {1,2,9,23,24,25,26,27,28,29,30,31};
  symSet[2, 1] := {0,4};
  symSet[3, 0] := {1,2,23,25,27,28,30};
  symSet[3, 1] := {0,4};
  symSet[4, 0] := {9,24,26,29,31};
  symSet[4, 1] := {};
  symSet[5, 0] := {7,9,11,12,13,14,16,17,18,24,29,31};
  symSet[5, 1] := {};
  symSet[6, 0] := {0,1,2,7,8,11,12,13,14,18};
  symSet[6, 1] := {4};
  symSet[7, 0] := {1,2,7,11,12,13,14,18};
  symSet[7, 1] := {4};
  symSet[8, 0] := {9,24,29,31};
  symSet[8, 1] := {};
  symSet[9, 0] := {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31};
  symSet[9, 1] := {0,1,2,3,4,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31};
  symSet[10, 0] := {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31};
  symSet[10, 1] := {0,1,2,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31};
  symSet[11, 0] := {7,11,12,13,14,18};
  symSet[11, 1] := {};
  symSet[12, 0] := {1,2,22,25};
  symSet[12, 1] := {};
  symSet[13, 0] := {1,2,3,4,5,6,8,9,10,15,16,17,19,20,21,22,23,24,25,26,27,28,29,30,31};
  symSet[13, 1] := {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31};
  symSet[14, 0] := {1,2,3,4,5,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31};
  symSet[14, 1] := {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31};
  symSet[15, 0] := {11,12,13,14,18};
  symSet[15, 1] := {};
  symSet[16, 0] := {0,1,2,7,8,9,11,12,13,14,18,23,25,26,27,28,30};
  symSet[16, 1] := {0,4};
  symSet[17, 0] := {0,1,2,7,8,10,11,12,13,14,18};
  symSet[17, 1] := {4};

END CRP.
