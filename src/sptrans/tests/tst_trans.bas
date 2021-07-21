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

run_tests()

End

Sub setup_test()
  set.clear(tr.flags$())
  tr.clear_replacements()
End Sub

Sub teardown_test()
End Sub

Sub test_parse_replace()
  lx.parse_basic("'!replace DEF Sub")
  tr.transpile()
  assert_string_equals("", sys.err$)
  expect_replacement(0, "def", "Sub")

  lx.parse_basic("'!replace ENDPROC { End Sub }")
  tr.transpile()
  assert_string_equals("", sys.err$)
  expect_replacement(1, "endproc", "End|Sub")

  lx.parse_basic("'!replace { THEN ENDPROC } { Then Exit Sub }")
  tr.transpile()
  assert_string_equals("", sys.err$)
  expect_replacement(2, "then|endproc", "Then|Exit|Sub")

  lx.parse_basic("'!replace GOTO%% { Goto %1 }")
  tr.transpile()
  assert_string_equals("", sys.err$)
  expect_replacement(3, "goto%%", "Goto|%1")

  lx.parse_basic("'!replace { THEN %% } { Then Goto %1 }")
  tr.transpile()
  assert_string_equals("", sys.err$)
  expect_replacement(4, "then|%%", "Then|Goto|%1")

  lx.parse_basic("'!replace '%% { CRLF$ %1 }")
  tr.transpile()
  assert_string_equals("", sys.err$)
  expect_replacement(5, "'%%", "CRLF$|%1")

  lx.parse_basic("'!replace &%h &h%1")
  tr.transpile()
  assert_string_equals("", sys.err$)
  expect_replacement(6, "&%h", "&h%1")

  lx.parse_basic("'!replace foo")
  tr.transpile()
  assert_string_equals("", sys.err$)
  expect_replacement(7, "foo", "")

  lx.parse_basic("'!replace {foo}")
  tr.transpile()
  assert_string_equals("", sys.err$)
  expect_replacement(7, Chr$(0), Chr$(0))
  expect_replacement(8, "foo", "")

  lx.parse_basic("'!replace foo {}")
  tr.transpile()
  assert_string_equals("", sys.err$)
  expect_replacement(8, Chr$(0), Chr$(0))
  expect_replacement(9, "foo", "")
End Sub

Sub test_parse_replace_given_errors()
  lx.parse_basic("'!replace")
  tr.transpile()
  assert_int_equals(0, tr.num_replacements%)
  assert_string_equals("!replace directive expects <from> argument", sys.err$)

  lx.parse_basic("'!replace {}")
  tr.transpile()
  assert_int_equals(0, tr.num_replacements%)
  assert_string_equals("!replace directive has empty <from> group", sys.err$)

  lx.parse_basic("'!replace {} y")
  tr.transpile()
  assert_int_equals(0, tr.num_replacements%)
  assert_string_equals("!replace directive has empty <from> group", sys.err$)

  lx.parse_basic("'!replace { x y")
  tr.transpile()
  assert_int_equals(0, tr.num_replacements%)
  assert_string_equals("!replace directive has missing '}'", sys.err$)

  lx.parse_basic("'!replace { x } { y z")
  tr.transpile()
  assert_int_equals(0, tr.num_replacements%)
  assert_string_equals("!replace directive has missing '}'", sys.err$)

  lx.parse_basic("'!replace { x } { y } z")
  tr.transpile()
  assert_int_equals(0, tr.num_replacements%)
  assert_string_equals("!replace directive has too many arguments", sys.err$)

  lx.parse_basic("'!replace { x } { y } { z }")
  tr.transpile()
  assert_int_equals(0, tr.num_replacements%)
  assert_string_equals("!replace directive has too many arguments", sys.err$)

  lx.parse_basic("'!replace { {")
  tr.transpile()
  assert_int_equals(0, tr.num_replacements%)
  assert_string_equals("!replace directive has unexpected '{'", sys.err$)

  lx.parse_basic("'!replace foo }")
  tr.transpile()
  assert_int_equals(0, tr.num_replacements%)
  assert_string_equals("!replace directive has unexpected '}'", sys.err$)
End Sub

Sub test_parse_given_too_many_rpl()
  Local i%
  For i% = 0 To tr.MAX_REPLACEMENTS% - 1
    lx.parse_basic("'!replace a" + Str$(i%) + " b")
    tr.transpile()
  Next
  assert_string_equals("", sys.err$)

  lx.parse_basic("'!replace foo bar")
  tr.transpile()
  assert_string_equals("!replace directive too many replacements (max 200)", sys.err$)
End Sub

Sub test_parse_unreplace()
  lx.parse_basic("'!replace foo bar")
  tr.transpile()
  lx.parse_basic("'!replace wom bat")
  tr.transpile()
  lx.parse_basic("'!unreplace foo")
  tr.transpile()

  assert_string_equals("", sys.err$)
  assert_int_equals(2, tr.num_replacements%)
  expect_replacement(0, Chr$(0), Chr$(0))
  expect_replacement(1, "wom", "bat")
End Sub

Sub test_parse_unreplace_given_errs()
  ' Test given missing argument to directive.
  lx.parse_basic("'!unreplace")
  tr.transpile()
  assert_string_equals("!unreplace directive expects <from> argument", sys.err$)

  ' Test given directive has too many arguments.
  lx.parse_basic("'!unreplace { a b } c")
  tr.transpile()
  assert_string_equals("!unreplace directive has too many arguments", sys.err$)

  ' Test given replacement not present.
  lx.parse_basic("'!replace wom bat")
  tr.transpile()
  lx.parse_basic("'!unreplace foo")
  tr.transpile()
  assert_string_equals("!unreplace directive could not find 'foo'", sys.err$)
  assert_int_equals(1, tr.num_replacements%)
  expect_replacement(0, "wom", "bat")
End Sub

Sub test_apply_replace()
  lx.parse_basic("'!replace x      y") : tr.transpile()
  lx.parse_basic("'!replace &hFFFF z") : tr.transpile()
  lx.parse_basic("Dim x = &hFFFF ' comment") : tr.transpile()

  expect_tokens(5)
  expect_tk(0, TK_KEYWORD, "Dim")
  expect_tk(1, TK_IDENTIFIER, "y")
  expect_tk(2, TK_SYMBOL, "=")
  expect_tk(3, TK_IDENTIFIER, "z")
  expect_tk(4, TK_COMMENT, "' comment")
  assert_string_equals("Dim y = z ' comment", lx.line$)
End Sub

Sub test_apply_replace_groups()
  lx.parse_basic("'!replace ab { cd ef }") : tr.transpile()
  lx.parse_basic("ab gh ij") : tr.transpile()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "cd")
  expect_tk(1, TK_IDENTIFIER, "ef")
  expect_tk(2, TK_IDENTIFIER, "gh")
  expect_tk(3, TK_IDENTIFIER, "ij")

  setup_test()
  lx.parse_basic("'!replace {ab cd} ef") : tr.transpile()
  lx.parse_basic("ab cd gh ij") : tr.transpile()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "ef")
  expect_tk(1, TK_IDENTIFIER, "gh")
  expect_tk(2, TK_IDENTIFIER, "ij")
End Sub

Sub test_apply_replace_patterns()
  setup_test()
  lx.parse_basic("'!replace { DEF PROC%% } { SUB proc%1 }") : tr.transpile()
  lx.parse_basic("foo DEF PROCWOMBAT bar") : tr.transpile()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "SUB")
  expect_tk(2, TK_IDENTIFIER, "procWOMBAT") ' Note don't want to change case of WOMBAT.
  expect_tk(3, TK_IDENTIFIER, "bar")

  setup_test()
  lx.parse_basic("'!replace GOTO%d { Goto %1 }") : tr.transpile()
  lx.parse_basic("foo GOTO1234 bar") : tr.transpile()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD   , "Goto")
  expect_tk(2, TK_NUMBER,     "1234")
  expect_tk(3, TK_IDENTIFIER, "bar") 

  setup_test()
  lx.parse_basic("'!replace { THEN %d } { Then Goto %1 }") : tr.transpile()

  ' Test %d pattern matches decimal digits ...
  lx.parse_basic("foo THEN 1234 bar") : tr.transpile()
  expect_tokens(5)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD   , "Then")
  expect_tk(2, TK_KEYWORD   , "Goto")
  expect_tk(3, TK_NUMBER,     "1234")
  expect_tk(4, TK_IDENTIFIER, "bar") 

  ' ... but it should not match other characters.
  lx.parse_basic("foo THEN wombat bar") : tr.transpile()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD   , "THEN")
  expect_tk(2, TK_IDENTIFIER, "wombat")
  expect_tk(3, TK_IDENTIFIER, "bar") 

  setup_test()
  lx.parse_basic("'!replace { PRINT '%% } { ? : ? %1 }") : tr.transpile()
  lx.parse_basic("foo PRINT '" + Chr$(34) + "wombat" + Chr$(34) + " bar") : tr.transpile()
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_SYMBOL,     "?")
  expect_tk(2, TK_SYMBOL,     ":")
  expect_tk(3, TK_SYMBOL,     "?")
  expect_tk(4, TK_STRING,     Chr$(34) + "wombat" + Chr$(34))
  expect_tk(5, TK_IDENTIFIER, "bar")

  setup_test()
  lx.parse_basic("'!replace '%% { : ? %1 }") : tr.transpile()
  lx.parse_basic("foo PRINT '" + Chr$(34) + "wombat" + Chr$(34) + " bar") : tr.transpile()
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "PRINT")
  expect_tk(2, TK_SYMBOL,     ":")
  expect_tk(3, TK_SYMBOL,     "?")
  expect_tk(4, TK_STRING,     Chr$(34) + "wombat" + Chr$(34))
  expect_tk(5, TK_IDENTIFIER, "bar")

  setup_test()
  lx.parse_basic("'!replace REM%% { ' %1 }") : tr.transpile()
  lx.parse_basic("foo REM This is a comment") : tr.transpile()
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_COMMENT, "' This is a comment")

  setup_test()
  lx.parse_basic("'!replace { Spc ( } { Space$ ( }") : tr.transpile()
  lx.parse_basic("foo Spc(5) bar") : tr.transpile()
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "Space$")
  expect_tk(2, TK_SYMBOL,     "(")
  expect_tk(3, TK_NUMBER,     "5")
  expect_tk(4, TK_SYMBOL,     ")")
  expect_tk(5, TK_IDENTIFIER, "bar")

  ' Test %h pattern matches hex digits ...
  setup_test()
  lx.parse_basic("'!replace GOTO%h { Goto %1 }") : tr.transpile()
  lx.parse_basic("foo GOTOabcdef0123456789 bar") : tr.transpile()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "Goto")
  expect_tk(2, TK_IDENTIFIER, "abcdef0123456789")
  expect_tk(3, TK_IDENTIFIER, "bar")

  ' ... but it should not match other characters.
  lx.parse_basic("foo GOTOxyz bar") : tr.transpile()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "GOTOxyz")
  expect_tk(2, TK_IDENTIFIER, "bar")
End Sub

Sub test_replace_fails_if_too_long()
  Local s$
  lx.parse_basic("'!replace foo foobar") : tr.transpile()

  ' Test where replaced string should be 255 characters.
  s$ = String$(248, "a")
  Cat s$, " foo"
  assert_int_equals(252, Len(s$))
  lx.parse_basic(s$)
  tr.transpile()
  assert_no_error()
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, String$(248, "a"))
  expect_tk(1, TK_IDENTIFIER, "foobar")


  ' Test where replaced string should be 256 characters.
  s$ = String$(251, "a")
  Cat s$, " foo"
  assert_int_equals(255, Len(s$))
  lx.parse_basic(s$)
  tr.transpile()
  assert_error("applying replacement makes line > 255 characters")
End Sub

Sub test_replace_with_fewer_tokens()
  ' Replace 1 token with 0.
  lx.parse_basic("'!replace bar") : tr.transpile()
  lx.parse_basic("foo bar wom") : tr.transpile()
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "wom")

  ' Removal of all tokens.
  setup_test()
  lx.parse_basic("'!replace bar") : tr.transpile()
  lx.parse_basic("bar bar bar") : tr.transpile()
  expect_tokens(0)

  ' Replace 2 tokens with 1.
  setup_test()
  lx.parse_basic("'!replace { foo bar } wom") : tr.transpile()
  lx.parse_basic("foo bar foo bar snafu") : tr.transpile()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "wom")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "snafu")

  ' Note that we don't end up with the single token "foo" because once we have
  ' applied a replacement we do not recursively apply that replacement to the
  ' already replaced text.
  setup_test()
  lx.parse_basic("'!replace { foo bar } foo") : tr.transpile()
  lx.parse_basic("foo bar bar") : tr.transpile()
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")

  ' Replace 3 tokens with 1 - again note we don't just end up with "foo".
  setup_test()
  lx.parse_basic("'!replace { foo bar wom } foo") : tr.transpile()
  lx.parse_basic("foo bar wom bar wom") : tr.transpile()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")

  ' Replace 3 tokens with 2 - and again we don't just end up with "foo bar".
  setup_test()
  lx.parse_basic("'!replace { foo bar wom } { foo bar }") : tr.transpile()
  lx.parse_basic("foo bar wom wom") : tr.transpile()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")
End Sub

Sub test_replace_with_more_tokens()
  ' Replace 1 token with 2 - note that we don't get infinite recursion because
  ' once we have applied the replacement text we not not recusively apply the
  ' replacement to the already replaced text.
  lx.parse_basic("'!replace foo { foo bar }") : tr.transpile()
  lx.parse_basic("foo wom") : tr.transpile()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")

  setup_test()
  lx.parse_basic("'!replace foo { bar foo }") : tr.transpile()
  lx.parse_basic("foo wom foo") : tr.transpile()
  expect_tokens(5)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "foo")
  expect_tk(2, TK_IDENTIFIER, "wom")
  expect_tk(3, TK_IDENTIFIER, "bar")
  expect_tk(4, TK_IDENTIFIER, "foo")

  ' Ensure replacement applied for multiple matches.
  setup_test()
  lx.parse_basic("'!replace foo { bar foo }") : tr.transpile()
  lx.parse_basic("foo foo") : tr.transpile()
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "foo")
  expect_tk(2, TK_IDENTIFIER, "bar")
  expect_tk(3, TK_IDENTIFIER, "foo")

  ' Replace 3 tokens with 4.
  setup_test()
  lx.parse_basic("'!replace { foo bar wom } { foo bar wom foo }") : tr.transpile()
  lx.parse_basic("foo bar wom bar wom") : tr.transpile()
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")
  expect_tk(3, TK_IDENTIFIER, "foo")
  expect_tk(4, TK_IDENTIFIER, "bar")
  expect_tk(5, TK_IDENTIFIER, "wom")
End Sub

  expect_tk(2, TK_IDENTIFIER, "ben")
End Sub

Sub test_replace_given_new_rpl()
  lx.parse_basic("'!replace foo bar") : tr.transpile()
  lx.parse_basic("foo wom bill") : tr.transpile()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "bill")

  lx.parse_basic("'!replace foo snafu") : tr.transpile()
  lx.parse_basic("foo wom bill") : tr.transpile()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "snafu")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "bill")
End Sub

Sub test_apply_unreplace()
  lx.parse_basic("'!replace foo bar") : tr.transpile()
  lx.parse_basic("'!replace wom bat") : tr.transpile()
  lx.parse_basic("'!replace bill ben") : tr.transpile()
  expect_replacement(0, "foo", "bar")
  expect_replacement(1, "wom", "bat")
  expect_replacement(2, "bill", "ben")
  expect_replacement(3, "", "")

  lx.parse_basic("foo wom bill") : tr.transpile()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "bat")
  expect_tk(2, TK_IDENTIFIER, "ben")

  lx.parse_basic("'!unreplace wom") : tr.transpile()
  assert_string_equals("", sys.err$)
  expect_replacement(0, "foo", "bar")
  expect_replacement(1, Chr$(0), Chr$(0))
  expect_replacement(2, "bill", "ben")
  expect_replacement(3, "", "")

  lx.parse_basic("foo wom bill") : tr.transpile()
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "ben")
End Sub

Sub test_comment_if()
  ' 'foo' is set, code inside !comment_if block should be commented.
  lx.parse_basic("'!set foo") : tr.transpile()
  lx.parse_basic("'!comment_if foo") : tr.transpile()
  lx.parse_basic("one") : tr.transpile()
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' one")
  lx.parse_basic("two") : tr.transpile()
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' two")
  lx.parse_basic("'!endif") : tr.transpile()

  ' Code outside the block should not be commented.
  lx.parse_basic("three") : tr.transpile()
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_comment_if_not()
  ' 'foo' is NOT set, code inside !comment_if NOT block should be commented.
  lx.parse_basic("'!comment_if not foo") : tr.transpile()
  lx.parse_basic("one") : tr.transpile()
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' one")
  lx.parse_basic("two") : tr.transpile()
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' two")
  lx.parse_basic("'!endif") : tr.transpile()

  ' 'foo' is set, code inside !comment_if NOT block should NOT be commented.
  lx.parse_basic("'!set foo") : tr.transpile()
  lx.parse_basic("'!comment_if not foo") : tr.transpile()
  lx.parse_basic("three") : tr.transpile()
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
  lx.parse_basic("'!endif") : tr.transpile()
End Sub

Sub test_uncomment_if()
  ' 'foo' is set, code inside !uncomment_if block should be uncommented.
  lx.parse_basic("'!set foo") : tr.transpile()
  lx.parse_basic("'!uncomment_if foo") : tr.transpile()

  lx.parse_basic("' one") : tr.transpile()
  assert_string_equals(" one", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")

  lx.parse_basic("REM two") : tr.transpile()
  assert_string_equals(" two", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "two")

  lx.parse_basic("'' three") : tr.transpile()
  assert_string_equals("' three", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' three")
  lx.parse_basic("'!endif") : tr.transpile()

  ' Code outside the block should not be uncommented.
  lx.parse_basic("' four") : tr.transpile()
  assert_string_equals("' four", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' four")
End Sub

Sub test_uncomment_if_not()
  ' 'foo' is NOT set, code inside !uncomment_if NOT block should be uncommented.
  lx.parse_basic("'!uncomment_if not foo") : tr.transpile()

  lx.parse_basic("' one") : tr.transpile()
  assert_string_equals(" one", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")

  lx.parse_basic("REM two") : tr.transpile()
  assert_string_equals(" two", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "two")

  lx.parse_basic("'' three") : tr.transpile()
  assert_string_equals("' three", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' three")
  lx.parse_basic("'!endif") : tr.transpile()

  ' 'foo' is set, code inside !uncomment_if NOT block should NOT be uncommented.
  lx.parse_basic("'!set foo") : tr.transpile()
  lx.parse_basic("'!uncomment_if not foo") : tr.transpile()
  lx.parse_basic("' four") : tr.transpile()
  assert_string_equals("' four", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' four")
  lx.parse_basic("'!endif") : tr.transpile()
End Sub

Sub test_unknown_directive()
  lx.parse_basic("'!wombat foo") : tr.transpile()
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

