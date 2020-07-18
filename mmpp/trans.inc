' Copyright (c) 2020 Thomas Hugo Williams

Const MAX_NUM_IFS = 10

Dim flatten_includes = 1

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
  parse_line(s$)
  process_directives()
End Sub

Sub parse_line(s$)
  lx_parse_basic(s$)
  If lx_error$ <> "" Then cerror(lx_error$)
  apply_replacements()
  If lx_error$ <> "" Then cerror(lx_error$)
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
      ' TODO: what if this changes the number of tokens?
    EndIf
  Next i
End Sub

Sub process_directives()
  If lx_token_lc$(0) = "'!endif" Then process_endif()

  add_comments()

  If lx_token_lc$(0) = "#include" Then process_include()

  If lx_type(0) <> TK_DIRECTIVE Then Exit Sub

  Local t$ = lx_directive$(0)
  If     t$ = "!clear"        Then : process_clear()
  ElseIf t$ = "!comments"     Then : process_comments()
  ElseIf t$ = "!comment_if"   Then : process_if()
  ElseIf t$ = "!flatten"      Then : process_flatten()
  ElseIf t$ = "!indent"       Then : process_indent()
  ElseIf t$ = "!uncomment_if" Then : process_if()
  ElseIf t$ = "!replace"      Then : process_replace()
  ElseIf t$ = "!set"          Then : process_set()
  ElseIf t$ = "!spacing"      Then : process_spacing()
  Else : cerror("Unknown directive: " + Mid$(t$, 2))
  EndIf

  parse_line("' PROCESSED: " + lx_line$)
End Sub

Sub process_endif()
  update_num_comments(- pop_if())
  parse_line("' PROCESSED: " + lx_line$)
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
    parse_line(String$(nc, "'") + lx_line$)
  ElseIf nc < 0 Then
    Do While nc < 0 And lx_num > 0 And lx_type(0) = TK_COMMENT
      parse_line(Space$(lx_start(0)) + Right$(lx_line$, Len(lx_line$) - lx_start(0)))
      nc = nc + 1
    Loop
  EndIf
End Sub

Sub process_clear()
  Local t$ = lx_token_lc$(1)
  If lx_num <> 2 Or t$ = "" Then
    cerror("Syntax error: !clear directive requires 'flag' parameter")
  EndIf
  If set_get(flags$(), flags_sz, t$) < 0 Then
    ' TODO: Is this really the behaviour we want?
    cerror("Error: flag '" + t$ + "' is not set")
  EndIf
  set_remove(flags$(), flags_sz, t$)
End Sub

Sub process_comments()
  Local t$ = lx_token_lc$(1)
  If t$ = "on" Then
    pp_comment = 1
  ElseIf t$ = "off" Then
    pp_comment = 0
  Else
    cerror("Syntax error: !comments directive requires 'on|off' parameter")
  EndIf
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
    cerror("Syntax error: " + lx_directive$(0) + " directive with invalid parameters")
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

Sub process_flatten()
  Local t$ = lx_token_lc$(1)
  If t$ = "on" Then
    flatten_includes = 1
  ElseIf t$ = "off" Then
    flatten_includes = 0
  Else
    cerror("Syntax error: !flatten directive requires 'on|off' parameter")
  EndIf
End Sub

Sub process_include()
  If lx_num <> 2 Or lx_type(1) <> TK_STRING Then
    cerror("Syntax error: #Include requires a 'file' parameter")
  EndIf
  open_file(lx_string$(1))
  parse_line("' -------- BEGIN " + lx_line$ + " --------")
End Sub

Sub process_indent()
  If lx_num < 2 Or lx_type(1) <> TK_NUMBER Then
    cerror("Syntax error: !indent requires 'number' parameter")
  EndIf
  pp_indent_sz = lx_number(1)
End Sub

Sub process_replace()
  If lx_num <> 3 Then
    cerror("Syntax error: !replace directive requires 'from' and 'to' parameters")
  EndIf
  map_put(replace$(), with$(), replace_sz, lx_token_lc$(1), lx_token_lc$(2))
End Sub

Sub process_set()
  Local t$ = lx_token_lc$(1)
  If lx_num <> 2 Or t$ = "" Then
    cerror("Syntax error: !set directive requires 'flag' parameter")
  EndIf
  If set_get(flags$(), flags_sz, t$) > -1 Then
    cerror("Error: flag '" + t$ + "' is already set")
  EndIf
  set_put(flags$(), flags_sz, t$)
End Sub

Sub process_spacing()
  ' TODO
End Sub
