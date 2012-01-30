MODULE RISC1;

	(*
		A. V. Shiryaev, 2012.01

		References:
			N. Wirth, Compiler Construction, June 2011
		Modifications:
			stack implemented
			ROT and LSH functions for OBC compatibility
	*)

	IMPORT SYSTEM, Texts, Oberon;

	CONST MemSize = 1024; (* in words *)
		MOV = 0; AND = 1; IOR = 2; XOR = 3; Lsl = 4; Asr = 5;
		ADD = 8; SUB = 9;  MUL = 10; Div = 11; CMP = 12;
		stackLen = 16; StkBase = 03FFF0H;

	VAR IR: INTEGER; (* instruction register *)
		PC: INTEGER; (* program counter *)
		SN, SZ (*, SC, SV*): BOOLEAN;  (* condition regosters *)
		R: ARRAY 16 OF INTEGER;
		stk: ARRAY stackLen OF INTEGER;

	PROCEDURE Trace1 (CONST msg: ARRAY OF CHAR; x: INTEGER);
		VAR W: Texts.Writer;
	BEGIN
		Texts.OpenWriter(W); Texts.Write(W, "{");
			Texts.WriteString(W, msg); Texts.WriteString(W, ": "); Texts.WriteInt(W, x, 0);
			Texts.Write(W, "}");
			Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
	END Trace1;

	(* SYSTEM.ROT replacement for 32-bit integers *)
	PROCEDURE ROT (x, n: INTEGER): INTEGER;
	BEGIN
		n := n MOD 32;
		RETURN SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, ASH(x, n)) + SYSTEM.VAL(SET, ASH(x, n-32)) * {0..n-1})
	END ROT;

	PROCEDURE LSH (x, n: INTEGER): INTEGER;
	BEGIN
		IF n = 0 THEN RETURN x
		ELSIF ABS(n) >= 32 THEN ASSERT(FALSE)
		ELSE RETURN LSL(x, n)
		END
	END LSH;

	(* Original Wirth' emulator, with stack support and some debugging *)
	PROCEDURE Execute* (VAR M: ARRAY OF INTEGER; VAR S: Texts.Scanner; VAR W: Texts.Writer);
		VAR pq, a, b, op, im: INTEGER;  (*instruction fields*)
			adr, A, B, C: INTEGER;
	BEGIN PC := 0;
		REPEAT (*interpretation cycle*)
			IR := M[PC];
			INC(PC); pq := IR DIV 40000000H MOD 4;  (*insr. class*)
			a := IR DIV 1000000H MOD 10H;
			b := IR DIV 100000H MOD 10H;
			op := IR DIV 10000H MOD 10H;
			im := IR MOD 10000H;
			CASE pq OF
				0, 1: (*register instructions*)
					B := R[b];
					IF pq = 0 THEN C := R[IR MOD 10H]
					ELSIF ODD(IR DIV 10000000H) THEN C := im + (-65536)
					ELSE C := im
					END ;
					CASE op OF
						MOV: A := C |
						AND: A := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, B) * SYSTEM.VAL(SET,C)) |
						IOR: A := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, B) + SYSTEM.VAL(SET,C)) |
						XOR: A := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, B) / SYSTEM.VAL(SET,C)) |
						Lsl: A := LSH(B, C) |
						Asr: IF ODD(IR DIV 20000000H) THEN A := ROT(B, -C) ELSE A := ASH(B, -C) END |
						ADD: A:= B + C |
						SUB, CMP: A:= B - C |
						MUL: A:= B * C |
						Div: A := B DIV C
					END ;
					IF op # CMP THEN R[a] := A END ;
					SN := A < 0; SZ := A = 0
			| 2: (*memory instructions*)
				ASSERT(R[b] MOD 4 = 0);
				ASSERT(IR MOD 4 = 0);
				ASSERT(~ODD(IR DIV 10000000H)); (* byte addressing not implemented *)
				adr := (R[b] + IR) MOD 100000H DIV 4;
				IF adr < MemSize THEN
					IF ODD(IR DIV 20000000H) THEN M[adr] := R[a] ELSE R[a] := M[adr] END
				ELSE (*I/O*)
					IF ODD(IR DIV 20000000H) THEN
						IF adr = 3FFF2H THEN Texts.WriteInt(W, R[a], 8)
						ELSIF adr = 3FFF3H THEN Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
						ELSIF adr <= StkBase THEN stk[StkBase - adr] := R[a]
						ELSE Trace1("I/O PUT, invalid word address", adr)
						END
					ELSE
						IF adr = 3FFF2H THEN Texts.Scan(S); R[a] := S.i
						ELSIF adr = 3FFF3H THEN
							IF S.class # Texts.Int THEN R[a] := 1 ELSE R[a] := 0 END
						ELSIF adr <= StkBase THEN R[a] := stk[StkBase - adr]
						ELSE Trace1("I/O GET, invalid word address", adr)
						END
					END
				END ;
			| 3: (*branch instructions*)
				IF (a = 0) & SN OR (a = 1) & SZ OR (a = 5) & SN OR (a = 6) & (SN OR SZ) OR (a = 7) OR
						(a = 8) & ~SN OR (a = 9) & ~SZ OR (a = 13) & ~SN OR (a = 14) & ~(SN OR SZ) THEN
					IF ODD(IR DIV 10000000H) THEN R[15] := PC*4 END ;
					IF ODD(IR DIV 20000000H) THEN PC := (PC + (IR MOD 1000000H)) MOD 40000H
					ELSE PC := R[IR MOD 10H] DIV 4
					END
				END
			END ;
			Texts.Append(Oberon.Log, W.buf)
		UNTIL PC = 0
	END Execute;

END RISC1.
