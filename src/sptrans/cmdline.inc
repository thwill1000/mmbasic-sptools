' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("lexer", "options", "sptools", "string", "defines")
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
      Case "C", "colour"       : cli.parse_no_arg("colour", i)
      Case "crunch"            : cli.parse_no_arg("crunch", i)
      Case "e", "empty-lines"  : cli.parse_arg("empty-lines", i, "{0|1}")
      Case "f", "format-only"  : cli.parse_no_arg("format-only", i)
      Case "I", "include-only" : cli.parse_no_arg("include-only", i)
      Case "i", "indent"       : cli.parse_arg("indent", i, "<number>")
      Case "k", "keywords"     : cli.parse_arg("keywords", i, "{l|p|u}")
      Case "h", "help"         : cli.usage() : End
      Case "n", "no-comments"  : cli.parse_no_arg("no-comments", i)
      Case "q", "quiet"        : cli.parse_no_arg("quiet", i)
      Case "s", "spacing"      : cli.parse_arg("spacing", i, "{0|1|2}")
      Case "v", "version"      : spt.print_version("sptrans") : End
      Case Else:
        If Left$(lx.option$(i), 1) = "D" Then
          cli.parse_no_arg("id", i);
        Else
          sys.err$ = "option " + lx.token$(i) + " is unknown"
        EndIf
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

  If i < lx.num Then
    Select Case lx.type(i)
      Case TK_STRING: opt.set("outfile", lx.string$(i))
      Case Else:      opt.set("outfile", lx.token$(i))
    End Select
    Inc i
  EndIf

  If i <> lx.num Then
    sys.err$ = "unexpected argument '" + lx.token$(i) + "'"
  ElseIf opt.format_only And opt.include_only Then
    sys.err$ = "--format-only and --include-only options are mutually exclusive"
  ElseIf opt.quiet And Not Len(opt.outfile$) Then
    sys.err$ = "--quiet option incompatible with writing to console"
  EndIf
End Sub

' Parses an option with an argument.
Sub cli.parse_arg(option$, i, arg$)
  If lx.token$(i + 1) <> "=" Or lx.token$(i + 2) = "" Then
    sys.err$ = "missing argument"
  Else
    opt.set(option$, lx.token$(i + 2))
  EndIf
  If sys.err$ <> "" Then sys.err$ = "option " + lx.token$(i) + " expects " + arg$ + " argument"
  Inc i, 3
End Sub

' Parses an option without an argument.
Sub cli.parse_no_arg(option$, i)
  If lx.token$(i + 1) = "=" Then
    sys.err$ = "option "
    Cat sys.err$, Choice(option$ = "id", "-D<id>", lx.token$(i))
    Cat sys.err$, " does not expect argument"
  ElseIf option$ = "id" Then
    Local id$ = Mid$(lx.token$(i), 3)
    If id$ = "" Then
      sys.err$ = "option -D<id> expects id"
    Else
      def.define(id$)
    EndIf
  Else
    opt.set(option$, "on")
  EndIf
  Inc i
End Sub

Sub cli.usage()
  Local in$ = "<input-file>"
  Local out$ = "<output-file>"
  Print "Usage: RUN " str.quote$("sptrans.bas") ", [OPTION]... " in$ " [" out$ "]"
  Print
  Print "Transcompile the given " in$ " flattening any #INCLUDE hierarchy and"
  Print "processing any !directives encountered. The transpiled output is written to"
  Print "the " out$ ", or the console if unspecified. By using the --format-only"
  Print "option it can also be used as a simple BASIC code formatter."
  Print
  Print "  --crunch               aggressively remove whitespace from the output, "
  Print "                         equivalent to:"
  Print "                           --empty-lines=0 --indent=0 --no-comments --spacing=0"
  Print "  -C, --colour           syntax highlight the output,"
  Print "                         only valid for output to VT100 serial console"
  Print "  -D<id>                 defines id, equivalent to !define <id> directive"
  Print "  -e, --empty-lines=0|1  controls output of empty lines:"
  Print "                           0 - omit all empty lines"
  Print "                           1 - include one empty line between each Function/Sub"
  Print "                         if omitted then original line spacing will be preserved"
  Print "  -f, --format-only      only format the output, do not follow #INCLUDEs or"
  Print "                         process directives"
  Print "  -h, --help             display this help and exit"
  Print "  -i, --indent=NUM       automatically indent output by NUM spaces per level,"
  Print "                         if omitted then original formatting will be preserved"
  Print "  -I, --include-only     inline #INCLUDEd files and format the output,"
  Print "                         without processing directives"
  Print "  -k, --keywords=l|p|u   controls keyword capitalisation:"
  Print "                           l - lowercase"
  Print "                           p - PascalCase"
  Print "                           u - UPPERCASE"
  Print "                         if omitted then original capitalisation will be"
  Print "                         preserved"
  Print "  -n, --no-comments      do not include comments in the output"
  Print "  -q, --quiet            run with minimal console output"
  Print "  -s, --spacing=0|1|2    controls output of spaces between tokens:"
  Print "                           0 - omit all unnecessary spaces"
  Print "                           1 - compact spacing"
  Print "                           2 - generous spacing"
  Print "                         if omitted then original token spacing will be"
  Print "                         preserved"
  Print "  -v, --version          output version information and exit"
  Print
  Print "Note that --no-comments, --empty-lines, --indent and --spacing will be"
  Print "overridden by the corresponding directives in source files, unless "
  Print "--format-only is also specified."
End Sub
