' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("options", "set")
sys.provides("trans")
If sys.err$ <> "" Then Error sys.err$

Dim tr.num_comments(MAX_NUM_FILES - 1)

' For each source file we maintain a stack of currently open !if directives.
' If 'i' is the base-0 index of the source file then
'   if_stack(i, if_stack_sz - 1)
'     = +1  : if the latest !if directive incremented 'num_comments'
'     = +2  : if the latest !if directive set the 'omit_flag'
'     = -1  : if the latest !if directive decremented 'num_comments'
'     = 0   : if the current !if directive is inactive
Const tr.MAX_NUM_IFS = 10
Dim tr.if_stack(MAX_NUM_FILES - 1, tr.MAX_NUM_IFS - 1)
Dim tr.if_stack_sz(MAX_NUM_FILES - 1)

' The list of replacements (from -> to).
Const tr.MAX_REPLACEMENTS% = 200
Dim tr.num_replacements
Dim tr.replacements$(tr.MAX_REPLACEMENTS% - 1, 1) Length 80

' Set to name of file after processing #INCLUDE.
Dim tr.include$

' If set we ignore/omit lines until we process an !ENDIF directive
' corresponding to the directive that set this flag.
Dim tr.omit_flag%

' Was the last non-omitted line empty after transpilation ?
Dim tr.empty_line_flag%

' Was the last line omitted ?
Dim tr.omitted_line_flag%

Const tr.STATUS_INCLUDE% = 2
Const tr.STATUS_OMIT_LINE% = 3

' Just transpile/inline #INCLUDE statements.
'
' @return  0  on error, see 'sys.err$' for details.
' @return  1  if current line did not start with #INCLUDE statement.
' @return  2  if current line started with #INCLUDE statement,
'             the filename/path is returned in 'tr.include$'.
Function tr.transpile_includes%()
  tr.include$ = ""
  If lx.token_lc$(0) = "#include" Then
    tr.process_include()
    tr.transpile_includes% = Choice(sys.err$ = "", tr.STATUS_INCLUDE%, 0)
  Else
    tr.transpile_includes% = 1
  EndIf
End Function

' Full transpilation.
'
' @return  0  on error, see 'sys.err$' for details.
'          1  on general success.
'          2  if current line started with #INCLUDE statement,
'             the filename/path is returned in 'tr.include$'.
'          3  if line was deleted/omitted by the transpiler.
Function tr.transpile%()
  tr.include$ = ""

  If lx.token_lc$(0) = "'!endif" Then
    tr.transpile% = tr.process_endif%()
    tr.omitted_line_flag% = (tr.transpile% = tr.STATUS_OMIT_LINE%)
    Exit Function
  EndIf

  If tr.omit_flag% Then
    If lx.type(0) = TK_DIRECTIVE Then
      Select Case lx.directive$(0)
        Case "!comment_if", "!ifdef", "!ifndef", "!uncomment_if"
          tr.push_if(0) ' Still need to record omitted !if's.
      End Select
    EndIf
    lx.reset("")
    tr.omitted_line_flag% = 1
    tr.transpile% = tr.STATUS_OMIT_LINE%
    Exit Function
  EndIf

  tr.add_comments()
  tr.apply_replacements()
  If sys.err$ <> "" Then Exit Function

  ' IF this line is empty
  ' AND the last line was omitted
  ' AND the last non-omitted line was empty.
  ' THEN omit this line.
  If lx.num = 0 Then                          ' IF this line is empty
    If tr.omitted_line_flag% Then             ' AND the last line was omitted
      If tr.empty_line_flag% Then             ' AND the last non-omitted line was empty
        tr.transpile% = tr.STATUS_OMIT_LINE%  ' THEN omit this line.
        Exit Function
      EndIf
    EndIf
  EndIF

  If lx.token_lc$(0) = "#include" Then
    tr.process_include()
    tr.transpile% = Choice(sys.err$ = "", tr.STATUS_INCLUDE%, 0)
    tr.omitted_line_flag% = 0
    Exit Function
  EndIf

  If lx.type(0) <> TK_DIRECTIVE Then
    tr.empty_line_flag% = (lx.num = 0)
    tr.transpile% = Choice(opt.comments = 0, tr.remove_comments%(), 1)
    tr.omitted_line_flag% = tr.transpile% = tr.STATUS_OMIT_LINE%
    Exit Function
  EndIf

  Select Case lx.directive$(0)
    Case "!clear"        : tr.process_clear()
    Case "!comments"     : tr.process_comments()
    Case "!comment_if"   : tr.process_if()
    Case "!empty-lines"  : tr.process_empty_lines()
    Case "!error"        : tr.process_error()
    Case "!ifdef"        : tr.process_if()
    Case "!ifndef"       : tr.process_if()
    Case "!indent"       : tr.process_indent()
    Case "!replace"      : tr.process_replace()
    Case "!set"          : tr.process_set()
    Case "!spacing"      : tr.process_spacing()
    Case "!uncomment_if" : tr.process_if()
    Case "!unreplace"    : tr.process_replace()  ' Same SUB for !replace & !unreplace.
    Case Else            : sys.err$ = "unknown " + Mid$(lx.directive$(0), 1) + " directive"
  End Select

  If sys.err$ = "" Then
'    lx.parse_basic("' PROCESSED: " + Mid$(lx.line$, lx.start(0) + 1))
    lx.reset("")
    tr.transpile% = tr.STATUS_OMIT_LINE%
    tr.omitted_line_flag% = 1
  EndIf
End Function

Function tr.process_endif%()
  Local x% = tr.pop_if()
  Select Case x%
    Case 0     : ' Do nothing.
    Case 1, -1 : tr.update_num_comments(-x%)
    Case 2     : tr.omit_flag% = 0
    Case Else  : Error
  End Select
  If sys.err$ <> "" Then Exit Function
'  lx.parse_basic("' PROCESSED: " + Mid$(lx.line$, lx.start(0) + 1))
  lx.reset("")
  tr.process_endif% = tr.STATUS_OMIT_LINE%
End Function

Sub tr.update_num_comments(x)
  Local i = in.num_open_files% - 1
  tr.num_comments(i) = tr.num_comments(i) + x
End Sub

Function tr.pop_if()
  Local i = in.num_open_files% - 1
  If tr.if_stack_sz(i) = 0 Then sys.err$ = "unmatched !endif" : Exit Function
  tr.if_stack_sz(i) = tr.if_stack_sz(i) - 1
  tr.pop_if = tr.if_stack(i, tr.if_stack_sz(i))
End Function

Sub tr.add_comments()
  Local nc = tr.num_comments(in.num_open_files% - 1)
  Local result%
  If nc > 0 Then
    result% = lx.parse_basic%(String$(nc, "'") + " " + lx.line$)
  ElseIf nc < 0 Then
    Do While nc < 0 And lx.num > 0 And lx.type(0) = TK_COMMENT
      If Mid$(lx.line$, lx.start(0), 1) = "'" Then
        result% = lx.parse_basic%(Left$(lx.line$, lx.start(0) - 1) + Mid$(lx.line$, lx.start(0) + 1))
      ElseIf LCase$(Mid$(lx.line$, lx.start(0), 3)) = "rem" Then
        result% = lx.parse_basic%(Left$(lx.line$, lx.start(0) - 1) + Mid$(lx.line$, lx.start(0) + 3))
      EndIf
      Inc nc, 1
    Loop
  EndIf
End Sub

' Applies replacements to the currently parsed line, lx.line$.
Sub tr.apply_replacements()
  If lx.num = 0 Then Exit Sub
  If tr.num_replacements% = 0 Then Exit Sub
  If lx.type(0) = TK_DIRECTIVE Then Exit Sub ' Don't replace within directives.

  Local capture$, i%, j%, k%, old_num%, s$, to_$
  For i% = 0 To tr.num_replacements% - 1

    ' Skip 'dead' entries.
    If tr.replacements$(i%, 0) = Chr$(0) Then Continue For

    j% = 0
    ' Need to use a DO rather than a FOR because the latter does not re-evaluate its end-point
    ' at the beginning of each iteration.
    Do While j% < lx.num
      k% = tr.match%(j%, i%, capture$)
      If k% > -1 Then
        s$ = Left$(lx.line$, lx.start(j%) - 1)
        to_$ = str.replace$(tr.replacements$(i%, 1), "|", " ")
        to_$ = str.replace$(to_$, "%1", Field$(capture$, 1, "|"))
        If Len(s$) + Len(to_$) + Len(lx.line$) - lx.start(k%) - lx.len(k%) > 255 Then
          sys.err$ = "applying replacement makes line > 255 characters"
          Exit Sub
        EndIf
        ' WARNING! In firmware 5.07 CAT does not error when it overflows 255 characters.
        Cat s$, to_$
        Cat s$, Mid$(lx.line$, lx.start(k%) + lx.len(k%))
        old_num% = lx.num%
        If lx.parse_basic%(s$) <> 0 Then Exit Sub

        ' Adjust j% so we don't resume searching for matches until immediately
        ' after the current replacement.
        Inc j%, Max(0, 1 + lx.num% - old_num% + k% - j%)
      Else
        Inc j%
      EndIf
    Loop
  Next

End Sub

' Attempts to match current token array against a 'from' specification.
'
' @param  ti  index into the token array from which to attempt the match.
' @param  ri  index into the replacements array for the 'from' we are trying to match.
' @return     the token index where the match ends, or -1 if there is no match.
Function tr.match%(ti%, ri%, capture$)
  Local done%, from$, i%, t$

  tr.match% = -1
  capture$ = ""

  Do
    from$ = Field$(tr.replacements$(ri, 0), i% + 1, "|")
    t$ = lx.token$(ti% + i%)

    If from$ = "" Then
      tr.match% = ti% + i% - 1
      done% = 1
    ElseIf InStr("%% %d %h", Right$(from$, 2)) Mod 3 = 1 Then
      done% = Not tr.capture%(from$, t$, capture$)
    Else
      done% = from$ <> LCase$(t$)
    EndIf

    Inc i%
  Loop Until done%
End Function

Function tr.capture%(pattern$, token$, capture$)
  Local allowed$

  Select Case Right$(pattern$, 2)
    Case "%%" : allowed$ = "*"                      ' match any character.
    Case "%d" : allowed$ = "0123456789"             ' match decimal digits.
    Case "%h" : allowed$ = "abcdefABCDEF0123456789" ' match hexadecimal digits.
    Case Else : Error "Unknown pattern."
  End Select

  If Len(pattern$) = 2 Then
    ' pattern$ is just a pattern, e.g. %%, %d, %h
    ' - we try to match and capture the entire token$.
    If tr.contains_only%(allowed$, token$) Then
      Cat capture$, token$ + "|"
      tr.capture% = 1
    EndIf

  ElseIf InStr(LCase$(token$), Left$(pattern$, Len(pattern$) - 2)) = 1 Then
    ' pattern$ is a prefix followed by a pattern, e.g. foo%%
    ' - we try to match and capture everything in token$ after the prefix.
    Local t$ = Mid$(token$, Len(pattern$) - 1)
    If tr.contains_only%(allowed$, t$) Then
      Cat capture$, t$ + "|"
      tr.capture% = 1
    EndIf
  EndIf
End Function

' Are all the characters in 's$' present in 'allowed$' ?
' If 'allowed$' is "*" then always returns 1 (true).
Function tr.contains_only%(allowed$, s$)
  If allowed$ <> "*" Then
    Local i%
    For i% = 1 To Len(s$)
      If Not InStr(allowed$, Mid$(s$, 1, 1)) Then Exit Function
    Next
  EndIf
  tr.contains_only% = 1
End Function

Sub tr.process_clear()
  If lx.num < 2 Then sys.err$ = "expects a <flag> argument"
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then opt.clear_flag(lx.token$(1))
  If sys.err$ <> "" Then sys.err$ = "!clear directive " + sys.err$
End Sub

Sub tr.process_comments()
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then opt.set_comments(lx.token_lc$(1))
  If sys.err$ <> "" Then sys.err$ = "!comments directive " + sys.err$
End Sub

Sub tr.process_if()
  Local invert
  Local t$ = lx.token_lc$(1)

  Select Case lx.directive$(0)
    Case "!ifdef", "!ifndef"
      If lx.num <> 2 Then sys.err$ = "expects 1 argument"

    Case Else
      If lx.num = 2 Then
        ' Do nothing
      ElseIf lx.num = 3 Then
        If t$ = "not" Then
          invert = 1
          t$ = lx.token_lc$(2)
        Else
          sys.err$ = "followed by unexpected token {" + lx.token$(1) + "}"
        EndIf
      Else
        sys.err$ = "has too many arguments"
      EndIf
  End Select

  If sys.err$ <> "" Then
    sys.err$ = lx.directive$(0) + " directive " + sys.err$
    Exit Sub
  EndIf

  Local x = opt.is_flag_set%(t$))
  If invert Then x = Not x

  Select Case lx.directive$(0)
    Case "!comment_if"
      tr.push_if(x)
      If x Then tr.update_num_comments(+1)

    Case "!ifdef"
      tr.push_if(Choice(x, 0, 2))
      tr.omit_flag% = Not x

    Case "!ifndef"
      tr.push_if(Choice(x, 2, 0))
      tr.omit_flag% = x

    Case "!uncomment_if"
      tr.push_if(-x)
      If x Then tr.update_num_comments(-1)

    Case Else
      Error
  End Select
End Sub

Sub tr.push_if(x)
  Local i = in.num_open_files% - 1
  If tr.if_stack_sz(i) = tr.MAX_NUM_IFS Then Error "Too many if directives"
  tr.if_stack(i, tr.if_stack_sz(i)) = x
  tr.if_stack_sz(i) = tr.if_stack_sz(i) + 1
End Sub

Sub tr.process_empty_lines()
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then opt.set_empty_lines(lx.token_lc$(1))
  If sys.err$ <> "" Then sys.err$ = "!empty-lines directive " + sys.err$
End Sub

Sub tr.process_error()
  If lx.num <> 2 Or lx.type(1) <> TK_STRING Then
    sys.err$ = "!error directive has missing " + str.quote$("message") + " argument"
  Else
    sys.err$ = lx.string$(1)
  EndIf
End Sub

Sub tr.process_include()
  If lx.num <> 2 Or lx.type(1) <> TK_STRING Then
    sys.err$ = "#INCLUDE expects a <file> argument"
  Else
    tr.include$ = lx.string$(1)
  EndIf
End Sub

Sub tr.process_indent()
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then opt.set_indent_sz(lx.token_lc$(1))
  If sys.err$ <> "" Then sys.err$ = "!indent directive " + sys.err$
End Sub

Sub tr.process_replace()
  Local in_group%
  Local i%
  Local gidx% = 0
  Local unreplace% = lx.directive$(0) = "!unreplace"
  Local groups$(1) = ( "", Choice(unreplace%, Chr$(0), "") )

  For i% = 1 To lx.num - 1
    Select Case lx.token_lc$(i%)
      Case "{"
        If in_group% Then
          sys.err$ = "has unexpected '{'"
        Else
          in_group% = 1
        EndIf
      Case "}"
        If in_group% Then
          in_group% = 0
          If gidx% = 0 Then
            If groups$(gidx%) = "" Then sys.err$ = "has empty <from> group"
          EndIf
          Inc gidx%
        Else
          sys.err$ = "has unexpected '}'"
        EndIf
      Case Else
        If gidx% > 1 Or (unreplace% And gidx% > 0) Then
          sys.err$ = "has too many arguments"
        ElseIf in_group% Then
          If groups$(gidx%) <> "" Then Cat groups$(gidx%), "|"
          Cat groups$(gidx%), lx.token$(i%)
        Else
          groups$(gidx%) = lx.token$(i%)
          Inc gidx%
        EndIf
    End Select

    If sys.err$ <> "" Then Exit For
  Next

  If sys.err$ = "" Then
    If in_group% Then
      sys.err$ = "has missing '}'"
    ElseIf gidx% < 1 Then
      sys.err$ = "expects <from> argument"
    Else
      tr.add_replacement(groups$(0), groups$(1))
    EndIf
  EndIf

  If sys.err$ <> "" Then sys.err$ = lx.directive$(0) + " directive " + sys.err$
End Sub

Sub tr.process_set()
  If lx.num < 2 Then sys.err$ = "expects <flag> argument"
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then opt.set_flag(lx.token$(1))
  If sys.err$ <> "" Then sys.err$ = "!set directive " + sys.err$
End Sub

Sub tr.process_spacing()
  If lx.num > 2 Then sys.err$ = " has too many arguments")
  If sys.err$ = "" Then opt.set_spacing(lx.token_lc$(1))
  If sys.err$ <> "" Then sys.err$ = "!spacing directive " + sys.err$
End Sub

Sub tr.clear_replacements()
  Local i%
  For i% = 0 To tr.num_replacements% - 1
    tr.replacements$(i%, 0) = ""
    tr.replacements$(i%, 1) = ""
  Next
  tr.num_replacements% = 0
End Sub

' Adds a new entry to the replacement list.
'
'   - if the entry exists then flags it as "dead" and adds a new entry to the
'     end of the list.
'   - if to_$ = Chr$(0) then expects entry to exist and flags it as "dead".
Sub tr.add_replacement(from$, to_$)
  Local f_lower$ = LCase$(from$)
  Local existing% = -1, i%

  ' Find existing replacement (if any) and flag entry dead.
  For i% = 0 To tr.num_replacements% - 1
    If f_lower$ = tr.replacements$(i%, 0) Then
      existing% = i%
      Exit For
    EndIf
  Next

  If existing% > -1 Then
    ' Flag existing entry as dead.
    tr.replacements$(existing%, 0) = Chr$(0)
    tr.replacements$(existing%, 1) = Chr$(0)
    If to_$ = Chr$(0) Then Exit Sub
  Else If to_$ = Chr$(0) Then
    sys.err$ = "could not find '" + from$ + "'"
    Exit Sub
  EndIf

  ' Handle too many entries.
  If tr.num_replacements% >= tr.MAX_REPLACEMENTS% Then
    sys.err$ = "too many replacements (max " + Str$(tr.MAX_REPLACEMENTS%) + ")"
    Exit Sub
  EndIf

  ' Actually add the new entry.
  tr.replacements$(tr.num_replacements%, 0) = f_lower$
  tr.replacements$(tr.num_replacements%, 1) = to_$
  Inc tr.num_replacements%
End Sub

Sub tr.dump_replacements()
  Local i%, s$
  For i% = 0 To tr.num_replacements% - 1
    Print Str$(i%) ": " ;
    Print Choice(tr.replacements$(i%, 0) = Chr$(0), "<null>", tr.replacements$(i%, 0));
    Print " => ";
    Print Choice(tr.replacements$(i%, 1) = Chr$(0), "<null>", tr.replacements$(i%, 1))
  Next
End Sub

' Removes all comment tokens from the current line.
'
' @return  tr.STATUS_OMIT_LINE% if as a result of calling this function the line
'          is now empty, otherwise 1.
Function tr.remove_comments%()
  If lx.num = 0 Then
    tr.remove_comments% = 1
    Exit Function
  EndIf

  Local i%
  Do While i% < lx.num
    If lx.type(i%) = TK_COMMENT Then lx.remove_token(i%)
    Inc i%
  Loop
  tr.remove_comments% = Choice(lx.num = 0, tr.STATUS_OMIT_LINE%, 1)
End Function
