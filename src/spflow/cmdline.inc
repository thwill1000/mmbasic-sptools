' Copyright (c) 2020 Thomas Hugo Williams

' Parses command-line 's$'.
'
' Sets 'err$' if it encounters an error.
Sub cl_parse(s$)
  Local i = 0, o$

  lx_parse_command_line(s$)
  If err$ <> "" Then Exit Sub

  ' Process options.

  Do While i < lx_num And err$ = "" And lx_type(i) = TK_OPTION
    Select Case lx_option$(i)
      Case "A", "all"     : cl_parse_no_arg("all", i)
      Case "b", "brief"   : cl_parse_no_arg("brief", i)
      Case "h", "help"    : cl_usage() : End
      Case "no-location"  : cl_parse_no_arg("no-location", i)
      Case "v", "version" : cl_version() : End
      Case Else:
        err$ = "option '" + lx_token$(i) + "' is unknown"
    End Select
  Loop

  If err$ <> "" Then Exit Sub

  ' Process arguments.

  If i >= lx_num Then err$ = "no input file specified" : Exit Sub
  If lx_type(i) <> TK_STRING Then err$ = "input file name must be quoted" : Exit Sub
  op_set("infile", lx_string$(i))
  i = i + 1

  If i >= lx_num Then Exit Sub
  If lx_type(i) <> TK_STRING Then err$ = "output file name must be quoted" : Exit Sub
  op_set("outfile", lx_string$(i))
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
  Print "Usage: RUN "; Chr$(34); "spflow.bas" ; Chr$(34); ", [OPTION]... "; in$; " ["; out$; "]"
  Print
  Print "Generate an MMBasic flowgraph for the " + in$
  Print
  Print "  -A, --all      produce graphs for all subroutines, even those"
  Print "                 unreachable from the global scope"
  Print "  -b, --brief    output the expanded subgraph for each subroutine only"
  Print "                 once, subsequent calls reference the output line"
  Print "                 containing the original expansion"
  Print "  -h, --help     display this help and exit"
  Print "  --no-location  omit filenames and line numbers from the output"
  Print "  -v, --version  output version information and exit"
End Sub

Sub cl_version()
  Print "spflow (SP tools) Release 1b2 for Colour Maximite 2, MMBasic 5.05"
  Print "Copyright (c) 2020 Thomas Hugo Williams"
  Print "A Toy Plastic Trumpet Production for Sockpuppet Studios."
  Print "License MIT <https://opensource.org/licenses/MIT>"
  Print "This is free software: you are free to change and redistribute it."
  Print "There is NO WARRANTY, to the extent permitted by law."
  Print
  Print "Written by Thomas Hugo Williams."
End Sub
