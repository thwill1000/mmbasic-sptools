' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Base 0
Option Default Integer
Option Explicit On

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/bits.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/map.inc"
#Include "../../splib/map2.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../../common/sptools.inc"
#Include "../keywords.inc"
#Include "../lexer.inc"
#Include "../options.inc"
#Include "../output.inc"

sys.provides("console")
Sub con.spin()
End Sub

#Include "../symbols.inc"
#Include "../input.inc"
#Include "../symproc.inc"
#Include "../treeshake.inc"

Dim actual$(20), expected$(20), lines$(20)

keywords.init()

add_test("test_unpickle_gvn_data")
add_test("test_unpickle_gvn_no_data")
add_test("test_fn_comparator")
add_test("test_get_orphan_fns")
add_test("test_get_orphan_fns_gvn_none")
add_test("test_shake_gvn_orphans")
add_test("test_shake_gvn_no_orphans")
add_test("test_shake_gvn_all_orphans")
add_test("test_shake_gvn_empty_lines")

run_tests()

End

Sub setup_test()
  opt.init()
  in.init()
  list.push(in.files$(), "my_file.bas")
  in.num_open_files% = 1
  out.line_num = 0
  symproc.init(32, 300, 1)
  clear_arrays()
  sys.err$ = ""
End Sub

Sub clear_arrays()
  array.fill(actual$())
  array.fill(expected$())
  array.fill(lines$())
End Sub

Sub parse_and_process(lines$())
  Local i%, result%
  For i% = 1 To Bound(lines$(), 1)
    Inc out.line_num
    in.line_num%(0) = i%
    result% = lx.parse_basic%(lines$(i%))
    If result% <> sys.SUCCESS Then Exit For
    result% = symproc.process%()
    If result% <> sys.SUCCESS Then Exit For
  Next
  assert_int_equals(sys.SUCCESS, result%)
End Sub

Sub test_unpickle_gvn_data()
  Const fn$ = "name,file_index,line_num,ref_offset,name_id,2:3,4:5"
  Local sline% = 1, scol% = 1, eline% = 1, ecol% = 1

  tree.unpickle(fn$, sline%, scol%, eline%, ecol%)

  assert_int_equals(2, sline%)
  assert_int_equals(3, scol%)
  assert_int_equals(4, eline%)
  assert_int_equals(5, ecol%)
End Sub

Sub test_unpickle_gvn_no_data()
  Local fn$ = sys.NO_DATA$, sline% = 1, scol% = 1, eline% = 1, ecol% = 1

  tree.unpickle(fn$, sline%, scol%, eline%, ecol%)

  assert_int_equals(0, sline%)
  assert_int_equals(0, scol%)
  assert_int_equals(0, eline%)
  assert_int_equals(0, ecol%)
End Sub

Sub test_fn_comparator()
  lines$(1) = "Sub foo()" '#3
  lines$(2) = "End Sub"
  lines$(3) = "Sub bar()" '#1
  lines$(4) = "End Sub"
  lines$(5) = "Function wom()" '#4
  lines$(6) = "End Function"
  lines$(7) = "Function bat()" '#2
  lines$(8) = "End Function"
  parse_and_process(lines$())

  assert_int_equals( 0, tree.fn_comparator%(1, 1))
  assert_int_equals(-1, tree.fn_comparator%(1, 2))
  assert_int_equals( 1, tree.fn_comparator%(1, 3))
  assert_int_equals(-1, tree.fn_comparator%(1, 4))
  assert_int_equals( 1, tree.fn_comparator%(2, 1))
  assert_int_equals( 0, tree.fn_comparator%(2, 2))
  assert_int_equals( 1, tree.fn_comparator%(2, 3))
  assert_int_equals( 1, tree.fn_comparator%(2, 4))
  assert_int_equals(-1, tree.fn_comparator%(3, 1))
  assert_int_equals(-1, tree.fn_comparator%(3, 2))
  assert_int_equals( 0, tree.fn_comparator%(3, 3))
  assert_int_equals(-1, tree.fn_comparator%(3, 4))
  assert_int_equals( 1, tree.fn_comparator%(4, 1))
  assert_int_equals(-1, tree.fn_comparator%(4, 2))
  assert_int_equals( 1, tree.fn_comparator%(4, 3))
  assert_int_equals( 0, tree.fn_comparator%(4, 4))
End Sub

Sub test_get_orphan_fns()
  Const num_lines% = given_orphan_fns%()

  Local actual%(4)
  assert_int_equals(3, tree.get_orphan_fns%(actual%()))
  Local expected%(4) = (4, 2, 1, -1, -1)
  assert_int_array_equals(expected%(), actual%())
End Sub

Sub test_get_orphan_fns_gvn_none()
  Const num_lines% = given_no_orphan_fns%()

  Local actual%(4)
  assert_int_equals(0, tree.get_orphan_fns%(actual%()))
End Sub

Sub test_shake_gvn_orphans()
  Const num_lines% = given_orphan_fns%()

  MkDir TMPDIR$
  opt.outfile$ = TMPDIR$ + "/unshaken.bas"
  Open opt.outfile$ For Output As #1
  Local i%
  For i% = 1 To num_lines% : Print #1, lines$(i%) : Next
  Close #1

  Const result% = tree.shake%()

  Open opt.outfile$ For Input As #1
  assert_line_equals("foo()", 1)
  assert_line_equals("Sub foo()", 1)
  assert_line_equals("End Sub", 1)
  assert_true(Eof(#1))
  Close #1
End Sub

Sub test_shake_gvn_no_orphans()
  Const num_lines% = given_no_orphan_fns%()

  MkDir TMPDIR$
  opt.outfile$ = TMPDIR$ + "/unshaken.bas"
  Open opt.outfile$ For Output As #1
  Local i%
  For i% = 1 To num_lines% : Print #1, lines$(i%) : Next
  Close #1

  Const result% = tree.shake%()

  Open opt.outfile$ For Input As #1
  For i% = 1 To num_lines% : assert_line_equals(lines$(i%), 1) : Next
  assert_true(Eof(#1))
  Close #1
End Sub

Sub test_shake_gvn_all_orphans()
  Const num_lines% = given_all_orphan_fns%()

  MkDir TMPDIR$
  opt.outfile$ = TMPDIR$ + "/unshaken.bas"
  Open opt.outfile$ For Output As #1
  Local i%
  For i% = 1 To num_lines% : Print #1, lines$(i%) : Next
  Close #1

  Const result% = tree.shake%()

  Open opt.outfile$ For Input As #1
  assert_true(Eof(#1))
  Close #1
End Sub

Sub test_shake_gvn_empty_lines()
  Const num_lines% = given_empty_lines%()

  MkDir TMPDIR$
  opt.outfile$ = TMPDIR$ + "/unshaken.bas"
  Open opt.outfile$ For Output As #1
  Local i%
  For i% = 1 To num_lines% : Print #1, lines$(i%) : Next
  Close #1

  Const result% = tree.shake%()

  Open opt.outfile$ For Input As #1
  assert_line_equals("foo()", 1)
  assert_line_equals("", 1)
  assert_line_equals("Sub foo()", 1)
  assert_line_equals("  bar()", 1)
  assert_line_equals("End Sub", 1)
  assert_line_equals("", 1)
  assert_line_equals("Sub bar()", 1)
  assert_line_equals("End Sub", 1)
  Close #1
End Sub

Function given_no_orphan_fns%()
  lines$(1) = "foo()"
  lines$(2) = "Sub foo()"
  lines$(3) = "  wom()"
  lines$(4) = "End Sub"
  lines$(5) = "Sub wom()"
  lines$(6) = "  bar()"
  lines$(7) = "  bat()"
  lines$(8) = "End Sub"
  lines$(9) = "Sub bat()"
  lines$(10) = "End Sub"
  lines$(11) = "Sub bar()"
  lines$(12) = "End Sub"
  parse_and_process(lines$())
  given_no_orphan_fns% = 12
End Function

Function given_orphan_fns%()
  lines$(1) = "foo()"
  lines$(2) = "Sub foo()" ' Not an orphan, called from *global*
  lines$(3) = "End Sub"
  lines$(4) = "Sub wom()" ' Orphan
  lines$(5) = "  bar()"
  lines$(6) = "  bat()"
  lines$(7) = "End Sub"
  lines$(8) = "Sub bat()" ' Orphan
  lines$(9) = "End Sub"
  lines$(10) = "Sub bar()" ' Orphan
  lines$(11) = "End Sub"
  parse_and_process(lines$())
  given_orphan_fns% = 11
End Function

Function given_all_orphan_fns%()
  lines$(1) = "Sub foo()"
  lines$(2) = "End Sub"
  lines$(3) = "Sub wom()"
  lines$(4) = "  bar()"
  lines$(5) = "  bat()"
  lines$(6) = "End Sub"
  lines$(7) = "Sub bat()"
  lines$(8) = "End Sub"
  lines$(9) = "Sub bar()"
  lines$(10) = "End Sub"
  parse_and_process(lines$())
  given_all_orphan_fns% = 10
End Function

Function given_empty_lines%()
  lines$(1) = "foo()"
  lines$(2) = ""
  lines$(3) = "Sub foo()" ' Not an orphan, called from *global*
  lines$(4) = "  bar()"
  lines$(5) = "End Sub"
  lines$(6) = ""
  lines$(7) = "Sub wom()" ' Orphan
  lines$(8) = "  bat()"
  lines$(9) = "End Sub"
  lines$(10) = ""
  lines$(11) = "Sub bat()" ' Orphan
  lines$(12) = "End Sub"
  lines$(13) = ""
  lines$(14) = "Sub bar()" ' Not an orphan, called by foo()
  lines$(15) = "End Sub"
  parse_and_process(lines$())
  given_empty_lines% = 15
End Function

Sub assert_line_equals(expected$, fnbr%)
  Local actual$
  Line Input #fnbr%, actual$
  assert_string_equals(expected$, actual$)
End Sub
