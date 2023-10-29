' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("keywords", "lexer", "output")
sys.provides("highlight")
If sys.err$ <> "" Then Error sys.err$
'!endif

Dim TK_COLOUR$(8)
TK_COLOUR$(TK_IDENTIFIER) = vt100.colour$("white")
TK_COLOUR$(TK_NUMBER)     = vt100.colour$("green")
TK_COLOUR$(TK_COMMENT)    = vt100.colour$("yellow")
TK_COLOUR$(TK_STRING)     = vt100.colour$("magenta")
TK_COLOUR$(TK_KEYWORD)    = vt100.colour$("cyan")
TK_COLOUR$(TK_SYMBOL)     = vt100.colour$("white")
TK_COLOUR$(TK_DIRECTIVE)  = vt100.colour$("red")
TK_COLOUR$(TK_LABEL)      = vt100.colour$("green")

Dim hil.within_csub% = 0

Sub hil.highlight()
  If lx.num% = 0 Then out.println() : Exit Sub
  Local col$, i%, n% = lx.start%(0) - 1
  For i% = 0 To lx.num% - 1
    ' Record entry and exit from CSUB definition.
    If InStr("|cfunction|csub|", "|" + lx.token_lc$(i%) + "|") Then hil.within_csub% = Not hil.within_csub%
    out.print(Space$(n%))
    col$ = hil.colour$(i%)
    out.print(col$ + lx.token$(i%))
    n% = lx.start%(i% + 1) - lx.start%(i%) - lx.len%(i%)
  Next
  out.println(vt100.colour$("reset"))
End Sub

' Gets the syntax highlighting colour to use for token 'i%'.
Function hil.colour$(i%)
  hil.colour$ = TK_COLOUR$(lx.type(i%))

  ' Special handling to highlight the non-standard hex data within CSUBs as if it were numbers.
  If Not hil.within_csub% Then Exit Function
  If Not lx.type%(i%) = TK_IDENTIFIER Then Exit Function
  Local t$ = lx.token$(i%)
  Local j%
  For j% = 1 To Len(t$)
    If Not InStr(".0123456789ABCDEFabcdef", Mid$(t$, j%, 1)) Then Exit Function
  Next
  If i% = 0 Then
    hil.colour$ = TK_COLOUR$(TK_NUMBER)
  ElseIf Not InStr("|cfunction|csub|", "|" + lx.token_lc$(i - 1) + "|") Then
    hil.colour$ = TK_COLOUR$(TK_NUMBER)
  EndIf
End Function
