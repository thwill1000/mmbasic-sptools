' Copyright (c) 2021-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 0.6.0

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("array", "console", "file", "history", "inifile", "map", "string")
sys.provides("gonzo")
If sys.err$ <> "" Then Error sys.err$
'!endif

Const CRLF = Chr$(&h0D) + Chr$(&h0A)
Const ECHO = &h01
Const COLLECT = &h02
Const SKIP_EMPTY = &h04

Const gonzo.DEVICE_DISCONNECTED = 0
Const gonzo.DEVICE_CMM2 = 1
Const gonzo.DEVICE_PICOMITE = 2
Const gonzo.DEVICE_OTHER = 3

Const gonzo.SERIAL_FNBR = 1
Const gonzo.IN_FNBR = 2
Const gonzo.LOG_FNBR = 3
Const gonzo.INI_FNBR = 4
Const gonzo.OUT_FNBR = 5
Const gonzo.CONSOLE_FNBR = 6

Const gonzo.DOT_DIR = "~/.gonzo"
Const gonzo.LOG_FILE = gonzo.DOT_DIR + "/gonzo.log"
Const gonzo.RIZZO_FILE = "/tmp/rizzo.bas"

Dim gonzo.comspec$
Dim gonzo.device_name$ = "DISCONNECTED"
Dim gonzo.device% = gonzo.DEVICE_DISCONNECTED
Dim gonzo.history%(array.new%(128)) ' 1K
Dim gonzo.rx_buf$
Dim gonzo.buf%(1000)
Dim gonzo.exit_flag%
Dim gonzo.rizzo_sent%

Sub gonzo.connect(verbose%)
  con.println("Connecting to " + gonzo.comspec$ + " ...")
  con.println("Press Ctrl-C to interrupt")

  On Error Skip 1
  Close #gonzo.LOG_FNBR
  On Error Clear

  On Error Skip 1
  Close #gonzo.SERIAL_FNBR
  On Error Clear

  Open gonzo.LOG_FILE For Output As #gonzo.LOG_FNBR

  On Error Skip 1
  Open gonzo.comspec$ As #gonzo.SERIAL_FNBR
  If Mm.ErrMsg$ <> "" Then
    con.errorln("Failed to connect:" + Mid$(Mm.ErrMsg$, InStr(Mm.ErrMsg$, ":") + 1))
    gonzo.device_name$ = "DISCONNECTED"
    On Error Clear
  Else
    gonzo.device_name$ = gonzo.get_device$()
  EndIf

  Select Case gonzo.device_name$
    Case "Colour Maximite 2", "Colour Maximite 2 G2" : gonzo.device% = gonzo.DEVICE_CMM2
    Case "DISCONNECTED" : gonzo.device% = gonzo.DEVICE_DISCONNECTED
    Case "PicoMite"     : gonzo.device% = gonzo.DEVICE_PICOMITE
    Case Else           : gonzo.device% = gonzo.DEVICE_OTHER
  End Select

  If verbose% Then
    If gonzo.device% <> gonzo.DEVICE_DISCONNECTED Then
      con.println("Connected to " + gonzo.device_name$)
    EndIf
    gonzo.update_title()
  EndIf

  ' New connection so 'rizzo' needs to be resent.
  gonzo.rizzo_sent% = 0
End Sub

Sub gonzo.update_title(prefix$)
  Const title$ = gonzo.device_name$ + " - " + gonzo.comspec$ + " - gonzo v" + sys.format_version$()
  Console SetTitle Choice(prefix$ = "", title$, prefix$ + " - " + title$)
End Sub

Function gonzo.prompt_for_comspec$()
  Local count% = 0, i%, s$

  Restore device_name_data
  Do
    Read s$
    If s$ = "" Then Exit Do
    Inc count%
  Loop
  Local devices$(array.new%(count%))
  Restore device_name_data
  For i% = 0 To count% - 1
    Read devices$(i%)
  Next

  Local history%(array.new%(128))
  history.fill(history%(), devices$())
  con.print("Device? ")
  Local device$ = con.readln$("/dev/ttyS0", history%())
  If sys.break_flag% Then Exit Sub

  Restore baud_rate_data
  count% =0
  Do
    Read s$
    If s$ = "" Then Exit Do
    Inc count%
  Loop
  Local baud_rates$(array.new%(count%))
  Restore baud_rate_data
  For i% = 0 To count% - 1
    Read baud_rates$(i%)
  Next

  history.fill(history%(), baud_rates$())
  con.print("Baud? ")
  Local baud$ = con.readln$("115200", history%())
  If sys.break_flag% Then Exit Sub

  gonzo.prompt_for_comspec$ = device$ + ": " + baud$
End Function

Sub gonzo.remote_file_cmd(command$, quiet%)
  If Not gonzo.check_connection%() Then Exit Sub

  gonzo.send_break()
  gonzo.read_until_prompt()
  gonzo.writeln(command$)
  gonzo.read_until_match("> " + command$)
  gonzo.clear_buf()
  gonzo.read_until_prompt(COLLECT Or SKIP_EMPTY)
  If LInStr(gonzo.buf%(), "Could not find") Then
    con.println("Error: file or directory not found")
  ElseIf LInStr(gonzo.buf%(), "Access denied") Then
    con.println("Error: file or directory exists")
  ElseIf Not quiet% Then
    ' con.print(LGetStr$(gonzo.buf%(), 1, 255))
    con.println("OK")
  EndIf
End Sub

Function gonzo.check_connection%()
  If gonzo.device% <> gonzo.DEVICE_DISCONNECTED Then
    gonzo.check_connection% = 1
  Else
    sys.err$ = "Error: no connection"
  EndIf
End Function

' Sends a file from the local to the remote using AUTOSAVE.
Sub gonzo.send_file(local_file$, remote_file$, verbose%)
  If Not gonzo.check_file_exists%(local_file$) Then Exit Sub

  ' Open the file to send.
  Open local_file$ For Input As #gonzo.IN_FNBR

  ' Cleanup for a new command.
  gonzo.send_break()
  gonzo.read_until_prompt()

  ' Send AUTOSAVE command.
  Local command$ = "Autosave"
  If gonzo.device% = gonzo.DEVICE_CMM2 Then Cat command$, " " + str.quote$(remote_file$)
  gonzo.writeln(command$)
  gonzo.read_until_match("> " + command$)
  Local s$
  If gonzo.getln%(s$) Then
    sys.err$ = gonzo.extract_error$(s$)
    If sys.err$ <> "" Then Close #gonzo.IN_FNBR : Exit Sub
  EndIf

  Local file_size% = Mm.Info(FileSize local_file$)
  If verbose% Then con.println("Autosave sending " + Str$(file_size%) + " bytes to '" + remote_file$ + "' ...")
  Local t% = Timer

  ' Echo the file to the serial port.
  Local count% = 0, x%
  Do While Not Eof(#gonzo.IN_FNBR) And Not sys.break_flag%
    Line Input #gonzo.IN_FNBR, s$
    gonzo.writeln(s$, CRLF)  ' Need CRLF on CMM2, what about other platforms ?
    x% = gonzo.getln%(s$)
    Inc count%
    If verbose% Then
      con.println(Choice(count% > 1, Chr$(27) + "[1F", "") + "Sent " + Str$(count%) + " lines")
    EndIf
  Loop
  Close #gonzo.IN_FNBR

  If sys.break_flag% Then sys.err$ = "Interrupted by user" : Exit Sub

  ' Send F6 or Ctrl-Z to terminate as appropriate.
  gonzo.write(Choice(gonzo.device% = gonzo.DEVICE_CMM2, Chr$(27) + "[17~", Chr$(26)))
  gonzo.read_until_prompt()

  ' Except on the CMM2 send SAVE command to write from flash to disk.
  If (gonzo.device% <> gonzo.DEVICE_CMM2) Then
    command$ = "Save " + str.quote$(remote_file$)
    gonzo.writeln(command$)
    gonzo.read_until_match("> " + command$)
    gonzo.clear_buf()
    gonzo.read_until_prompt(COLLECT Or SKIP_EMPTY)
    sys.err$ = gonzo.extract_error_ls$(gonzo.buf%())
  EndIf

  If verbose% And sys.err$ = "" Then
    con.println("OK, " + Str$((file_size% * 8000) / (Timer - t%), 0, 1) + " bit/s")
  EndIf
End Sub

Sub gonzo.clear_buf()
  LongString Clear gonzo.buf%()
End Sub

' Trim the size of the file on the remote.
Sub gonzo.trim_remote_file(file$, size%)
  If gonzo.send_rizzo%() <> 0 Then Exit Sub

  gonzo.writeln("Run " + str.quote$(gonzo.RIZZO_FILE))
  ' If the remote is a CMM2 then we need to wait for the program to start.
  ' TODO: Wait for "Filename? " prompt to be written instead on all remote types ?
  If gonzo.device% = gonzo.DEVICE_CMM2 Then Pause 1000
  gonzo.writeln(file$)
  gonzo.writeln(Str$(size%))
  gonzo.read_until_prompt()
End Sub

' Write and send 'rizzo.bas' to the remote.
Function gonzo.send_rizzo%()
  ' Only send the file once per session.
  If gonzo.rizzo_sent% Then Exit Function

  ' Ensure there is a '/tmp' directory on the remote.
  gonzo.remote_file_cmd("MkDir " + str.quote$("/tmp"), 1)

  Open gonzo.RIZZO_FILE For Output As #gonzo.OUT_FNBR
  Print #gonzo.OUT_FNBR, "Dim f$, s$, x%"
  Print #gonzo.OUT_FNBR, "Line Input " + str.quote$("Filename? ") + ", f$"
  Print #gonzo.OUT_FNBR, "Line Input " + str.quote$("Size? ") + ", s$"
  Print #gonzo.OUT_FNBR, "x% = Val(s$)"
  Print #gonzo.OUT_FNBR, "Open f$ For Input As #1"
  Print #gonzo.OUT_FNBR, "Open " str.quote$("/tmp/") " + f$ For Output As #2"
  Print #gonzo.OUT_FNBR, "Do While x% > 0"
  Print #gonzo.OUT_FNBR, "  s$ = Input$(Min(255, x%), #1)"
  Print #gonzo.OUT_FNBR, "  Print #2, s$;"
  Print #gonzo.OUT_FNBR, "  Inc x%, -Min(255, x%)"
  Print #gonzo.OUT_FNBR, "Loop"
  Print #gonzo.OUT_FNBR, "Close #2"
  Print #gonzo.OUT_FNBR, "Close #1"
  Print #gonzo.OUT_FNBR, "Copy " str.quote$("/tmp/") " + f$ To f$"
  Print #gonzo.OUT_FNBR, "Kill " str.quote$("/tmp/") " + f$"
  Print #gonzo.OUT_FNBR, "End"
  Close #gonzo.OUT_FNBR

  gonzo.send_file(gonzo.RIZZO_FILE, gonzo.RIZZO_FILE, 0)
  If sys.err$ <> "" Then
    gonzo.send_rizzo% = -1
    Exit Function
  EndIf

  gonzo.rizzo_sent% = 1
End Function

Sub gonzo.xsend_file(local_file$, remote_file$)
  If Not gonzo.check_file_exists%(local_file$) Then Exit Sub

  ' Cleanup for a new command.
  gonzo.send_break()
  gonzo.read_until_prompt()

  ' Send XMODEM RECEIVE command to remote.
  Local command$ = "XModem Receive " + str.quote$(remote_file$)
  gonzo.writeln(command$)
  gonzo.read_until_match("> " + command$)
  Local s$
  If gonzo.getln%(s$) Then
    sys.err$ = gonzo.extract_error$(s$)
    If sys.err$ <> "" Then Exit Sub
  EndIf

  ' Perform XMODEM SEND.
  Local file_size% = Mm.Info(FileSize local_file$)
  con.println("XModem sending " + Str$(file_size%) + " bytes to '" + remote_file$ + "' ...")
  Local t% = Timer
  XModem Send local_file$, #gonzo.SERIAL_FNBR, 1

  ' Trim file on remote to remove padding.
  gonzo.trim_remote_file(remote_file$, file_size%)
  If sys.err$ <> "" Then Exit Sub

  con.println("OK, " + Str$((file_size% * 8000) / (Timer - t%), 0, 1) + " bit/s")
End Sub

' @return  0 on success, -1 on failure.
Function gonzo.transpile%(in_file$, out_file$, args$)
  ' Note that double-quotes have to be escaped in the command.
  Local command$ = "mmbasic " + Mm.Info$(Path) + "../sptrans/sptrans.bas "
  Cat command$, args$ + " "
  Cat command$, "\" + Chr$(34) + in_file$ + "\" + Chr$(34) + " "
  Cat command$, "\" + Chr$(34) + out_file$ + "\" + Chr$(34)
  Local exit_status%
  System command$, , exit_status%
  con.foreground("yellow")
  gonzo.transpile% = Choice(exit_status%, -1, 0)
End Function

' Sends a Ctrl-C to the remote.
Sub gonzo.send_break()
  gonzo.write(Chr$(3))
End Sub

Function gonzo.extract_error$(s$)
  Local buf%(array.new%(32))
  LongString Append buf%(), s$
  gonzo.extract_error$ = gonzo.extract_error_ls$(buf%())
End Function

Function gonzo.extract_error_ls$(buf%())
  Local st% = LInStr(buf%(), "Error : ")
  If Not st% Then Exit Function
  Inc st%, 8
  Local en% = st%
  For en% = st% To LLen(buf%())
    Select Case LGetByte(buf%(), en%)
      Case &h0A, &h0D : Exit For
    End Select
  Next
  gonzo.extract_error_ls$ = "Remote error: " + LGetStr$(buf%(), st%, en% - st% + 1)
End Function

Function gonzo.get_device$()
  gonzo.send_break()
  gonzo.read_until_prompt()
  gonzo.writeln("? Mm.Device$")
  gonzo.read_until_match("> ? Mm.Device$")
  gonzo.clear_buf()
  gonzo.read_until_prompt(COLLECT Or SKIP_EMPTY)
  If sys.break_flag% Then
    con.println("Interrupted by user")
    gonzo.get_device$ = "DISCONNECTED"
  Else
    gonzo.get_device$ = LGetStr$(gonzo.buf%(), 1, LInStr(gonzo.buf%(), Chr$(&h0A)) - 1)
  EndIf
End Function

Function gonzo.get_file_size%(file$)
  gonzo.send_break()
  gonzo.read_until_prompt()
  Local command$ = "? Str$(Mm.Info(FileSize " + str.quote$(file$) + "))"
  gonzo.writeln(command$)
  gonzo.read_until_match("> " + command$)
  gonzo.clear_buf()
  gonzo.read_until_prompt(COLLECT Or SKIP_EMPTY)
  gonzo.get_file_size% = Val(LGetStr$(gonzo.buf%(), 1, 255))
  Select Case gonzo.get_file_size%
    Case -2 : sys.err$ = "Remote error: is a directory"
    Case -1 : sys.err$ = "Remote error: file not found"
  End Select
End Function

' Reads a character from the serial port.
'
' @param  timeout  milliseconds to try before returning a -1.
' @return          ASCII code of read character, or -1 if no character available.
Function gonzo.getc%(timeout%)
  Local t% = Timer + timeout%
  Local ch$
  Do
    ch$ = Input$(1, #gonzo.SERIAL_FNBR)
    If ch$ <> "" Then
      Print #gonzo.LOG_FNBR, ch$;
      gonzo.getc% = Asc(ch$)
      Exit Function
    EndIf
    If timeout% > 0 Then Pause 1
  Loop Until Timer >= t%
  gonzo.getc% = -1
End Function

' Reads a line from the serial port.
'
' @param   s$  the read line is returned int this.
' @return  1   if something was read including an empty line, 0 if nothing was read.
Function gonzo.getln%(s$)
  Local ch%
  Do
    ch% = gonzo.getc%(500)
    If ch% > -1 Then
      ' TODO: handle both CR and LF
      If ch% = &h0A Then
        s$ = gonzo.rx_buf$
        gonzo.rx_buf$ = ""
        gonzo.getln% = 1
        Exit Function
      ElseIf ch% <> &h0D Then
        If Len(gonzo.rx_buf$) < 255 Then Cat gonzo.rx_buf$, Chr$(ch%)
      EndIf
    EndIf
  Loop Until Eof(#gonzo.SERIAL_FNBR)
  s$ = ""
End Function

Sub gonzo.handle_press_any_key()
  If InStr(gonzo.rx_buf$, "PRESS ANY KEY ...") <> 1 Then Exit Sub
  gonzo.rx_buf$ = ""
  gonzo.write(" ")
  ' Ignore krud.
  Do While gonzo.getc%(500) <> &h0D : Loop
  Do While gonzo.getc%(500) <> &h0D : Loop
End Sub

Function gonzo.load_inifile%(f$)
  Local mp$(map.new%(10)), num%

  If file.exists%(f$) Then
    On Error Skip 1
    Open f$ For Input As #gonzo.INI_FNBR
    If Mm.ErrMsg$ = "" Then
      gonzo.load_inifile% = inifile.read%(gonzo.INI_FNBR, mp$(), num%)
      Close #gonzo.INI_FNBR
    EndIf
    If Not gonzo.load_inifile% Then sys.err$ = "Error reading '" + f$ + "'"
  Else
    gonzo.load_inifile% = 1
  EndIf

  gonzo.comspec$ = map.get$(mp$(), "comspec")
  If gonzo.comspec$ = sys.NO_DATA$ Then gonzo.comspec$ = "/dev/ttyS0: 115200"
End Function

' Parses command line.
'
' @param       cmd_line$  command line to parse.
' @param[out]  cmd$       on exit the command.
' @param[out]  argc%      on exit the number of additional arguments.
' @param[out]  argv$()    on exit the additional arguments.
Sub gonzo.parse_cmd_line(cmd_line$, cmd$, argc%, argv$())
  Local s$ = str.trim$(cmd_line$)
  argc% = 0 : cmd$ = ""
  If s$ = "" Then Exit Sub

  cmd$ = str.next_token$(s$)

  Select Case Left$(cmd$, 1)
    Case "*"
      cmd$ = Mid$(cmd$, 2) ' Ignore leading *
    Case "!"
      argv$(argc% + Bound(argv$(), 0)) = Mid$(cmd$, 2)
      If argv$(argc% + Bound(argv$(), 0)) <> "" Then Inc argc%
      cmd$ = "!"
  End Select

  ' Read no more arguments than will fit in array and fill remainder with empty strings.
  Local i% = argc%
  For i% = argc% + Bound(argv$(), 0) To Bound(argv$(), 1)
    argv$(i%) = str.next_token$()
    If argv$(i%) = sys.NO_DATA$ Then argv$(i%) = "" Else Inc argc%
  Next
End Sub

Sub gonzo.read_until_match(pattern$)
  Local s$, x%
  Do
    ' Pass Ctrl-C onto the remote.
    If sys.break_flag% Then
      sys.break_flag% = 0
      gonzo.send_break()
    EndIf

    ' TODO: support ^]C to exit without sending a break to the remote.

    x% = gonzo.getln%(s$)
    s$ = gonzo.strip_garbage$(s$)
    If file.fnmatch%(pattern$, s$) Then Exit Do
  Loop
End Sub

' Strips leading ESC[?25h (show cursor) control sequences that the PicoMite
' uses to keep USB connection alive.
Function gonzo.strip_garbage$(s$)
  Const garbage$ = Chr$(&h1B) + "[?25h"
  Do While InStr(s$, garbage$) = 1
    s$ = Mid$(s$, Len(garbage$) + 1)
  Loop
  gonzo.strip_garbage$ = s$
End Function

' Reads input until there is a command-prompt.
Sub gonzo.read_until_prompt(flags%)
  Const CMM2_MESS$ = Chr$(&h1B) + "[?25h" + Chr$(&h1B) + "[37m" + Chr$(&h1B) + "[m"
  Local x%, s$, i%
  Do
    ' Pass Ctrl-C onto the remote.
    If sys.break_flag% Then
      sys.break_flag% = 0
      gonzo.send_break()
    EndIf

    ' TODO: support ^]C to exit without sending a break to the remote.

    x% = gonzo.getln%(s$)
    If x% Then
      If InStr(s$, CMM2_MESS$) = 1 Then s$ = Mid$(s$, Len(CMM2_MESS$) + 1)
      If s$ = "" And (flags% And SKIP_EMPTY) > 0 Then Continue Do
      If flags% And ECHO Then con.println(s$)
      If flags% And COLLECT Then LongString Append gonzo.buf%(), s$ + Chr$(&h0A)
    Else
      If Left$(gonzo.rx_buf$, 2) = "> " Then Exit Do
    EndIf
  Loop
End Sub

Function gonzo.save_inifile%(f$)
  Local mp$(map.new%(10)), num%
  map.put(mp$(), "comspec", gonzo.comspec$)

  On Error Skip 1
  Open f$ For Output As #gonzo.INI_FNBR
  If Mm.ErrMsg$ = "" Then
    gonzo.save_inifile% = inifile.write%(gonzo.INI_FNBR, mp$(), num%)
    Close #gonzo.INI_FNBR
  EndIf
  If Not gonzo.save_inifile% Then sys.err$ = "Error writing '" + f$ + "' - " + Mm.ErrMsg$
End Function

Sub gonzo.write(s$)
  If Not sys.break_flag% Then Print #gonzo.SERIAL_FNBR, s$;
End Sub

Sub gonzo.writeln(s$, eol$)
  If sys.break_flag% Then Exit Sub

  ' By default use CR '\r' as the end of line character. As strange as this may
  ' seem to a Unix developer LF '\n' or a Windows developer CRLF '\r\n' this
  ' is the default for serial comms.
  Print #gonzo.SERIAL_FNBR, s$ Choice(eol$ = "", Chr$(&h0D), eol$);
End Sub

Function gonzo.usage$(cmd$)
  Restore gonzo_commands
  Local synonyms$, usage$, description$
  Do
    Read synonyms$, usage$, description$
    ' MMBasic does not allow double-quote in DATA so we use @ signs as place-holders.
    usage$ = str.replace$(usage$, "@", Chr$(34))
    If synonyms$ = "<END>" Then Error "No usage information for: " + cmd$
    If InStr(synonyms$, "|" + LCase$(cmd$) + "|") Then
      gonzo.usage$ = "Usage: " + cmd$
      If usage$ <> "" Then Cat gonzo.usage$, " " + usage$
      Exit Do
    EndIf
  Loop
End Function

Function gonzo.check_arg_count%(cmd$, argc%, expected%)
  gonzo.check_arg_count% = gonzo.check_arg_range%(cmd$, argc%, expected%, expected%)
End Function

Function gonzo.check_arg_max%(cmd$, argc%, maximum%)
  gonzo.check_arg_max% = gonzo.check_arg_range%(cmd$, argc%, 0, maximum%)
End Function

Function gonzo.check_arg_min%(cmd$, argc%, minimum%)
  gonzo.check_arg_max% = gonzo.check_arg_range%(cmd$, argc%, minimum%, 100)
End Function

Function gonzo.check_arg_range%(cmd$, argc%, minimum%, maximum%)
  If argc% >= minimum% And argc% <= maximum% Then
    gonzo.check_arg_range% = 1
  Else
    sys.err$ = gonzo.usage$(cmd$)
  EndIf
End Function

Function gonzo.check_file_exists%(local_file$)
  If file.exists%(local_file$) Then
    gonzo.check_file_exists% = 1
  Else
    sys.err$ = "Error: file not found"
  EndIf
End Function

gonzo_commands:
Data "|!|",                 "<index>",               "repeats a previous command from the history"
Data "|break|",             "",                      "send a Ctrl-C to remote"
Data "|chdir|cd|",          "<directory>",           "change local directory"
Data "|cls|",               "",                      "clear local terminal"
Data "|connect|",           "",                      "connect to remote"
Data "|device|",            "",                      "report type of remote device"
Data "|exit|quit|",         "",                      "exit the gonzo shell"
Data "|files|dir|ls|",      "[<file|directory>]",    "list local directory contents"
Data "|help|",              "[<command>]",           "display help text"
Data "|history|",           "",                      "display history of recent commands"
Data "|log|",               "[clear]",               "show (or clear) receive log"
Data "|pwd|",               "",                      "display current local directory"
Data "|rchdir|rcd|",        "<directory>",           "change remote directory"
Data "|rcls|",              "",                      "clear remote terminal"
Data "|rename|mv|",         "<src-file> <dst-file>", "rename local file or directory"
Data "|rexec|rex|",         "<command string>",      "execute command on remote"
Data "|rcopy|rcp|",         "<src-file> <dst-file>", "copy remote file"
Data "|rdelete|rkill|rrm|", "<file|directory>",      "delete remote file or (empty) directory"
Data "|receive|get|",       "<src-file> [<dst-file>]", "receive file from remote using AUTOSAVE"
Data "|rfiles|rdir|rls|",   "[<file|directory>]",    "list remote directory contents"
Data "|rmkdir|",            "<directory>",           "make directory on remote"
Data "|rpwd|",              "",                      "display current remote directory"
Data "|rrename|rmv|",       "<src-file> <dst-file>", "rename remote file or directory"
Data "|rsize|",             "<file>",                "display size of remote file"
Data "|rtest|",             "[--no-crunch] [<file>]", "execute unit-tests on remote"
Data "|rtype|rcat|rlist|",  "<file>",                "list remote file contents"
Data "|send|put|",          "[OPTION]... <src-file> [<dst-file>]", "send file to remote using AUTOSAVE"
Data "|take|",              "<file>",                "read and execute gonzo commands from file"
Data "|term|",              "",                      "open serial terminal"
Data "|trans|sptrans|",     "[OPTION]... <src-file> [<dst-file>]", "transpile local file"
Data "|type|cat|list|",     "<file>",                "list local file contents"
Data "|version|",           "",                      "display current gonzo version"
Data "|xreceive|xget|",     "<src-file> [<dst-file>]", "receive file from remote using XMODEM"
Data "|xsend|xput|",        "[OPTION]... <src-file> [<dst-file>]", "send file from to remote using XMODEM"
Data "<END>", "", ""

Sub dump(s$)
  Local i%
  For i% = 1 To Len(s$)
    con.print(Hex$(Asc(Mid$(s$, i%, 1)), 2) + " ")
  Next
End Sub

device_name_data:

Data "/dev/ttyS0",   "/dev/ttyS1"
Data "/dev/ttyACM0", "/dev/ttyACM1", "/dev/ttyACM2"
Data "/dev/ttyUSB0"
Data ""

baud_rate_data:

Data "9600", "19200", "28800", "38400", "57600", "76800"
Data "115200", "230400", "460800", "576000", "921600", ""
