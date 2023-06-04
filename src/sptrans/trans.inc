' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("options", "set", "defines", "expression")
sys.provides("trans")
If sys.err$ <> "" Then Error sys.err$

Dim tr.num_comments(MAX_NUM_FILES - 1)

' For each source file we maintain a stack of currently open !IF directives.
' If 'i' is the base-0 index of the source file then
'   if_stack(i, if_stack_sz - 1)
' describes the state of the latest !IF directive:
Const tr.INACTIVE_IF           = &b000010
Const tr.ACTIVE_IF             = &b000011 ' Also active !ELIF
Const tr.INACTIVE_ELSE         = &b000100
Const tr.ACTIVE_ELSE           = &b000101
Const tr.INACTIVE_COMMENT_IF   = &b001000
Const tr.ACTIVE_COMMENT_IF     = &b001001
Const tr.INACTIVE_UNCOMMENT_IF = &b010000
Const tr.ACTIVE_UNCOMMENT_IF   = &b010001
Const tr.OMITTED_IF            = &b100000 ' Also omitted !COMMENT_IF, !ELIF
                                          ' !ELSE, !UNCOMMENT_IF
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

Const tr.INCLUDE_FILE = 1
Const tr.OMIT_LINE = 2

' Just transpile/inline #INCLUDE statements.
'
' @return  sys.FAILURE      on error, see 'sys.err$' for details.
'          sys.SUCCESS      if the current line should be included in the
'                           output.
'          tr.INCLUDE_FILE  if current line started with #INCLUDE statement, the
'                           filename/path is returned in 'tr.include$'.
'          tr.OMIT_LINE     if the current line should be omitted from the
'                           output.
Function tr.transpile_includes%()
  tr.include$ = ""
  If lx.token_lc$(0) = "#include" Then
    tr.process_include()
    tr.transpile_includes% = Choice(sys.err$ = "", tr.INCLUDE_FILE, sys.FAILURE)
  EndIf
End Function

' Full transpilation.
'
' @return  sys.FAILURE      on error, see 'sys.err$' for details.
'          sys.SUCCESS      if the current line should be included in the
'                           output.
'          tr.INCLUDE_FILE  if current line started with #INCLUDE statement, the
'                           filename/path is returned in 'tr.include$'.
'          tr.OMIT_LINE     if the current line should be omitted from the
'                           output.
Function tr.transpile%()
  tr.include$ = ""

  If lx.type(0) = TK_DIRECTIVE Then
    ' Remove any trailing comment from directive.
    If lx.type(lx.num - 1) = TK_COMMENT Then lx.remove_token(lx.num - 1)

    ' Check that is is a known directive.
    If Not tr.is_known_directive%(lx.directive$(0)) Then
      sys.err$ = "Unknown " + lx.directive$(0) + " directive"
      tr.transpile% = sys.FAILURE
      Exit Function
    EndIf
  EndIf

  Select Case lx.token_lc$(0)
    Case "'!endif", "'!else", "'!elif"
      ' TODO: Requiring the trailing brackets in the CALL may be an MMBasic bug.
      Call "tr.process_" + Mid$(lx.token_lc$(0), 3) + "()"
      If sys.err$ = "" Then
        lx.reset("") ' Is this really necessary ?
        tr.omitted_line_flag% = 1
        tr.transpile% = tr.OMIT_LINE
      Else
        tr.transpile% = sys.FAILURE
      EndIf
      Exit Function
  End Select

  If tr.omit_flag% < 0 Then
    Error "Invalid state"
  ElseIf tr.omit_flag% Then
    If lx.type(0) = TK_DIRECTIVE Then
      If InStr("|!comment_if|!if|!ifdef|!ifndef|!uncomment_if|", "|" + lx.directive$(0) + "|") Then
        tr.push_if(tr.OMITTED_IF)
        Inc tr.omit_flag%
      EndIf
    EndIf
    lx.reset("")
    tr.omitted_line_flag% = 1
    tr.transpile% = tr.OMIT_LINE
    Exit Function
  EndIf

  tr.add_comments()
  tr.apply_replacements()
  If sys.err$ <> "" Then
    tr.transpile% = sys.FAILURE
    Exit Function
  EndIf

  If lx.num = 0 Then                  ' IF this line is empty
    If tr.omitted_line_flag% Then     ' AND the last line was omitted
      If tr.empty_line_flag% Then     ' AND the last non-omitted line was empty
        tr.transpile% = tr.OMIT_LINE  ' THEN omit this line.
        Exit Function
      EndIf
    EndIf
  EndIF

  If lx.token_lc$(0) = "#include" Then
    tr.process_include()
    tr.transpile% = Choice(sys.err$ = "", tr.INCLUDE_FILE, sys.FAILURE)
    tr.omitted_line_flag% = 0
    Exit Function
  EndIf

  If lx.type(0) <> TK_DIRECTIVE Then
    tr.empty_line_flag% = (lx.num = 0)
    tr.transpile% = Choice(opt.comments = 0, tr.remove_comments%(), sys.SUCCESS)
    tr.omitted_line_flag% = tr.transpile% = tr.OMIT_LINE
    Exit Function
  EndIf

  tr.transpile% = tr.OMIT_LINE

  Select Case lx.directive$(0)
    Case "!comments"     : tr.process_comments()
    Case "!comment_if"   : tr.process_if()
    Case "!define"       : tr.process_define()
    Case "!elif"         : tr.process_elif()
    Case "!else"         : tr.process_else()
    Case "!empty-lines"  : tr.process_empty_lines()
    Case "!error"        : tr.process_error()
    Case "!if"           : tr.process_if()
    Case "!ifdef"        : tr.process_if()
    Case "!ifndef"       : tr.process_if()
    Case "!info"         : tr.transpile% = tr.process_info%()
    Case "!indent"       : tr.process_indent()
    Case "!replace"      : tr.process_replace()
    Case "!spacing"      : tr.process_spacing()
    Case "!uncomment_if" : tr.process_if()
    Case "!undef"        : tr.process_undef()
    Case "!unreplace"    : tr.process_replace()  ' Same SUB for !replace & !unreplace.
    Case Else            : Error "Invalid state" ' Should have been caught earlier.
  End Select

  If sys.err$ <> "" Then
    tr.transpile% = sys.FAILURE
  ElseIf tr.transpile% = tr.OMIT_LINE Then
    ' lx.parse_basic("' PROCESSED: " + Mid$(lx.line$, lx.start(0) + 1))
    lx.reset("")
    tr.omitted_line_flag% = 1
  EndIf
End Function

Function tr.is_known_directive%(t$)
  Local u$ = "|" + Mid$(t$, 2) + "|"
  If InStr("|comments|comment_if|define|elif|else|empty-lines|endif|error|if|ifdef|", u$) Then
    tr.is_known_directive% = 1
  ElseIf InStr("|ifndef|info|indent|replace|spacing|uncomment_if|undef|unreplace|", u$) Then
    tr.is_known_directive% = 1
  EndIf
End Function

Sub tr.process_elif()
  Select Case tr.pop_if()
    Case tr.INACTIVE_IF
      Inc tr.omit_flag%, -1
      tr.process_if()
    Case tr.ACTIVE_IF
      Inc tr.omit_flag%
      tr.push_if(tr.OMITTED_IF)
    Case tr.OMITTED_IF
      tr.push_if(tr.OMITTED_IF)
    Case Else
      sys.err$ = "!elif directive without !if"
  End Select
End Sub

Sub tr.process_else()
  If lx.num <> 1 Then
    sys.err$ = "!else directive has too many arguments"
    Exit Sub
  EndIf

  Select Case tr.pop_if()
    Case -1
      If sys.err$ = "" Then Error "Internal error"
    Case tr.ACTIVE_IF
      Inc tr.omit_flag%
      tr.push_if(tr.INACTIVE_ELSE)
    Case tr.INACTIVE_IF
      Inc tr.omit_flag%, -1
      tr.push_if(tr.ACTIVE_ELSE)
    Case tr.OMITTED_IF
      tr.push_if(tr.OMITTED_IF)
    Case tr.INACTIVE_ELSE, tr.ACTIVE_ELSE
      sys.err$ = "Too many !else directives"
  End Select
End Sub

Sub tr.process_endif()
  If lx.num <> 1 Then
    sys.err$ = "!endif directive has too many arguments"
    Exit Sub
  EndIf

  Select Case tr.pop_if()
    Case tr.ACTIVE_COMMENT_IF
      tr.update_num_comments(-1)
    Case tr.ACTIVE_UNCOMMENT_IF
      tr.update_num_comments(+1)
    Case tr.INACTIVE_ELSE, tr.INACTIVE_IF, tr.OMITTED_IF
      Inc tr.omit_flag%, -1
  End Select
End Sub

Sub tr.update_num_comments(x)
  Local i = in.num_open_files% - 1
  tr.num_comments(i) = tr.num_comments(i) + x
End Sub

Function tr.if_stack_to_string$()
  Const i% = in.num_open_files% - 1
  Local j%, s$
  For j% = tr.if_stack_sz(i%) - 1 To 0 Step -1
    Cat s$, Bin$(tr.if_stack(i%, j%))
    If j% > 0 Then Cat s$, " "
  Next
  tr.if_stack_to_string$ = s$
End Function

Function tr.peek_if%()
  Const i% = in.num_open_files% - 1
  If tr.if_stack_sz(i%) Then
    tr.peek_if% = tr.if_stack(i%, tr.if_stack_sz(i%) - 1)
  Else
    tr.peek_if% = -1
  EndIf
End Function

Function tr.pop_if(directive$)
  Const i% = in.num_open_files% - 1
  If tr.if_stack_sz(i%) Then
    Inc tr.if_stack_sz(i%), -1
    tr.pop_if = tr.if_stack(i%, tr.if_stack_sz(i%))
  Else
    sys.err$ = lx.directive$(0) + " directive without !if"
    tr.pop_if = -1
  EndIf
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
        If lx.parse_basic%(s$) <> sys.SUCCESS Then Exit Sub

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

Sub tr.process_undef()
  If lx.num < 2 Then sys.err$ = "expects a <flag> argument"
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then def.undefine(lx.token$(1))
  If sys.err$ <> "" Then sys.err$ = "!undef directive " + sys.err$
End Sub

Sub tr.process_comments()
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then opt.set_comments(lx.token_lc$(1))
  If sys.err$ <> "" Then sys.err$ = "!comments directive " + sys.err$
End Sub

Sub tr.process_if()
  ' Replace !IFDEF and !IFNDEF directives with equivalent !IF DEFINED.
  Select Case lx.directive$(0)
    Case "!ifdef"
      If lx.num <> 2 Then
        sys.err$ = "expects 1 argument"
      Else
        Local dummy% = lx.parse_basic%("'!if defined (" + lx.token$(1) + ")")
      EndIf
    Case "!ifndef"
      If lx.num <> 2 Then
        sys.err$ = "expects 1 argument"
      Else
        Local dummy% = lx.parse_basic%("'!if not defined (" + lx.token$(1) + ")")
      EndIf
    Case Else
      If lx.num < 2 Then sys.err$ = "expects at least 1 argument"
  End Select

  If sys.err$ <> "" Then
    sys.err$ = lx.directive$(0) + " directive " + sys.err$
    Exit Sub
  EndIf

  Local x%
  If ex.eval%(1, x%) <> 0 Then Exit Sub
  If x% < 0 Or x% > 1 Then Error "Value is not true (1) or false (0): " + x%

  Select Case lx.directive$(0)
    Case "!comment_if"
      tr.push_if(x% Or tr.INACTIVE_COMMENT_IF)
      If x% Then tr.update_num_comments(+1)

    Case "!if", "!elif"
      tr.push_if(x% Or tr.INACTIVE_IF)
      Inc tr.omit_flag%, Not x%

    Case "!uncomment_if"
      tr.push_if(x% Or tr.INACTIVE_UNCOMMENT_IF)
      If x% Then tr.update_num_comments(-1)

    Case Else
      Error "Unknown !if directive: " + lx.directive$(0)
  End Select
End Sub

Sub tr.push_if(x)
  Local i = in.num_open_files% - 1
  If tr.if_stack_sz(i) = tr.MAX_NUM_IFS Then Error "Too many !if directives"
  tr.if_stack(i, tr.if_stack_sz(i)) = x
  Inc tr.if_stack_sz(i)
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
  If lx.num >= 2 And lx.type(1) = TK_STRING And (lx.num = 2 Or lx.type(2) = TK_COMMENT) Then
    tr.include$ = lx.string$(1)
  Else
    sys.err$ = "#INCLUDE expects a <file> argument"
  EndIf
End Sub

Function tr.process_info%()
  If lx.num <> 3 Then
    sys.err$ = "expects two arguments"
  ElseIf lx.token_lc$(1) <> "defined" Then
    sys.err$ = "has invalid first argument: " + lx.token_lc$(1)
  Else
    Local defined% = def.is_defined%(lx.token$(2))
    If defined% Then
      lx.replace_token(0, "' Preprocessor value " + UCase$(lx.token$(2)) + " defined", TK_COMMENT)
      lx.remove_token(2)
      lx.remove_token(1)
      tr.process_info% = sys.SUCCESS
    Else
      tr.process_info% = tr.OMIT_LINE
    EndIf
  EndIf
  If sys.err$ <> "" Then
    sys.err$ = "!info directive " + sys.err$
    tr.process_info% = sys.FAILURE
  EndIf
End Function

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

Sub tr.process_define()
  If lx.num < 2 Then sys.err$ = "expects <id> argument"
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then def.define(lx.token$(1))
  If sys.err$ <> "" Then sys.err$ = "!define directive " + sys.err$
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
  ElseIf to_$ = Chr$(0) Then
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
' @return  tr.OMIT_LINE if as a result of calling this function the line
'          is now empty, otherwise 1.
Function tr.remove_comments%()
  If lx.num = 0 Then Exit Function

  Local i%
  Do While i% < lx.num
    If lx.type(i%) = TK_COMMENT Then lx.remove_token(i%)
    Inc i%
  Loop
  tr.remove_comments% = Choice(lx.num = 0, tr.OMIT_LINE, sys.SUCCESS)
End Function
