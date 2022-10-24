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
#Include "../console.inc"

Const BASE% = Mm.Info(Option Base)
Const TMPDIR$ = sys.string_prop$("tmpdir") + "/tst_console"

add_test("test_history_clear")
add_test("test_history_count")
add_test("test_history_fill")
add_test("test_history_newest")
add_test("test_history_newest_gvn_overflow")
add_test("test_history_pop")
add_test("test_history_pop_gvn_overflow")
add_test("test_history_put")
add_test("test_history_put_given_duplicate")
add_test("test_history_put_appends_to_file")
add_test("test_history_put_trims_spaces")
add_test("test_history_put_ignores_bangs")
add_test("test_history_put_ignores_empty")
add_test("test_history_get")
add_test("test_history_given_overflow")
add_test("test_history_save")
add_test("test_history_save_given_empty")
add_test("test_history_load")
add_test("test_history_load_given_empty")
add_test("test_history_load_trims_count")
add_test("test_history_trim")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
  file.mkdir(TMPDIR$)
End Sub

Sub teardown_test()
  ' TODO: recursive deletion of TMPDIR$
End Sub

Sub test_history_clear()
  Local h%(array.new%(128))
  fill_with_ones(h%())
  given_some_elements(h%())

  con.history_clear(h%())

  assert_int_equals(con.history_count%(h%()))
End Sub

' Fills history buffer with &h01 so that we are not testing the code
' with the expectation that the buffer is all zeroed.
Sub fill_with_ones(h%())
  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Memory Set h_addr%, &h01, h_size%
End Sub

Sub given_some_elements(h%())
  con.history_put(h%(), "foo")
  con.history_put(h%(), "bar")
  con.history_put(h%(), "snafu")
  con.history_put(h%(), "wombat")
End Sub

Sub test_history_count()
  Local h%(array.new%(128))

  assert_int_equals(0, con.history_count%(h%()))

  given_some_elements(h%())

  assert_int_equals(4, con.history_count%(h%()))
End Sub

Sub test_history_fill()
  Local h%(array.new%(128))
  fill_with_ones(h%())

  Local elements1$(BASE% + 1) = ( "foo", "bar" )
  con.history_fill(h%(), elements1$())

  assert_int_equals(2, con.history_count%(h%()))
  assert_string_equals("foo", con.history_get$(h%(), 0))
  assert_string_equals("bar", con.history_get$(h%(), 1))

  Local elements2$(BASE% + 3) = ( "snafu", "wombat", "foo", "bar" )
  con.history_fill(h%(), elements2$())

  assert_int_equals(4, con.history_count%(h%()))
  assert_string_equals("snafu",  con.history_get$(h%(), 0))
  assert_string_equals("wombat", con.history_get$(h%(), 1))
  assert_string_equals("foo",    con.history_get$(h%(), 2))
  assert_string_equals("bar",    con.history_get$(h%(), 3))
End Sub

Sub test_history_get()
  Local h%(array.new%(128))

  given_some_elements(h%())

  assert_string_equals("wombat", con.history_get$(h%(), 0))
  assert_string_equals("snafu",  con.history_get$(h%(), 1))
  assert_string_equals("bar",    con.history_get$(h%(), 2))
  assert_string_equals("foo",    con.history_get$(h%(), 3))
  assert_string_equals("",       con.history_get$(h%(), 4))

  On Error Ignore
  Local s$ = con.history_get$(h%(), -1)
  assert_raw_error("index out of bounds: -1")
  On Error Abort
End Sub

Sub test_history_given_overflow()
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

  assert_string_equals("wombat", con.history_get$(h%(), 0))
  assert_string_equals("snafu",  con.history_get$(h%(), 1))
  assert_string_equals("",       con.history_get$(h%(), 2))

  con.history_put(h%(), "a")
  ' Array should have the values:
  '   <5><0><1>a<6>wombat<5>snaf

  assert_string_equals("a",      con.history_get$(h%(), 0))
  assert_string_equals("wombat", con.history_get$(h%(), 1))
  assert_string_equals("",       con.history_get$(h%(), 2))
End Sub

Sub test_history_load()
  Local h%(array.new%(128))
  fill_with_ones(h%())
  Local filename$ = TMPDIR$ + "/test_history_load"

  Open filename$ For Output As #5
  Print #5, "foo"
  Print #5, "bar"
  Print #5, "snafu"
  Print #5, "wombat"
  Close #5

  con.history_load(h%(), filename$, 5)

  assert_int_equals(4, con.history_count%(h%()))
  assert_string_equals("wombat", con.history_get$(h%(), 0)))
  assert_string_equals("snafu", con.history_get$(h%(), 1)))
  assert_string_equals("bar", con.history_get$(h%(), 2)))
  assert_string_equals("foo", con.history_get$(h%(), 3)))
End Sub

Sub test_history_load_given_empty()
  Local h%(array.new%(128))
  fill_with_ones(h%())
  Local filename$ = TMPDIR$ + "/test_history_load_empty"

  Open filename$ For Output As #5
  Close #5

  con.history_load(h%(), filename$, 5)

  assert_int_equals(0, con.history_count%(h%()))
End Sub

Sub test_history_load_trims_count()
  Local h%(array.new%(128))
  fill_with_ones(h%())
  Local filename$ = TMPDIR$ + "/test_history_load_trims_count"
  Local i%

  Open filename$ For Output As #5
  For i% = 1 To 200
    Print #5, "foo_" + Str$(i%)
  Next
  Close #5

  con.history_load(h%(), filename$, 5)

  assert_int_equals(100, con.history_count%(h%()))
  assert_string_equals("foo_200", con.history_get$(h%(), 0)))
  assert_string_equals("foo_199", con.history_get$(h%(), 1)))
  assert_string_equals("foo_101", con.history_get$(h%(), 99)))
End Sub

Sub test_history_newest()
  Local h%(array.new%(128))

  assert_int_equals(0, con.history_newest%(h%()))

  con.history_put(h%(), "foo")
  assert_int_equals(1, con.history_newest%(h%()))

  con.history_put(h%(), "wom")
  con.history_put(h%(), "bat")
  assert_int_equals(3, con.history_newest%(h%()))
End Sub

Sub test_history_newest_gvn_overflow()
  Local h%(array.new%(2)) ' 16 bytes
  con.history_put(h%(), "foo")
  con.history_put(h%(), "bar")
  con.history_put(h%(), "wom")
  con.history_put(h%(), "bat")
  con.history_put(h%(), "snafu")

  assert_int_equals(2, con.history_count%(h%()))
  assert_int_equals(5, con.history_newest%(h%()))
End Sub

Sub test_history_pop()
  Local h%(array.new%(128))
  con.history_put(h%(), "foo")

  assert_string_equals("foo", con.history_pop$(h%()))
  assert_int_equals(0, con.history_count%(h%()))
  assert_int_equals(0, con.history_newest%(h%()))

  con.history_put(h%(), "foo")
  con.history_put(h%(), "bar")
  con.history_put(h%(), "wombat")

  assert_string_equals("wombat", con.history_pop$(h%()))
  assert_int_equals(2, con.history_count%(h%()))
  assert_int_equals(2, con.history_newest%(h%()))
  assert_string_equals("bar", con.history_get$(h%(), 0))

  assert_string_equals("bar", con.history_pop$(h%()))
  assert_int_equals(1, con.history_count%(h%()))
  assert_int_equals(1, con.history_newest%(h%()))
  assert_string_equals("foo", con.history_get$(h%(), 0))

  assert_string_equals("foo", con.history_pop$(h%()))
  assert_int_equals(0, con.history_count%(h%()))
  assert_int_equals(0, con.history_newest%(h%()))
  assert_string_equals("", con.history_get$(h%(), 0))

  ' Popping an empty history buffer is harmless.
  assert_string_equals("", con.history_pop$(h%()))
  assert_int_equals(0, con.history_count%(h%()))
  assert_int_equals(0, con.history_newest%(h%()))
  assert_string_equals("", con.history_get$(h%(), 0))
End Sub

Sub test_history_pop_gvn_overflow()
  Local h%(array.new%(2)) ' 16 bytes
  con.history_put(h%(), "foo")
  con.history_put(h%(), "bar")
  con.history_put(h%(), "wom")
  con.history_put(h%(), "bat")
  con.history_put(h%(), "snafu")

  assert_string_equals("snafu", con.history_pop$(h%()))
End Sub

Sub test_history_put()
  Local h%(array.new%(128))
  Local h_addr% = Peek(VarAddr h%())

  con.history_put(h%(), "foo")

  assert_int_equals(1,        Peek(Short h_addr%)))
  assert_int_equals(3,        Peek(Byte h_addr% + 2)))
  assert_int_equals(Asc("f"), Peek(Byte h_addr% + 3)))
  assert_int_equals(Asc("o"), Peek(Byte h_addr% + 4)))
  assert_int_equals(Asc("o"), Peek(Byte h_addr% + 5)))
  assert_int_equals(0,        Peek(Byte h_addr% + 6)))

  con.history_put(h%(), "snafu")

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

Sub test_history_put_given_duplicate()
  Local h%(array.new%(128))
  Local h_addr% = Peek(VarAddr h%())
  con.history_put(h%(), "foo")
  con.history_put(h%(), "bar")

  ' Duplicate item.
  con.history_put(h%(), "bar")

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

Sub test_history_put_appends_to_file()
  Local h%(array.new%(128))
  Local filename$ = TMPDIR$ + "/test_history_put_appends_to_file"
  On Error Skip 1
  Kill filename$

  con.history_put(h%(), "foo", filename$, 5)

  Local s$
  Open filename$ For Input As #5
  Line Input #5, s$
  assert_string_equals("foo", s$)
  assert_int_equals(1, Eof(#5))
  Close #5

  con.history_put(h%(), "bar", filename$, 5)
  con.history_put(h%(), "snafu", filename$, 5)
  con.history_put(h%(), "wombat", filename$, 5)

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

Sub test_history_put_ignores_bangs()
  Local h%(array.new%(128))
  Local h_addr% = Peek(VarAddr h%())

  con.history_put(h%(), "!foo")
  con.history_put(h%(), "  !foo  ")

  assert_int_equals(0, con.history_count%(h%()))
End Sub

Sub test_history_put_ignores_empty()
  Local h%(array.new%(128))
  Local h_addr% = Peek(VarAddr h%())

  con.history_put(h%(), "")
  con.history_put(h%(), "  ")

  assert_int_equals(0, con.history_count%(h%()))
End Sub

Sub test_history_put_trims_spaces()
  Local h%(array.new%(128))
  Local h_addr% = Peek(VarAddr h%())

  con.history_put(h%(), "  foo  ")

  assert_string_equals("foo", con.history_get$(h%(), 0))
End Sub

Sub test_history_save()
  Local h%(array.new%(128))
  given_some_elements(h%())
  Local filename$ = TMPDIR$ + "/test_history_save"

  con.history_save(h%(), filename$, 5)

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

Sub test_history_save_given_empty()
  Local h%(array.new%(128))
  Local filename$ = TMPDIR$ + "/test_history_save_given_empty"

  con.history_save(h%(), filename$, 5)

  Local s$
  Open filename$ For Input As #5
  Line Input #5, s$
  assert_string_equals("", s$)
  assert_int_equals(1, Eof(#5))
  Close #5
End Sub

Sub test_history_trim()
  Local h%(array.new%(128))
  given_some_elements(h%())

  con.history_trim(h%(), 3)

  assert_int_equals(3, con.history_count%(h%()))
  assert_string_equals("wombat", con.history_get$(h%(), 0))
  assert_string_equals("snafu",  con.history_get$(h%(), 1))
  assert_string_equals("bar",    con.history_get$(h%(), 2))

  con.history_trim(h%(), 2)
  assert_int_equals(2, con.history_count%(h%()))
  assert_string_equals("wombat", con.history_get$(h%(), 0))
  assert_string_equals("snafu",  con.history_get$(h%(), 1))

  con.history_trim(h%(), 0)
  assert_int_equals(0, con.history_count%(h%()))
End Sub
