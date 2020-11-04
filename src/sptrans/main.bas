' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const BS$ = Chr$(8)
Const CR$ = Chr$(13)
Const QU$ = Chr$(34)

#Include "input.inc"
#Include "lexer.inc"
#Include "options.inc"
#Include "output.inc"
#Include "pprint.inc"
#Include "trans.inc"
#Include "cmdline.inc"
#Include "../common/error.inc"
#Include "../common/file.inc"
#Include "../common/list.inc"
#Include "../common/map.inc"
#Include "../common/set.inc"
#Include "../common/sptools.inc"
#Include "../common/strings.inc"
#Include "../common/vt100.inc"

Sub cendl()
  If opt.outfile$ <> "" Then Print
End Sub

Sub cout(s$)
  If opt.outfile$ <> "" Then Print s$;
End Sub

Sub cerror(msg$)
  Local i = in.files_sz - 1
  Print
  Print "[" + in.files$(i) + ":" + Str$(in.line_num(i)) + "] Error: " + msg$
  End
End Sub

Sub main()
  Local s$, t

  opt.init()

  cli.parse(Mm.CmdLine$)
  If err$ <> "" Then Print "sptrans: "; err$ : Print : cli.usage() : End

  If Not fil.exists%(opt.infile$) Then
    Print "sptrans: input file '" opt.infile$ "' not found."
    End
  EndIf

  If opt.outfile$ <> "" Then
    If fil.exists%(opt.outfile$)) Then
      Line Input "Overwrite existing '" + opt.outfile$ + "' [y|N] ? ", s$
      If LCase$(s$) <> "y" Then Print "CANCELLED" : End
      Print
    EndIf
    opt.colour = 0
  EndIf

  lx.load_keywords(SPT_RESOURCES_DIR$ + "/keywords.txt")

  ' No line numbers when output to file.
  If opt.outfile$ <> "" Then out.line_num_fmt$ = ""

  out.open(opt.outfile$)

  If Not opt.format_only Then
    If opt.colour Then out.print(TK_COLOUR$(TK_COMMENT))
    out.print("' Transpiled on " + DateTime$(Now))
    If opt.colour Then out.print(vt100.colour$("reset"))
    out.endl()
    out.endl()
  EndIf

  cout("Transpiling from '" + opt.infile$ + "' to '" + opt.outfile$ + "' ...") : cendl()
  in.open(opt.infile$)
  If err$ <> "" Then cerror(err$)
  cout(in.files$(0)) : cendl()
  cout("   ")

  t = Timer
  Do
    cout(BS$ + Mid$("\|/-", ((in.line_num(in.files_sz - 1) \ 8) Mod 4) + 1, 1))

    s$ = in.readln$()
    lx.parse_basic(s$)
    If err$ = "" Then
      If Not opt.format_only Then transpile()
      If tr_include$ <> "" Then open_include()
    EndIf
    If err$ <> "" Then cerror(err$)

    pp.print_line()

    If Eof(#in.files_sz) Then
      If in.files_sz > 1 Then close_include() Else in.close()
      If err$ <> "" Then cerror(err$)
      cout(BS$ + " " + CR$ + Space$(1 + in.files_sz * 2))
    EndIf

  Loop Until in.files_sz = 0

  Print
  Print "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")

  out.close()

End Sub

Sub open_include()
  Local s$ = lx.line$
  s$ = "' BEGIN:     " + s$ + " " + String$(66 - Len(s$), "-")
  lx.parse_basic(s$)
  If err$ = "" Then in.open(tr_include$)
  If err$ = "" Then
    Local i = in.files_sz
    cout(CR$ + Space$((i - 1) * 2) + in.files$(i - 1)) : cendl()
    cout(" " + Space$(i * 2))
  EndIf
End Sub

Sub close_include()
  Local s$ = "#Include " + QU$ + in.files$(in.files_sz - 1) + QU$
  s$ = "' END:       " + s$ + " " + String$(66 - Len(s$), "-")
  lx.parse_basic(s$)
  If err$ = "" Then pp.print_line()
  If err$ = "" Then in.close()
End Sub

main()
End
