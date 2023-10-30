#!/usr/local/bin/mmbasic

' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Base 0
Option Explicit On
Option Default Integer

Const BS$ = Chr$(8)
Const CR$ = Chr$(13)

#Include "../splib/system.inc"
#Include "../splib/array.inc"
#Include "../splib/bits.inc"
#Include "../splib/list.inc"
#Include "../splib/string.inc"
#Include "../splib/file.inc"
#Include "../splib/map.inc"
#Include "../splib/map2.inc"
#Include "../splib/set.inc"
#Include "../splib/vt100.inc"
#Include "../common/sptools.inc"
#Include "input.inc"
#Include "keywords.inc"
#Include "lexer.inc"
#Include "options.inc"
#Include "defines.inc"
#Include "format.inc"
#Include "output.inc"
#Include "highlight.inc"
#Include "expression.inc"
#Include "symbols.inc"
#Include "trans.inc"
#Include "cmdline.inc"
#Include "symproc.inc"

Sub cendl(always%)
  If Not Len(opt.outfile$) Then Exit Sub
  If Not always% And opt.quiet Then Exit Sub
  Print
End Sub

Sub cout(s$, always%)
  If Not Len(opt.outfile$) Then Exit Sub
  If Not always% And opt.quiet Then Exit Sub
  Print s$;
End Sub

Sub cerror(msg$)
  Const i% = in.num_open_files% - 1
  Print
  If i% >= 0 Then Print "[" + in.files$(i%) + ":" + Str$(in.line_num%(i%)) + "] ";
  Print "Error: " + msg$
  If Mm.Device$ = "MMB4L" Then End 1 Else End
End Sub

Sub main()
  in.init()
  opt.init()
  def.init()
  keywords.init()
  symproc.init()

  cli.parse(Mm.CmdLine$)
  If sys.err$ <> "" Then Print "sptrans: "; sys.err$ : End

  If Not file.exists%(opt.infile$) Then
    Print "sptrans: input file '" opt.infile$ "' not found."
    End
  EndIf

  Local s$
  If opt.outfile$ <> "" Then
    If file.exists%(opt.outfile$)) Then
      Line Input "Overwrite existing '" + opt.outfile$ + "' [y|N] ? ", s$
      If LCase$(s$) <> "y" Then Print "CANCELLED" : End
    EndIf
    opt.colour = 0
  EndIf

  ' No line numbers when output to file.
  If opt.outfile$ <> "" Then out.line_num_width% = 0

  out.open(opt.outfile$)

  If Not opt.format_only% Then
    If in.buffer_line%("' Transpiled on " + DateTime$(Now)) <> sys.SUCCESS Then cerror(sys.err$)
    If in.buffer_line%("") Then cerror(sys.err$)
  EndIf

  cout("Transpiling from '" + opt.infile$ + "' to '" + opt.outfile$ + "' ...") : cendl()
  If in.open%(opt.infile$) <> sys.SUCCESS Then cerror(sys.err$)
  cout(in.files$(0)) : cendl()
  cout("   ")

  Local ok%, t% = Timer
  Do
    cout(BS$ + Mid$("\|/-", ((in.line_num%(in.num_open_files% - 1) \ 8) Mod 4) + 1, 1))

    ' Parse
    s$ = in.readln$()
    ok% = lx.parse_basic%(s$)

    ' Transpile
    If ok% = sys.SUCCESS Then
      If opt.format_only Then
        ok% = Choice(opt.comments = 0, tr.remove_comments%(), sys.SUCCESS)
      ElseIf opt.include_only Then
        ok% = tr.transpile_includes%()
      Else
        ok% = tr.transpile%()
      EndIf
    EndIf
    Select Case ok%
      Case sys.FAILURE, sys.SUCCESS, tr.OMIT_LINE
        ' Do nothing
      Case tr.INCLUDE_FILE
        open_include()
        ok% = tr.OMIT_LINE
      Case Else:
        Error "Invalid trans state: " + Str$(ok%)
    End Select

    ' Process Symbols
    If ok% = sys.SUCCESS And opt.list_all% Then ok% = symproc.process%()

    ' Format
    If ok% = sys.SUCCESS And opt.format% Then ok% = fmt.format%()

    ' Output
    Select Case ok%
      Case sys.FAILURE
        cerror(sys.err$)
      Case sys.SUCCESS
        If opt.colour% Then hil.highlight() Else out.println(lx.line$)
      Case fmt.OMIT_LINE
        ' Do nothing
      Case fmt.EMPTY_LINE_BEFORE
        out.println()
        If opt.colour% Then hil.highlight() Else out.println(lx.line$)
      Case fmt.EMPTY_LINE_AFTER
        If opt.colour% Then hil.highlight() Else out.println(lx.line$)
        out.println()
      Case Else
        Error "Invalid format state: " + Str$(ok%)
    End Select

    If Eof(#in.num_open_files%) Then
      If in.num_open_files% > 1 Then close_include() Else in.close()
      If sys.err$ <> "" Then cerror(sys.err$)
      cout(BS$ + " " + CR$ + Space$(1 + in.num_open_files% * 2))
    EndIf

  Loop Until in.num_open_files% = 0

  out.close()

  If opt.list_all% Then
    If list_symbols%() <> sys.SUCCESS Then cerror(sys.err$)
  EndIf

  If Not opt.quiet Then Print BS$ "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")
End Sub

Sub open_include()
  Local s$ = "' #Include " + str.quote$(file.get_canonical$(tr.include$))
  If Len(s$) < 79 Then Cat s$, " "
  If Len(s$) < 80 Then Cat s$, String$(80 - Len(s$), "-")
  If in.buffer_line%(s$) <> sys.SUCCESS Then cerror(sys.err$)

  If in.open%(tr.include$) = sys.SUCCESS Then
    Local i% = in.num_open_files%
    cout(CR$ + Space$((i% - 1) * 2) + in.files$(i% - 1)) : cendl()
    cout(" " + Space$(i% * 2))
  Else
    cerror(sys.err$)
  EndIf
End Sub

Sub close_include()
  If in.buffer_line%("' " + String$(78, "-")) <> sys.SUCCESS Then cerror(sys.err$)
  in.close()
End Sub

Function list_symbols%()
  '!dynamic_call sym.dump_names%
  '!dynamic_call sym.dump_functions%
  '!dynamic_call sym.dump_references%
  '!dynamic_call sym.dump_orphan_fns%
  list_symbols% = list_symbols_for%("identifiers", "sym.dump_names%")
  If list_symbols% = sys.SUCCESS Then
    list_symbols% = list_symbols_for%("functions", "sym.dump_functions%")
  EndIf
  If list_symbols% = sys.SUCCESS Then
    list_symbols% = list_symbols_for%("references", "sym.dump_references%")
  EndIf
  If list_symbols% = sys.SUCCESS Then
    list_symbols% = list_symbols_for%("orphans", "sym.dump_orphan_fns%")
  EndIf
End Function

Function list_symbols_for%(type$, dump_sub$)
  Local f$, fnbr%
  If Len(opt.outfile$) Then
    f$ = opt.outfile$ + "." + type$
    fnbr% = 10
    Open f$ For Output As fnbr%
    ? BS$ "Writing '" + f$ "' ..." 
  EndIf
  list_symbols_for% = Call(dump_sub$, fnbr%)
  If fnbr% Then Close fnbr%
End Function

main()
End
