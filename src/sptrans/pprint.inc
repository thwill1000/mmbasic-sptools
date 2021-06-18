' Copyright (c) 2020-2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("keywords", "lexer", "options", "output")
sys.provides("pprint")
If sys.err$ <> "" Then Error sys.err$

Dim TK_COLOUR$(7)
TK_COLOUR$(TK_IDENTIFIER) = vt100.colour$("white")
TK_COLOUR$(TK_NUMBER)     = vt100.colour$("green")
TK_COLOUR$(TK_COMMENT)    = vt100.colour$("yellow")
TK_COLOUR$(TK_STRING)     = vt100.colour$("magenta")
TK_COLOUR$(TK_KEYWORD)    = vt100.colour$("cyan")
TK_COLOUR$(TK_SYMBOL)     = vt100.colour$("white")
TK_COLOUR$(TK_DIRECTIVE)  = vt100.colour$("red")

Dim pp.previous = 0 ' 0 : previous line was empty
                    ' 1 : previous line was comment
                    ' 2 : previous line had content
Dim pp.indent_lvl

Sub pp.print_line()
  Local i, t$, u$

  ' If excluding comments then remove any trailing comment on the line.
  ' TODO: should this be responsibility of transpile step not pretty-printing?
  If opt.comments = 0 Then
    If lx.num >= 1 Then
      If lx.type(lx.num - 1) = TK_COMMENT Then
        lx.type(lx.num - 1) = 0
        Inc lx.num, -1
      EndIf
    EndIf
  EndIf

  ' Ignore empty lines if the 'empty-lines' option is set or the previous line
  ' was empty.
  If (opt.empty_lines > -1 Or pp.previous = 0) And lx.num = 0 Then Exit Sub

  ' Nothing more to do for empty lines.
  If lx.num = 0 Then pp.previous = 0 : out.endl() : Exit Sub

  For i = 0 To lx.num - 1

    t$ = " " + lx.token_lc$(i) + " "

    ' If the 'empty-lines' option is 'single|1' and previous printed line
    ' had content and the line starts with {Function|Sub} then print empty line.
    If opt.empty_lines = 1 And pp.previous = 2 Then
      If i = 0 And Instr(" sub function ", t$) > 0 Then out.endl()
    EndIf

    ' Tokens requiring us to decrease the indent level before printing them.
    If Instr(" end ", t$) Then
      If Instr(" select sub function ", " " + lx.token_lc$(i + 1) + " ") Then
        pp.indent_lvl = pp.indent_lvl - 1
        If lx.token_lc$(i + 1) = "select" Then pp.indent_lvl = pp.indent_lvl - 1
      EndIf
    ElseIf Instr(" else elseif endif loop next ", t$) > 0 Then
      pp.indent_lvl = pp.indent_lvl - 1
    ElseIf t$ = " case " Then
      u$ = Choice(i > 0, lx.token_lc$(i - 1), "")
      If u$ <> "select" Then pp.indent_lvl = pp.indent_lvl - 1
    EndIf

    ' Indent the first token.
    If i = 0 Then
      If opt.indent_sz = -1 Then
        ' Use existing indentation.
        out.print(Space$(lx.start(0) - 1))
      ElseIf lx.type(0) = TK_COMMENT And (opt.spacing = -1 Or opt.spacing = 2) Then
        ' Use existing indentation.
        out.print(Space$(lx.start(0) - 1))
      ElseIf pp.indent_lvl > 0 Then
        ' Use automatic indentation.
        out.print(Space$(pp.indent_lvl * opt.indent_sz))
      EndIf
    EndIf

    ' Output the token with a trailing space where required.
    If opt.colour Then out.print(TK_COLOUR$(lx.type(i)))
    u$ = lx.token$(i)
    If lx.type(i) = TK_KEYWORD Then
      Select Case opt.keywords
        Case  0 : u$ = LCase$(keywords.get$(u$))
        Case  1 : u$ = keywords.get$(u$)
        Case  2 : u$ = UCase$(keywords.get$(u$))
      End Select
      If u$ = sys.NO_DATA$ Then Error
    EndIf
    out.print(u$ + Space$(pp.num_spaces(i)))

    ' Tokens requiring us to increase the indent level after printing them.
    u$ = Choice(i > 0, " " + lx.token_lc$(i - 1) + " ", "")
    If InStr(" continue end exit ", u$) <= 0 Then
      If t$ = " do " Then
        pp.indent_lvl = pp.indent_lvl + 1

      ElseIf t$ = " for " Then
        u$ = " " + lx.token_lc$(i + 1) + " "
        If Instr(" input output random ", u$) <= 0 Then pp.indent_lvl = pp.indent_lvl + 1

      ElseIf t$ = " else " Then
        u$ = lx.token_lc$(i + 1)
        If u$ <> "if" Then pp.indent_lvl = pp.indent_lvl + 1

      ElseIf Instr(" case function select sub ", t$) Then
          pp.indent_lvl = pp.indent_lvl + 1

      ElseIf t$ = " then " Then
        u$ = Choice(i < lx.num - 1, lx.token_lc$(i + 1), "")
        If u$ = "" Or Left$(u$, 1) = "'" Then pp.indent_lvl = pp.indent_lvl + 1

      EndIf
    EndIf

  Next i

  If opt.colour Then out.print(vt100.colour$("reset"))
  out.endl()
  If lx.type(0) = TK_COMMENT Then pp.previous = 1 Else pp.previous = 2

  ' If the 'empty-lines' option is 'single|1' and the line ends with
  ' End {Function|Sub} then print one.
  If opt.empty_lines = 1 Then
    If Instr(" function sub ", t$) > 0 Then
      u$ = lx.token_lc$(lx.num - 2)
      If u$ = "end" Then out.endl() : pp.previous = 0
    EndIf
  EndIf

  ' "Fix" the indent level if it goes badly wrong.
  If pp.indent_lvl < 0 Then pp.indent_lvl = 0

End Sub

' How many spaces should follow token 'i' ?
Function pp.num_spaces(i)

  ' Never need a space after the last token.
  If i >= lx.num - 1 Then Exit Function

  ' Preserve existing spaces before a comment or if opt.spacing = -1,
  If (opt.spacing = -1) Or (lx.type(i + 1) = TK_COMMENT) Then
    pp.num_spaces = lx.start(i + 1) - lx.start(i) - lx.len(i)
    Exit Function
  EndIf

  Local t$ = lx.token_lc$(i)
  Local u$ = lx.token_lc$(i + 1)

  ' Never need a space before a comma, semi-colon or closing bracket,
  ' except after a comma.
  If InStr(",;)", u$) Then
    If t$ <> "," Then Exit Function
  EndIf

  ' Never need a space after an opening bracket.
  If t$ = "(" Then Exit Function

  ' Rules applying to 'generous' spacing.
  If opt.spacing >= 2 Then
    ' Don't need a space before an opening bracket
    ' unless preceeded by a symbol or one of these keywords:
    If u$ = "(" Then
      If lx.type(i) <> TK_SYMBOL Then
        If Not InStr(" and elseif if or step until ", " " + t$ + " ") Then Exit Function
      EndIf
    EndIf

    ' Do not add a space after +/- in many cases.
    If InStr("+-", t$) Then
      If lx.num > 1 Then
        If InStr(" , = ( < > <> step ", " " + LCase$(lx.token$(i - 1)) + " ") Then Exit Function
      EndIf
    EndIf

    ' Need a space before/after any symbol.
    If lx.type(i) = TK_SYMBOL Then pp.num_spaces = 1 : Exit Function
    If lx.type(i + 1) = TK_SYMBOL Then pp.num_spaces = 1 : Exit Function
  EndIf

  ' Rules applying to 'compact' spacing.
  If opt.spacing >= 1 Then
    ' Need a space between a keyword/identifier and string.
    If lx.type(i) = TK_KEYWORD Or lx.type(i) = TK_IDENTIFIER Then
      If lx.type(i + 1) = TK_STRING Then pp.num_spaces = 1 : Exit Function
    EndIf

    ' Need a space before a comment.
    If lx.type(i + 1) = TK_COMMENT Then pp.num_spaces = 1 : Exit Function

    ' Need a space after a string unless followed by a symbol.
    If lx.type(i) = TK_STRING Then
      If lx.type(i + 1) <> TK_SYMBOL Then pp.num_spaces = 1 : Exit Function
    EndIf

    ' Space after a closing bracket unless followed by a symbol.
    If lx.token$(i) = ")" Then
      If lx.type(i + 1) <> TK_SYMBOL Then pp.num_spaces = 1 : Exit Function
    EndIf

    ' Need a space before a ':'
    If u$ = ":" Then pp.num_spaces = 1 : Exit Function

    ' Need a space after these:
    If InStr(" and elseif if or step until : ", " " + t$ + " ") Then pp.num_spaces = 1 : Exit Function
  EndIf

  ' Rules applying to minimal spacing
  Select Case lx.type(i)
    Case TK_KEYWORD, TK_IDENTIFIER, TK_NUMBER, TK_DIRECTIVE
      Select Case lx.type(i + 1)
        Case TK_KEYWORD, TK_IDENTIFIER, TK_NUMBER
          pp.num_spaces = 1
      End Select
  End Select
End Function
