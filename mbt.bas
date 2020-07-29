' Transpiled on 29-07-2020 23:35:31

' Copyright (c) 2020 Thomas Hugo Williams
'
' Settings for building an optimised CMM2 version of 'mbt'

' PROCESSED: !set TARGET_CMM2

' BEGIN:     #Include "constants.mbt" ------------------------------------------
' Copyright (c) 2020 Thomas Hugo Williams
'
' Constant values to inline

' PROCESSED: !set INLINE_CONSTANTS

' From "lexer.inc"
' PROCESSED: !replace TK_IDENTIFIER  1
' PROCESSED: !replace TK_NUMBER      2
' PROCESSED: !replace TK_COMMENT     3
' PROCESSED: !replace TK_STRING      4
' PROCESSED: !replace TK_KEYWORD     5
' PROCESSED: !replace TK_SYMBOL      6
' PROCESSED: !replace TK_DIRECTIVE   7
' PROCESSED: !replace TK_OPTION      8
' END:       #Include "constants.mbt" ------------------------------------------
' BEGIN:     #Include "main.bas" -----------------------------------------------
' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Const INSTALL_DIR$ = "\mbt"
Const RESOURCES_DIR$ = INSTALL_DIR$ + "\resources"

' BEGIN:     #Include "lexer.inc" ----------------------------------------------
' Copyright (c) 2020 Thomas Hugo Williams

' PROCESSED: !comment_if INLINE_CONSTANTS
' Const TK_IDENTIFIER = 1
' Const TK_NUMBER = 2
' Const TK_COMMENT = 3
' Const TK_STRING = 4
' Const TK_KEYWORD = 5
' Const TK_SYMBOL = 6
' Const TK_DIRECTIVE = 7
' Const TK_OPTION = 8
' PROCESSED: !endif

Const LX_MAX_KEYWORDS = 1000
Dim lx_keywords$(LX_MAX_KEYWORDS - 1) Length 20
Dim lx_keywords_sz = 0
set_init(lx_keywords$(), LX_MAX_KEYWORDS)

Const LX_MAX_TOKENS = 100
Dim lx_type(LX_MAX_TOKENS - 1)
Dim lx_start(LX_MAX_TOKENS - 1)
Dim lx_len(LX_MAX_TOKENS - 1)

Dim lx_char$
Dim lx_line$
Dim lx_next_char$
Dim lx_num
Dim lx_pos

Sub lx_load_keywords(f$)
  Local i, s$

  Open f$ For Input As #1

  Do
    Line Input #1, s$
    If Len(s$) > 0 And Left$(s$, 1) <> "'" Then
      set_put(lx_keywords$(), lx_keywords_sz, LCase$(s$))
    EndIf
  Loop While Not Eof(#1)

  Close #1
End Sub

Sub lx_parse_basic(line$)
  lx_reset_globals(line$)
  lx_advance()

  Do While lx_char$ <> Chr$(10)
    If lx_char$ = " " Then
      lx_advance()
    ElseIf InStr("&.0123456789", lx_char$) Then
      lx_parse_number()
    ElseIf lx_char$ = "'" Then
      lx_parse_comment_or_directive()
    ElseIf lx_char$ = Chr$(34) Then
      lx_parse_string()
    ElseIf InStr("@#_abcdefghijklmnopqrstuvwxyz", lx_char$) Then
      lx_parse_keyword()
    Else
      lx_parse_symbol()
    EndIf

    If err$ <> "" Then Exit Do
  Loop
End Sub

Sub lx_reset_globals(line$)
  ' Clear old token data
  Do While lx_num > 0
    lx_num = lx_num - 1
    lx_type(lx_num) = 0
    lx_start(lx_num) = 0
    lx_len(lx_num) = 0
  Loop

  err$ = ""
  lx_line$ = line$
  lx_next_char$ = ""
  lx_pos = 0
End Sub

Sub lx_advance()
  lx_pos = lx_pos + 1
  If lx_next_char$ = "" Then
    If lx_pos > Len(lx_line$) Then
      lx_char$ = Chr$(10)
    Else
      lx_char$ = LCase$(Chr$(Peek(Var lx_line$, lx_pos)))
    EndIf
  Else
    lx_char$ = lx_next_char$
  EndIf
  If lx_pos + 1 > Len(lx_line$) Then
    lx_next_char$ = Chr$(10)
  Else
    lx_next_char$ = LCase$(Chr$(Peek(Var lx_line$, lx_pos + 1)))
  EndIf
End Sub

Sub lx_parse_number()
  If InStr(".0123456789", lx_char$) Then
    lx_parse_decimal()
  ElseIf lx_char$ = "&" Then
    If lx_next_char$ = "b"  Then
      lx_parse_binary()
    ElseIf lx_next_char$ = "h" Then
      lx_parse_hexadecimal()
    ElseIf lx_next_char$ = "o" Then
      lx_parse_octal()
    Else
      Then err$ = "Unknown literal type &" + lx_next_char$ : Exit Sub
    EndIf
  EndIf
End Sub

Sub lx_parse_decimal()
  Local start = lx_pos

  lx_advance_while("0123456789")

  If lx_char$ = "." Then
    lx_advance()
    lx_advance_while("0123456789")
  EndIf

  If lx_char$ = "e" Then
    lx_advance()
    If lx_char$ = "-" Or lx_char$ = "+" Then lx_advance()
    lx_advance_while("0123456789")
  EndIf

  lx_store(2, start, lx_pos - start)
End Sub

Sub lx_store(type, start, length)
  If length = 0 Then Error "Empty token"
  lx_type(lx_num) = type
  lx_start(lx_num) = start
  lx_len(lx_num) = length
  lx_num = lx_num + 1
End Sub

Sub lx_advance_while(allowed$)
  Do While InStr(allowed$, lx_char$) > 0 : lx_advance() : Loop
End Sub

Sub lx_parse_binary()
  Local start = lx_pos

  lx_advance()
  lx_advance()
  lx_advance_while("01")
  lx_store(2, start, lx_pos - start)
End Sub

Sub lx_parse_hexadecimal()
  Local start = lx_pos

  lx_advance()
  lx_advance()
  lx_advance_while("0123456789abcdefABCDEF")
  lx_store(2, start, lx_pos - start)
End Sub

Sub lx_parse_octal()
  Local start = lx_pos

  lx_advance()
  lx_advance()
  lx_advance_while("01234567")
  lx_store(2, start, lx_pos - start)
End Sub

Sub lx_parse_comment_or_directive()
  If lx_next_char$ = "!" Then
    lx_parse_directive()
  Else
    lx_parse_comment()
  EndIf
End Sub

Sub lx_parse_directive()
  Local start = lx_pos

  lx_advance()
  lx_advance()
  lx_advance_while("-_abcdefghijklmnopqrstuvwxyz0123456789")
  lx_store(7, start, lx_pos - start)
End Sub

Sub lx_parse_comment()
  lx_store(3, lx_pos, Len(lx_line$) - lx_pos + 1)
  lx_char$ = Chr$(10)
End Sub

Sub lx_parse_string()
  Local start = lx_pos

  lx_advance()
  lx_advance_until(Chr$(10) + Chr$(34))
  If lx_char$ = Chr$(10) Then err$ = "No closing quote" : Exit Sub
  lx_store(4, start, lx_pos - start + 1)
  lx_advance()
End Sub

Sub lx_advance_until(disallowed$)
  Do While Not InStr(disallowed$, lx_char$) > 0 : lx_advance() : Loop
End Sub

Sub lx_parse_keyword()
  Local start = lx_pos

  lx_advance()
  lx_advance_while("._abcdefghijklmnopqrstuvwxyz0123456789")
  If lx_char$ = "$" Then lx_advance()
  If lx_is_keyword(Mid$(lx_line$, start, lx_pos - start)) Then
    lx_store(5, start, lx_pos - start)
  Else
    lx_store(1, start, lx_pos - start)
  EndIf
End Sub

Function lx_is_keyword(t$)
  lx_is_keyword = set_get(lx_keywords$(), lx_keywords_sz, LCase$(t$)) > -1
End Function

Sub lx_parse_symbol()
  Local start = lx_pos

  If lx_char$ <> "<" And lx_char$ <> ">" And lx_char$ <> "=" Then
    lx_store(6, start, 1)
    lx_advance()
  Else
    lx_advance()
    If lx_char$ = "<" Or lx_char$ = ">" Or lx_char$ = "=" Then
      lx_store(6, start, 2)
      lx_advance()
    Else
      lx_store(6, start, 1)
    EndIf
  EndIf
End Sub

' Gets the text of token 'i'.
'
' If i > the number of tokens then returns the empty string.
Function lx_token$(i)
  If i < lx_num And lx_len(i) > 0 Then
    lx_token$ = Mid$(lx_line$, lx_start(i), lx_len(i))
  EndIf
End Function

' Gets the lower-case text of token 'i'.
'
' If i > the number of tokens then returns the empty string.
Function lx_token_lc$(i)
  lx_token_lc$ = LCase$(lx_token$(i))
End Function

' Gets the directive corresponding to token 'i' without the leading single quote.
'
' Throws an Error if token 'i' is not a directive.
Function lx_directive$(i)
  If lx_type(i) <> 7 Then Error "{" + lx_token$(i) + "} is not a directive"
  lx_directive$ = Mid$(lx_line$, lx_start(i) + 1, lx_len(i) - 1)
End Function

' Gets the string corresponding to token 'i' without the surrounding quotes.
'
' Throws an Error if token 'i' is not a string literal.
Function lx_string$(i)
  If lx_type(i) <> 4 Then Error "{" + lx_token$(i) + "} is not a string literal"
  lx_string$ = Mid$(lx_line$, lx_start(i) + 1, lx_len(i) - 2)
End Function

' Gets the number corresponding to token 'i'.
'
' Throws an Error if token 'i' is not a number literal.
Function lx_number(i) As Float
  If lx_type(i) <> 2 Then Error "{" + lx_token$(i) + "} is not a number literal"
  lx_number = Val(lx_token$(i))
End Function

' Performs simple space separator based tokenisation.
Sub lx_tokenise(line$)
  Local start = -1

  err$ = ""
  lx_line$ = line$
  lx_next_char$ = ""
  lx_num = 0
  lx_pos = 0
  lx_advance()

  Do While lx_char$ <> Chr$(10)
    If lx_char$ = " " Then
      If start > -1 Then
        lx_store(1, start, lx_pos - start)
        start = -1
      EndIf
    Else
      If start = -1 Then start = lx_pos
    EndIf
    lx_advance()
  Loop

  If start > -1 Then lx_store(1, start, lx_pos - start)
End Sub

Sub lx_parse_command_line(line$)
  lx_reset_globals(line$)
  lx_advance()

  Do While lx_char$ <> Chr$(10)
    If lx_char$ = " " Then
      lx_advance()
    ElseIf InStr("&.0123456789", lx_char$) Then
      lx_parse_number()
    ElseIf lx_char$ = "'" Then
      lx_parse_comment_or_directive()
    ElseIf lx_char$ = Chr$(34) Then
      lx_parse_string()
    ElseIf InStr("@#_abcdefghijklmnopqrstuvwxyz", lx_char$) Then
      lx_parse_keyword()
    ElseIf InStr("-/", lx_char$) Then
      lx_parse_option()
    Else
      lx_parse_symbol()
    EndIf

    If err$ <> "" Then Exit Do
  Loop
End Sub

Sub lx_parse_option()
  Local e = 0
  Local legal$ = "-_abcdefghijklmnopqrstuvwxyz0123456789"
  Local start = lx_pos

  If lx_char$ = "-" Then
    lx_advance()
    If lx_char$ = "-" Then lx_advance()
    If InStr(legal$, lx_char$) < 1 Then e = 1 Else lx_advance_while(legal$)
  ElseIf lx_char$ = "/" Then
    lx_advance()
    If InStr(legal$, lx_char$) < 1 Then e = 1 Else lx_advance_while(legal$)
  Else
    Error ' this should never happen
  EndIf

  If e = 1 Or InStr("= " + Chr$(10), lx_char$) < 1 Then
    If InStr("= " + Chr$(10), lx_char$) < 1 Then lx_advance()
    err$ = "Illegal command-line option format: " + Mid$(lx_line$, start, lx_pos - start)
    Exit Sub
  EndIf

  lx_store(8, start, lx_pos - start)
End Sub

' Gets the command-line option corresponding to token 'i'.
'
' Throws an Error if token 'i' is not a command-line option.
Function lx_option$(i)
  If lx_type(i) <> 8 Then Error "{" + lx_token$(i) + "} is not a command-line option"
  If Mid$(lx_line$, lx_start(i), 2) = "--" Then
    lx_option$ = Mid$(lx_line$, lx_start(i) + 2, lx_len(i) - 2)
  Else
    lx_option$ = Mid$(lx_line$, lx_start(i) + 1, lx_len(i) - 1)
  EndIf
End Function
' END:       #Include "lexer.inc" ----------------------------------------------
' BEGIN:     #Include "options.inc" --------------------------------------------
' Copyright (c) 2020 Thomas Hugo Williams

Dim op_colour       '  0    : no syntax colouring of console output
                    '  1    : VT100 syntax colouring of console output
Dim op_comments     ' -1    : preserve comments
                    '  0    : omit all comments
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
    Case "no-comments" : op_set_no_comments(v$)
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
    Case Else
      err$ = "expects 'on|off' argument"
  End Select
End Sub

Sub op_set_empty_lines(value$)
  Select Case value$
    Case "preserve", "default", "on", "-1", "" : op_empty_lines = -1
    Case "none", "omit", "off", "0"            : op_empty_lines = 0
    Case "single", "1"                         : op_empty_lines = 1
    Case Else
      err$ = "expects 'on|off|single' argument"
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
        err$= "expects 'on|<number>' argument"
      EndIf
    End Select
  End Select
End Sub

Sub op_set_no_comments(value$)
  Select Case value$
    Case "default", "off", "0", "" : op_comments = -1
    Case "on", "1"                 : op_comments = 0
    Case Else                      : err$ = "expects 'on|off' argument"
  End Select
End Sub

Sub op_set_spacing(value$)
  Select Case value$
    Case "preserve", "default", "on", "-1", "" : op_spacing = -1
    Case "minimal", "off", "omit", "0"         : op_spacing = 0
    Case "compact", "1"                        : op_spacing = 1
    Case "generous", "2"                       : op_spacing = 2
    Case Else
      err$ = "expects 'on|minimal|compact|generous' argument"
  End Select
End Sub
' END:       #Include "options.inc" --------------------------------------------
' BEGIN:     #Include "pprint.inc" ---------------------------------------------
' Copyright (c) 2020 Thomas Hugo Williams

Const VT100_RED = Chr$(27) + "[31m"
Const VT100_GREEN = Chr$(27) + "[32m"
Const VT100_YELLOW = Chr$(27) + "[33m"
Const VT100_BLUE = Chr$(27) + "[34m"
Const VT100_MAGENTA = Chr$(27) + "[35m"
Const VT100_CYAN = Chr$(27) + "[36m"
Const VT100_WHITE = Chr$(27) + "[37m"
Const VT100_RESET = Chr$(27) + "[0m"

Dim TK_COLOUR$(7)
TK_COLOUR$(1) = VT100_WHITE
TK_COLOUR$(2) = VT100_GREEN
TK_COLOUR$(3) = VT100_YELLOW
TK_COLOUR$(4) = VT100_MAGENTA
TK_COLOUR$(5) = VT100_CYAN
TK_COLOUR$(6) = VT100_WHITE
TK_COLOUR$(7) = VT100_RED

Dim pp_count
Dim pp_previous = 0 ' 0 : previous line was empty
                    ' 1 : previous line was comment
                    ' 2 : previous line had content
Dim pp_file_num = -1
Dim pp_indent_lvl

Sub pp_open(f$)
  If f$ <> "" Then
    pp_file_num = 10
    Open f$ For Output As #pp_file_num
  EndIf

  If op_format_only = 0 Then
    pp_inc_line()
    pp_attrib(TK_COLOUR$(3))
    pp_out("' Transpiled on " + DateTime$(Now)) : pp_endl()
    pp_attrib(VT100_RESET)
    pp_inc_line()
    pp_endl()
  EndIf
End Sub

Sub pp_close()
  If pp_file_num > -1 Then Close #pp_file_num
End Sub

Sub pp_inc_line()
  pp_count = pp_count + 1
  If pp_file_num = -1 Then
    pp_attrib(VT100_WHITE)
    pp_out(Format$(pp_count, "%-4g") + ": ")
  EndIf
End Sub

Sub pp_print_line()
  Local i, t$, u$

  ' Ignore empty lines if the 'empty-lines' option is set or the previous line
  ' was empty.
  If (op_empty_lines > -1 Or pp_previous = 0) And lx_num = 0 Then Exit Sub

  ' Ignore lines consisting solely of a comment if the 'comments' option is 0.
  If op_comments = 0 Then
    If lx_num = 1 Then
      If lx_type(0) = 3 Then Exit Sub
    EndIf
  EndIf

  pp_inc_line()

  ' Nothing more to do for empty lines.
  If lx_num = 0 Then pp_previous = 0 : pp_endl() : Exit Sub

  For i = 0 To lx_num - 1

    ' If we are not including comments and we reach a comment then don't process
    ' any further tokens ... there shouldn't be any.
    If op_comments = 0 Then
      If i = lx_num - 1 Then
        If lx_type(i) = 3 Then Exit For
      EndIf
    EndIf

    t$ = " " + lx_token_lc$(i) + " "

    ' If the 'empty-lines' option is 'single|1' and previous printed line
    ' had content and the line starts with {Function|Sub} then print empty line.
    If op_empty_lines = 1 And pp_previous = 2 Then
      If i = 0 And Instr(" sub function ", t$) > 0 Then pp_endl() : pp_inc_line()
    EndIf

    ' Tokens requiring us to decrease the indent level before printing them.
    If Instr(" end ", t$) Then
      If Instr(" select sub function ", " " + lx_token_lc$(i + 1) + " ") Then
        pp_indent_lvl = pp_indent_lvl - 1
        If lx_token_lc$(i + 1) = "select" Then pp_indent_lvl = pp_indent_lvl - 1
      EndIf
    ElseIf Instr(" case else elseif endif loop next exit ", t$) > 0 Then
      pp_indent_lvl = pp_indent_lvl - 1
    EndIf

    ' Indent the first token.
    If i = 0 Then
      If op_indent_sz = -1 Then
        ' Use existing indentation.
        pp_out(Space$(lx_start(0) - 1))
      ElseIf pp_indent_lvl > 0 Then
        ' Use automatic indentation.
        pp_out(Space$(pp_indent_lvl * op_indent_sz))
      EndIf
    EndIf

    ' Output the token with a trailing space where required.
    pp_attrib(TK_COLOUR$(lx_type(i)))
    pp_out(lx_token$(i) + Space$(pp_num_spaces(i)))

    ' Tokens requiring us to increase the indent level after printing them.
    If t$ = " do " Then
      pp_indent_lvl = pp_indent_lvl + 1

    ElseIf t$ = " for " Then
      u$ = " " + lx_token_lc$(i + 1) + " "
      If Instr(" input output random ", u$) <= 0 Then pp_indent_lvl = pp_indent_lvl + 1

    ElseIf t$ = " else " Then
      u$ = lx_token_lc$(i + 1)
      If u$ <> "if" Then pp_indent_lvl = pp_indent_lvl + 1

    ElseIf Instr(" case function select sub ", t$) Then
      If i = 0 Then
        pp_indent_lvl = pp_indent_lvl + 1
      Else If lx_token_lc$(i - 1) <> "end" Then
        pp_indent_lvl = pp_indent_lvl + 1
        If Instr(" case ", t$) Then pp_indent_lvl = pp_indent_lvl + 1
      EndIf

    ElseIf t$ = " then " Then
      u$ = lx_token_lc$(i + 1)
      If u$ = "" Or Left$(u$, 1) = "'" Then pp_indent_lvl = pp_indent_lvl + 1

    EndIf

  Next i

  pp_attrib(VT100_RESET)
  pp_endl()
  If lx_type(0) = 3 Then pp_previous = 1 Else pp_previous = 2

  ' If the 'empty-lines' option is 'single|1' and the line ends with
  ' End {Function|Sub} then print one.
  If op_empty_lines = 1 Then
    If Instr(" function sub ", t$) > 0 Then
      u$ = lx_token_lc$(lx_num - 2)
      If u$ = "end" Then pp_inc_line() : pp_endl() : pp_previous = 0
    EndIf
  EndIf

  ' "Fix" the indent level if it goes badly wrong.
  If pp_indent_lvl < 0 Then pp_indent_lvl = 0

End Sub

' How many spaces should follow token 'i' ?
Function pp_num_spaces(i)

  ' Never need a space after the last token.
  If i >= lx_num - 1 Then Exit Function

  If op_spacing = -1 Then
    ' Maintain existing spaces.
    pp_num_spaces = lx_start(i + 1) - lx_start(i) - lx_len(i)
    Exit Function
  EndIf

  Local t$ = lx_token$(i)
  Local u$ = lx_token$(i + 1)

  ' Never need a space before a comma, semi-colon or closing bracket.
  If InStr(",;)", u$) Then Exit Function

  ' Never need a space after an opening bracket.
  If t$ = "(" Then Exit Function

  ' Rules applying to 'generous' spacing.
  If op_spacing >= 2 Then
    ' Don't need a space before an opening bracket
    ' unless it is preceeded by a symbol.
    If u$ = "(" Then
      If lx_type(i) <> 6 Then Exit Function
    EndIf

    ' Don't need a space after +/- if preceeded by equals.
    If InStr("+-", t$) Then
      If lx_num > 1 Then
        If lx_token$(i - 1) = "=" Then Exit Function
      EndIf
    EndIf

    ' Need a space before/after any symbol.
    If lx_type(i) = 6 Then pp_num_spaces = 1 : Exit Function
    If lx_type(i + 1) = 6 Then pp_num_spaces = 1 : Exit Function
  EndIf

  ' Rules applying to 'compact' spacing.
  If op_spacing >= 1 Then
    ' Need a space between a keyword/identifier and string.
    If lx_type(i) = 5 Or lx_type(i) = 1 Then
      If lx_type(i + 1) = 4 Then pp_num_spaces = 1 : Exit Function
    EndIf

    ' Need a space before a comment.
    If lx_type(i + 1) = 3 Then pp_num_spaces = 1 : Exit Function

    ' Need a space after a string unless followed by a symbol.
    If lx_type(i) = 4 Then
      If lx_type(i + 1) <> 6 Then pp_num_spaces = 1 : Exit Function
    EndIf

    ' Space after a closing bracket unless followed by a symbol.
    If lx_token$(i) = ")" Then
      If lx_type(i + 1) <> 6 Then pp_num_spaces = 1 : Exit Function
    EndIf

    ' Need a space before or after a ':'
    If lx_token$(i) = ":" Then pp_num_spaces = 1 : Exit Function
    If lx_token$(i + 1) = ":" Then pp_num_spaces = 1 : Exit Function
  EndIf

  ' Rules applying to minimal spacing
  Select Case lx_type(i)
    Case 5, 1, 2, 7
      Select Case lx_type(i + 1)
        Case 5, 1, 2
          pp_num_spaces = 1
      End Select
  End Select
End Function

Sub pp_attrib(c$)
  If pp_file_num < 0 And op_colour > 0 Then pp_out(c$)
End Sub

Sub pp_out(s$)
  If pp_file_num < 0 Then
    Print s$;
  Else
    Print #pp_file_num, s$;
  EndIf
End Sub

Sub pp_endl()
  If pp_file_num < 0 Then Print Else Print #pp_file_num
End Sub
' END:       #Include "pprint.inc" ---------------------------------------------
' BEGIN:     #Include "trans.inc" ----------------------------------------------
' Copyright (c) 2020 Thomas Hugo Williams

Const MAX_NUM_IFS = 10

' We ignore the 0'th element in these.
Dim num_comments(MAX_NUM_FILES)
Dim num_ifs(MAX_NUM_FILES)
Dim if_stack(MAX_NUM_FILES, MAX_NUM_IFS)

' The set of active flags.
Const MAX_NUM_FLAGS = 10
Dim flags$(MAX_NUM_FLAGS - 1)
Dim flags_sz = 0
set_init(flags$(), MAX_NUM_FLAGS)

' The map of replacements.
Const MAX_NUM_REPLACEMENTS = 200
Dim replace$(MAX_NUM_REPLACEMENTS - 1) Length 50
Dim with$(MAX_NUM_REPLACEMENTS - 1) Length 50
Dim replace_sz
map_init(replace$(), with$(), MAX_NUM_REPLACEMENTS)

Sub transpile(s$)
  lx_parse_basic(s$)
  If err$ <> "" Then cerror(err$)

  If lx_token_lc$(0) = "'!endif" Then process_endif()

  add_comments()
  apply_replacements()
  If err$ <> "" Then cerror(err$)

  If lx_token_lc$(0) = "#include" Then process_include()

  If lx_type(0) <> 7 Then Exit Sub

  Local t$ = lx_directive$(0)
  If     t$ = "!clear"        Then : process_clear()
  ElseIf t$ = "!comments"     Then : process_comments()
  ElseIf t$ = "!comment_if"   Then : process_if()
  ElseIf t$ = "!empty-lines"  Then : process_empty_lines()
  ElseIf t$ = "!indent"       Then : process_indent()
  ElseIf t$ = "!uncomment_if" Then : process_if()
  ElseIf t$ = "!replace"      Then : process_replace()
  ElseIf t$ = "!set"          Then : process_set()
  ElseIf t$ = "!spacing"      Then : process_spacing()
  Else : cerror("Unknown directive: " + Mid$(t$, 2))
  EndIf

  lx_parse_basic("' PROCESSED: " + Mid$(lx_line$, lx_start(0) + 1))
End Sub

Sub process_endif()
  update_num_comments(- pop_if())
  lx_parse_basic("' PROCESSED: " + Mid$(lx_line$, lx_start(0) + 1))
End Sub

Sub update_num_comments(x)
  num_comments(num_files) = num_comments(num_files) + x
End Sub

Function pop_if()
  If num_ifs(num_files) = 0 Then Error "If directive stack is empty"
  pop_if = if_stack(num_files, num_ifs(num_files))
  num_ifs(num_files) = num_ifs(num_files) - 1
End Function

Sub add_comments()
  Local nc = num_comments(num_files)
  If nc > 0 Then
    lx_parse_basic(String$(nc, "'") + " " + lx_line$)
  ElseIf nc < 0 Then
    Do While nc < 0 And lx_num > 0 And lx_type(0) = 3
      lx_parse_basic(Space$(lx_start(0)) + Right$(lx_line$, Len(lx_line$) - lx_start(0)))
      nc = nc + 1
    Loop
  EndIf
End Sub

' Applies replacements to the currently parsed line, lx_line$.
Sub apply_replacements()
  If replace_sz = 0 Then Exit Sub

  Local i, r$, s$
  For i = 0 TO lx_num - 1
    r$ = map_get$(replace$(), with$(), replace_sz, lx_token_lc$(i))
    If r$ <> Chr$(0) Then
      s$ = Left$(lx_line$, lx_start(i) - 1) + r$ + Mid$(lx_line$, lx_start(i) + lx_len(i))
      lx_parse_basic(s$)
      ' TODO: at the moment this can't change the number of tokens, but when it
      '       can this will need looking at closer.
    EndIf
  Next i
End Sub

Sub process_clear()
  Local t$ = lx_token_lc$(1)
  If lx_num <> 2 Or t$ = "" Then
    cerror("Syntax error: !clear directive expects a <flag> argument")
  EndIf
  If set_get(flags$(), flags_sz, t$) < 0 Then
    ' TODO: Is this really the behaviour we want?
    cerror("Error: flag '" + t$ + "' is not set")
  EndIf
  set_remove(flags$(), flags_sz, t$)
End Sub

Sub process_comments()
  If lx_num > 2 Then cerror("Syntax error: !comments directive has too many arguments")
  op_set_comments(lx_token_lc$(1))
  If err$ <> "" Then cerror("Syntax error: !comments directive " + err$)
End Sub

Sub process_if()
  Local invert, is_set, t$

  t$ = lx_token_lc$(1)

  If lx_num = 2 Then
    ' Do nothing
  ElseIf lx_num = 3 Then
    If t$ = "not" Then
      invert = 1
    Else
      t$ = "Syntax error: " + lx_directive$(0) + " directive followed by unexpected token {"
      t$ = t$ + lx_token$(1) + "}"
      cerror(t$)
    EndIf
  Else
    cerror("Syntax error: " + lx_directive$(0) + " directive with invalid arguments")
  EndIf

  Local x = set_get(flags$(), flags_sz, t$) > -1
  If invert Then x = Not is_set

  If lx_directive$(0) = "!comment_if" Then
    push_if(x)
    If x Then update_num_comments(+1)
  ElseIf lx_directive$(0) = "!uncomment_if" Then
    push_if(-x)
    If x Then update_num_comments(-1)
  Else
    Error
  EndIf
End Sub

Sub push_if(x)
  If num_ifs(num_files) = MAX_NUM_IFS Then Error "Too many if directives"
  num_ifs(num_files) = num_ifs(num_files) + 1
  if_stack(num_files, num_ifs(num_files)) = x
End Sub

Sub process_empty_lines()
  If lx_num > 2 Then cerror("Syntax error: !empty-lines directive has too many arguments")
  op_set_empty_lines(lx_token_lc$(1))
  If err$ <> "" Then cerror("Syntax error: !empty-lines directive " + err$)
End Sub

Sub process_include()
  If lx_num <> 2 Or lx_type(1) <> 4 Then
    cerror("Syntax error: #Include expects a <file> argument")
  EndIf
  open_file(lx_string$(1))
  lx_parse_basic("' BEGIN:     " + lx_line$ + " " + String$(66 - Len(lx_line$), "-"))
End Sub

Sub process_indent()
  If lx_num > 2 Then cerror("Syntax error: !indent directive has too many arguments")
  op_set_indent_sz(lx_token_lc$(1))
  If err$ <> "" Then cerror("Syntax error: !indent directive " + err$)
End Sub

Sub process_replace()
  If lx_num <> 3 Then
    cerror("Syntax error: !replace directive expects <from> and <to> argumentss")
  EndIf
  map_put(replace$(), with$(), replace_sz, lx_token_lc$(1), lx_token_lc$(2))
End Sub

Sub process_set()
  Local t$ = lx_token_lc$(1)
  If lx_num <> 2 Or t$ = "" Then
    cerror("Syntax error: !set directive expects <flag> argument")
  EndIf
  If set_get(flags$(), flags_sz, t$) > -1 Then
    cerror("Error: flag '" + t$ + "' is already set")
  EndIf
  set_put(flags$(), flags_sz, t$)
End Sub

Sub process_spacing()
  If lx_num > 2 Then cerror("Syntax error: !spacing directive has too many arguments")
  op_set_spacing(lx_token_lc$(1))
  If err$ <> "" Then cerror("Syntax error: !spacing directive " + err$)
End Sub

' END:       #Include "trans.inc" ----------------------------------------------
' BEGIN:     #Include "cmdline.inc" --------------------------------------------
' Copyright (c) 2020 Thomas Hugo Williams

' Parses command-line 's$'.
'
' Sets 'err$' if it encounters an error.
Sub cl_parse(s$)
  Local i = 0, o$

  lx_parse_command_line(s$)
  If err$ <> "" Then Exit Sub

  ' Process options.

  Do While i < lx_num And err$ = "" And lx_type(i) = 8
    Select Case lx_option$(i)
      Case "C", "colour"      : cl_parse_no_arg("colour", i)
      Case "e", "empty-lines" : cl_parse_arg("empty-lines", i, "{0|1}")
      Case "f", "format-only" : cl_parse_no_arg("format-only", i)
      Case "i", "indent"      : cl_parse_arg("indent", i, "<number>")
      Case "h", "help"        : cl_usage() : End
      Case "n", "no-comments" : cl_parse_no_arg("no-comments", i)
      Case "s", "spacing"     : cl_parse_arg("spacing", i, "{0|1|2}")
      Case "v", "version"     : cl_version() : End
      Case Else:
        err$ = "option '" + lx_token$(i) + "' is unknown"
    End Select
  Loop

  If err$ <> "" Then Exit Sub

  ' Process arguments.

  If i >= lx_num Then err$ = "no input file specified" : Exit Sub
  If lx_type(i) <> 4 Then err$ = "input file name must be quoted" : Exit Sub
  mbt_in$ = lx_string$(i)
  i = i + 1

  If i >= lx_num Then Exit Sub
  If lx_type(i) <> 4 Then err$ = "output file name must be quoted" : Exit Sub
  mbt_out$ = lx_string$(i)
  i = i + 1

  If i <> lx_num Then err$ = "unexpected argument '" + lx_token$(i) + "'"
End Sub

' Parses an option with an argument.
Sub cl_parse_arg(option$, i, arg$)
  If lx_token$(i + 1) <> "=" Or lx_token$(i + 2) = "" Then
    err$ = "missing argument"
  Else
    op_set(option$, lx_token$(i + 2))
  EndIf
  If err$ <> "" Then err$ = "option '" + lx_token$(i) + "' expects " + arg$ + " argument"
  i = i + 3
End Sub

' Parses an option without an argument.
Sub cl_parse_no_arg(option$, i)
  If lx_token$(i + 1) = "=" Then
    err$ = "option '" + lx_token$(i) + "' does not expect argument"
  Else
    op_set(option$, "on")
  EndIf
  i = i + 1
End Sub

Sub cl_usage()
  Local in$ = Chr$(34) + "input file" + Chr$(34)
  Local out$ = Chr$(34) + "output file" + Chr$(34)
  Print "Usage: RUN "; Chr$(34); "mbt.bas" ; Chr$(34); ", [OPTION]... "; in$; " ["; out$; "]"
  Print
  Print "Transcompiles the given "; in$; " flattening any #Include hierarchy and processing"
  Print "any !directives encountered. The transpiled output is written to the "; out$; ", or"
  Print "the console if unspecified. By using the --format-only option it can also be used as"
  Print "a simple BASIC code formatter."
  Print
  Print "  -C, --colour           syntax highlight the output,"
  Print "                         only valid for output to VT100 serial console"
  Print "  -e, --empty-lines=0|1  controls output of empty lines:"
  Print "                           0 - omit all empty lines"
  Print "                           1 - include one empty line between each Function/Sub"
  Print "                         if ommitted then original formatting will be preserved"
  Print "  -f, --format-only      only format the output, do not follow #Includes or"
  Print "                         process directives"
  Print "  -h, --help             display this help and exit"
  Print "  -i, --indent=NUM       automatically indent output by NUM spaces per level,"
  Print "                         if omitted then original formatting will be preserved"
  Print "  -n, --no-comments      do not include comments in the output"
  Print "  -s, --spacing=0|1|2    controls output of spaces between tokens:"
  Print "                           0 - omit all unnecessary spaces"
  Print "                           1 - compact spacing"
  Print "                           2 - generous spacing"
  Print "                         if omitted then original formatting will be preserved"
  Print "  -v, --version          output version information and exit"
  Print
  Print "Note that --no-comments, --empty-lines, --indent and --spacing will be overridden by"
  Print "the corresponding directives in source files, unless --format-only is also specified."
End Sub

Sub cl_version()
  Print "mbt: an MMBasic transcompiler and code-formatter"
  Print "Release 1b1 for Colour Maximite 2, MMBasic 5.05"
  Print "Copyright (c) 2020 Thomas Hugo Williams"
  Print "A Toy Plastic Trumpet Production for Sockpuppet Studios."
  Print "License MIT <https://opensource.org/licenses/MIT>"
  Print "This is free software: you are free to change and redistribute it."
  Print "There is NO WARRANTY, to the extent permitted by law."
  Print
  Print "Written by Thomas Hugo Williams."
End Sub
' END:       #Include "cmdline.inc" --------------------------------------------
' BEGIN:     #Include "../common/file.inc" -------------------------------------
' Copyright (c) 2020 Thomas Hugo Williams

' Gets the parent directory of 'f$', or the empty string if it does not have one.
Function fi_get_parent$(f$)
  Local c, i

  For i = Len(f$) To 1 Step -1
    c = Asc(Mid$(f$, i, 1))
    ' ASCII 47= / and ASCII 92 = \
    If c = 47 Or c = 92 Then Exit For
  Next i
  If i = 0 Then
    fi_get_parent$ = ""
  Else
    fi_get_parent$ = Left$(f$, i - 1)
  EndIf
End Function

' Gets the name of file/directory 'f$' minus any path information.
Function fi_get_name$(f$)
  Local c, i

  For i = Len(f$) To 1 Step -1
    c = Asc(Mid$(f$, i, 1))
    ' ASCII 47= / and ASCII 92 = \
    If c = 47 Or c = 92 Then Exit For
  Next i
  fi_get_name$ = Mid$(f$, i + 1)
End Function

Function fi_is_absolute(f$)
  fi_is_absolute = 1
  If InStr(f$, "/") = 1 Then Exit Function
  If InStr(f$, "\") = 1 Then Exit Function
  If InStr(UCase$(f$), "A:\") = 1 Then Exit Function
  If InStr(UCase$(f$), "A:/") = 1 Then Exit Function
  fi_is_absolute = 0
End Function

' Gets the canonical path for file/directory 'f$'.
Function fi_get_canonical$(f$)
  Local i
  Local sz = 20
  Local elements$(sz - 1) Length 40

  list_init(elements$(), sz)

  If fi_is_absolute(f$) Then
    If Instr(UCase$(f$), "A:") = 1 Then
      str_tokenise(f$, "/\", elements$(), sz)
    Else
      str_tokenise("A:" + f$, "/\", elements$(), sz)
    EndIf
  Else
    str_tokenise(Cwd$ + "/" + f$, "/\", elements$(), sz)
  EndIf

  elements$(0) = "A:"

  Do While i < sz
    If elements$(i) = "." Then
      list_remove(elements$(), sz, i)
    ElseIf elements$(i) = ".." Then
      list_remove(elements$(), sz, i)
      list_remove(elements$(), sz, i - 1)
      i = i - 1
    Else
      i = i + 1
    EndIf
  Loop

  fi_get_canonical$ = str_join$(elements$(), sz, "/")
End Function

' Does the file/directory 'f$' exist?
'
' @return  1 if the file exists, otherwise 0.
Function fi_exists(f$)
  fi_exists = Mm.Info(FileSize fi_get_canonical$(f$)) <> -1
End Function

' END:       #Include "../common/file.inc" -------------------------------------
' BEGIN:     #Include "../common/list.inc" -------------------------------------
' Copyright (c) 2020 Thomas Hugo Williams

' Initialises the list.
Sub list_init(list$(), sz)
  list_clear(list$(), sz)
End Sub

' Clears the list and resets the size.
Sub list_clear(elements$(), sz)
  Do While sz > 0
    sz = sz - 1
    elements$(sz) = Chr$(&h7F) ' so empty elements are at the end when sorted
  Loop
End Sub

' Appends an element to the end of the list.
Sub list_add(elements$(), sz, s$)
  elements$(sz) = s$
  sz = sz + 1
End Sub

' Inserts an element into the list.
Sub list_insert(elements$(), sz, index, s$)
  Local i
  If index > sz Then Error "index > sz"
  For i = sz To index + 1 Step -1
    elements$(i) = elements$(i - 1)
  Next i
  elements$(i) = s$
  sz = sz + 1
End Sub

' Removes an element from the list.
Sub list_remove(elements$(), sz, index)
  Local i
  If index >= sz Then Error "index >= sz"
  For i = index To sz - 1
    elements$(i) = elements$(i + 1)
  Next i
  sz = sz - 1
  elements$(sz) = Chr$(&h7F)
End Sub

' Removes and returns the element at the end of the list.
Function list_pop$(elements$(), sz)
  sz = sz - 1
  If sz >= 0 Then list_pop$ = elements$(sz) Else list_pop$ = Chr$(&h7F)
End Function

' Appends an element to the end of the list.
Sub list_push(elements$(), sz, s$)
  elements$(sz) = s$
  sz = sz + 1
End Sub

' Prints the contents of the list.
Sub list_dump(elements$(), sz)
  Local i
  For i = 0 To sz - 1
    Print "[" Str$(i) "] " elements$(i)
  Next i
  Print "END"
End Sub
' END:       #Include "../common/list.inc" -------------------------------------
' BEGIN:     #Include "../common/map.inc" --------------------------------------
' Copyright (c) 2020 Thomas Hugo Williams

' Initialises the keys and values.
Sub map_init(keys$(), values$(), num_elements)
  Local sz = num_elements ' don't want to change num_elements
  map_clear(keys$(), values$(), sz)
End Sub

' Clears the keys and values and resets the size.
Sub map_clear(keys$(), values$(), sz)
  Local i
  For i = 0 To sz - 1
    keys$(i) = Chr$(&h7F) ' so empty elements are at the end when sorted
    values$(i) = Chr$(0)
  Next i
  sz = 0
End Sub

' Adds a key/value pair.
Sub map_put(keys$(), values$(), sz, k$, v$)
  Local i = set_get(keys$(), sz, k$)
  If i <> -1 Then values$(i) = v$ : Exit Sub
  keys$(sz) = k$
  values$(sz) = v$
  sz = sz + 1
  If sz > 1 Then
    If keys$(sz - 1) < keys$(sz - 2) Then map_sort(keys$(), values$(), sz)
  EndIf
End Sub

' Resorts the keys and values.
Sub map_sort(keys$(), values$(), sz)
  Local i, idx(sz - 1), k$(sz - 1), v$(sz - 1)

  For i = 0 To sz - 1
    k$(i) = keys$(i)
    v$(i) = values$(i)
  Next i

  Sort k$(), idx()

  For i = 0 To sz - 1
    keys$(i) = k$(i)
    values$(i) = v$(idx(i))
  Next i
End Sub

' Gets the value corresponding to a key, or Chr$(0) if the key is not present.
Function map_get$(keys$(), values$(), sz, k$)
  Local i = set_get(keys$(), sz, k$)
  If i > -1 Then map_get$ = values$(i) Else map_get$ = Chr$(0)
End Function

' Removes a key/value pair.
Sub map_remove(keys$(), values$(), sz, k$)
  Local i = set_get(keys$(), sz, k$)
  If i > -1 Then
    keys$(i) = Chr$(&h7F)
    values$(i) = Chr$(0)
    If sz > 1 Then map_sort(keys$(), values$(), sz)
    sz = sz - 1
  EndIf
End Sub

' Prints the contents of the map.
Sub map_dump(keys$(), values$(), sz)
  Local i, length
  For i = 0 To sz - 1
    If Len(keys$(i)) > length Then length = Len(keys$(i))
  Next i
  For i = 0 To sz - 1
    Print "["; Str$(i); "] "; keys$(i); Space$(length - Len(keys$(i))); " => "; values$(i)
  Next i
  Print "END"
End Sub

' END:       #Include "../common/map.inc" --------------------------------------
' BEGIN:     #Include "../common/set.inc" --------------------------------------
' Copyright (c) 2020 Thomas Hugo Williams

' Initialises the set.
Sub set_init(set$(), num_elements)
  Local sz = num_elements ' don't want to change num_elements
  set_clear(set$(), sz)
End Sub

' Clears the set and resets the size.
Sub set_clear(set$(), sz)
  Local i
  For i = 0 To sz - 1
    set$(i) = Chr$(&h7F) ' so empty elements are at the end when sorted
  Next i
  sz = 0
End Sub

' Adds a value to the set.
Sub set_put(set$(), sz, s$)
  If set_get(set$(), sz, s$) <> -1  Then Exit Sub
  set$(sz) = s$
  sz = sz + 1
  If sz > 1 Then
    If set$(sz - 1) < set$(sz - 2) Then
      Sort set$()
    EndIf
  EndIf
End Sub

' Gets the index of a value in the set, or -1 if not present.
Function set_get(set$(), sz, s$)
  Local i, lb, ub

  ' Binary search of set$()
  lb = 0
  ub = sz - 1
  Do
    i = (lb + ub) \ 2
    If s$ > set$(i) Then
      lb = i + 1
    ElseIf s$ < set$(i) Then
      ub = i - 1
    Else
      set_get = i : Exit Function
    EndIf
  Loop Until ub < lb

  set_get = -1
End Function

' Removes a value from the set if present.
Sub set_remove(set$(), sz, s$)
  Local i = set_get(set$(), sz, s$)
  If i > -1 Then
    set$(i) = Chr$(&h7F)
    Sort set$()
    sz = sz - 1
  EndIf
End Sub

' Prints the contents of the set.
Sub set_dump(set$(), sz)
  Local i
  For i = 0 To sz - 1
    Print "["; Str$(i); "] "; set$(i)
  Next i
  Print "END"
End Sub

' END:       #Include "../common/set.inc" --------------------------------------
' BEGIN:     #Include "../common/string.inc" -----------------------------------
' Copyright (c) 2020 Thomas Hugo Williams

Sub str_tokenise(s$, sep$, tokens$(), tokens_sz)
  Local c$, i, start = 1
  For i = 1 To Len(s$)
    c$ = Mid$(s$, i, 1)
    If Instr(sep$, c$) > 0 Then
      tokens$(tokens_sz) = Mid$(s$, start, i - start)
      tokens_sz = tokens_sz + 1
      start = i + 1
    EndIf
  Next i

  If i > start Then
    tokens$(tokens_sz) = Mid$(s$, start, i - start)
    tokens_sz = tokens_sz + 1
  EndIf
End Sub

Function str_join$(tokens$(), tokens_sz, ch$)
  Local i
  For i = 0 To tokens_sz - 1
    If i > 0 Then str_join$ = str_join$ + ch$
    str_join$ = str_join$ + tokens$(i)
  Next i
End Function

' END:       #Include "../common/string.inc" -----------------------------------

Dim num_files = 0
' We ignore the 0'th element in these.
Dim file_stack$(MAX_NUM_FILES) Length 40
Dim cur_line_no(MAX_NUM_FILES)
Dim mbt_in$     ' input filepath
Dim mbt_out$    ' output filepath
Dim err$        ' global error message / flag

Sub open_file(f$)
  Local f2$, p

  cout(Chr$(13)) ' CR

  If num_files > 0 Then
    f2$ = fi_get_parent$(file_stack$(1)) + f$
  Else
    f2$ = f$
  EndIf

  If Not fi_exists(f2$) Then cerror("#Include file '" + f2$ + "' not found")
  cout(Space$(num_files * 2) + f2$) : cendl()
  num_files = num_files + 1
  Open f2$ For Input As #num_files
  file_stack$(num_files) = f2$
  cout(Space$(1 + num_files * 2))
End Sub

Sub close_file()
  Close #num_files
  num_files = num_files - 1
  cout(Chr$(8) + " " + Chr$(13) + Space$(1 + num_files * 2))
End Sub

Sub cendl()
  If pp_file_num = -1 Then Exit Sub
  Print
End Sub

Sub cout(s$)
  If pp_file_num = -1 Then Exit Sub
  Print s$;
End Sub

Sub cerror(msg$)
  Print
  Print "[" + file_stack$(num_files) + ":" + Str$(cur_line_no(num_files)) + "] Error: " + msg$
  End
End Sub

Function read_line$()
  Local s$
  Line Input #num_files, s$
  read_line$ = s$
  cur_line_no(num_files) = cur_line_no(num_files) + 1
End Function

Sub main()
  Local s$, t

  op_init()

  cl_parse(Mm.CmdLine$)
  If err$ <> "" Then Print "mbt: "; err$ : Print : cl_usage() : End

  If mbt_out$ <> "" Then
    If fi_exists(mbt_out$)) Then
      Print "mbt: file '" + mbt_out$ + "' already exists, please delete it first" : End
    EndIf
  EndIf

  Cls

  lx_load_keywords(RESOURCES_DIR$ + "\keywords.txt")

  pp_open(mbt_out$)
  cout("Transpiling from '" + mbt_in$ + "' to '" + mbt_out$ + "' ...") : cendl()
  open_file(mbt_in$)

  t = Timer
  Do
    cout(Chr$(8) + Mid$("\|/-", ((cur_line_no(num_files) \ 8) Mod 4) + 1, 1))
    s$ = read_line$()
    If op_format_only Then
      lx_parse_basic(s$)
      If err$ <> "" Then cerror(err$)
    Else
      transpile(s$)
    EndIf
    pp_print_line()

    If Eof(#num_files) Then
      If num_files > 1 Then
        s$ = "' END:       #Include " + Chr$(34)
        s$ = s$ + file_stack$(num_files) + Chr$(34) + " "
        s$ = s$ + String$(80 - Len(s$), "-")
        transpile(s$)
        pp_print_line()
      EndIf
      close_file()
    EndIf

  Loop Until num_files = 0

  Print
  Print "Time taken = " + Format$((Timer - t) / 1000, "%.1f s")

  pp_close()

End Sub

main()
End
' END:       #Include "main.bas" -----------------------------------------------

