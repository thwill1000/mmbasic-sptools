' Copyright (c) 2021-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 0.6.0

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("history")
sys.provides("console")
If sys.err$ <> "" Then Error sys.err$

Dim con.fnbr_in% = 0 ' File number to read input from.

' Sounds the console bell.
Sub con.bell()
  Console Bell
End Sub

' Clears the console.
Sub con.cls()
  Cls
End Sub

' Moves cursor to the beginning of the previous line.
Sub con.cursor_previous()
  Print Chr$(27) "[F";
End Sub

' Writes an error string to the console followed by a newline.
'
' @param  s$  the string to write.
Sub con.errorln(s$)
  Print s$
End Sub

' Sets the console foreground colour.
'
' @param  fg$  new foreground colour.
Sub con.foreground(fg$)
  Select Case LCase$(fg$)
    Case "black"   : ? Chr$(27) "[30m";
    Case "red"     : ? Chr$(27) "[31m";
    Case "green"   : ? Chr$(27) "[32m";
    Case "yellow"  : ? Chr$(27) "[33m";
    Case "blue"    : ? Chr$(27) "[34m";
    Case "magenta", "purple" : ? Chr$(27) "[35m";
    Case "cyan"    : ? Chr$(27) "[36m";
    Case "white"   : ? Chr$(27) "[37m";
    Case "default", "reset" : ? Chr$(27) "[0m";
    Case "bright blue"      : ? Chr$(27) "[94m";
    Case Else      : Error : "Unknown ANSI colour: " + fg$
  End Select
End Sub

Sub con.open_in(fnbr%, f$)
  con.close_in()
  Open f$ For Input As #fnbr%
  con.fnbr_in% = fnbr%
End Sub

Sub con.close_in()
  If con.fnbr_in% Then Close #con.fnbr_in%
  con.fnbr_in% = 0
End Sub

' Reads a character from the keyboard or script file.
' @return  ASCII code of read character, or -1 if no character available.
Function con.getc%()
  Local ch$ = Input$(1, #con.fnbr_in%)
  If Not Len(ch$) Then
    If con.fnbr_in% Then
      con.close_in()
      ch$ = Input$(1, 0)
    EndIf
  EndIf
  con.getc% = Choice(Len(ch$), Asc(ch$), -1)
End Function

' Writes an string to the console without a newline.
'
' @param  s$  the string to write.
Sub con.print(s$)
  Print s$;
End Sub

' Writes a string to the console followed by a newline.
'
' @param  s$  the string to write.
Sub con.println(s$)
  Print s$
End Sub

' Read a line of text from the console supporting basic line editing controls.
'
' @param  initial$           initial text, may be empty.
' @param  history%()         buffer containing the command history.
' @param  history_filename$  optional file to write updated command history to.
' @param  history_fnbr%      optional file number to use.
' @return                    the line of text read.
Function con.readln$(initial$, history%(), history_filename$, history_fnbr%)
  Local ch%, hidx%, p%, old$, overwrite%, s$

  con.readln$ = initial$
  p% = Len(initial$) + 1
  Print initial$;
  hidx% = Choice(initial$ = "", -1, history.find%(history%(), initial$))

  Do While Not sys.break_flag%
    ch% = con.getc%()

    Select Case ch%
      Case -1
        Continue Do

      Case 8 ' Backspace
        If p% = 1 Then
          con.bell()
        Else
          ' Delete the character immediately to the left.
          s$ = Mid$(con.readln$, p%)
          con.readln$ = Left$(con.readln$, p% - 2) + s$
          Print Chr$(&h08) s$ " " String$(Len(s$) + 1, &h08);
          Inc p%, -1
        EndIf

      Case 10 ' \n: Line Feed
        Print
        ' Don't add empty lines, or lines read from a script to the history.
        If con.readln$ <> "" And con.fnbr_in% = 0 Then
          history.push(history%(), con.readln$, history_filename$, history_fnbr%)
        EndIf
        Exit Do

      Case 13 ' \r: Carriage Return
        ' Do nothing.

      Case 127 ' Delete
        If p% = Len(con.readln$) + 1 Then
          con.bell()
        Else
          ' Delete the current character.
          s$ = Mid$(con.readln$, p% + 1)
          con.readln$ = Left$(con.readln$, p% - 1) + s$
          Print s$ " " String$(Len(s$) + 1, &h08);
        EndIf

      Case 128, 129 ' Up, Down
        If hidx% = -1 Then old$ = con.readln$
        Inc hidx%, Choice(ch% = 128, 1, -1)
        If hidx% <= -1 Then
          hidx% = -1
          s$ = old$
        Else
          s$ = history.get$(history%(), hidx%)
          If s$ = "" Then s$ = con.readln$ : Inc hidx%, -1
        EndIf

        Print String$(p% - 1, &h08) String$(p% - 1, " ") String$(p% - 1, &h08) s$;
        con.readln$ = s$
        p% = Len(s$) + 1

      Case 130 ' Left
        If p% > 1 Then
          Inc p%, -1
          Print Chr$(27) "[D";
        EndIf

      Case 131 ' Right
        If p% <= Len(con.readln$) Then
          Inc p%, 1
          Print Chr$(27) "[C";
        EndIf

      Case 132 ' Insert
        overwrite% = Not overwrite%

      Case 134 ' Home
        Print String$(p% - 1, &h08);
        p% = 1

      Case 135 ' End
        Do While p% <= Len(con.readln$)
          Print Chr$(27) "[C";
          Inc p%
        Loop

      Case < 32, > 126
        ' Print "<" Str$(ch%) ">";
        con.bell()

      Case Else
        If Len(con.readln$) = 255 Then
          con.bell()
        ElseIf p% > Len(con.readln$) Then
          Cat con.readln$, Chr$(ch%)
          Print Chr$(ch%);
          Inc p%
        ElseIf overwrite% Then
          con.readln$ = Left$(con.readln$, p% - 1) + Chr$(ch%) + Mid$(con.readln$, p% + 1)
          Print Chr$(ch%);
          Inc p%
        Else
          s$ = Mid$(con.readln$, p%)
          con.readln$ = Left$(con.readln$, p% - 1) + Chr$(ch%) + s$
          Print Chr$(ch%) s$ String$(Len(s$), &h08);
          Inc p%
        EndIf
    End Select
  Loop

  If sys.break_flag% Then con.readln$ = ""
End Function
