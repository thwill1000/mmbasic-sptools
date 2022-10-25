' Copyright (c) 2021-2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 2022.01.00

Option Explicit On
Option Default None
Option Base InStr(Mm.CmdLine$, "--base=1") > 0

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../history.inc"

Const BASE% = Mm.Info(Option Base)
Const TMPDIR$ = sys.string_prop$("tmpdir") + "/tst_history"

add_test("test_clear")
add_test("test_count")
add_test("test_fill")
add_test("test_newest")
add_test("test_newest_gvn_overflow")
add_test("test_pop")
add_test("test_pop_gvn_overflow")
add_test("test_push")
add_test("test_push_given_duplicate")
add_test("test_push_appends_to_file")
add_test("test_push_trims_spaces")
add_test("test_push_ignores_bangs")
add_test("test_push_ignores_empty")
add_test("test_get")
add_test("test_given_overflow")
add_test("test_save")
add_test("test_save_given_empty")
add_test("test_load")
add_test("test_load_given_empty")
add_test("test_load_trims_count")
add_test("test_trim")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
  file.mkdir(TMPDIR$)
End Sub

Sub teardown_test()
  ' TODO: recursive deletion of TMPDIR$
End Sub

Sub test_clear()
  Local h%(array.new%(128))
  fill_with_ones(h%())
  given_some_elements(h%())

  history.clear(h%())

  assert_int_equals(history.count%(h%()))
End Sub

' Fills history buffer with &h01 so that we are not testing the code
' with the expectation that the buffer is all zeroed.
Sub fill_with_ones(h%())
  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Memory Set h_addr%, &h01, h_size%
End Sub

Sub given_some_elements(h%())
  history.push(h%(), "foo")
  history.push(h%(), "bar")
  history.push(h%(), "snafu")
  history.push(h%(), "wombat")
End Sub

Sub test_count()
  Local h%(array.new%(128))

  assert_int_equals(0, history.count%(h%()))

  given_some_elements(h%())

  assert_int_equals(4, history.count%(h%()))
End Sub

Sub test_fill()
  Local h%(array.new%(128))
  fill_with_ones(h%())

  Local elements1$(BASE% + 1) = ( "foo", "bar" )
  history.fill(h%(), elements1$())

  assert_int_equals(2, history.count%(h%()))
  assert_string_equals("foo", history.get$(h%(), 0))
  assert_string_equals("bar", history.get$(h%(), 1))

  Local elements2$(BASE% + 3) = ( "snafu", "wombat", "foo", "bar" )
  history.fill(h%(), elements2$())

  assert_int_equals(4, history.count%(h%()))
  assert_string_equals("snafu",  history.get$(h%(), 0))
  assert_string_equals("wombat", history.get$(h%(), 1))
  assert_string_equals("foo",    history.get$(h%(), 2))
  assert_string_equals("bar",    history.get$(h%(), 3))
End Sub

Sub test_get()
  Local h%(array.new%(128))

  given_some_elements(h%())

  assert_string_equals("wombat", history.get$(h%(), 0))
  assert_string_equals("snafu",  history.get$(h%(), 1))
  assert_string_equals("bar",    history.get$(h%(), 2))
  assert_string_equals("foo",    history.get$(h%(), 3))
  assert_string_equals("",       history.get$(h%(), 4))

  On Error Ignore
  Local s$ = history.get$(h%(), -1)
  assert_raw_error("index out of bounds: -1")
  On Error Abort
End Sub

Sub test_given_overflow()
  Local h%(array.new%(2)) ' 16 bytes
  Local h_addr% = Peek(VarAddr h%())
  Local check% = Peek(Byte h_addr% + 16) ' The byte one beyond the end of the array

  given_some_elements(h%())
  ' Array should have the values:
  '   <4><0><6>wombat<5>snafu<3>

  assert_int_equals(4,        Peek(Short h_addr%))
  assert_int_equals(6,        Peek(Byte h_addr% + 2))
  assert_int_equals(Asc("u"), Peek(Byte h_addr% + 14))
  assert_int_equals(3,        Peek(Byte h_addr% + 15))
  assert_int_equals(check%,   Peek(Byte h_addr% + 16))

  assert_string_equals("wombat", history.get$(h%(), 0))
  assert_string_equals("snafu",  history.get$(h%(), 1))
  assert_string_equals("",       history.get$(h%(), 2))

  history.push(h%(), "a")
  ' Array should have the values:
  '   <5><0><1>a<6>wombat<5>snaf

  assert_string_equals("a",      history.get$(h%(), 0))
  assert_string_equals("wombat", history.get$(h%(), 1))
  assert_string_equals("",       history.get$(h%(), 2))
End Sub

Sub test_load()
  Local h%(array.new%(128))
  fill_with_ones(h%())
  Local filename$ = TMPDIR$ + "/test_load"

  Open filename$ For Output As #5
  Print #5, "foo"
  Print #5, "bar"
  Print #5, "snafu"
  Print #5, "wombat"
  Close #5

  history.load(h%(), filename$, 5)

  assert_int_equals(4, history.count%(h%()))
  assert_string_equals("wombat", history.get$(h%(), 0)))
  assert_string_equals("snafu", history.get$(h%(), 1)))
  assert_string_equals("bar", history.get$(h%(), 2)))
  assert_string_equals("foo", history.get$(h%(), 3)))
End Sub

Sub test_load_given_empty()
  Local h%(array.new%(128))
  fill_with_ones(h%())
  Local filename$ = TMPDIR$ + "/test_load_empty"

  Open filename$ For Output As #5
  Close #5

  history.load(h%(), filename$, 5)

  assert_int_equals(0, history.count%(h%()))
End Sub

Sub test_load_trims_count()
  Local h%(array.new%(128))
  fill_with_ones(h%())
  Local filename$ = TMPDIR$ + "/test_load_trims_count"
  Local i%

  Open filename$ For Output As #5
  For i% = 1 To 200
    Print #5, "foo_" + Str$(i%)
  Next
  Close #5

  history.load(h%(), filename$, 5)

  assert_int_equals(100, history.count%(h%()))
  assert_string_equals("foo_200", history.get$(h%(), 0)))
  assert_string_equals("foo_199", history.get$(h%(), 1)))
  assert_string_equals("foo_101", history.get$(h%(), 99)))
End Sub

Sub test_newest()
  Local h%(array.new%(128))

  assert_int_equals(0, history.newest%(h%()))

  history.push(h%(), "foo")
  assert_int_equals(1, history.newest%(h%()))

  history.push(h%(), "wom")
  history.push(h%(), "bat")
  assert_int_equals(3, history.newest%(h%()))
End Sub

Sub test_newest_gvn_overflow()
  Local h%(array.new%(2)) ' 16 bytes
  history.push(h%(), "foo")
  history.push(h%(), "bar")
  history.push(h%(), "wom")
  history.push(h%(), "bat")
  history.push(h%(), "snafu")

  assert_int_equals(2, history.count%(h%()))
  assert_int_equals(5, history.newest%(h%()))
End Sub

Sub test_pop()
  Local h%(array.new%(128))
  history.push(h%(), "foo")

  assert_string_equals("foo", history.pop$(h%()))
  assert_int_equals(0, history.count%(h%()))
  assert_int_equals(0, history.newest%(h%()))

  history.push(h%(), "foo")
  history.push(h%(), "bar")
  history.push(h%(), "wombat")

  assert_string_equals("wombat", history.pop$(h%()))
  assert_int_equals(2, history.count%(h%()))
  assert_int_equals(2, history.newest%(h%()))
  assert_string_equals("bar", history.get$(h%(), 0))

  assert_string_equals("bar", history.pop$(h%()))
  assert_int_equals(1, history.count%(h%()))
  assert_int_equals(1, history.newest%(h%()))
  assert_string_equals("foo", history.get$(h%(), 0))

  assert_string_equals("foo", history.pop$(h%()))
  assert_int_equals(0, history.count%(h%()))
  assert_int_equals(0, history.newest%(h%()))
  assert_string_equals("", history.get$(h%(), 0))

  ' Popping an empty history buffer is harmless.
  assert_string_equals("", history.pop$(h%()))
  assert_int_equals(0, history.count%(h%()))
  assert_int_equals(0, history.newest%(h%()))
  assert_string_equals("", history.get$(h%(), 0))
End Sub

Sub test_pop_gvn_overflow()
  Local h%(array.new%(2)) ' 16 bytes
  history.push(h%(), "foo")
  history.push(h%(), "bar")
  history.push(h%(), "wom")
  history.push(h%(), "bat")
  history.push(h%(), "snafu")

  assert_string_equals("snafu", history.pop$(h%()))
End Sub

Sub test_push()
  Local h%(array.new%(128))
  Local h_addr% = Peek(VarAddr h%())

  history.push(h%(), "foo")

  assert_int_equals(1,        Peek(Short h_addr%)))
  assert_int_equals(3,        Peek(Byte h_addr% + 2)))
  assert_int_equals(Asc("f"), Peek(Byte h_addr% + 3)))
  assert_int_equals(Asc("o"), Peek(Byte h_addr% + 4)))
  assert_int_equals(Asc("o"), Peek(Byte h_addr% + 5)))
  assert_int_equals(0,        Peek(Byte h_addr% + 6)))

  history.push(h%(), "snafu")

  assert_int_equals(2,        Peek(Short h_addr%)))
  assert_int_equals(5,        Peek(Byte h_addr% + 2)))
  assert_int_equals(Asc("s"), Peek(Byte h_addr% + 3)))
  assert_int_equals(Asc("n"), Peek(Byte h_addr% + 4)))
  assert_int_equals(Asc("a"), Peek(Byte h_addr% + 5)))
  assert_int_equals(Asc("f"), Peek(Byte h_addr% + 6)))
  assert_int_equals(Asc("u"), Peek(Byte h_addr% + 7)))
  assert_int_equals(3,        Peek(Byte h_addr% + 8)))
  assert_int_equals(Asc("f"), Peek(Byte h_addr% + 9)))
  assert_int_equals(Asc("o"), Peek(Byte h_addr% + 10)))
  assert_int_equals(Asc("o"), Peek(Byte h_addr% + 11)))

  Local i%
  For i% = 12 To 1023
    If Peek(Byte h_addr% + i%) <> 0 Then
      assert_fail("Assert failed, byte " + Str$(i%) + " of h%() is non-zero")
      Exit For
    EndIf
  Next
End Sub

Sub test_push_given_duplicate()
  Local h%(array.new%(128))
  Local h_addr% = Peek(VarAddr h%())
  history.push(h%(), "foo")
  history.push(h%(), "bar")

  ' Duplicate item.
  history.push(h%(), "bar")

  assert_int_equals(2,        Peek(Short h_addr%)))
  assert_int_equals(3,        Peek(Byte h_addr% + 2)))
  assert_int_equals(Asc("b"), Peek(Byte h_addr% + 3)))
  assert_int_equals(Asc("a"), Peek(Byte h_addr% + 4)))
  assert_int_equals(Asc("r"), Peek(Byte h_addr% + 5)))
  assert_int_equals(3,        Peek(Byte h_addr% + 6)))
  assert_int_equals(Asc("f"), Peek(Byte h_addr% + 7)))
  assert_int_equals(Asc("o"), Peek(Byte h_addr% + 8)))
  assert_int_equals(Asc("o"), Peek(Byte h_addr% + 9)))

  Local i%
  For i% = 10 To 1023
    If Peek(Byte h_addr% + i%) <> 0 Then
      assert_fail("Assert failed, byte " + Str$(i%) + " of h%() is non-zero")
      Exit For
    EndIf
  Next
End Sub

Sub test_push_appends_to_file()
  Local h%(array.new%(128))
  Local filename$ = TMPDIR$ + "/test_push_appends_to_file"
  On Error Skip 1
  Kill filename$

  history.push(h%(), "foo", filename$, 5)

  Local s$
  Open filename$ For Input As #5
  Line Input #5, s$
  assert_string_equals("foo", s$)
  assert_int_equals(1, Eof(#5))
  Close #5

  history.push(h%(), "bar", filename$, 5)
  history.push(h%(), "snafu", filename$, 5)
  history.push(h%(), "wombat", filename$, 5)

  Open filename$ For Input As #5
  Line Input #5, s$
  assert_string_equals("foo", s$) ' Expect oldest item first.
  Line Input #5, s$
  assert_string_equals("bar", s$)
  Line Input #5, s$
  assert_string_equals("snafu", s$)
  Line Input #5, s$
  assert_string_equals("wombat", s$)
  assert_int_equals(1, Eof(#5))
  Close #5
End Sub

Sub test_push_ignores_bangs()
  Local h%(array.new%(128))
  Local h_addr% = Peek(VarAddr h%())

  history.push(h%(), "!foo")
  history.push(h%(), "  !foo  ")

  assert_int_equals(0, history.count%(h%()))
End Sub

Sub test_push_ignores_empty()
  Local h%(array.new%(128))
  Local h_addr% = Peek(VarAddr h%())

  history.push(h%(), "")
  history.push(h%(), "  ")

  assert_int_equals(0, history.count%(h%()))
End Sub

Sub test_push_trims_spaces()
  Local h%(array.new%(128))
  Local h_addr% = Peek(VarAddr h%())

  history.push(h%(), "  foo  ")

  assert_string_equals("foo", history.get$(h%(), 0))
End Sub

Sub test_save()
  Local h%(array.new%(128))
  given_some_elements(h%())
  Local filename$ = TMPDIR$ + "/test_save"

  history.save(h%(), filename$, 5)

  Local s$
  Open filename$ For Input As #5
  Line Input #5, s$
  assert_string_equals("foo", s$) ' Expect oldest item first.
  Line Input #5, s$
  assert_string_equals("bar", s$)
  Line Input #5, s$
  assert_string_equals("snafu", s$)
  Line Input #5, s$
  assert_string_equals("wombat", s$)
  assert_int_equals(1, Eof(#5))
  Close #5
End Sub

Sub test_save_given_empty()
  Local h%(array.new%(128))
  Local filename$ = TMPDIR$ + "/test_save_given_empty"

  history.save(h%(), filename$, 5)

  Local s$
  Open filename$ For Input As #5
  Line Input #5, s$
  assert_string_equals("", s$)
  assert_int_equals(1, Eof(#5))
  Close #5
End Sub

Sub test_trim()
  Local h%(array.new%(128))
  given_some_elements(h%())

  history.trim(h%(), 3)

  assert_int_equals(3, history.count%(h%()))
  assert_string_equals("wombat", history.get$(h%(), 0))
  assert_string_equals("snafu",  history.get$(h%(), 1))
  assert_string_equals("bar",    history.get$(h%(), 2))

  history.trim(h%(), 2)
  assert_int_equals(2, history.count%(h%()))
  assert_string_equals("wombat", history.get$(h%(), 0))
  assert_string_equals("snafu",  history.get$(h%(), 1))

  history.trim(h%(), 0)
  assert_int_equals(0, history.count%(h%()))
End Sub
