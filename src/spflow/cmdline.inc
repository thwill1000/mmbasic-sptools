' Copyright (c) 2020 Thomas Hugo Williams

' Parses command-line 's$'.
'
' Sets 'err$' if it encounters an error.
Sub cli.parse(s$)
  Local i = 0, o$

  lx.parse_command_line(s$)
  If err$ <> "" Then Exit Sub

  ' Process options.

  Do While i < lx.num And err$ = "" And lx.type(i) = TK_OPTION
    Select Case lx.option$(i)
      Case "A", "all"     : cli.parse_no_arg("all", i)
      Case "b", "brief"   : cli.parse_no_arg("brief", i)
      Case "h", "help"    : cli.usage() : End
      Case "no-location"  : cli.parse_no_arg("no-location", i)
      Case "v", "version" : cli.version() : End
      Case Else:
        err$ = "option '" + lx.token$(i) + "' is unknown"
    End Select
  Loop

  If err$ <> "" Then Exit Sub

  ' Process arguments.

  If i >= lx.num Then err$ = "no input file specified" : Exit Sub
  If lx.type(i) <> TK_STRING Then err$ = "input file name must be quoted" : Exit Sub
  opt.set("infile", lx.string$(i))
  i = i + 1

  If i >= lx.num Then Exit Sub
  If lx.type(i) <> TK_STRING Then err$ = "output file name must be quoted" : Exit Sub
  opt.set("outfile", lx.string$(i))
  i = i + 1

  If i <> lx.num Then err$ = "unexpected argument '" + lx.token$(i) + "'"
End Sub

' Parses an option with an argument.
Sub cli.parse_arg(option$, i, arg$)
  If lx.token$(i + 1) <> "=" Or lx.token$(i + 2) = "" Then
    err$ = "missing argument"
  Else
    opt.set(option$, lx.token$(i + 2))
  EndIf
  If err$ <> "" Then err$ = "option '" + lx.token$(i) + "' expects " + arg$ + " argument"
  i = i + 3
End Sub

' Parses an option without an argument.
Sub cli.parse_no_arg(option$, i)
  If lx.token$(i + 1) = "=" Then
    err$ = "option '" + lx.token$(i) + "' does not expect argument"
  Else
    opt.set(option$, "on")
  EndIf
  i = i + 1
End Sub

Sub cli.usage()
  Local in$ = Chr$(34) + "input file" + Chr$(34)
  Local out$ = Chr$(34) + "output file" + Chr$(34)
  Print "Usage: RUN "; Chr$(34); "spflow.bas" ; Chr$(34); ", [OPTION]... "; in$; " ["; out$; "]"
  Print
  Print "Generate an MMBasic flowgraph for the " + in$
  Print
  Print "  -A, --all      produce graphs for all functions/subroutines, even those"
  Print "                 unreachable from the global scope"
  Print "  -b, --brief    output the expanded subgraph for each subroutine only"
  Print "                 once, subsequent calls reference the output line"
  Print "                 containing the original expansion"
  Print "  -h, --help     display this help and exit"
  Print "  --no-location  omit filenames and line numbers from the output"
  Print "  -v, --version  output version information and exit"
End Sub

Sub cli.version()
  Print "spflow " + SPT_VERSION$
  Print "Copyright (c) 2020 Thomas Hugo Williams"
  Print "A Toy Plastic Trumpet Production for Sockpuppet Studios."
  Print "License MIT <https://opensource.org/licenses/MIT>"
  Print "This is free software: you are free to change and redistribute it."
  Print "There is NO WARRANTY, to the extent permitted by law."
  Print
  Print "Written by Thomas Hugo Williams."
End Sub
