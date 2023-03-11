' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("lexer", "options", "sptools", "string")
sys.provides("cmdline")
If sys.err$ <> "" Then Error sys.err$

' Parses command-line 's$'.
'
' Sets 'sys.err$' if it encounters an error.
Sub cli.parse(s$)
  Local i = 0, o$

  If lx.parse_command_line%(s$) <> 0 Then Exit Sub

  ' Process options.

  Do While i < lx.num And sys.err$ = "" And lx.type(i) = TK_OPTION
    Select Case lx.option$(i)
      Case "A", "all"     : cli.parse_no_arg("all", i)
      Case "b", "brief"   : cli.parse_no_arg("brief", i)
      Case "h", "help"    : cli.usage() : End
      Case "no-location"  : cli.parse_no_arg("no-location", i)
      Case "v", "version" : spt.print_version("spflow") : End
      Case Else:
        sys.err$ = "option '" + lx.token$(i) + "' is unknown"
    End Select
  Loop

  If sys.err$ <> "" Then Exit Sub

  ' Process arguments.

  If i >= lx.num Then sys.err$ = "no input file specified" : Exit Sub
  Select Case lx.type(i)
    Case TK_STRING: opt.set("infile", lx.string$(i))
    Case Else:      opt.set("infile", lx.token$(i))
  End Select
  Inc i

  If i >= lx.num Then Exit Sub
  Select Case lx.type(i)
    Case TK_STRING: opt.set("outfile", lx.string$(i))
    Case Else:      opt.set("outfile", lx.token$(i))
  End Select
  Inc i

  If i <> lx.num Then sys.err$ = "unexpected argument '" + lx.token$(i) + "'"
End Sub

' Parses an option with an argument.
Sub cli.parse_arg(option$, i, arg$)
  If lx.token$(i + 1) <> "=" Or lx.token$(i + 2) = "" Then
    sys.err$ = "missing argument"
  Else
    opt.set(option$, lx.token$(i + 2))
  EndIf
  If sys.err$ <> "" Then sys.err$ = "option '" + lx.token$(i) + "' expects " + arg$ + " argument"
  i = i + 3
End Sub

' Parses an option without an argument.
Sub cli.parse_no_arg(option$, i)
  If lx.token$(i + 1) = "=" Then
    sys.err$ = "option '" + lx.token$(i) + "' does not expect argument"
  Else
    opt.set(option$, "on")
  EndIf
  i = i + 1
End Sub

Sub cli.usage()
  Local in$ = "<input-file>"
  Local out$ = "<output-file>"
  Print "Usage: RUN " str.quote$("spflow.bas") ", [OPTION]... " in$ " [" out$ "]"
  Print
  Print "Generate an MMBasic flowgraph for the " in$
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
