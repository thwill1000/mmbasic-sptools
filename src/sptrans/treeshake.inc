' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

' Performs 'tree-shaking' to remove unused functions & subroutines.

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("array", "output", "symbols")
sys.provides("treeshake")
If sys.err$ <> "" Then Error sys.err$
'!endif

Function tree.shake%()
  If opt.outfile$ = "" Then Error "No output file specified"

  Local orphans%(array.new%(sym.MAX_FUNCTIONS))
  tree.shake% = tree.get_orphan_fns%(orphans%())
  If tree.shake% < 0 Then Exit Function

  Open opt.outfile$ For Input As #1
  Open opt.outfile$ + ".shake" For Output As #2

  Local i% = 0, fn$ = sys.NO_DATA$, line_num%, s$, tmp% = orphans%(i%)
  Inc i%
  If tmp% >= 0 Then fn$ = Mid$(sym.functions$(tmp%), sym.MAX_NAME_LEN + 1)
  Local sline%, scol%, eline%, ecol%
  tree.unpickle(fn$, sline%, scol%, eline%, ecol%)

  Local was_empty% ' Last output line was empty
  Local was_omitted% ' Last input line was omitted

  Do While Not Eof(#1)
    Inc line_num%
    Line Input #1, s$

    If line_num% = sline% Then
      Do While Not Eof(#1) And line_num% < eline%
        Inc line_num%
        Line Input #1, s$
      Loop
      tmp% = orphans%(i%)
      Inc i%
      If tmp% >= 0 Then
        fn$ = Mid$(sym.functions$(tmp%), sym.MAX_NAME_LEN + 1)
      Else
        fn$ = sys.NO_DATA$
      EndIf
      tree.unpickle(fn$, sline%, scol%, eline%, ecol%)
      was_omitted% = 1
      Continue Do
    EndIf

    ' Don't accumulate empty lines between omitted functions.
    If Not (s$ = "" And was_empty% And was_omitted%) Then
      was_empty% = s$ = ""
      was_omitted% = 0
      Print #2, s$ + out.eol$;
    EndIf
  Loop

  Close #2
  Close #1

  Kill opt.outfile$
  Rename opt.outfile$ + ".shake" As opt.outfile$

  tree.shake% = sys.SUCCESS
End Function

Sub tree.unpickle(fn$, sline%, scol%, eline%, ecol%)
  If fn$ = sys.NO_DATA$ Then
    sline% = 0
    scol% = 0
    eline% = 0
    ecol% = 0
  Else
    sline% = Val(Field$(Field$(fn$, 6, ","), 1, ":"))
    scol% = Val(Field$(Field$(fn$, 6, ","), 2, ":"))
    eline% = Val(Field$(Field$(fn$, 7, ","), 1, ":"))
    ecol% = Val(Field$(Field$(fn$, 7, ","), 2, ":"))
  EndIf
End Sub

' Gets orphan functions in the order that they are declared.
'
' @param[out]  indexes into sym.functions%() of orphaned functions.
' @return      number of orphaned functions.
Function tree.get_orphan_fns%(indexes%())
  ' Set all elements to -1.
  Memory Set Peek(VarAddr indexes%()), &hFF, (Bound(indexes%(), 1) + 1) * 8

  ' Get orphaned identifiers.
  Local orphans%(array.new%(sym.MAX_NAMES \ 64) + 1)
  Local num_orphans% = sym.get_orphans%(0, orphans%())
  If num_orphans% < 0 Then
    tree.get_orphan_fns% = num_orphans%
    Exit Function
  EndIf
  bits.big_clear(orphans%(), 0) ' *global* is not an orphan.

  ' Copy orphaned functions into the array.
  Local fn$, i%, j%, id%
  For i% = 0 To map2.size%(sym.functions$()) - 1
    fn$ = Mid$(sym.functions$(i%), sym.MAX_NAME_LEN + 1)
    id% = Val(Field$(fn$, 5))
    If bits.big_get%(orphans%(), id%) Then
      indexes%(j%) = i%
      Inc j%
    EndIf
  Next

  ' Sort the array in declaration order.
  Const result% = Choice(j%, array.qsort_ints%(indexes%(), 0, j%, "tree.fn_comparator%"), 0)

  tree.get_orphan_fns% = Choice(result% = sys.SUCCESS, j%, result%)
End Function

' @return  -1 if fn a% is declared before b%
'          +1 if fn a% is declared after b%
'!dynamic_call tree.fn_comparator%
Function tree.fn_comparator%(a%, b%)
  Const fn_a$ = Mid$(sym.functions$(a%), sym.MAX_NAME_LEN + 1)
  Const fn_b$ = Mid$(sym.functions$(b%), sym.MAX_NAME_LEN + 1)
  Const line_a% = Val(Field$(Field$(fn_a$, 6, ","), 1, ":"))
  Const line_b% = Val(Field$(Field$(fn_b$, 6, ","), 1, ":"))
  If line_a% <> line_b% Then tree.fn_comparator% = Choice(line_a% - line_b% < 0, -1, 1)
End Function
