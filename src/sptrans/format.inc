' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("keywords", "lexer", "options")
sys.provides("format")
If sys.err$ <> "" Then Error sys.err$
'!endif

Const fmt.LINE_NUM_WIDTH = 6 ' TODO: control with option.
Const fmt.OMIT_LINE = 2
Const fmt.EMPTY_LINE_BEFORE = 3
Const fmt.EMPTY_LINE_AFTER = 4

Dim fmt.previous% = 0 ' 0 : previous line was empty
                      ' 1 : previous line was comment
                      ' 2 : previous line had content
Dim fmt.indent_lvl%

' Formats the current line according to the formatting options.
'
' @return  sys.FAILURE            on error, see 'sys.err$' for details.
'          sys.SUCCESS            if the current line should be included
'                                 the output.
'          fmt.OMIT_LINE          if the current line should be omitted from
'                                 the output.
'          fmt.EMPTY_LINE_BEFORE  if the current line should be preceeded by a
'                                 new empty line in the output.
'          fmt.EMPTY_LINE_AFTER   if the current line should be folowed by a
'                                 new empty line in the output.
Function fmt.format%()
  If Not lx.num% Then
    If opt.empty_lines% > -1 Then
      fmt.format% = fmt.OMIT_LINE
    Else
      fmt.previous% = 0
    EndIf
    Exit Function
  EndIf

  Local i%, indent%, t$, u$

  For i% = 0 To lx.num% - 1

    If opt.comments% = 0 Then
      ' Remove comments.
      If lx.type%(i%) = TK_COMMENT Then
        lx.remove_token(i%)
        If lx.num = 0 Then
          fmt.format% = fmt.OMIT_LINE
          Exit Function
        EndIf
        Continue For
      EndIf
    EndIf

    t$ = "|" + lx.token_lc$(i) + "|"

    ' Tokens requiring us to decrease the indent level before.
    If Instr("|end|", t$) Then
      u$ = "|" + lx.token_lc$(i + 1) + "|"
      If Instr("|csub|sub|function|", u$) Then
        Inc fmt.indent_lvl%, -1
      ElseIf Instr("|select|", u$) Then
        Inc fmt.indent_lvl%, -2
      EndIf
    ElseIf Instr("|else|elseif|endif|loop|next|", t$) Then
      Inc fmt.indent_lvl%, -1
    ElseIf t$ = "|case|" Then
      If Choice(i%, lx.token_lc$(i% - 1), "") <> "select" Then Inc fmt.indent_lvl%, -1
    EndIf

    ' Keyword capitalisation.
    If opt.keywords% >= 0 Then
      If lx.type(i%) = TK_KEYWORD Then
        u$ = lx.token$(i%)
        Select Case opt.keywords%
          Case 0: u$ = LCase$(keywords.get$(u$))
          Case 1: u$ = keywords.get$(u$)
          Case 2: u$ = UCase$(keywords.get$(u$))
        End Select
        If u$ = sys.NO_DATA$ Then Error
        lx.replace_token(i%, u$, TK_KEYWORD)
      EndIf
    EndIf

    ' Token spacing.
    fmt.format% = lx.set_space_before%(i%, fmt.num_spaces%(i%))
    If fmt.format% < 0 Then Exit Function

    ' Tokens requiring us to increase the indent level after.
    u$ = Choice(i > 0, "|" + lx.token_lc$(i - 1) + "|", "")
    If Not InStr("|continue|end|exit|", u$) Then
      If t$ = "|do|" Then
        Inc fmt.indent_lvl%
      ElseIf t$ = "|for|" Then
        u$ = "|" + lx.token_lc$(i + 1) + "|"
        If Instr("|input|output|random|", u$) <= 0 Then Inc fmt.indent_lvl%
      ElseIf t$ = "|else|" Then
        If lx.token_lc$(i + 1) <> "if" Then Inc fmt.indent_lvl%
      ElseIf Instr("|case|csub|function|select|sub|", t$) Then
        Inc fmt.indent_lvl%
      ElseIf t$ = "|then|" Then
        u$ = Choice(i < lx.num - 1, lx.token_lc$(i + 1), "")
        If u$ = "" Or Left$(u$, 1) = "'" Then Inc fmt.indent_lvl%
      EndIf
    EndIf

  Next ' iteration over tokens.

  ' Remove trailing whitespace.
  If lx.num% Then
    fmt.format% = lx.set_space_after%(lx.num% - 1, 0)
    If fmt.format% < 0 Then Exit Function
  EndIf

  ' "Fix" the indent level if it goes badly wrong.
  If fmt.indent_lvl% < 0 Then fmt.indent_lvl% = 0

  ' If the 'empty-lines' option is 'single|1' and previous printed line
  ' had content and the line starts with {Function|Sub} then insert empty line.
  If opt.empty_lines% = 1 And fmt.previous% = 2 Then
    If Instr("|cfunction|csub|sub|function|", "|" + lx.token_lc$(0) + "|") Then
      fmt.format% = fmt.EMPTY_LINE_BEFORE
    EndIf
  EndIf

  fmt.previous% = Choice(lx.type%(0) = TK_COMMENT, 1, 2)

  ' If the 'empty-lines' option is 'single|1' and the line ends with
  ' End {Function|Sub} then print one.
  If opt.empty_lines% = 1 Then
    If Instr("|cfunction|csub|function|sub|", "|" + lx.token_lc$(lx.num% - 1) + "|") Then
      If lx.token_lc$(lx.num% - 2) = "end" Then
        fmt.format% = fmt.EMPTY_LINE_AFTER
        fmt.previous% = 0
      EndIf
    EndIf
  EndIf
End Function

' How many spaces should be before token 'i%' ?
Function fmt.num_spaces%(i%)
  Local n% = -99

  Select Case i%
    Case 0
      If lx.type(0) = TK_NUMBER Then
        n% = fmt.LINE_NUM_WIDTH - Len(lx.token$(0))
      Else
        n% = fmt.num_spaces_indent%(0)
      EndIf
    Case 1
      If lx.type(0) = TK_NUMBER Then n% = fmt.num_spaces_indent%(1)
  End Select

  If n% = -99 Then
    Select Case opt.spacing%
      Case -1: n% = lx.start(i%) - lx.start(i% - 1) - lx.len(i% - 1)
      Case 0:  n% = fmt.num_spaces_minimal%(i%)
      Case 1:  n% = fmt.num_spaces_compact%(i%)
      Case 2:  n% = fmt.num_spaces_generous%(i%)
    End Select
  EndIf

  fmt.num_spaces% = Max(n%, 0)
End Function

' How many spaces should token 'i%' be indented by ?
Function fmt.num_spaces_indent%(i%)
  Local n%
  If opt.indent_sz% = -1 Then
    ' Use existing indentation.
    n% = lx.start%(i%) - Choice(i%, fmt.LINE_NUM_WIDTH, 1)
  ElseIf lx.type(i%) = TK_LABEL Then
    ' Use no indentation.
    n% = 0
  ElseIf lx.type%(i%) = TK_COMMENT And (opt.spacing% = -1 Or opt.spacing% = 2) Then
    ' Use existing indentation.
    n% = lx.start%(i%) - Choice(i%, fmt.LINE_NUM_WIDTH, 1)
  ElseIf fmt.indent_lvl% > 0 Then
    ' Use automatic indentation.
    n% = fmt.indent_lvl% * opt.indent_sz%
  EndIf
  If lx.type%(0) = TK_NUMBER Then Inc n%
  fmt.num_spaces_indent% = Max(0, n%)
End Function

Function fmt.num_spaces_minimal%(i%)
  Local n%
  Select Case lx.type(i%)
    Case TK_COMMENT
      n% = lx.start(i%) - lx.start(i% - 1) - lx.len(i% - 1)
    Case TK_IDENTIFIER, TK_KEYWORD, TK_NUMBER
      Select Case lx.type(i% - 1)
        Case TK_STRING, TK_SYMBOL
          n% = 0
        Case Else
          n% = 1
      End Select
    Case TK_STRING
      Select Case lx.type%(i% - 1)
        Case TK_IDENTIFIER, TK_SYMBOL
          n% = 0
        Case Else
          n% = 1
      End Select
    Case TK_SYMBOL
      If lx.token$(i%) = "?" Then
        n% = 1
      Else
        n% = InStr("|is|step|", "|" + lx.token_lc$(i% - 1) + "|") > 0
      EndIf
  End Select
  fmt.num_spaces_minimal% = n%
End Function

Function fmt.num_spaces_compact%(i%)
  Local n%
  Select Case lx.type(i%)
    Case TK_COMMENT
      n% = Max(lx.start(i%) - lx.start(i% - 1) - lx.len(i% - 1), 1)
    Case TK_IDENTIFIER, TK_NUMBER
      Select Case lx.type(i% - 1)
        Case TK_SYMBOL
          n% = InStr(":)", lx.token$(i% - 1)) > 0
        Case Else
          n% = 1
      End Select
    Case TK_KEYWORD
      n% = Not InStr("(?-+,*=<=>=<>\/;", lx.token$(i - 1))
    Case TK_STRING
      Select Case lx.type%(i% - 1)
        Case TK_SYMBOL
          n% = lx.token$(i% - 1) = ")"
        Case Else
          n% = 1
      End Select
    Case TK_SYMBOL
      Select Case lx.token$(i%)
        Case ":", "?"
          n% = 1
        Case "("
          Select Case lx.type(i% - 1)
            Case TK_IDENTIFIER, TK_SYMBOL
              n% = 0
            Case TK_KEYWORD
              n% = InStr("|and|elseif|if|or|step|until|", "|" + lx.token_lc$(i% - 1) + "|") > 0
            Case Else
              n% = 1
          End Select
        Case Else
          n% = InStr("|case|is|step|", "|" + lx.token_lc$(i% - 1) + "|") > 0
      End Select
  End Select
  fmt.num_spaces_compact% = n%
End Function

Function fmt.num_spaces_generous%(i%)
  Local n% = 1
  Select Case lx.type(i%)
    Case TK_COMMENT
      n% = Max(lx.start(i%) - lx.start(i% - 1) - lx.len(i% - 1), 1)
    Case TK_IDENTIFIER, TK_NUMBER
      Select Case lx.token$(i% - 1)
        Case "("
          n% = 0
        Case "-", "+"
          n% = Not InStr("|step|,|(|<|<=|=<|<>|=>|>=|>|=|", "|" + lx.token_lc$(i% - 2) + "|")
      End Select
    Case TK_KEYWORD
      n% = lx.token$(i% - 1) <> "("
    Case TK_STRING
      n% = lx.token$(i% - 1) <> "("
    Case TK_SYMBOL
      Select Case lx.token$(i%)
        Case ";"
          n% = 0
        Case "-", "+"
          n% = Not InStr("(", lx.token$(i% - 1))
        Case "(", ")", ","
          Select Case lx.type(i% - 1)
            Case TK_KEYWORD
              n% = InStr("|and|elseif|if|or|step|until|", "|" + lx.token_lc$(i% - 1) + "|") > 0
            Case TK_SYMBOL
              n% = Not InStr("()", lx.token_lc$(i% - 1))
            Case Else
              n% = 0
          End Select
      End Select
  End Select
  fmt.num_spaces_generous% = n%
End Function
