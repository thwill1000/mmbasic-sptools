' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5

#Include "lexer.inc"
#Include "map.inc"
#Include "pprint.inc"
#Include "set.inc"
#Include "trans.inc"

Dim num_files = 0
' We ignore the 0'th element in these.
Dim file_stack$(MAX_NUM_FILES) Length 40
Dim cur_line_no(MAX_NUM_FILES)
Dim format_only ' set =1 to just format / pretty-print and not transpile
Dim in$         ' input filepath
Dim out$        ' output filepath
Dim err$        ' global error message / flag

Sub open_file(f$)
  Local f2$, p

  cout(Chr$(13)) ' CR

  If num_files > 0 Then
    f2$ = fi_get_parent$(file_stack$(1)) + f$
  Else
    f2$ = f$
  EndIf

  If Not fi_exists(f2$) Then cerror("#Include file '" + f2$ + "' not found")
  cout(Space$(num_files * 2) + f2$) : cendl()
  num_files = num_files + 1
  Open f2$ For Input As #num_files
  file_stack$(num_files) = f2$
  cout(Space$(1 + num_files * 2))
End Sub

Function fi_get_parent$(f$)
  Local ch$, p

  p = Len(f$)
  Do
    ch$ = Chr$(Peek(Var f$, p))
    If (ch$ = "/") Or (ch$ = "\") Then Exit Do
    p = p - 1
  Loop Until p = 0

  If p > 0 Then fi_get_parent$ = Left$(f$, p)
End Function

Function fi_exists(f$)
  Local s$
  s$ = Dir$(f$, File)
  If s$ = "" Then s$ = Dir$(f$, Dir)
  fi_exists = s$ <> ""
End Function

Sub close_file()
  Close #num_files
  num_files = num_files - 1
  cout(Chr$(8) + " " + Chr$(13) + Space$(1 + num_files * 2))
End Sub

Sub cendl()
  If pp_file_num = -1 Then Exit Sub
  Print
End Sub

Sub cout(s$)
  If pp_file_num = -1 Then Exit Sub
  Print s$;
End Sub

Sub cerror(msg$)
  Print
  Print "[" + file_stack$(num_files) + ":" + Str$(cur_line_no(num_files)) + "] Error: " + msg$
  End
End Sub

Function read_line$()
  Local s$
  Line Input #num_files, s$
  read_line$ = s$
  cur_line_no(num_files) = cur_line_no(num_files) + 1
End Function

Sub parse_cmdline()
  Local i = 0, o$
  Local spaces = -2, indent = -2, comments = -2, empty_lines = -2

  lx_parse_command_line(Mm.CmdLine$)

  ' Process options.

  Do While i < lx_num
    If lx_type(i) = TK_OPTION Then
      o$ = LCase$(lx_option$(i))
      If o$ = "h" Or o$ = "help" Then
        print_usage()
        End
      ElseIf o$ = "spaces" Then
        If lx_type(i + 1) <> TK_NUMBER Then err$ = "Expected integer option" : Exit Sub
        spaces = lx_number(i + 1)
        i = i + 2
      ElseIf o$ = "indent" Then
        If lx_type(i + 1) <> TK_NUMBER Then err$ = "Expected integer option" : Exit Sub
        indent = lx_number(i + 1)
        i = i + 2
      ElseIf o$ = "comments" Then
        If lx_type(i + 1) <> TK_NUMBER Then err$ = "Expected integer option" : Exit Sub
        comments = lx_number(i + 1)
        i = i + 2
      ElseIf o$ = "emptylines" Then
        If lx_type(i + 1) <> TK_NUMBER Then err$ = "Expected integer option" : Exit Sub
        emptylines = lx_number(i + 1)
        i = i + 2
      ElseIf o$ = "foo" Then
        format_only = 1
        i = i + 1
      Else
        err$ = "Unrecognised command-line option: " + lx_token$(i) : Exit Sub
      EndIf
    Else
      Exit Do
    EndIf
  Loop

  ' Process arguments.

  If i >= lx_num Then err$ = "No input file specified" : Exit Sub
  If lx_type(i) <> TK_STRING Then err$ = "Input file name must be quoted" : Exit Sub
  in$ = lx_string$(i)
  i = i + 1

  If i >= lx_num Then Exit Sub
  If lx_type(i) <> TK_STRING Then err$ = "Output file name must be quoted" : Exit Sub
  out$ = lx_string$(i)
  i = i + 1
End Sub

Sub main()
  Local s$, t

  parse_cmdline()
  If err$ <> "" Then Print "mmpp: "; err$ : Print : print_usage() : End

  Cls

  lx_load_keywords()

  pp_open(out$, format_only)
  pp_spaces = 2
  cout("Transpiling from '" + in$ + "' to '" + out$ + "' ...") : cendl()
  open_file(in$)

  t = Timer
  Do
    cout(Chr$(8) + Mid$("\|/-", ((cur_line_no(num_files) \ 8) Mod 4) + 1, 1))
    s$ = read_line$()
    If format_only Then
      lx_parse_basic(s$)
      If lx_error$ <> "" Then cerror(lx_error$)
    Else
      transpile(s$)
    EndIf
    pp_print_line()

    If Eof(#num_files) Then
      If num_files > 1 Then
        s$ = "' -------- END #Include " + Chr$(34)
        s$ = s$ + file_stack$(num_files) + Chr$(34) + " --------"
        transpile(s$)
        pp_print_line()
      EndIf
      close_file()
    EndIf

  Loop Until num_files = 0

  cout(Chr$(13) + "Time taken = " + Format$((Timer - t) / 1000, "%.1f s"))

  pp_close()

End Sub

Sub print_usage()
  Local in$ = Chr$(34) + "input file" + Chr$(34)
  Local out$ = Chr$(34) + "output file" + Chr$(34)
  Print "Usage: RUN "; Chr$(34); "mmpp.bas" ; Chr$(34); ", [OPTION]... "; in$; " ["; out$; "]"
  Print
  Print "Transcompiles the given "; in$; " flattening any #Include hierarchy and processing"
  Print "any !directives encountered. The transpiled output is written to the "; out$; ", or"
  Print "the console if unspecified. By using the --format-only option it can also be used as"
  Print "a simple BASIC code formatter."
  Print
  Print "  -c, --comments=0|1     controls output of comments:"
  Print "                           0 - omit all comments"
  Print "                           1 - insert additional comments from transpiler"
  Print "                         if omitted then comments will be preserved"
  Print "  -C, --colour           syntax highlight the output,"
  Print "                         only valid for output to VT100 serial console"
  Print "  -e, --empty-lines=0|1  controls output of empty lines:"
  Print "                           0 - omit all empty lines"
  Print "                           1 - include one empty line between each Function/Sub"
  Print "                         if ommitted then original formatting will be preserved"
  Print "  -f, --format-only      only format the output, do not follow #Includes or"
  Print "                         process directives"
  Print "  -h, --help             display these instructions"
  Print "  -i, --indent=NUM       automatically indent output by NUM spaces per level,"
  Print "                         if omitted then original formatting will be preserved"
  Print "  -s, --spacing=0|1|2    controls output of spaces between tokens:"
  Print "                           0 - omit all unnecessary spaces"
  Print "                           1 - compact spacing"
  Print "                           2 - generous spacing"
  Print "                         if omitted then original formatting will be preserved"
  Print
  Print "Note that --comments, --empty-lines, --indent and --spacing will be overridden by"
  Print "the corresponding directives in source files, unless --format-only is also specified."
End Sub

main()
End
