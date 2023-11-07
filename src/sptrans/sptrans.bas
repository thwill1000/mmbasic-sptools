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
#Include "expression.inc"
#Include "symbols.inc"
#Include "trans.inc"
#Include "cmdline.inc"
#Include "symproc.inc"
#Include "console.inc"

Sub main()
  in.init()
  opt.init()
  def.init()
  keywords.init()
  symproc.init()

  ' Sanity check
  If tr.OMIT_LINE <> fmt.OMIT_LINE Then Error "Sanity check failed"

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
    If in.buffer_line%("' Transpiled on " + DateTime$(Now)) <> sys.SUCCESS Then con.error(sys.err$)
    If in.buffer_line%("") Then con.error(sys.err$)
  EndIf

  con.out("Transpiling from '" + opt.infile$ + "' to '" + opt.outfile$ + "' ...") : con.endl()
  If in.open%(opt.infile$) <> sys.SUCCESS Then con.error(sys.err$)
  con.out(in.files$(0)) : con.endl()
  con.out("   ")

  Local ok%, t% = Timer
  Do
    con.out(BS$ + Mid$("\|/-", ((in.line_num%(in.num_open_files% - 1) \ 8) Mod 4) + 1, 1))

    ' Parse
    s$ = in.readln$()
    ok% = lx.parse_basic%(s$)
    If ok% < 0 Then Exit Do

    ' Transpile
    If opt.format_only Then
      ok% = Choice(opt.comments = 0, tr.remove_comments%(), sys.SUCCESS)
    ElseIf opt.include_only Then
      ok% = tr.transpile_includes%()
    Else
      ok% = tr.transpile%()
    EndIf
    If ok% < 0 Then
      Exit Do
    ElseIf ok% = tr.INCLUDE_FILE Then
      open_include()
      ok% = fmt.OMIT_LINE
    EndIf

    ' Format
    If ok% = sys.SUCCESS And opt.format% Then ok% = fmt.format%()

    ' Output / Process Symbols
    Select Case ok%
      Case sys.FAILURE
        Exit Do
      Case sys.SUCCESS
        out.line()
        If opt.list_all% Then ok% = symproc.process%()
      Case fmt.OMIT_LINE
        out.omit_line()
      Case fmt.EMPTY_LINE_BEFORE
        out.empty_line()
        out.line()
        If opt.list_all% Then ok% = symproc.process%()
      Case fmt.EMPTY_LINE_AFTER
        out.line()
        If opt.list_all% Then ok% = symproc.process%()
        out.empty_line()
      Case Else
        Error "Invalid format state: " + Str$(ok%)
    End Select
    If ok% < 0 Then Exit Do

    If Eof(#in.num_open_files%) Then
      If in.num_open_files% > 1 Then close_include() Else in.close()
      If sys.err$ <> "" Then con.error(sys.err$)
      con.out(BS$ + " " + CR$ + Space$(1 + in.num_open_files% * 2))
    EndIf

  Loop Until in.num_open_files% = 0

  If ok% < 0 Then con.error(sys.err$)

  out.close()

  If opt.list_all% Then
    If list_symbols%() <> sys.SUCCESS Then con.error(sys.err$)
  EndIf

  If Not opt.quiet Then Print BS$ "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")
End Sub

Sub open_include()
  If in.open%(tr.include$) = sys.SUCCESS Then
    Local i% = in.num_open_files%
    con.out(CR$ + Space$((i% - 1) * 2) + in.files$(i% - 1)) : con.endl()
    con.out(" " + Space$(i% * 2))
  Else
    con.error(sys.err$)
  EndIf

  Const f$ = in.files$(in.num_open_files% - 1)
  If in.buffer_line%("") <> sys.SUCCESS Then con.error(sys.err$)
  If in.buffer_line%("'_" + f$ + " ++++") <> sys.SUCCESS Then con.error(sys.err$)
End Sub

Sub close_include()
  Const f$ = in.files$(in.num_open_files% - 1)
  If in.buffer_line%("") <> sys.SUCCESS Then con.error(sys.err$)
  If in.buffer_line%("'_---- " + f$) <> sys.SUCCESS Then con.error(sys.err$)
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
