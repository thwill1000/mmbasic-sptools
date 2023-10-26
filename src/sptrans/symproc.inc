' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

' Processes parsed MMBasic input to populate the symbol tables.

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("lexer", "symbols")
sys.provides("symproc")
If sys.err$ <> "" Then Error sys.err$
'!endif

Const symproc.GLOBAL_SCOPE = "*global*"

Dim symproc.scope$

Sub symproc.init(max_functions%, max_identifiers%, references_size_kb%))
  sym.init(max_functions%, max_identifiers%, references_size_kb%)
  If sym.add_function%(symproc.GLOBAL_SCOPE, in.files$(0), 1) <> sys.SUCCESS Then Error sys.err$
  symproc.scope$ = symproc.GLOBAL_SCOPE
End Sub

Function symproc.fn_decl%(name$)
  If symproc.scope$ <> symproc.GLOBAL_SCOPE Then
    symproc.fn_decl% = sys.error%(sys.FAILURE, "Nested FUNCTION/SUB")
  Else
    Local fnbr% = in.num_open_files% - 1
    symproc.fn_decl% = sym.add_function%(name$, in.files$(fnbr%), in.line_num%(fnbr%))
    If symproc.fn_decl% >= 0 Then symproc.scope$ = name$
  EndIf
End Function

Function symproc.fn_end%()
  If symproc.scope$ = symproc.GLOBAL_SCOPE Then
    symproc.fn_end% = sys.error%(sys.FAILURE, "Unbalanced END FUNCTION/SUB")
  Else
    symproc.scope$ = symproc.GLOBAL_SCOPE
  EndIf
End Function

Function symproc.identifier%(idx%)
  symproc.identifier% = sym.add_name%(lx.token$(idx%))
  If symproc.identifier% < 0 Then Exit Function

  If idx% > 0 Then
    If InStr(" cfunction csub function sub ", " " + lx.token_lc$(idx% - 1) + " ") Then
      symproc.identifier% = symproc.fn_decl%(lx.token_lc$(idx%))
      Exit Function
    EndIf
  EndIf

  If symproc.scope$ = symproc.GLOBAL_SCOPE Then
    symproc.identifier% = sym.switch_function%(symproc.GLOBAL_SCOPE)
  EndIf
  If symproc.identifier% >= 0 Then
    symproc.identifier% = sym.add_reference%(lx.token$(idx%))
  EndIf
End Function

Function symproc.keyword%(idx%)
  If idx% < lx.num - 1 Then
    If lx.token_lc$(idx%) = "end" Then
      If InStr(" cfunction csub function sub ", " " + lx.token_lc$(idx% + 1) + " ") Then
        symproc.keyword% = symproc.fn_end%()
      EndIf
    EndIf
  EndIf
End Function

Function symproc.process%()
  Local i%
  For i% = 0 To lx.num - 1
    Select Case lx.type(i%)
      Case TK_IDENTIFIER
        symproc.process% = symproc.identifier%(i%)
      Case TK_KEYWORD
        symproc.process% = symproc.keyword%(i%)
    End Select
    If symproc.process% < 0 Then Exit For
  Next

  If symproc.process% >= 0 Then symproc.process% = sys.SUCCESS
End Function
