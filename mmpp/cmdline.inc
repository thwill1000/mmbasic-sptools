' Copyright (c) 2020 Thomas Hugo Williams

Sub parse_cmdline(s$)
  Local i = 0, o$

  lx_parse_command_line(s$)
  If lx_error$ <> "" Then err$ = lx_error$ : Exit Sub

  ' Process options.

  Do While i < lx_num

    If lx_type(i) = TK_OPTION Then
      o$ = lx_option$(i)

      If o$ = "C" Or o$ = "colour" Then
        pp_colour = 1
        i = i + 1

      ElseIf o$ = "c" Or o$ = "comments" Then
        err$ = "option '--comments' expects argument of 0 or 1"
        If lx_token$(i + 1) <> "=" Then Exit Sub
        If lx_token$(i + 2) <> "0" And lx_token$(i + 2) <> "1" Then Exit Sub
        err$ = ""
        pp_comments = lx_number(i + 2)
        i = i + 3

      ElseIf o$ = "e" Or o$ = "empty-lines" Then
        err$ = "option '--empty-lines' expects argument of 0 or 1"
        If lx_token$(i + 1) <> "=" Then Exit Sub
        If lx_token$(i + 2) <> "0" And lx_token$(i + 2) <> "1" Then Exit Sub
        err$ = ""
        pp_empty_lines = lx_number(i + 2)
        i = i + 3

      ElseIf o$ = "f" Or o$ = "format-only" Then
        mbt_format_only = 1
        i = i + 1

      ElseIf o$ = "i" or o$ = "indent" Then
        err$ = "option '--indent' expects number argument >= 0"
        If lx_token$(i + 1) <> "=" Then Exit Sub
        If lx_type(i + 2) <> TK_NUMBER Then Exit Sub
        err$ = ""
        pp_indent_sz = lx_number(i + 2)
        i = i + 3

      ElseIf o$ = "h" Or o$ = "help" Then
        print_usage()
        End

      ElseIf o$ = "s" Or o$ = "spacing" Then
        err$ = "option '--spacing' expects argument of 0, 1 or 2"
        If lx_token$(i + 1) <> "=" Then Exit Sub
        If lx_type(i + 2) <> TK_NUMBER Then Exit Sub
        pp_spacing = lx_number(i + 2)
        If pp_spacing > 2 Then Exit Sub
        err$ = ""
        i = i + 3

      Else
        err$ = "option '" + lx_token$(i) + "' is unknown" : Exit Sub
      EndIf

    Else
      Exit Do

    EndIf
  Loop

  ' Process arguments.

  If i >= lx_num Then err$ = "no input file specified" : Exit Sub
  If lx_type(i) <> TK_STRING Then err$ = "input file name must be quoted" : Exit Sub
  mbt_in$ = lx_string$(i)
  i = i + 1

  If i >= lx_num Then Exit Sub
  If lx_type(i) <> TK_STRING Then err$ = "output file name must be quoted" : Exit Sub
  mbt_out$ = lx_string$(i)
  i = i + 1

  If i <> lx_num Then err$ = "unexpected argument '" + lx_token$(i) + "'"
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

