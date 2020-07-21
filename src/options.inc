' Copyright (c) 2020 Thomas Hugo Williams

Dim op_colour       '  0    : no syntax colouring of console output
                    '  1    : VT100 syntax colouring of console output
Dim op_comments     ' -1    : preserve comments
                    '  0    : omit all comments
                    '  1    : insert additional comments from transpiler
Dim op_empty_lines  ' -1    : preserve empty lines
                    '  0    : omit all empty lines
                    '  1    : include empty line between each Function/Sub
Dim op_format_only  '  0    : transpile
                    '  1    : just format / pretty-print
Dim op_indent_sz    ' -1    : preserve indenting
                    '  0..N : automatically indent by N spaces per level
Dim op_spacing      ' -1    : preserve spacing
                    '  0    : omit all unnecessary (non-indent) spaces
                    '  1    : space compactly
                    '  2    : space generously

Sub op_init()
  op_colour = 0
  op_comments = -1
  op_empty_lines = -1
  op_format_only = 0
  op_indent_sz = -1
  op_spacing = -1
End Sub

' Sets the value for an option.
'
' If name$ or value$ are invalid then sets err$.
Sub op_set(name$, value$)
  Local n$ = LCase$(name$)
  Local v$ = LCase$(value$)

  Select Case n$
    Case "colour"      : op_set_colour(v$)
    Case "comments"    : op_set_comments(v$)
    Case "empty-lines" : op_set_empty_lines(v$)
    Case "format-only" : op_set_format_only(v$)
    Case "indent"      : op_set_indent_sz(v$)
    Case "spacing"     : op_set_spacing(v$)
    Case Else
      err$ = "unknown option: " + name$
  End Select
End Sub

Sub op_set_colour(value$)
  Select Case value$
    Case "default", "off", "0", "" : op_colour = 0
    Case "on", "1"                 : op_colour = 1
    Case Else
      err$ = "expects 'on|off' argument"
  End Select
End Sub

Sub op_set_comments(value$)
  Select Case value$
    Case "preserve", "default", "on", "-1", "" : op_comments = -1
    Case "none", "omit", "off", "0"            : op_comments = 0
    Case "extra", "1"                          : op_comments = 1
    Case Else
      err$ = "expects 'preserve|none|extra' argument"
  End Select
End Sub

Sub op_set_empty_lines(value$)
  Select Case value$
    Case "preserve", "default", "on", "-1", "" : op_empty_lines = -1
    Case "none", "omit", "off", "0"            : op_empty_lines = 0
    Case "single", "1"                         : op_empty_lines = 1
    Case Else
      err$ = "expects 'preserve|none|single' argument"
  End Select
End Sub

Sub op_set_format_only(value$)
  Select Case value$
    Case "default", "off", "0", "" : op_format_only = 0
    Case "on", "1"                 : op_format_only = 1
    Case Else                      : err$ = "expects 'on|off' argument"
  End Select
End Sub

Sub op_set_indent_sz(value$)
  Select Case value$
    Case "preserve", "default", "on", "-1", "" : op_indent_sz = -1
    Case Else
      If Str$(Val(value$)) = value$ And Val(value$) >= 0 Then
        op_indent_sz = Val(value$)
      Else
        err$= "expects 'preserve|<number>' argument"
      EndIf
    End Select
  End Select
End Sub

Sub op_set_spacing(value$)
  Select Case value$
    Case "preserve", "default", "on", "-1", "" : op_spacing = -1
    Case "minimal", "off", "omit", "0"         : op_spacing = 0
    Case "compact", "1"                        : op_spacing = 1
    Case "generous", "2"                       : op_spacing = 2
    Case Else
      err$ = "expects 'preserve|minimal|compact|generous' argument"
  End Select
End Sub
