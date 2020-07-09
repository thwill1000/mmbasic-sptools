' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "lexer.inc"
#Include "replace.inc"
#Include "pprint.inc"

Const MAX_NUM_FILES = 5
Const MAX_NUM_FLAGS = 10
Const MAX_NUM_IFS = 10

Dim num_files = 0
Dim flatten_includes = 1

' We just ignore the 0'th element in all of these.
Dim file_stack$(MAX_NUM_FILES) Length 40
Dim cur_line_no(MAX_NUM_FILES)
Dim num_comments(MAX_NUM_FILES)
Dim num_ifs(MAX_NUM_FILES)
Dim if_stack(MAX_NUM_FILES, MAX_NUM_IFS)
Dim flags$(MAX_NUM_FLAGS)

Sub open_file(f$)
  Local f2$, p

  cout(Chr$(13)) ' CR

  If num_files > 0 Then
    f2$ = get_parent$(file_stack$(1)) + f$
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

Function get_parent$(f$)
  Local ch$, p

  p = Len(f$)
  Do
    ch$ = Chr$(Peek(Var f$, p))
    If (ch$ = "/") Or (ch$ = "\") Then Exit Do
    p = p - 1
  Loop Until p = 0

  If p > 0 Then get_parent$ = Left$(f$, p)
End Function

Function fi_exists(f$)
  Local s$
  s$ = Dir$(f$, File)
  If s$ = "" Then s$ = Dir$(f$, Dir)
  fi_exists = s$ <> ""
End Function

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

Sub close_file()
  Close #num_files
  num_files = num_files - 1
  cout(Chr$(8) + " " + Chr$(13) + Space$(1 + num_files * 2))
End Sub

Function read_line$()
  Local s$
  Line Input #num_files, s$
  read_line$ = s$
  cur_line_no(num_files) = cur_line_no(num_files) + 1
End Function

Sub add_comments()
  Local nc = num_comments(num_files)
  If nc > 0 Then
    parse_line(String$(nc, "'") + lx_line$)
  ElseIf nc < 0 Then
    Do While nc < 0 And lx_num > 0 And lx_type(0) = LX_COMMENT
      parse_line(Space$(lx_start(0)) + Right$(lx_line$, Len(lx_line$) - lx_start(0)))
      nc = nc + 1
    Loop
  EndIf
End Sub

Sub push_if(x)
  If num_ifs(num_files) = MAX_NUM_IFS Then Error "Too many if directives"
  num_ifs(num_files) = num_ifs(num_files) + 1
  if_stack(num_files, num_ifs(num_files)) = x
End Sub

Function pop_if()
  If num_ifs(num_files) = 0 Then Error "If directive stack is empty"
  pop_if = if_stack(num_files, num_ifs(num_files))
  num_ifs(num_files) = num_ifs(num_files) - 1
End Function

Sub process_directives()
  Local t$ = lx_token_lc$(0)

  If t$ = "'!endif" Then
    update_num_comments(- pop_if())
    parse_line("' PROCESSED: " + lx_line$)
  EndIf

  add_comments()

  t$ = lx_token_lc$(0)

  If t$ = "#include" Then
    Local f$ = lx_token$(1)
    f$ = Mid$(f$, 2, Len(f$) - 2)
    open_file(f$)
    parse_line("' -------- BEGIN " + lx_line$ + " --------")
  EndIf

  If lx_type(0) <> LX_DIRECTIVE    Then : Exit Sub
  ElseIf t$ = "'!clear"            Then : process_clear()
  ElseIf t$ = "'!comments"         Then : process_comments()
  ElseIf t$ = "'!comment_if"       Then : process_comment_if()
  ElseIf t$ = "'!flatten"          Then : process_flatten()
  ElseIf t$ = "'!indent"           Then : process_indent()
  ElseIf t$ = "'!uncomment_if"     Then : process_uncomment_if()
  ElseIf t$ = "'!replace"          Then : process_replace()
  ElseIf t$ = "'!set"              Then : process_set()
  ElseIf t$ = "'!spacing"          Then : process_spacing()
  Else : cerror("Unknown directive: " + Mid$(t$, 2))
  EndIf

  parse_line("' PROCESSED: " + lx_line$)
End Sub

Sub process_clear()
  If lx_num <> 2 Then cerror("Syntax error: !clear directive requires 'flag' parameter")
  clear_flag(lx_token_lc$(1))
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

Sub process_comment_if()
  Local t$, x

  t$ = lx_token_lc$(1)

  If lx_num = 2 Then
    x = get_flag(t$)
  Else If lx_num = 3 Then
    If t$ <> "not" Then
      t$ = "Syntax error: !comment_if directive followed by unexpected token '"
      t$ = t$ + lx_token$(1) + "'"
      cerror(t$)
    EndIf
    x = 1 - get_flag(t$)
  Else
    cerror("Syntax error: !comment_if directive with invalid parameters")
  EndIf

  push_if(x)
  If x Then update_num_comments(+1)
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

Sub process_indent()
  If lx_num < 2 Or lx_type(1) <> LX_NUMBER Then
    cerror("Syntax error: !indent requires 'number' parameter")
  Else 
    pp_indent_sz = lx_get_number(1)
  EndIf
End Sub

Sub process_uncomment_if()
  Local t$, x

  t$ = lx_token_lc$(1)

  If lx_num = 2 Then
    x = get_flag(t$)
  Else If lx_num = 3 Then
    If t$ <> "not" Then
      t$ = "Syntax error: !uncomment_if directive followed by unexpected token '"
      t$ = t$ + lx_token$(1) + "'"
      cerror(t$)
    EndIf
    x = 1 - get_flag(t$)
  Else
    cerror("Syntax error: !comment_if directive with invalid parameters")
  EndIf

  push_if(-x)
  If x Then update_num_comments(-1)
End Sub

Sub process_replace()
  If lx_num <> 3 Then
    cerror("Syntax error: !replace directive requires 'from' and 'to' parameters")
  EndIf
  rp_add(lx_token_lc$(1), lx_token_lc$(2))
End Sub

Sub process_set()
  If lx_num <> 2 Then cerror("Syntax error: !set directive requires 'flag' parameter")
  set_flag(lx_token_lc$(1))
End Sub

Sub process_spacing()
  ' TODO
End Sub

Sub update_num_comments(x)
  num_comments(num_files) = num_comments(num_files) + x
End Sub

Function get_flag(s$)
  Local i
  If s$ = "" Then Error "No flag specified"
  For i = 0 To MAX_NUM_FLAGS - 1
    If flags$(i) = s$ Then get_flag = 1 : Exit Function
  Next i
End Function

Sub set_flag(s$)
  Local i, j = -1
  If s$ = "" Then Error "No flag specified"
  For i = 0 To MAX_NUM_FLAGS - 1
    If j = -1 And flags$(i) = "" Then j = i
    If flags$(i) = s$ Then Exit Sub ' already set
  Next i
  If j = -1 Then Error "Too many flags"
  flags$(j) = s$
End Sub

Sub clear_flag(s$)
  Local i
  If s$ = "" Then Error "No flag specified"
  For i = 0 To MAX_NUM_FLAGS - 1
    If flags$(i) = s$ Then flags$(i) = "" : Exit Sub
  Next i
End Sub

Sub parse_line(s$)
  lx_parse_line(s$)
  rp_apply()
End Sub

Sub main()
  Local in$, out$, s$, t

  Cls

  lx_load_keywords()

  lx_parse_line(Mm.CmdLine$)
  If lx_num = 0 Then Error "No input filename specified"
  If lx_num > 0 Then
    If lx_type(0) <> LX_STRING Then Error "Input filename must be quoted"
    in$ = lx_get_string$(0)
  EndIf
  If lx_num > 1 Then
    If lx_type(1) <> LX_STRING Then Error "Output filename must be quoted"
    out$ = lx_get_string$(1)
  EndIf

  pp_open(out$, 0)
  cout("Transpiling from '" + in$ + "' to '" + out$ + "' ...") : cendl()
  open_file(in$)

  t = Timer
  Do
    cout(Chr$(8) + Mid$("\|/-", ((cur_line_no(num_files) \ 8) Mod 4) + 1, 1))
    s$ = read_line$()
    parse_line(s$)
    If lx_error$ <> "" Then cerror(lx_error$)
    process_directives()
    pp_print_line()

    If Eof(#num_files) Then
      If num_files > 1 Then
        s$ = "' -------- END #Include " + Chr$(34)
        s$ = s$ + file_stack$(num_files) + Chr$(34) + " --------"
        parse_line(s$)
        pp_print_line()
      EndIf
      close_file()
    EndIf

  Loop Until num_files = 0

  cout(Chr$(13) + "Time taken = " +Format$((Timer - t) / 1000, "%.1f s"))

  pp_close()

End Sub

main()
End
