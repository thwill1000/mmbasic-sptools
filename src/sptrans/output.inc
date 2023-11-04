' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("lexer", "options")
sys.provides("output")
If sys.err$ <> "" Then Error sys.err$
'!endif

Dim TK_COLOUR$(8) Length 12
TK_COLOUR$(TK_IDENTIFIER) = vt100.colour$("white")
TK_COLOUR$(TK_NUMBER)     = vt100.colour$("green")
TK_COLOUR$(TK_COMMENT)    = vt100.colour$("yellow")
TK_COLOUR$(TK_STRING)     = vt100.colour$("magenta")
TK_COLOUR$(TK_KEYWORD)    = vt100.colour$("cyan")
TK_COLOUR$(TK_SYMBOL)     = vt100.colour$("white")
TK_COLOUR$(TK_DIRECTIVE)  = vt100.colour$("red")
TK_COLOUR$(TK_LABEL)      = vt100.colour$("green")

Dim out.append%
Dim out.eol$ = Chr$(10)
Dim out.empty_line_flag% ' Last non-omitted line was empty.
Dim out.file_num%
Dim out.line_num%
Dim out.line_num_width% = 5
Dim out.omitted_line_flag% ' Last line was omitted.
Dim out.within_csub%
Dim out.write_cb$ = "out.default_cb"

Sub out.default_cb(fnbr%, s$)
  Print #fnbr%, s$;
End Sub

Sub out.open(f$)
  If f$ <> "" Then
    out.file_num% = 10
    Open f$ For Output As #out.file_num%
  EndIf
End Sub

Sub out.close()
  If out.file_num% > 0 Then Close #out.file_num%
  out.file_num% = 0
End Sub

Sub out.write(s$)
  If out.append% Then
    Call out.write_cb$, out.file_num%, s$
    If Right$(s$, Len(out.eol$)) = out.eol$ Then out.append% = 0
  Else
    Inc out.line_num%
    out.append% = 1
    If out.line_num_width% Then out.write(str.rpad$(Str$(out.line_num%), out.line_num_width%) + " ")
    out.write(s$)
  EndIf
End Sub

Sub out.line()
  If lx.num% = 0 Then
    out.empty_line()
  Else
    If opt.colour% Then out.highlight() Else out.write(lx.line$ + out.eol$)
    out.empty_line_flag% = 0
    out.omitted_line_flag% = 0
  EndIf
End Sub

Sub out.highlight()
  Local col$, i%, n% = lx.start%(0) - 1
  For i% = 0 To lx.num% - 1
    ' Record entry and exit from CSUB definition.
    If InStr("|cfunction|csub|", "|" + lx.token_lc$(i%) + "|") Then out.within_csub% = Not out.within_csub%
    out.write(Space$(n%))
    col$ = out.colour$(i%)
    out.write(col$ + lx.token$(i%))
    n% = lx.start%(i% + 1) - lx.start%(i%) - lx.len%(i%)
  Next
  out.write(vt100.colour$("reset") + out.eol$)
End Sub

' Gets the syntax highlighting colour to use for token 'i%'.
Function out.colour$(i%)
  out.colour$ = TK_COLOUR$(lx.type(i%))

  ' Special handling to highlight the non-standard hex data within CSUBs as if it were numbers.
  If Not out.within_csub% Then Exit Function
  If Not lx.type%(i%) = TK_IDENTIFIER Then Exit Function
  Local t$ = lx.token$(i%)
  Local j%
  For j% = 1 To Len(t$)
    If Not InStr(".0123456789ABCDEFabcdef", Mid$(t$, j%, 1)) Then Exit Function
  Next
  If i% = 0 Then
    out.colour$ = TK_COLOUR$(TK_NUMBER)
  ElseIf Not InStr("|cfunction|csub|", "|" + lx.token_lc$(i - 1) + "|") Then
    out.colour$ = TK_COLOUR$(TK_NUMBER)
  EndIf
End Function

Sub out.omit_line()
  out.omitted_line_flag% = 1
End Sub

Sub out.empty_line()
  If out.line_num% = 0 Then Exit Sub
  If out.omitted_line_flag% And out.empty_line_flag% Then Exit Sub
  out.write(out.eol$)
  out.empty_line_flag% = 1
  out.omitted_line_flag% = 0
End Sub
