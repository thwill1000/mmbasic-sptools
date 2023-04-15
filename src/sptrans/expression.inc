' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("defines")
sys.provides("expression")
If sys.err$ <> "" Then Error sys.err$

' Evaluates an !IF preprocessor expression on the current line.
'
' @param[in]  idx      token index to start evaluating the expression from.
' @param[out] result%  1 for true, 0 for false.
' @return              sys.SUCCESS on success, any other value is an error,
'                      see 'sys.err$' for details.
Function ex.eval%(idx%, result%)
  Local i%, expr$, x%, t$

  For i% = idx% To lx.num - 1
    t$ = lx.token_lc$(i%)
    Select Case t$
      Case "defined"
        ' Ignore for now
      Case "!", "not"
        Cat expr$, " Not "
      Case "&&", "and"
        Cat expr$, " And "
      Case "||", "or"
        Cat expr$, " Or "
      Case "xor"
        Cat expr$, " Xor "
      Case "(", ")"
        Cat expr$, t$
      Case Else
        Select Case lx.type(i%)
          Case TK_IDENTIFIER, TK_NUMBER, TK_KEYWORD
            Cat expr$, Str$(def.is_defined%(t$))
          Case Else
            expr$ = ""
            Exit For
        End Select
    End Select
  Next

  ' Print "Expression: " expr$
  If expr$ = "" Then
    ex.eval% = sys.FAILURE
  Else
    ex.eval% = sys.SUCCESS
    On Error Ignore
    result% = Eval(expr$)
    If Mm.ErrNo <> 0 Then
      ex.eval% = sys.FAILURE
      On Error Clear
    EndIf
  EndIf

  If ex.eval% <> sys.SUCCESS Then sys.err$ = "Invalid expression syntax"
End Function
