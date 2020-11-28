' Copyright (c) 2020 Thomas Hugo Williams

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("map", "set")
sys.provides("trans")
If sys.err$ <> "" Then Error sys.err$

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
Dim flags$(set.new%(10))
set.init(flags$())

' The map of replacements.
Dim replace$(map.new%(200))
map.init(replace$())

' Set to name of file after processing #Include
Dim tr_include$

Sub transpile()
  tr_include$ = ""

  If lx.token_lc$(0) = "'!endif" Then
    process_endif()
    If sys.err$ <> "" Then Exit Sub
  EndIf

  add_comments()
  apply_replacements()
  If sys.err$ <> "" Then Exit Sub

  If lx.token_lc$(0) = "#include" Then
    process_include()
    If sys.err$ <> "" Then Exit Sub
  EndIf

  If lx.type(0) <> TK_DIRECTIVE Then Exit Sub

  Local t$ = lx.directive$(0)
  If     t$ = "!clear"        Then : process_clear()
  ElseIf t$ = "!comments"     Then : process_comments()
  ElseIf t$ = "!comment_if"   Then : process_if()
  ElseIf t$ = "!empty-lines"  Then : process_empty_lines()
  ElseIf t$ = "!indent"       Then : process_indent()
  ElseIf t$ = "!uncomment_if" Then : process_if()
  ElseIf t$ = "!replace"      Then : process_replace()
  ElseIf t$ = "!set"          Then : process_set()
  ElseIf t$ = "!spacing"      Then : process_spacing()
  Else : sys.err$ = "unknown " + Mid$(t$, 2) + " directive"
  EndIf

  If sys.err$ <> "" Then Exit Sub

  lx.parse_basic("' PROCESSED: " + Mid$(lx.line$, lx.start(0) + 1))
End Sub

Sub process_endif()
  update_num_comments(- popt.if())
  If sys.err$ <> "" Then Exit Sub
  lx.parse_basic("' PROCESSED: " + Mid$(lx.line$, lx.start(0) + 1))
End Sub

Sub update_num_comments(x)
  Local i = in.num_open_files% - 1
  num_comments(i) = num_comments(i) + x
End Sub

Function popt.if()
  Local i = in.num_open_files% - 1
  If if_stack_sz(i) = 0 Then sys.err$ = "unmatched !endif" : Exit Function
  if_stack_sz(i) = if_stack_sz(i) - 1
  popt.if = if_stack(i, if_stack_sz(i))
End Function

Sub add_comments()
  Local nc = num_comments(in.num_open_files% - 1)
  If nc > 0 Then
    lx.parse_basic(String$(nc, "'") + " " + lx.line$)
  ElseIf nc < 0 Then
    Do While nc < 0 And lx.num > 0 And lx.type(0) = TK_COMMENT
      lx.parse_basic(Space$(lx.start(0)) + Right$(lx.line$, Len(lx.line$) - lx.start(0)))
      nc = nc + 1
    Loop
  EndIf
End Sub

' Applies replacements to the currently parsed line, lx.line$.
Sub apply_replacements()
  If map.size%(replace$()) = 0 Then Exit Sub

  Local i, r$, s$
  For i = 0 TO lx.num - 1
    r$ = map.get$(replace$(), lx.token_lc$(i))
    If r$ <> map.NULL$ Then
      s$ = Left$(lx.line$, lx.start(i) - 1) + r$ + Mid$(lx.line$, lx.start(i) + lx.len(i))
      lx.parse_basic(s$)
      ' TODO: at the moment this can't change the number of tokens, but when it
      '       can this will need looking at closer.
      If sys.err$ <> "" Then Exit Sub
    EndIf
  Next i
End Sub

Sub process_clear()
  If lx.num < 2 Then sys.err$ = "expects a <flag> argument"
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  Local t$
  If sys.err$ = "" Then
    t$ = lx.token_lc$(1)
    ' TODO: Is this really the behaviour we want?
    If set.get%(flags$(), t$) < 0 Then sys.err$ = "flag '" + t$ + "' is not set"
  EndIf
  If sys.err$ = "" Then set.remove(flags$(), t$)
  If sys.err$ <> "" Then sys.err$ = "!clear directive " + sys.err$
End Sub

Sub process_comments()
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then opt.set_comments(lx.token_lc$(1))
  If sys.err$ <> "" Then sys.err$ = "!comments directive " + sys.err$
End Sub

Sub process_if()
  Local invert
  Local t$ = lx.token_lc$(1)

  If lx.num = 2 Then
    ' Do nothing
  ElseIf lx.num = 3 Then
    If t$ = "not" Then
      invert = 1
    Else
      sys.err$ = "followed by unexpected token {" + lx.token$(1) + "}"
    EndIf
  Else
    sys.err$ = "has too many arguments"
  EndIf

  If sys.err$ <> "" Then
    sys.err$ = lx.directive$(0) + " directive " + sys.err$
    Exit Sub
  EndIf

  Local x = set.get%(flags$(), t$) > -1
  If invert Then x = Not x

  If lx.directive$(0) = "!comment_if" Then
    push_if(x)
    If x Then update_num_comments(+1)
  ElseIf lx.directive$(0) = "!uncomment_if" Then
    push_if(-x)
    If x Then update_num_comments(-1)
  Else
    Error
  EndIf
End Sub

Sub push_if(x)
  Local i = in.num_open_files% - 1
  If if_stack_sz(i) = MAX_NUM_IFS Then Error "Too many if directives"
  if_stack(i, if_stack_sz(i)) = x
  if_stack_sz(i) = if_stack_sz(i) + 1
End Sub

Sub process_empty_lines()
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then opt.set_empty_lines(lx.token_lc$(1))
  If sys.err$ <> "" Then sys.err$ = "!empty-lines directive " + sys.err$
End Sub

Sub process_include()
  If lx.num <> 2 Or lx.type(1) <> TK_STRING Then
    sys.err$ = "#Include expects a <file> argument"
  Else
    tr_include$ = lx.string$(1)
  EndIf
End Sub

Sub process_indent()
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then opt.set_indent_sz(lx.token_lc$(1))
  If sys.err$ <> "" Then sys.err$ = "!indent directive " + sys.err$
End Sub

Sub process_replace()
  If lx.num < 3 Then sys.err$ = "expects <from> and <to> arguments"
  If lx.num > 3 Then sys.err$ = "has too many arguments"
  If sys.err$ = "" Then map.put(replace$(), lx.token_lc$(1), lx.token_lc$(2))
  If sys.err$ <> "" Then sys.err$ = "!replace directive " + sys.err$
End Sub

Sub process_set()
  If lx.num < 2 Then sys.err$ = "expects <flag> argument"
  If lx.num > 2 Then sys.err$ = "has too many arguments"
  Local t$
  If sys.err$ = "" Then
    t$ = lx.token_lc$(1)
    If set.get%(flags$(), t$) > -1 Then sys.err$ = "flag '" + t$ + "' is already set"
  EndIf
  If sys.err$ = "" Then set.put(flags$(), t$)
  If sys.err$ <> "" Then sys.err$ = "!set directive " + sys.err$
End Sub

Sub process_spacing()
  If lx.num > 2 Then sys.err$ = " has too many arguments")
  If sys.err$ = "" Then opt.set_spacing(lx.token_lc$(1))
  If sys.err$ <> "" Then sys.err$ = "!spacing directive " + sys.err$
End Sub
