' Copyright (c) 2021 Thomas Hugo Williams

Option Explicit On
Option Default None
Option Base Choice(InStr(Mm.CmdLine$, "--base=1"), 1, 0)

#Include "../system.inc"
#Include "../array.inc"
#Include "../list.inc"
#Include "../map.inc"
#Include "../string.inc"
#Include "../file.inc"
#Include "../vt100.inc"
#Include "../inifile.inc"
#Include "../../sptest/unittest.inc"

Const BASE% = Mm.Info(Option Base)
Const TEST_FILE$ = "/tmp/tst_inifile.ini"

add_test("test_read")
add_test("test_read_given_map_overflow")
add_test("test_read_given_missing_key")
add_test("test_read_given_missing_value")
add_test("test_read_given_empty_value")
add_test("test_write")

run_tests(Choice(InStr(Mm.CmdLine$, "--base"), "", "--base=1"))

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_read()
  Local mp$(map.new%(10)), num%

  Open TEST_FILE$ For Output As #1
  Print #1, "key1  = value1  "
  Print #1, "  key2 =  value2"
  Print #1, "; key3 = value3"
  Print #1, "   ; key4 = value4"
  Print #1, "key5 = value5 ; comment"
  Close #1

  Open TEST_FILE$ For Input As #1
  assert_true(inifile.read%(1, mp$(), num%))
  Close #1

  assert_string_equals("", sys.err$)
  assert_int_equals(3, num%)
  assert_int_equals(3, map.size%(mp$()))
  assert_string_equals("key1", mp$(BASE%))
  assert_string_equals("value1", map.get$(mp$(), "key1"))
  assert_string_equals("key2", mp$(BASE% + 1))
  assert_string_equals("value2", map.get$(mp$(), "key2"))
  assert_string_equals("key5", mp$(BASE% + 2))
  assert_string_equals("value5", map.get$(mp$(), "key5"))
End Sub

Sub test_read_given_map_overflow()
  Local mp$(map.new%(2)), num%

  Open TEST_FILE$ For Output As #1
  Print #1, "key1 = value1"
  Print #1, "key2 = value2"
  Print #1, "key3 = value3"
  Close #1

  Open TEST_FILE$ For Input As #1
  assert_false(inifile.read%(1, mp$(), num%))
  Close #1

  assert_string_equals("too many values (line 3)", sys.err$)
  assert_int_equals(3, num%)
  assert_int_equals(2, map.size%(mp$()))
  assert_string_equals("key1", mp$(BASE%))
  assert_string_equals("value1", map.get$(mp$(), "key1"))
  assert_string_equals("key2", mp$(BASE% + 1))
  assert_string_equals("value2", map.get$(mp$(), "key2"))
End Sub

Sub test_read_given_missing_key()
  Local mp$(map.new%(10)), num%

  Open TEST_FILE$ For Output As #1
  Print #1, "key1 = value1"
  Print #1, " = value2 ; missing key"
  Print #1, "key3 = value3"
  Close #1

  Open TEST_FILE$ For Input As #1
  assert_false(inifile.read%(1, mp$(), num%))
  Close #1

  assert_string_equals("missing key (line 2)", sys.err$)
  assert_int_equals(1, num%)
End Sub

Sub test_read_given_missing_value()
  Local mp$(map.new%(10)), num%

  Open TEST_FILE$ For Output As #1
  Print #1, "key1 = value1"
  Print #1, "key2 ; missing value"
  Print #1, "key3 = value3"
  Close #1

  Open TEST_FILE$ For Input As #1
  assert_false(inifile.read%(1, mp$(), num%))
  Close #1

  assert_string_equals("missing value (line 2)", sys.err$)
  assert_int_equals(1, num%)
End Sub

Sub test_read_given_empty_value()
  Local mp$(map.new%(10)), num%

  Open TEST_FILE$ For Output As #1
  Print #1, "key1 = value1"
  Print #1, "key2 = ; empty value"
  Print #1, "key3 = value3"
  Close #1

  Open TEST_FILE$ For Input As #1
  assert_true(inifile.read%(1, mp$(), num%))
  Close #1

  assert_string_equals("", sys.err$)
  assert_int_equals(3, num%)
  assert_int_equals(3, map.size%(mp$()))
  assert_string_equals("key1", mp$(BASE%))
  assert_string_equals("value1", map.get$(mp$(), "key1"))
  assert_string_equals("key2", mp$(BASE% + 1))
  assert_string_equals("", map.get$(mp$(), "key2"))
  assert_string_equals("key3", mp$(BASE% + 2))
  assert_string_equals("value3", map.get$(mp$(), "key3"))
End Sub

Sub test_write()
  Local mp$(map.new%(10)), num%
  map.put(mp$(), "wom", "bat")
  map.put(mp$(), "sna", "fu")
  map.put(mp$(), "foo", "bar")
  map.put(mp$(), "empty", "")

  Open TEST_FILE$ For Output As #1
  assert_true(inifile.write%(1, mp$(), num%))
  Close #1

  assert_int_equals(4, num%)
  assert_string_equals("", sys.err$)

  Open TEST_FILE$ For Input As #1
  Local s$
  Line Input #1, s$
  assert_string_equals("empty = ", s$)
  Line Input #1, s$
  assert_string_equals("foo = bar", s$)
  Line Input #1, s$
  assert_string_equals("sna = fu", s$)
  Line Input #1, s$
  assert_string_equals("wom = bat", s$)
  assert_true(Eof(#1))
  Close #1
End Sub
