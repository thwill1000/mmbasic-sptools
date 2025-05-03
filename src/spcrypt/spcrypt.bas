' Copyright (c) 2021-2025 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 6.00
'
' MD5 algorithm from https://en.wikipedia.org/wiki/MD5
' XXTEA algorithm from https://en.wikipedia.org/wiki/XXTEA

Option Explicit On
Option Default None
Option Base 0

#Include "../splib/system.inc"
#Include "../splib/array.inc"
#Include "../splib/crypt.inc"
#Include "../splib/string.inc"
#Include "../splib/list.inc"
#Include "../splib/file.inc"
#Include "../common/sptools.inc"

Const PROG_NAME$ = LCase$(file.trim_extension$(file.get_name$(Mm.Info(Current))))

Dim cmd$
Dim in_file$
Dim out_file$
Dim password$
Dim version%
Dim ok%

ok% = parse_cmdline%()
If Not ok% Then print_usage() : End
If version% Then spt.print_version(PROG_NAME$) : End

If Not file.exists%(in_file$) Then
  ok% = 0
  sys.err$ = "input file '" + in_file$ + "' not found"
EndIf

If ok% Then
  Select Case cmd$
    Case "decrypt" : ok% = cmd_decrypt%()
    Case "encrypt" : ok% = cmd_encrypt%()
    Case "md5"     : ok% = cmd_md5%()
    Case Else      : Error "Unimplemented command."
  End Select
EndIf

If ok% Then
  Print "OK"
ElseIf sys.err$ <> "" Then
  Print PROG_NAME$ + ": " + sys.err$
EndIf

End

Function parse_cmdline%()

  Local token$ = str.next_token$(Mm.CmdLine$)
  Local opt$, value$

  Do
    token$ = Choice(token$ = sys.NO_DATA$, "", token$)
    If token$ = "" Then Exit Do
    If parse_option%(token$) Then
      If version% Then parse_cmdline% = 1 : Exit Function
    ElseIf sys.err$ <> "" Then
      Exit Function
    ElseIf cmd$ = "" Then
      cmd$ = LCase$(token$)
    ElseIf in_file$ = "" Then
      in_file$ = token$
    ElseIf out_file$ = "" Then
      out_file$ = token$
    Else
      sys.err$ = "unexpected argument '" + token$ + "'"
      Exit Function
    EndIf
    token$ = str.next_token$()
  Loop

  ' Validate command.
  Select Case cmd$
    Case "" : sys.err$ = "no command specified"
    Case "decrypt", "encrypt", "md5"
    Case Else : sys.err$ = "unknown command '" + cmd$ + "' specified"
  End Select
  If cmd$ = "md5" And password$ <> "" Then
    sys.err$ = "MD5 command does not support '--password' option"
  EndIf
  If sys.err$ <> "" Then Exit Function

  ' Validate input file.
  in_file$ = str.trim$(str.unquote$(in_file$))
  If in_file$ = "" Then sys.err$ = "no input file specified" : Exit Function

  ' Validate output file.
  out_file$ = str.trim$(str.unquote$(out_file$))
  If cmd$ = "md5" And out_file$ <> "" Then
    sys.err$ = "MD5 command does not expect output file"
    Exit Function
  EndIf
  If out_file$ = "" Then out_file$ = in_file$ + "." + cmd$ + "ed"

  parse_cmdline% = 1
End Function

' Parses a token to see if it is an option.
'
' @param  token$  the token to parse.
' @return         1 if it is an option, or 0 if it is not an option.
'                 On error sets sys.err$ and returns 0.
Function parse_option%(token$)
  If InStr(token$, "-") <> 1 Then Exit Function

  Local p% = InStr(token$, "=")
  Local opt$ = Choice(p% = 0, token$, Mid$(token$, 1, p% - 1))
  Local value$ = Choice(p% = 0, "", Mid$(token$, p% + 1))

  Select Case opt$
    Case "-p", "--password"
      If value$ = "" Then
        sys.err$ = "option '" + opt$ + "' expects argument"
      Else
        password$ = value$
      EndIf
    Case "--version"
      If value$ = "" Then
        version% = 1
      Else
        sys.err$ = "option '" + opt$ + "' does not expect an argument"
      EndIf
    Case Else
      sys.err$ = "unknown option '" + opt$ + "'"
  End Select

  parse_option% = (sys.err$ = "")
End Function

Sub print_usage()
  Const fin$ = "<input-file>"
  Const fout$ = "<output-file>"

  If sys.err$ <> "" Then Print PROG_NAME$ + ": " + sys.err$ : Print

  Print "Usage *" PROG_NAME$ " [OPTION]... <command> " fin$ " [" fout$ "]"
  Print
  Print "Options:"
  Print "  -p, --password=<password>  Use <password> for encryption/decryption."
  Print "                             If omitted then user will be prompted."
  Print "  --version                  Output version information and exit."
  Print
  Print "Commands:"
  Print "  decrypt  Decrypt " fin$ " using XXTEA algorithm."
  Print "  encrypt  Encrypt " fin$ " using XXTEA algorithm."
  Print "  md5      Calculate MD5 checksum for " fin$ "."
End Sub

Function cmd_decrypt%()
  If Not prompt_for_overwrite%() Then Print "CANCELLED" : Exit Function
  If Not prompt_for_password%()  Then Print "CANCELLED" : Exit Function

  Print "Decrypting from '" in_file$ "' to '" out_file$ "' ..."
  Local md5%(array.new%(2))
  If Not crypt.md5%(Peek(VarAddr password$) + 1, Len(password$), md5%()) Then Exit Function
  Open in_file$ For Input As #1
  Open out_file$ For Output As #2
  Local iv%(array.new%(2)) ' Ignored for decryption.
  cmd_decrypt% = crypt.xxtea_file%("decrypt", 1, 2, md5%(), iv%())
  Close #2
  Close #1
End Function

Function prompt_for_overwrite%()
  Local s$ = "y"
  If file.exists%(out_file$) Then
    Line Input "Overwrite existing '" + out_file$ + "' [y|N] ? ", s$
    s$ = LCase$(str.trim$(s$))
  EndIf
  prompt_for_overwrite% = (s$ = "y")
Exit Function

Function prompt_for_password%()
  password$ = str.trim$(password$)
  If password$ = "" Then
    Input "Password? ", password$
    password$ = str.trim$(password$)
  EndIf
  prompt_for_password% = password$ <> ""
Exit Function

Function cmd_encrypt%()
  If Not prompt_for_overwrite%() Then Print "CANCELLED" : Exit Function
  If Not prompt_for_password%()  Then Print "CANCELLED" : Exit Function

  Print "Encrypting from '" in_file$ "' to '" out_file$ "' ..."
  Local md5%(array.new%(2))
  If Not crypt.md5%(Peek(VarAddr password$) + 1, Len(password$), md5%()) Then Exit Function
  Open in_file$ For Input As #1
  Open out_file$ For Output As #2
  Local iv%(array.new%(2))
  fill_iv(iv%())
  cmd_encrypt% = crypt.xxtea_file%("encrypt", 1, 2, md5%(), iv%())
  Close #2
  Close #1
End Function

Sub fill_iv(iv%())
  Local i%, iv_addr% = Peek(VarAddr iv%()))
  For i% = 0 To 15 : Poke Byte iv_addr% + i%, Fix(256 * Rnd()) : Next
End Sub

Function cmd_md5%()
  Open in_file$ For Input As #1
  Local md5%(array.new%(2))
  cmd_md5% = crypt.md5_file%(1, md5%())
  Close #1
  If cmd_md5% Then Print crypt.md5_fmt$(md5%())
End Function
