' Copyright (c) 2020 Thomas Hugo Williams

'!comment_if foo
'!uncomment_if foo
'!comment_if_not foo
'!uncomment_if_not foo
'!endif
'!enable foo
'!disable foo
'!replace foo bar

Option Explicit On
Option Default Integer

#Include "lexer.inc"

Const VT100_RED = Chr$(27) + "[31m"
Const VT100_GREEN = Chr$(27) + "[32m"
Const VT100_YELLOW = Chr$(27) + "[33m"
Const VT100_BLUE = Chr$(27) + "[34m"
Const VT100_MAGENTA = Chr$(27) + "[35m"
Const VT100_CYAN = Chr$(27) + "[36m"
Const VT100_WHITE = Chr$(27) + "[37m"

Dim TK_COLOUR$(6)
TK_COLOUR$(LX_IDENTIFIER) = VT100_WHITE
TK_COLOUR$(LX_NUMBER) = VT100_GREEN
TK_COLOUR$(LX_COMMENT) = VT100_YELLOW
TK_COLOUR$(LX_STRING_LITERAL) = VT100_MAGENTA
TK_COLOUR$(LX_KEYWORD) = VT100_CYAN
TK_COLOUR$(LX_SYMBOL) = VT100_WHITE
TK_COLOUR$(LX_DIRECTIVE) = VT100_RED

Sub main()
  Local col, count, f$, i, no_space, s$, t$

  Cls

  lx_init()

  f$ = "mmpp.bas"
'  f$ = "examples/zmim_main.bas"
'  f$ = "examples/maxdash.bas"
  Open f$ For Input As #1

  Do
    Line Input #1, s$

    count = count + 1
    Print VT100_WHITE$ + Format$(count, "%-4g") + ": ";
    lx_parse_line(s$)

    For i = 0 To lx_num - 1
      If i = 0 Then Print Space$(lx_start(i) - 1);
      t$ = lx_get_token$(i)
      If t$ <> "" Then
'        Print VT100_WHITE; "{";
        Print TK_COLOUR$(lx_type(i)); t$;
        If i < lx_num - 1 Then
          no_space = t$ = "("
          no_space = no_space Or lx_get_token$(i + 1) = "("
          no_space = no_space Or lx_get_token$(i + 1) = ")"
          no_space = no_space Or lx_get_token$(i + 1) = ","
          no_space = no_space Or lx_get_token$(i + 1) = ";"
          no_space = no_space And t$ <> "=" And t$ <> ","
          If Not no_space Then Print " ";
        EndIf
'        Print VT100_WHITE; "}";
      EndIf
    Next i
    Print

'    If count = 40 Then Exit

  Loop Until Eof(#1)

  Close #1

End Sub

main()
End
