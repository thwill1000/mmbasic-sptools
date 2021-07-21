' Copyright (c) 2020-2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.05

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Dim in.num_open_files = 1

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/map.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../../common/sptools.inc"
#Include "../keywords.inc"
#Include "../lexer.inc"
#Include "../trans.inc"

keywords.load()

add_test("test_parse_replace")
add_test("test_parse_replace_given_errors")
add_test("test_parse_unreplace")
add_test("test_parse_unreplace_given_errs")
add_test("test_parse_given_too_many_rpl")
add_test("test_apply_replace")
add_test("test_apply_replace_groups")
add_test("test_apply_replace_patterns")
add_test("test_replace_fails_if_too_long")
add_test("test_replace_with_fewer_tokens")
add_test("test_replace_with_more_tokens")
add_test("test_replace_given_new_rpl")
add_test("test_apply_unreplace")
add_test("test_comment_if")
add_test("test_comment_if_not")
add_test("test_uncomment_if")
add_test("test_uncomment_if_not")
add_test("test_unknown_directive")
add_test("test_remove_if")
add_test("test_remove_if_not")

run_tests()

End

Sub setup_test()
  set.clear(tr.flags$())
  tr.clear_replacements()
End Sub

Sub teardown_test()
End Sub

Sub test_parse_replace()
  Local ok%

  lx.parse_basic("'!replace DEF Sub")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(0, "def", "Sub")

  lx.parse_basic("'!replace ENDPROC { End Sub }")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(1, "endproc", "End|Sub")

  lx.parse_basic("'!replace { THEN ENDPROC } { Then Exit Sub }")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(2, "then|endproc", "Then|Exit|Sub")

  lx.parse_basic("'!replace GOTO%% { Goto %1 }")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(3, "goto%%", "Goto|%1")

  lx.parse_basic("'!replace { THEN %% } { Then Goto %1 }")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(4, "then|%%", "Then|Goto|%1")

  lx.parse_basic("'!replace '%% { CRLF$ %1 }")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(5, "'%%", "CRLF$|%1")

  lx.parse_basic("'!replace &%h &h%1")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(6, "&%h", "&h%1")

  lx.parse_basic("'!replace foo")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(7, "foo", "")

  lx.parse_basic("'!replace {foo}")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(7, Chr$(0), Chr$(0))
  expect_replacement(8, "foo", "")

  lx.parse_basic("'!replace foo {}")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(8, Chr$(0), Chr$(0))
  expect_replacement(9, "foo", "")
End Sub

Sub test_parse_replace_given_errors()
  Local ok%

  lx.parse_basic("'!replace")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive expects <from> argument")

  lx.parse_basic("'!replace {}")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has empty <from> group")

  lx.parse_basic("'!replace {} y")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has empty <from> group")

  lx.parse_basic("'!replace { x y")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has missing '}'")

  lx.parse_basic("'!replace { x } { y z")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has missing '}'")

  lx.parse_basic("'!replace { x } { y } z")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has too many arguments")

  lx.parse_basic("'!replace { x } { y } { z }")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has too many arguments")

  lx.parse_basic("'!replace { {")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has unexpected '{'")

  lx.parse_basic("'!replace foo }")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has unexpected '}'")
End Sub

Sub test_parse_given_too_many_rpl()
  Local i%, ok%

  For i% = 0 To tr.MAX_REPLACEMENTS% - 1
    lx.parse_basic("'!replace a" + Str$(i%) + " b") : ok% = tr.transpile%()
  Next
  assert_no_error()

  lx.parse_basic("'!replace foo bar") : ok% = tr.transpile%()
  assert_error("!replace directive too many replacements (max 200)")
End Sub

Sub test_parse_unreplace()
  Local ok%

  lx.parse_basic("'!replace foo bar") : ok% = tr.transpile%()
  lx.parse_basic("'!replace wom bat") : ok% = tr.transpile%()
  lx.parse_basic("'!unreplace foo") : ok% = tr.transpile%()

  assert_no_error()
  assert_int_equals(2, tr.num_replacements%)
  expect_replacement(0, Chr$(0), Chr$(0))
  expect_replacement(1, "wom", "bat")
End Sub

Sub test_parse_unreplace_given_errs()
  Local ok%

  ' Test given missing argument to directive.
  lx.parse_basic("'!unreplace") : ok% = tr.transpile%()
  assert_error("!unreplace directive expects <from> argument")

  ' Test given directive has too many arguments.
  lx.parse_basic("'!unreplace { a b } c") : ok% = tr.transpile%()
  assert_error("!unreplace directive has too many arguments")

  ' Test given replacement not present.
  lx.parse_basic("'!replace wom bat") : ok% = tr.transpile%()
  lx.parse_basic("'!unreplace foo") : ok% = tr.transpile%()
  assert_error("!unreplace directive could not find 'foo'")
  assert_int_equals(1, tr.num_replacements%)
  expect_replacement(0, "wom", "bat")
End Sub

Sub test_apply_replace()
  Local ok%

  lx.parse_basic("'!replace x      y") : ok% = tr.transpile%()
  lx.parse_basic("'!replace &hFFFF z") : ok% = tr.transpile%()
  lx.parse_basic("Dim x = &hFFFF ' comment") : ok% = tr.transpile%()

  expect_tokens(5)
  expect_tk(0, TK_KEYWORD, "Dim")
  expect_tk(1, TK_IDENTIFIER, "y")
  expect_tk(2, TK_SYMBOL, "=")
  expect_tk(3, TK_IDENTIFIER, "z")
  expect_tk(4, TK_COMMENT, "' comment")
  assert_string_equals("Dim y = z ' comment", lx.line$)
End Sub

Sub test_apply_replace_groups()
  Local ok%

  lx.parse_basic("'!replace ab { cd ef }") : ok% = tr.transpile%()
  lx.parse_basic("ab gh ij") : ok% = tr.transpile%()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "cd")
  expect_tk(1, TK_IDENTIFIER, "ef")
  expect_tk(2, TK_IDENTIFIER, "gh")
  expect_tk(3, TK_IDENTIFIER, "ij")

  setup_test()
  lx.parse_basic("'!replace {ab cd} ef") : ok% = tr.transpile%()
  lx.parse_basic("ab cd gh ij") : ok% = tr.transpile%()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "ef")
  expect_tk(1, TK_IDENTIFIER, "gh")
  expect_tk(2, TK_IDENTIFIER, "ij")
End Sub

Sub test_apply_replace_patterns()
  Local ok%

  setup_test()
  lx.parse_basic("'!replace { DEF PROC%% } { SUB proc%1 }") : ok% = tr.transpile%()
  lx.parse_basic("foo DEF PROCWOMBAT bar") : ok% = tr.transpile%()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "SUB")
  expect_tk(2, TK_IDENTIFIER, "procWOMBAT") ' Note don't want to change case of WOMBAT.
  expect_tk(3, TK_IDENTIFIER, "bar")

  setup_test()
  lx.parse_basic("'!replace GOTO%d { Goto %1 }") : ok% = tr.transpile%()
  lx.parse_basic("foo GOTO1234 bar") : ok% = tr.transpile%()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD   , "Goto")
  expect_tk(2, TK_NUMBER,     "1234")
  expect_tk(3, TK_IDENTIFIER, "bar") 

  setup_test()
  lx.parse_basic("'!replace { THEN %d } { Then Goto %1 }") : ok% = tr.transpile%()

  ' Test %d pattern matches decimal digits ...
  lx.parse_basic("foo THEN 1234 bar") : ok% = tr.transpile%()
  expect_tokens(5)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD   , "Then")
  expect_tk(2, TK_KEYWORD   , "Goto")
  expect_tk(3, TK_NUMBER,     "1234")
  expect_tk(4, TK_IDENTIFIER, "bar") 

  ' ... but it should not match other characters.
  lx.parse_basic("foo THEN wombat bar") : ok% = tr.transpile%()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD   , "THEN")
  expect_tk(2, TK_IDENTIFIER, "wombat")
  expect_tk(3, TK_IDENTIFIER, "bar") 

  setup_test()
  lx.parse_basic("'!replace { PRINT '%% } { ? : ? %1 }") : ok% = tr.transpile%()
  lx.parse_basic("foo PRINT '" + Chr$(34) + "wombat" + Chr$(34) + " bar") : ok% = tr.transpile%()
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_SYMBOL,     "?")
  expect_tk(2, TK_SYMBOL,     ":")
  expect_tk(3, TK_SYMBOL,     "?")
  expect_tk(4, TK_STRING,     Chr$(34) + "wombat" + Chr$(34))
  expect_tk(5, TK_IDENTIFIER, "bar")

  setup_test()
  lx.parse_basic("'!replace '%% { : ? %1 }") : ok% = tr.transpile%()
  lx.parse_basic("foo PRINT '" + Chr$(34) + "wombat" + Chr$(34) + " bar") : ok% = tr.transpile%()
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "PRINT")
  expect_tk(2, TK_SYMBOL,     ":")
  expect_tk(3, TK_SYMBOL,     "?")
  expect_tk(4, TK_STRING,     Chr$(34) + "wombat" + Chr$(34))
  expect_tk(5, TK_IDENTIFIER, "bar")

  setup_test()
  lx.parse_basic("'!replace REM%% { ' %1 }") : ok% = tr.transpile%()
  lx.parse_basic("foo REM This is a comment") : ok% = tr.transpile%()
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_COMMENT, "' This is a comment")

  setup_test()
  lx.parse_basic("'!replace { Spc ( } { Space$ ( }") : ok% = tr.transpile%()
  lx.parse_basic("foo Spc(5) bar") : ok% = tr.transpile%()
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "Space$")
  expect_tk(2, TK_SYMBOL,     "(")
  expect_tk(3, TK_NUMBER,     "5")
  expect_tk(4, TK_SYMBOL,     ")")
  expect_tk(5, TK_IDENTIFIER, "bar")

  ' Test %h pattern matches hex digits ...
  setup_test()
  lx.parse_basic("'!replace GOTO%h { Goto %1 }") : ok% = tr.transpile%()
  lx.parse_basic("foo GOTOabcdef0123456789 bar") : ok% = tr.transpile%()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "Goto")
  expect_tk(2, TK_IDENTIFIER, "abcdef0123456789")
  expect_tk(3, TK_IDENTIFIER, "bar")

  ' ... but it should not match other characters.
  lx.parse_basic("foo GOTOxyz bar") : ok% = tr.transpile%()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "GOTOxyz")
  expect_tk(2, TK_IDENTIFIER, "bar")
End Sub

Sub test_replace_fails_if_too_long()
  Local ok%, s$

  lx.parse_basic("'!replace foo foobar") : ok% = tr.transpile%()

  ' Test where replaced string should be 255 characters.
  s$ = String$(248, "a")
  Cat s$, " foo"
  assert_int_equals(252, Len(s$))
  lx.parse_basic(s$)
  ok% = tr.transpile%()
  assert_no_error()
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, String$(248, "a"))
  expect_tk(1, TK_IDENTIFIER, "foobar")


  ' Test where replaced string should be 256 characters.
  s$ = String$(251, "a")
  Cat s$, " foo"
  assert_int_equals(255, Len(s$))
  lx.parse_basic(s$)
  ok% = tr.transpile%()
  assert_error("applying replacement makes line > 255 characters")
End Sub

Sub test_replace_with_fewer_tokens()
  Local ok%

  ' Replace 1 token with 0.
  lx.parse_basic("'!replace bar") : ok% = tr.transpile%()
  lx.parse_basic("foo bar wom") : ok% = tr.transpile%()
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "wom")

  ' Removal of all tokens.
  setup_test()
  lx.parse_basic("'!replace bar") : ok% = tr.transpile%()
  lx.parse_basic("bar bar bar") : ok% = tr.transpile%()
  expect_tokens(0)

  ' Replace 2 tokens with 1.
  setup_test()
  lx.parse_basic("'!replace { foo bar } wom") : ok% = tr.transpile%()
  lx.parse_basic("foo bar foo bar snafu") : ok% = tr.transpile%()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "wom")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "snafu")

  ' Note that we don't end up with the single token "foo" because once we have
  ' applied a replacement we do not recursively apply that replacement to the
  ' already replaced text.
  setup_test()
  lx.parse_basic("'!replace { foo bar } foo") : ok% = tr.transpile%()
  lx.parse_basic("foo bar bar") : ok% = tr.transpile%()
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")

  ' Replace 3 tokens with 1 - again note we don't just end up with "foo".
  setup_test()
  lx.parse_basic("'!replace { foo bar wom } foo") : ok% = tr.transpile%()
  lx.parse_basic("foo bar wom bar wom") : ok% = tr.transpile%()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")

  ' Replace 3 tokens with 2 - and again we don't just end up with "foo bar".
  setup_test()
  lx.parse_basic("'!replace { foo bar wom } { foo bar }") : ok% = tr.transpile%()
  lx.parse_basic("foo bar wom wom") : ok% = tr.transpile%()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")
End Sub

Sub test_replace_with_more_tokens()
  Local ok%

  ' Replace 1 token with 2 - note that we don't get infinite recursion because
  ' once we have applied the replacement text we not not recusively apply the
  ' replacement to the already replaced text.
  lx.parse_basic("'!replace foo { foo bar }") : ok% = tr.transpile%()
  lx.parse_basic("foo wom") : ok% = tr.transpile%()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")

  setup_test()
  lx.parse_basic("'!replace foo { bar foo }") : ok% = tr.transpile%()
  lx.parse_basic("foo wom foo") : ok% = tr.transpile%()
  expect_tokens(5)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "foo")
  expect_tk(2, TK_IDENTIFIER, "wom")
  expect_tk(3, TK_IDENTIFIER, "bar")
  expect_tk(4, TK_IDENTIFIER, "foo")

  ' Ensure replacement applied for multiple matches.
  setup_test()
  lx.parse_basic("'!replace foo { bar foo }") : ok% = tr.transpile%()
  lx.parse_basic("foo foo") : ok% = tr.transpile%()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "foo")
  expect_tk(2, TK_IDENTIFIER, "bar")
  expect_tk(3, TK_IDENTIFIER, "foo")

  ' Replace 3 tokens with 4.
  setup_test()
  lx.parse_basic("'!replace { foo bar wom } { foo bar wom foo }") : ok% = tr.transpile%()
  lx.parse_basic("foo bar wom bar wom") : ok% = tr.transpile%()
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")
  expect_tk(3, TK_IDENTIFIER, "foo")
  expect_tk(4, TK_IDENTIFIER, "bar")
  expect_tk(5, TK_IDENTIFIER, "wom")
End Sub

Sub test_replace_given_new_rpl()
  Local ok%

  lx.parse_basic("'!replace foo bar") : ok% = tr.transpile%()
  lx.parse_basic("foo wom bill") : ok% = tr.transpile%()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "bill")

  lx.parse_basic("'!replace foo snafu") : ok% = tr.transpile%()
  lx.parse_basic("foo wom bill") : ok% = tr.transpile%()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "snafu")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "bill")
End Sub

Sub test_apply_unreplace()
  Local ok%

  lx.parse_basic("'!replace foo bar") : ok% = tr.transpile%()
  lx.parse_basic("'!replace wom bat") : ok% = tr.transpile%()
  lx.parse_basic("'!replace bill ben") : ok% = tr.transpile%()
  expect_replacement(0, "foo", "bar")
  expect_replacement(1, "wom", "bat")
  expect_replacement(2, "bill", "ben")
  expect_replacement(3, "", "")

  lx.parse_basic("foo wom bill") : ok% = tr.transpile%()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "bat")
  expect_tk(2, TK_IDENTIFIER, "ben")

  lx.parse_basic("'!unreplace wom") : ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(0, "foo", "bar")
  expect_replacement(1, Chr$(0), Chr$(0))
  expect_replacement(2, "bill", "ben")
  expect_replacement(3, "", "")

  lx.parse_basic("foo wom bill") : ok% = tr.transpile%()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "ben")
End Sub

Sub test_comment_if()
  Local ok%

  ' 'foo' is set, code inside !comment_if block should be commented.
  lx.parse_basic("'!set foo") : ok% = tr.transpile%()
  lx.parse_basic("'!comment_if foo") : ok% = tr.transpile%()
  lx.parse_basic("one") : ok% = tr.transpile%()
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' one")
  lx.parse_basic("two") : ok% = tr.transpile%()
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' two")
  lx.parse_basic("'!endif") : ok% = tr.transpile%()

  ' Code outside the block should not be commented.
  lx.parse_basic("three") : ok% = tr.transpile%()
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_comment_if_not()
  Local ok%

  ' 'foo' is NOT set, code inside !comment_if NOT block should be commented.
  lx.parse_basic("'!comment_if not foo") : ok% = tr.transpile%()
  lx.parse_basic("one") : ok% = tr.transpile%()
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' one")
  lx.parse_basic("two") : ok% = tr.transpile%()
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' two")
  lx.parse_basic("'!endif") : ok% = tr.transpile%()

  ' 'foo' is set, code inside !comment_if NOT block should NOT be commented.
  lx.parse_basic("'!set foo") : ok% = tr.transpile%()
  lx.parse_basic("'!comment_if not foo") : ok% = tr.transpile%()
  lx.parse_basic("three") : ok% = tr.transpile%()
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
  lx.parse_basic("'!endif") : ok% = tr.transpile%()
End Sub

Sub test_uncomment_if()
  Local ok%

  ' 'foo' is set, code inside !uncomment_if block should be uncommented.
  lx.parse_basic("'!set foo") : ok% = tr.transpile%()
  lx.parse_basic("'!uncomment_if foo") : ok% = tr.transpile%()

  lx.parse_basic("' one") : ok% = tr.transpile%()
  assert_string_equals(" one", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")

  lx.parse_basic("REM two") : ok% = tr.transpile%()
  assert_string_equals(" two", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "two")

  lx.parse_basic("'' three") : ok% = tr.transpile%()
  assert_string_equals("' three", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' three")

  lx.parse_basic("'!endif") : ok% = tr.transpile%()

  ' Code outside the block should not be uncommented.
  lx.parse_basic("' four") : ok% = tr.transpile%()
  assert_string_equals("' four", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' four")
End Sub

Sub test_uncomment_if_not()
  Local ok%

  ' 'foo' is NOT set, code inside !uncomment_if NOT block should be uncommented.
  lx.parse_basic("'!uncomment_if not foo") : ok% = tr.transpile%()

  lx.parse_basic("' one") : ok% = tr.transpile%()
  assert_string_equals(" one", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")

  lx.parse_basic("REM two") : ok% = tr.transpile%()
  assert_string_equals(" two", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "two")

  lx.parse_basic("'' three") : ok% = tr.transpile%()
  assert_string_equals("' three", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' three")
  lx.parse_basic("'!endif") : ok% = tr.transpile%()

  ' 'foo' is set, code inside !uncomment_if NOT block should NOT be uncommented.
  lx.parse_basic("'!set foo") : ok% = tr.transpile%()
  lx.parse_basic("'!uncomment_if not foo") : ok% = tr.transpile%()
  lx.parse_basic("' four") : ok% = tr.transpile%()
  assert_string_equals("' four", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' four")
  lx.parse_basic("'!endif") : ok% = tr.transpile%()
End Sub

Sub test_remove_if()
  Local ok%

  ' 'foo' is set, code inside !remove_if block should be omitted.
  lx.parse_basic("'!set foo") : ok% = tr.transpile%()
  lx.parse_basic("'!remove_if foo") : ok% = tr.transpile%()
  lx.parse_basic("one") : ok% = tr.transpile%()
  expect_tokens(0)
  lx.parse_basic("two") : ok% = tr.transpile%()
  expect_tokens(0)
  lx.parse_basic("'!endif") : ok% = tr.transpile%()

  ' Code outside the block should not be omitted.
  lx.parse_basic("three") : ok% = tr.transpile%()
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_remove_if_not()
  Local ok%

  ' 'foo' is not set, code inside !remove_if block should be omitted.
  lx.parse_basic("'!remove_if not foo") : ok% = tr.transpile%()
  lx.parse_basic("one") : ok% = tr.transpile%()
  expect_tokens(0)
  lx.parse_basic("two") : ok% = tr.transpile%()
  expect_tokens(0)
  lx.parse_basic("'!endif") : ok% = tr.transpile%()

  ' Code outside the block should not be omitted.
  lx.parse_basic("three") : ok% = tr.transpile%()
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_unknown_directive()
  lx.parse_basic("'!wombat foo")
  assert_int_equals(0, tr.transpile%())
  assert_error("unknown !wombat directive")
End Sub

Sub expect_replacement(i%, from$, to_$)
  assert_true(from$ = tr.replacements$(i%, 0), "Assert failed, expected from$ = '" + from$ + "', but was '" + tr.replacements$(i%, 0) + "'")
  assert_true(to_$  = tr.replacements$(i%, 1), "Assert failed, expected to_$ = '"   + to_$  + "', but was '" + tr.replacements$(i%, 1) + "'")
End Sub

Sub expect_tokens(num)
  assert_no_error()
  assert_true(lx.num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx.num))
End Sub

Sub expect_tk(i, type, s$)
  assert_true(lx.type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx.type(i)))
  assert_string_equals(s$, lx.token$(i))
End Sub

