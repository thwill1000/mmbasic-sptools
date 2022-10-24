' Copyright (c) 2021-2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 2022.01.00

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("array")
sys.provides("console")
If sys.err$ <> "" Then Error sys.err$

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

' Clears the command history.
'
' @param  h%()  buffer containing the command history.
Sub con.history_clear(h%())
  ' TODO: strictly speaking it should be sufficient to write &h00 to the first byte.
  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Memory Set h_addr%, &h00, h_size%
End Sub

' Gets the number of elements in the command history.
'
' @param  h%()  buffer containing the command history.
' @return       the number of elements.
Function con.history_count%(h%())
  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Local slen%, p% = h_addr% + 2
  Do
    slen% = Peek(Byte p%)
    If slen% = 0 Then Exit Do ' End of history.
    Inc p%, slen% + 1
    If p% >= h_addr% + h_size% Then Exit Do ' Incomplete element, end of history.
    Inc con.history_count%
  Loop
End Function

' Gets a string element from the command history.
'
' @param  h%()  buffer containing the command history.
' @param  idx%  index of the element to retrieve, the first element is always
'               idx% = 0 irrespective of OPTION BASE.
' @return       string element, or empty string if idx% >= number of elements.
Function con.history_get$(h%(), idx%)
  If idx% < 0 Then Error "index out of bounds: " + Str$(idx%)

  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Local i%, p% = h_addr% + 2
  For i% = 0 To idx%
    If Peek(Byte p%) = 0 Then Exit Function ' Return empty string.
    If i% < idx% Then Inc p%, Peek(Byte p%) + 1
  Next
  If p% + Peek(Byte p%) < h_addr% + h_size% Then
    Memory Copy p%, Peek(VarAddr con.history_get$), Peek(Byte p%) + 1
  EndIf
End Function

' Fills the command history from an array of elements.
'
' @param  h%()         buffer containing the command history.
' @param  elements$()  the elements. The first element in this array
'                      will become the newest element in the history.
Sub con.history_fill(h%(), elements$())
  con.history_clear(h%())
  Local i%
  For i% = Bound(elements$(), 1) To Bound(elements$(), 0) Step -1
    con.history_put(h%(), elements$(i%))
  Next
End Sub

' Finds the index of an element in the command history.
'
' @param  h%()     buffer containing the command history.
' @param  needle$  element to find.
' @return          index of the element, or -1 if not found.
Function con.history_find%(h%(), needle$)
  If needle$ = "" Then Error "invalid argument: needle$"

  ' TODO: could be faster by not calling con.history_get()
  Local i% = -1, s$
  Do
    Inc i%
    s$ = con.history_get$(h%(), i%)
  Loop Until s$ = "" Or s$ = needle$

  con.history_find% = Choice(s$ = "", -1, i%)
End Function

' Reads the command history from a file.
'
' @param  h%()       buffer containing the command history.
' @param  filename$  the file to read from.
' @param  fnbr%      the file number to use.
Sub con.history_load(h%(), filename$, fnbr%)
  con.history_clear(h%())
  Open filename$ For Input As #fnbr%
  Local count%, s$
  Do While Not Eof(#fnbr%)
    Line Input #fnbr%, s$
    con.history_put(h%(), s$)
    Inc count%
  Loop
  Close #fnbr%

  ' This will prevent the history file from growing in an unbound manner.
  If count% > 200 Then con.history_save(h%(), filename$, fnbr%)
End Sub

' Gets the id of the newest in the command history buffer,
' for use with the ! command.
'
' @param  h%()  buffer containing the command history.
' @return       the id of element 0, or 0 if the history is empty.
Function con.history_newest%(h%())
  Local h_addr% = Peek(VarAddr h%())
  con.history_newest% = Peek(Short h_addr%)
End Function

' Gets and removes the newest element from the command history.
' Note the history file is not adjusted accordingly.
'
' TODO: Currently unused, consider removing.
'
' @param  h%()  buffer containing the command history.
Function con.history_pop$(h%())
  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Local sz% = Peek(Byte h_addr% + 2)
  If sz% > 0 Then
    Memory Copy h_addr% + 2, Peek(VarAddr con.history_pop$), sz% + 1
    Memory Copy h_addr% + sz% + 3, h_addr% + 2, h_size% - sz% - 3
    Poke Short h_addr%, Peek(Short h_addr%) - 1
  EndIf
End Function

' Adds an element to the command history. The new element will appear at
' index 0 and the remaining elements will all be shifted one space.
' Optionally a history file is updated with the new element.
'
' @param  h%()       buffer containing the command history.
' @param  cmd$       the element.
' @param  filename$  the history file to update, this is optional.
' @param  fnbr%      the file number to use, this is optional.
Sub con.history_put(h%(), cmd$, filename$, fnbr%)
  Local s$ = str.trim$(cmd$)
  If s$ = "" Then Exit Sub
  If s$ = con.history_get$(h%(), 0) Then Exit Sub ' Don't insert duplicate entry.
  If Left$(s$, 1) = "!" Then Exit Sub ' Don't insert elements beginning !

  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  ' Update first 2 bytes which contain id of the newest element.
  Poke Short h_addr%, Peek(Short h_addr%) + 1
  ' Shift existing elements right by length + 1 of new element.
  If Peek(Byte h_addr% + 2) > 0 Then
    Memory Copy h_addr% + 2, h_addr% + 3 + Len(s$), h_size% - 3 - Len(s$)
  EndIf
  ' Copy new element into the buffer.
  Memory Copy Peek(VarAddr s$), h_addr% + 2, Len(s$) + 1

  ' Append to history file.
  If filename$ <> "" Then
    Open filename$ For Append As #fnbr%
    Print #fnbr%, s$
    Close #fnbr%
  EndIf
End Sub

' Writes the command history to a file.
'
' @param  h%()       buffer containing the command history.
' @param  filename$  the file to write to.
' @param  fnbr%      the file number to use.
Sub con.history_save(h%(), filename$, fnbr%)
  Open filename$ For Output As #fnbr%
  Local i%, s$
  For i% = con.history_count%(h%()) - 1 To 0 Step -1
    s$ = con.history_get$(h%(), i%)
    Print #fnbr%, s$
  Next
  Close #fnbr%
End Sub

' Trims the size of the command history.
'
' TODO: Currently unused, consider removing.
'
' @param  h%()    buffer containing the command history.
' @param  count%  number of elements to trim the command history to.
Sub con.history_trim(h%(), count%)
  If count% < 0 Then Error "invalid argument: count%"

  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Local i%, slen%, p% = h_addr% + 2
  Do While i% < count%
    slen% = Peek(Byte p%)
    If slen% = 0 Then Exit Do ' End of history.
    Inc p%, slen% + 1
    If p% >= h_addr% + h_size% Then Exit Do ' Incomplete element, end of history.
    Inc i%
  Loop

  Poke Byte p%, &h00
End Sub

' Read a line of text from the console supporting basic line editing controls.
'
' @param  initial$           initial text, may be empty.
' @param  history%()         buffer containing the command history.
' @param  history_filename$  optional file to write updated command history to.
' @param  history_fnbr%      optional file number to use.
' @return                    the line of text read.
Function con.readln$(initial$, history%(), history_filename$, history_fnbr%)
  Local ch$, hidx%, p%, old$, overwrite%, s$

  con.readln$ = initial$
  p% = Len(initial$) + 1
  Print initial$;
  hidx% = Choice(initial$ = "", -1, con.history_find%(history%(), initial$))

  Do While Not sys.break_flag%
    ch$ = Inkey$
    If ch$ = "" Then Pause 1 : Continue Do

    Select Case Asc(ch$)
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

      Case 10, 13 ' Enter
        Print
        If con.readln$ <> "" Then
          con.history_put(history%(), con.readln$, history_filename$, history_fnbr%)
        EndIf
        Exit Do

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
        Inc hidx%, Choice(Asc(ch$) = 128, 1, -1)
        If hidx% <= -1 Then
          hidx% = -1
          s$ = old$
        Else
          s$ = con.history_get$(history%(), hidx%)
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
        ' Print "<" Str$(Asc(ch$)) ">";
        con.bell()

      Case Else
        If Len(con.readln$) = 255 Then
          con.bell()
        ElseIf p% > Len(con.readln$) Then
          Cat con.readln$, ch$
          Print ch$;
          Inc p%
        ElseIf overwrite% Then
          con.readln$ = Left$(con.readln$, p% - 1) + ch$ + Mid$(con.readln$, p% + 1)
          Print ch$;
          Inc p%
        Else
          s$ = Mid$(con.readln$, p%)
          con.readln$ = Left$(con.readln$, p% - 1) + ch$ + s$
          Print ch$ s$ String$(Len(s$), &h08);
          Inc p%
        EndIf
    End Select
  Loop

  If sys.break_flag% Then con.readln$ = ""
End Function
