' Copyright (c) 2020 Thomas Hugo Williams

' Parses command-line 's$'.
'
' Sets 'err$' if it encounters an error.
Sub cl_parse(s$)
  Local i = 0, o$

  err$ = ""
  lx_parse_command_line(s$)
  If lx_error$ <> "" Then err$ = lx_error$ : Exit Sub

  ' Process options.

  Do While i < lx_num And err$ = "" And lx_type(i) = TK_OPTION
    Select Case lx_option$(i)
      Case "C", "colour"      : cl_parse_no_arg("colour", i)
      Case "e", "empty-lines" : cl_parse_arg("empty-lines", i, "{0|1}")
      Case "f", "format-only" : cl_parse_no_arg("format-only", i)
      Case "i", "indent"      : cl_parse_arg("indent", i, "<number>")
      Case "h", "help"        : cl_usage() : End
      Case "n", "no-comments" : cl_parse_no_arg("no-comments", i)
      Case "s", "spacing"     : cl_parse_arg("spacing", i, "{0|1|2}")
      Case "v", "version"     : cl_version() : End
      Case Else:
        err$ = "option '" + lx_token$(i) + "' is unknown"
    End Select
  Loop

  If err$ <> "" Then Exit Sub

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

' Parses an option with an argument.
Sub cl_parse_arg(option$, i, arg$)
  If lx_token$(i + 1) <> "=" Or lx_token$(i + 2) = "" Then
    err$ = "missing argument"
  Else
    op_set(option$, lx_token$(i + 2))
  EndIf
  If err$ <> "" Then err$ = "option '" + lx_token$(i) + "' expects " + arg$ + " argument"
  i = i + 3
End Sub

' Parses an option without an argument.
Sub cl_parse_no_arg(option$, i)
  If lx_token$(i + 1) = "=" Then
    err$ = "option '" + lx_token$(i) + "' does not expect argument"
  Else
    op_set(option$, "on")
  EndIf
  i = i + 1
End Sub

Sub cl_usage()
  Local in$ = Chr$(34) + "input file" + Chr$(34)
  Local out$ = Chr$(34) + "output file" + Chr$(34)
  Print "Usage: RUN "; Chr$(34); "mbt.bas" ; Chr$(34); ", [OPTION]... "; in$; " ["; out$; "]"
  Print
  Print "Transcompiles the given "; in$; " flattening any #Include hierarchy and processing"
  Print "any !directives encountered. The transpiled output is written to the "; out$; ", or"
  Print "the console if unspecified. By using the --format-only option it can also be used as"
  Print "a simple BASIC code formatter."
  Print
  Print "  -C, --colour           syntax highlight the output,"
  Print "                         only valid for output to VT100 serial console"
  Print "  -e, --empty-lines=0|1  controls output of empty lines:"
  Print "                           0 - omit all empty lines"
  Print "                           1 - include one empty line between each Function/Sub"
  Print "                         if ommitted then original formatting will be preserved"
  Print "  -f, --format-only      only format the output, do not follow #Includes or"
  Print "                         process directives"
  Print "  -h, --help             display this help and exit"
  Print "  -i, --indent=NUM       automatically indent output by NUM spaces per level,"
  Print "                         if omitted then original formatting will be preserved"
  Print "  -n, --no-comments      do not include comments in the output"
  Print "  -s, --spacing=0|1|2    controls output of spaces between tokens:"
  Print "                           0 - omit all unnecessary spaces"
  Print "                           1 - compact spacing"
  Print "                           2 - generous spacing"
  Print "                         if omitted then original formatting will be preserved"
  Print "  -v, --version          output version information and exit"
  Print
  Print "Note that --no-comments, --empty-lines, --indent and --spacing will be overridden by"
  Print "the corresponding directives in source files, unless --format-only is also specified."
End Sub

Sub cl_version()
  Print "mbt: an MMBasic transcompiler and code-formatter"
  Print "Release 1b1 for Colour Maximite 2, MMBasic 5.05"
  Print "Copyright (c) 2020 Thomas Hugo Williams"
  Print "A Toy Plastic Trumpet Production for Sockpuppet Studios."
  Print "License MIT <https://opensource.org/licenses/MIT>"
  Print "This is free software: you are free to change and redistribute it."
  Print "There is NO WARRANTY, to the extent permitted by law."
  Print
  Print "Written by Thomas Hugo Williams."
End Sub
