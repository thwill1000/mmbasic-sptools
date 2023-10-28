' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

' Processes parsed MMBasic input to populate the symbol tables.

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("lexer", "output", "symbols")
sys.provides("symproc")
If sys.err$ <> "" Then Error sys.err$
'!endif

Const symproc.GLOBAL_SCOPE = "*global*"

' Line number in the transpiled code at which the leading comment for a
' function potentially started.
Dim symproc.comment_line%

Dim symproc.scope$

Sub symproc.init(max_functions%, max_identifiers%, references_size_kb%))
  sym.init(max_functions%, max_identifiers%, references_size_kb%)
  If sym.add_function%(symproc.GLOBAL_SCOPE, in.files$(0), 1) <> sys.SUCCESS Then Error sys.err$
  symproc.scope$ = symproc.GLOBAL_SCOPE
End Sub

' Called at the start a of FUNCTION/SUB definition.
'
' @param  idx%  index of the CFUNCTION/CSUB/FUNCTION/SUB token.
Function symproc.fn_decl%(idx%)
  If symproc.scope$ <> symproc.GLOBAL_SCOPE Then
    symproc.fn_decl% = sys.error%(sys.FAILURE, "Nested FUNCTION/SUB")
  Else
    Const fnbr% = in.num_open_files% - 1, fn_name$ = lx.token_lc$(idx% + 1)
    Const file$ = in.files$(fnbr%), line% = in.line_num%(fnbr%), scol% = lx.start(idx%)
    Const sline% = Choice(symproc.comment_line%, symproc.comment_line%, out.line_num)
    symproc.fn_decl% = sym.add_function%(fn_name$, file$, line%, sline%, scol%)
    If symproc.fn_decl% >= 0 Then symproc.scope$ = fn_name$
  EndIf
End Function

' Called at the END of the current FUNCTION/SUB definition.
'
' @param  idx%  index of the CFUNCTION/CSUB/FUNCTION/SUB token.
Function symproc.fn_end%(idx%)
  If symproc.scope$ = symproc.GLOBAL_SCOPE Then
    symproc.fn_end% = sys.error%(sys.FAILURE, "Unbalanced END FUNCTION/SUB")
  Else
    Const ecol% = lx.start(idx%) + lx.len(idx%) - 1
    symproc.fn_end% = sym.end_function%(symproc.scope$, out.line_num, ecol%)
    symproc.scope$ = symproc.GLOBAL_SCOPE
  EndIf
End Function

Function symproc.identifier%(idx%)
  symproc.identifier% = sym.add_name%(lx.token$(idx%))
  If symproc.identifier% < 0 Then Exit Function

  If idx% > 0 Then
    If InStr(" cfunction csub function sub ", " " + lx.token_lc$(idx% - 1) + " ") Then
      symproc.identifier% = symproc.fn_decl%(idx% - 1)
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
        symproc.keyword% = symproc.fn_end%(idx% + 1)
      EndIf
    EndIf
  EndIf
End Function

Function symproc.process%()
  If lx.num > 0 And lx.type(0) = TK_COMMENT Then
    If Not symproc.comment_line% Then symproc.comment_line% = out.line_num%
    Exit Function
  EndIf

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

  symproc.comment_line% = 0
  If symproc.process% >= 0 Then symproc.process% = sys.SUCCESS
End Function
