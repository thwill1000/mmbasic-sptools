' Copyright (c) 2020 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.provides("options")
If sys.err$ <> "" Then Error sys.err$

Dim opt.colour       '  0    : no syntax colouring of console output
                    '  1    : VT100 syntax colouring of console output
Dim opt.comments     ' -1    : preserve comments
                    '  0    : omit all comments
Dim opt.empty_lines  ' -1    : preserve empty lines
                    '  0    : omit all empty lines
                    '  1    : include empty line between each Function/Sub
Dim opt.format_only  '  0    : transpile
                    '  1    : just format / pretty-print
Dim opt.indent_sz    ' -1    : preserve indenting
                    '  0..N : automatically indent by N spaces per level
Dim opt.spacing      ' -1    : preserve spacing
                    '  0    : omit all unnecessary (non-indent) spaces
                    '  1    : space compactly
                    '  2    : space generously
Dim opt.infile$      ' input file/path
Dim opt.outfile$     ' output file/path, empty for output to console

Sub opt.init()
  opt.colour = 0
  opt.comments = -1
  opt.empty_lines = -1
  opt.format_only = 0
  opt.indent_sz = -1
  opt.spacing = -1
  opt.infile$ = ""
  opt.outfile$ = ""
End Sub

' Sets the value for an option.
'
' If name$ or value$ are invalid then sets sys.err$.
Sub opt.set(name$, value$)
  Select Case LCase$(name$)
    Case "colour"      : opt.set_colour(value$)
    Case "comments"    : opt.set_comments(value$)
    Case "empty-lines" : opt.set_empty_lines(value$)
    Case "format-only" : opt.set_format_only(value$)
    Case "indent"      : opt.set_indent_sz(value$)
    Case "no-comments" : opt.set_no_comments(value$)
    Case "spacing"     : opt.set_spacing(value$)
    Case "infile"      : opt.set_infile(value$)
    Case "outfile"     : opt.set_outfile(value$)
    Case Else
      sys.err$ = "unknown option: " + name$
  End Select
End Sub

Sub opt.set_colour(value$)
  Select Case LCase$(value$)
    Case "default", "off", "0", "" : opt.colour = 0
    Case "on", "1"                 : opt.colour = 1
    Case Else
      sys.err$ = "expects 'on|off' argument"
  End Select
End Sub

Sub opt.set_comments(value$)
  Select Case LCase$(value$)
    Case "preserve", "default", "on", "-1", "" : opt.comments = -1
    Case "none", "omit", "off", "0"            : opt.comments = 0
    Case Else
      sys.err$ = "expects 'on|off' argument"
  End Select
End Sub

Sub opt.set_empty_lines(value$)
  Select Case LCase$(value$)
    Case "preserve", "default", "on", "-1", "" : opt.empty_lines = -1
    Case "none", "omit", "off", "0"            : opt.empty_lines = 0
    Case "single", "1"                         : opt.empty_lines = 1
    Case Else
      sys.err$ = "expects 'on|off|single' argument"
  End Select
End Sub

Sub opt.set_format_only(value$)
  Select Case LCase$(value$)
    Case "default", "off", "0", "" : opt.format_only = 0
    Case "on", "1"                 : opt.format_only = 1
    Case Else                      : sys.err$ = "expects 'on|off' argument"
  End Select
End Sub

Sub opt.set_indent_sz(value$)
  Select Case LCase$(value$)
    Case "preserve", "default", "on", "-1", "" : opt.indent_sz = -1
    Case Else
      If Str$(Val(value$)) = value$ And Val(value$) >= 0 Then
        opt.indent_sz = Val(value$)
      Else
        sys.err$= "expects 'on|<number>' argument"
      EndIf
    End Select
  End Select
End Sub

Sub opt.set_no_comments(value$)
  Select Case LCase$(value$)
    Case "default", "off", "0", "" : opt.comments = -1
    Case "on", "1"                 : opt.comments = 0
    Case Else                      : sys.err$ = "expects 'on|off' argument"
  End Select
End Sub

Sub opt.set_spacing(value$)
  Select Case LCase$(value$)
    Case "preserve", "default", "on", "-1", "" : opt.spacing = -1
    Case "minimal", "off", "omit", "0"         : opt.spacing = 0
    Case "compact", "1"                        : opt.spacing = 1
    Case "generous", "2"                       : opt.spacing = 2
    Case Else
      sys.err$ = "expects 'on|minimal|compact|generous' argument"
  End Select
End Sub

Sub opt.set_infile(value$)
  opt.infile$ = value$
End Sub

Sub opt.set_outfile(value$)
  opt.outfile$ = value$
End Sub
