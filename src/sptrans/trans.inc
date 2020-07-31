' Copyright (c) 2020 Thomas Hugo Williams

Dim num_comments(MAX_NUM_FILES - 1)

' For each source file we maintain a stack of currently open !if directives.
' If 'i' is the base-0 index of the source file then
'   if_stack(i, if_stack_sz - 1)
'     = +1  : if the current !if directive incremented 'num_comments'
'     = -1  : if the current !if directive decremented 'num_comments'
'     = 0   : if the current !if directive is inactive
Const MAX_NUM_IFS = 10
Dim if_stack(MAX_NUM_FILES - 1, MAX_NUM_IFS - 1)
Dim if_stack_sz(MAX_NUM_FILES - 1)

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

' Set to name of file after processing #Include
Dim tr_include$

Sub transpile(s$)
  tr_include$ = ""
  lx_parse_basic(s$)
  If err$ <> "" Then Exit Sub

  If lx_token_lc$(0) = "'!endif" Then
    process_endif()
    If err$ <> "" Then Exit Sub
  EndIf

  add_comments()
  apply_replacements()
  If err$ <> "" Then Exit Sub

  If lx_token_lc$(0) = "#include" Then
    process_include()
    If err$ <> "" Then Exit Sub
  EndIf

  If lx_type(0) <> TK_DIRECTIVE Then Exit Sub

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
  Else : err$ = "unknown " + Mid$(t$, 2) + " directive"
  EndIf

  If err$ <> "" Then Exit Sub

  lx_parse_basic("' PROCESSED: " + Mid$(lx_line$, lx_start(0) + 1))
End Sub

Sub process_endif()
  update_num_comments(- pop_if())
  If err$ <> "" Then Exit Sub
  lx_parse_basic("' PROCESSED: " + Mid$(lx_line$, lx_start(0) + 1))
End Sub

Sub update_num_comments(x)
  Local i = in_files_sz - 1
  num_comments(i) = num_comments(i) + x
End Sub

Function pop_if()
  Local i = in_files_sz - 1
  If if_stack_sz(i) = 0 Then err$ = "unmatched !endif" : Exit Function
  if_stack_sz(i) = if_stack_sz(i) - 1
  pop_if = if_stack(i, if_stack_sz(i))
End Function

Sub add_comments()
  Local nc = num_comments(in_files_sz - 1)
  If nc > 0 Then
    lx_parse_basic(String$(nc, "'") + " " + lx_line$)
  ElseIf nc < 0 Then
    Do While nc < 0 And lx_num > 0 And lx_type(0) = TK_COMMENT
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
      If err$ <> "" Then Exit Sub
    EndIf
  Next i
End Sub

Sub process_clear()
  If lx_num < 2 Then err$ = "expects a <flag> argument"
  If lx_num > 2 Then err$ = "has too many arguments"
  Local t$
  If err$ = "" Then
    t$ = lx_token_lc$(1)
    ' TODO: Is this really the behaviour we want?
    If set_get(flags$(), flags_sz, t$) < 0 Then err$ = "flag '" + t$ + "' is not set"
  EndIf
  If err$ = "" Then set_remove(flags$(), flags_sz, t$)
  If err$ <> "" Then err$ = "!clear directive " + err$
End Sub

Sub process_comments()
  If lx_num > 2 Then err$ = "has too many arguments"
  If err$ = "" Then op_set_comments(lx_token_lc$(1))
  If err$ <> "" Then err$ = "!comments directive " + err$
End Sub

Sub process_if()
  Local invert
  Local t$ = lx_token_lc$(1)

  If lx_num = 2 Then
    ' Do nothing
  ElseIf lx_num = 3 Then
    If t$ = "not" Then
      invert = 1
    Else
      err$ = "followed by unexpected token {" + lx_token$(1) + "}"
    EndIf
  Else
    err$ = "has too many arguments"
  EndIf

  If err$ <> "" Then
    err$ = lx_directive$(0) + " directive " + err$
    Exit Sub
  EndIf

  Local x = set_get(flags$(), flags_sz, t$) > -1
  If invert Then x = Not x

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
  Local i = in_files_sz - 1
  If if_stack_sz(i) = MAX_NUM_IFS Then Error "Too many if directives"
  if_stack(i, if_stack_sz(i)) = x
  if_stack_sz(i) = if_stack_sz(i) + 1
End Sub

Sub process_empty_lines()
  If lx_num > 2 Then err$ = "has too many arguments"
  If err$ = "" Then op_set_empty_lines(lx_token_lc$(1))
  If err$ <> "" Then err$ = "!empty-lines directive " + err$
End Sub

Sub process_include()
  If lx_num <> 2 Or lx_type(1) <> TK_STRING Then
    err$ = "#Include expects a <file> argument"
  Else
    tr_include$ = lx_string$(1)
  EndIf
End Sub

Sub process_indent()
  If lx_num > 2 Then err$ = "has too many arguments"
  If err$ = "" Then op_set_indent_sz(lx_token_lc$(1))
  If err$ <> "" Then err$ = "!indent directive " + err$
End Sub

Sub process_replace()
  If lx_num < 3 Then err$ = "expects <from> and <to> arguments"
  If lx_num > 3 Then err$ = "has too many arguments"
  If err$ = "" Then map_put(replace$(), with$(), replace_sz, lx_token_lc$(1), lx_token_lc$(2))
  If err$ <> "" Then err$ = "!replace directive " + err$
End Sub

Sub process_set()
  If lx_num < 2 Then err$ = "expects <flag> argument"
  If lx_num > 2 Then err$ = "has too many arguments"
  Local t$
  If err$ = "" Then
    t$ = lx_token_lc$(1)
    If set_get(flags$(), flags_sz, t$) > -1 Then err$ = "flag '" + t$ + "' is already set"
  EndIf
  If err$ = "" Then set_put(flags$(), flags_sz, t$)
  If err$ <> "" Then err$ = "!set directive " + err$
End Sub

Sub process_spacing()
  If lx_num > 2 Then err$ = " has too many arguments")
  If err$ = "" Then op_set_spacing(lx_token_lc$(1))
  If err$ <> "" Then err$ = "!spacing directive " + err$
End Sub
