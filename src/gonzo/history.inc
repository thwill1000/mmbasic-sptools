' Copyright (c) 2021-2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 2022.01.00

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.provides("history")
If sys.err$ <> "" Then Error sys.err$

' The format of the command history buffer, h%() :
'   2  bytes - id of the newest command in the buffer, aka the 0th element
'   1  byte  - n0, length of command 0
'   n0 bytes - characters for command 0
'   1  byte  - n1, length of command 1
'   n1 bytes - characters for command 1
'   ...
'
' New commands are pushed to the front of the buffer and old ones are shifted
' right. If a command even partially shifts out of the buffer then it is lost,
' history.get$() will not retrieve partial commands.

' Clears the command history.
'
' @param  h%()  buffer containing the command history.
Sub history.clear(h%())
  ' TODO: strictly speaking it should be sufficient to write &h00 to the first byte.
  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Memory Set h_addr%, &h00, h_size%
End Sub

' Gets the number of elements in the command history.
'
' @param  h%()  buffer containing the command history.
' @return       the number of elements.
Function history.count%(h%())
  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Local slen%, p% = h_addr% + 2
  Do
    slen% = Peek(Byte p%)
    If slen% = 0 Then Exit Do ' End of history.
    Inc p%, slen% + 1
    If p% >= h_addr% + h_size% Then Exit Do ' Incomplete element, end of history.
    Inc history.count%
  Loop
End Function

' Gets a string element from the command history.
'
' @param  h%()  buffer containing the command history.
' @param  idx%  index of the element to retrieve, the first element is always
'               idx% = 0 irrespective of OPTION BASE.
' @return       string element, or empty string if idx% >= number of elements.
Function history.get$(h%(), idx%)
  If idx% < 0 Then Error "index out of bounds: " + Str$(idx%)

  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Local i%, p% = h_addr% + 2
  For i% = 0 To idx%
    If Peek(Byte p%) = 0 Then Exit Function ' Return empty string.
    If i% < idx% Then Inc p%, Peek(Byte p%) + 1
  Next
  If p% + Peek(Byte p%) < h_addr% + h_size% Then
    Memory Copy p%, Peek(VarAddr history.get$), Peek(Byte p%) + 1
  EndIf
End Function

' Fills the command history from an array of elements.
'
' @param  h%()         buffer containing the command history.
' @param  elements$()  the elements. The first element in this array
'                      will become the newest element in the history.
Sub history.fill(h%(), elements$())
  history.clear(h%())
  Local i%
  For i% = Bound(elements$(), 1) To Bound(elements$(), 0) Step -1
    history.push(h%(), elements$(i%))
  Next
End Sub

' Finds the index of an element in the command history.
'
' @param  h%()     buffer containing the command history.
' @param  needle$  element to find.
' @return          index of the element, or -1 if not found.
Function history.find%(h%(), needle$)
  If needle$ = "" Then Error "invalid argument: needle$"

  ' TODO: could be faster by not calling history.get()
  Local i% = -1, s$
  Do
    Inc i%
    s$ = history.get$(h%(), i%)
  Loop Until s$ = "" Or s$ = needle$

  history.find% = Choice(s$ = "", -1, i%)
End Function

' Reads the command history from a file.
'
' @param  h%()       buffer containing the command history.
' @param  filename$  the file to read from.
' @param  fnbr%      the file number to use.
Sub history.load(h%(), filename$, fnbr%)
  history.clear(h%())
  Open filename$ For Input As #fnbr%
  Local count%, s$
  Do While Not Eof(#fnbr%)
    Line Input #fnbr%, s$
    history.push(h%(), s$)
    Inc count%
  Loop
  Close #fnbr%

  ' This will prevent the history file from growing in an unbound manner.
  If count% > 200 Then history.save(h%(), filename$, fnbr%)
End Sub

' Gets the id of the newest in the command history buffer,
' for use with the ! command.
'
' @param  h%()  buffer containing the command history.
' @return       the id of element 0, or 0 if the history is empty.
Function history.newest%(h%())
  Local h_addr% = Peek(VarAddr h%())
  history.newest% = Peek(Short h_addr%)
End Function

' Gets and removes the newest element from the command history.
' Note the history file is not adjusted accordingly.
'
' TODO: Currently unused, consider removing.
'
' @param  h%()  buffer containing the command history.
Function history.pop$(h%())
  Local h_addr% = Peek(VarAddr h%())
  Local h_size% = (Bound(h%(), 1) - Bound(h%(), 0) + 1) * 8
  Local sz% = Peek(Byte h_addr% + 2)
  If sz% > 0 Then
    Memory Copy h_addr% + 2, Peek(VarAddr history.pop$), sz% + 1
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
Sub history.push(h%(), cmd$, filename$, fnbr%)
  Local s$ = str.trim$(cmd$)
  If s$ = "" Then Exit Sub
  If s$ = history.get$(h%(), 0) Then Exit Sub ' Don't insert duplicate entry.
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
Sub history.save(h%(), filename$, fnbr%)
  Open filename$ For Output As #fnbr%
  Local i%, s$
  For i% = history.count%(h%()) - 1 To 0 Step -1
    s$ = history.get$(h%(), i%)
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
Sub history.trim(h%(), count%)
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
