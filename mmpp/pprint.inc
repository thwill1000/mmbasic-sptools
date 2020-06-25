' Copyright (c) 2020 Thomas Hugo Williams

Const VT100_RED = Chr$(27) + "[31m"
Const VT100_GREEN = Chr$(27) + "[32m"
Const VT100_YELLOW = Chr$(27) + "[33m"
Const VT100_BLUE = Chr$(27) + "[34m"
Const VT100_MAGENTA = Chr$(27) + "[35m"
Const VT100_CYAN = Chr$(27) + "[36m"
Const VT100_WHITE = Chr$(27) + "[37m"
Const VT100_RESET = Chr$(27) + "[0m"

Dim TK_COLOUR$(6)
TK_COLOUR$(LX_IDENTIFIER) = VT100_WHITE
TK_COLOUR$(LX_NUMBER) = VT100_GREEN
TK_COLOUR$(LX_COMMENT) = VT100_YELLOW
TK_COLOUR$(LX_STRING) = VT100_MAGENTA
TK_COLOUR$(LX_KEYWORD) = VT100_CYAN
TK_COLOUR$(LX_SYMBOL) = VT100_WHITE
TK_COLOUR$(LX_DIRECTIVE) = VT100_RED

Dim pp_file_num = -1
Dim pp_count
Dim pp_indent

Sub pp_open(f$)
  If f$ <> "" Then
    pp_file_num = 10
    Open f$ For Output As #pp_file_num
  EndIf
End Sub

Sub pp_close()
  If pp_file_num > -1 Then Close #pp_file_num
End Sub

Sub pp_print_line()
  pp_print_compact()
End Sub

Sub pp_print_default()
  Local i, no_space, t$, u$

  For i = 0 To lx_num - 1
    If i = 0 Then pp_out(Space$(lx_start(i) - 1))
    t$ = lx_get_token$(i)
    If t$ <> "" Then
      pp_attrib(TK_COLOUR$(lx_type(i)))
      pp_out(t$)
      If i < lx_num - 1 Then
        u$ = lx_get_token$(i + 1)
        no_space = t$ = "("
        no_space = no_space Or u$ = "(" Or u$ = ")" Or u$ = "," Or u$ = ";"
        no_space = no_space And t$ <> "=" And t$ <> ","
        If Not no_space Then pp_out(" ")
      EndIf
    EndIf
  Next i
  pp_attrib(VT100_RESET)
  pp_endl()
End Sub

Sub pp_inc_line()
  pp_count = pp_count + 1
  If pp_file_num = -1 Then
    pp_attrib(VT100_WHITE)
    pp_out(Format$(pp_count, "%-4g") + ": ")
  EndIf
End Sub

Function needs_trailing_space(i)
  Local t = lx_type(i)
  needs_trailing_space = t = LX_KEYWORD Or t = LX_IDENTIFIER Or t = LX_NUMBER
End Function

Sub pp_print_compact()
  Local i, space, t$, u$

  If lx_num = 0 Then Exit Sub
  If lx_num = 1 And lx_type(i) = LX_COMMENT Then Exit Sub

  pp_inc_line()

  For i = 0 To lx_num - 1
    If i = lx_num - 1 And lx_type(i) = LX_COMMENT Then Exit For

    t$ = LCase$(lx_get_token$(i))
    If t$ <> "" Then
      If Instr(" else elseif endif end loop next exit ", " " + t$  + " ") > 0 Then
        pp_indent = pp_indent - 1 ': Print "{"; pp_indent; "}";
        If t$ = "end" Then pp_indent = pp_indent - 1
      EndIf

      If i = 0 and pp_indent > 0 Then pp_out(Space$(pp_indent))

      pp_attrib(TK_COLOUR$(lx_type(i)))
      pp_out(lx_get_token$(i))
      If i < lx_num - 1 Then
        If needs_trailing_space(i) Then
          space = needs_trailing_space(i + 1)
        Else
          space = 0
        EndIf
        If space Then pp_out(" ")
      EndIf

      If Instr(" else then for do sub function ", " " + t$ + " ") > 0 Then
        pp_indent = pp_indent + 1 ': Print "{"; pp_indent; "}";
        u$ = LCase$(lx_get_token$(i + 1))
        If t$ = "for" And (u$ = "input" Or u$ = "output") Then
          pp_indent = pp_indent - 1 ': Print "{"; pp_indent; "}";
        EndIf
        If t$ = "then" Then
          If u$ <> "" And Left$(u$, 1) <> "'" Then
            pp_indent = pp_indent -1
          EndIf
        EndIf
      EndIf
    EndIf
  Next i
  pp_attrib(VT100_RESET)
  pp_endl()

  If Instr(" sub function ", " " + t$ + " ") Then
    pp_inc_line()
    pp_endl()
  EndIf

End Sub

Sub pp_attrib(c$)
  If pp_file_num < 0 Then pp_out(c$)
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
