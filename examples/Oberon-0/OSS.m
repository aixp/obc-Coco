MODULE OSS;

	(*
		A. V. Shiryaev, 2012.01
	*)

	IMPORT S:=Oberon0S, Texts, Oberon;

	CONST
		IdLen* = 16;

		times* = 1; div* = 3; mod* = 4; and* = 5; plus* = 6; minus* = 7; or* = 8;
		eql* = 9; neq* = 10; lss* = 11; geq* = 12; leq* = 13; gtr* = 14;
		not* = 32;

	TYPE Ident* = ARRAY IdLen OF CHAR;

	VAR W: Texts.Writer;

	PROCEDURE Mark* (CONST msg: ARRAY OF CHAR);
	BEGIN
		INC(S.errors);
		Texts.WriteString(W, "  pos "); Texts.WriteInt(W, S.nextPos, 0);
			Texts.WriteString(W, ": "); Texts.WriteString(W, msg);
			Texts.WriteLn(W);
		Texts.Append(Oberon.Log, W.buf)
	END Mark;

BEGIN
	Texts.OpenWriter(W)
END OSS.
