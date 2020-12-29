' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

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

  lx.parse_command_line(s$)
  If sys.err$ <> "" Then Exit Sub

  ' Process options.

  Do While i < lx.num And sys.err$ = "" And lx.type(i) = TK_OPTION
    Select Case lx.option$(i)
      Case "C", "colour"      : cli.parse_no_arg("colour", i)
      Case "e", "empty-lines" : cli.parse_arg("empty-lines", i, "{0|1}")
      Case "f", "format-only" : cli.parse_no_arg("format-only", i)
      Case "i", "indent"      : cli.parse_arg("indent", i, "<number>")
      Case "k", "keywords"    : cli.parse_arg("keywords", i, "{l|p|u}")
      Case "h", "help"        : cli.usage() : End
      Case "n", "no-comments" : cli.parse_no_arg("no-comments", i)
      Case "s", "spacing"     : cli.parse_arg("spacing", i, "{0|1|2}")
      Case "v", "version"     : spt.version("sptrans") : End
      Case Else:
        sys.err$ = "option '" + lx.token$(i) + "' is unknown"
    End Select
  Loop

  If sys.err$ <> "" Then Exit Sub

  ' Process arguments.

  If i >= lx.num Then sys.err$ = "no input file specified" : Exit Sub
  If lx.type(i) <> TK_STRING Then sys.err$ = "input file name must be quoted" : Exit Sub
  opt.set("infile", lx.string$(i))
  i = i + 1

  If i >= lx.num Then Exit Sub
  If lx.type(i) <> TK_STRING Then sys.err$ = "output file name must be quoted" : Exit Sub
  opt.set("outfile", lx.string$(i))
  i = i + 1

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
  Local in$ = str.quote$("input file")
  Local out$ = str.quote$("output file")
  Print "Usage: RUN " str.quote$("sptrans.bas") ", [OPTION]... " in$ " [" out$ "]"
  Print
  Print "Transcompile the given " in$ " flattening any #Include hierarchy and processing"
  Print "any !directives encountered. The transpiled output is written to the " out$ ", or"
  Print "the console if unspecified. By using the --format-only option it can also be used as"
  Print "a simple BASIC code formatter."
  Print
  Print "  -C, --colour           syntax highlight the output,"
  Print "                         only valid for output to VT100 serial console"
  Print "  -e, --empty-lines=0|1  controls output of empty lines:"
  Print "                           0 - omit all empty lines"
  Print "                           1 - include one empty line between each Function/Sub"
  Print "                         if ommitted then original line spacing will be preserved"
  Print "  -f, --format-only      only format the output, do not follow #Includes or"
  Print "                         process directives"
  Print "  -h, --help             display this help and exit"
  Print "  -i, --indent=NUM       automatically indent output by NUM spaces per level,"
  Print "                         if omitted then original formatting will be preserved"
  Print "  -k, --keywords=l|p|u   controls keyword capitalisation:"
  Print "                           l - lowercase"
  Print "                           p - PascalCase"
  Print "                           u - UPPERCASE"
  Print "                         if omitted then original capitalisation will be preserved"
  Print "  -n, --no-comments      do not include comments in the output"
  Print "  -s, --spacing=0|1|2    controls output of spaces between tokens:"
  Print "                           0 - omit all unnecessary spaces"
  Print "                           1 - compact spacing"
  Print "                           2 - generous spacing"
  Print "                         if omitted then original token spacing will be preserved"
  Print "  -v, --version          output version information and exit"
  Print
  Print "Note that --no-comments, --empty-lines, --indent and --spacing will be overridden by"
  Print "the corresponding directives in source files, unless --format-only is also specified."
End Sub
