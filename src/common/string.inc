' Copyright (c) 2019-20 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.provides("string")
If sys.err$ <> "" Then Error sys.err$

Function str.centre$(s$, x%)
  If Len(s$) < x% Then
    str.centre$ = Space$((x% - Len(s$)) \ 2) + s$
    str.centre$ = str.centre$ + Space$(x% - Len(str.centre$))
  Else
    str.centre$ = s$
  EndIf
End Function

Function str.join$(a$(), ch$, lb_%, num%)
  Local lb% = Choice(lb_% = 0, Bound(a$(), 0), lb_%)
  Local ub% = Choice(num% = 0, Bound(a$(), 1), lb% + num% - 1)
  Local i%
  For i% = lb% To ub%
    If i% > lb% Then Cat str.join$, ch$
    Cat str.join$, a$(i%)
  Next
End Function

Function str.lpad$(s$, x%)
  str.lpad$ = s$
  If Len(s$) < x% Then str.lpad$ = Space$(x% - Len(s$)) + s$
End Function

' Tokenises a string.
'
' @param   s$     string to tokenise.
' @param   sep$   one or more token separator characters.
'                 If empty then use space and skip empty tokens.
' @param   skip%  1 to skip empty tokens, 0 to return them.
' @return  the first token. To retrieve subsequent tokens call this function
'          with no parameters, i.e. tk$ = str.next_token$().
'          Returns sys.NO_DATA$ if there are no more tokens.
Function str.next_token$(s_$, sep_$, skip_%)
  Static s$, sep$, skip%, st%

  If s_$ = "" Then
    If sep_$ <> "" Then
      ' Special case of the first call to next_token$() on the empty string.
      If Not skip_% Then Exit Function
    EndIf
  Else
    s$ = s_$
    st% = 1
    If sep_$ = "" Then
      ' If no separator specified then use space and skip empty tokens.
      sep$ = " " : skip% = 1
    Else
      sep$ = sep_$ : skip% = skip_%
    EndIf
  EndIf

  ' Have we already processed then entire string?
  If st% > Len(s$) + 1 Then str.next_token$ = sys.NO_DATA$ : Exit Function

  Local i%
  For i% = st% To Len(s$)
    If InStr(sep$, Mid$(s$, i%, 1)) > 0 Then
      str.next_token$ = Mid$(s$, st%, i% - st%)
      st% = i% + 1
      If skip% And str.next_token$ = "" Then Continue For
      Exit Function
    EndIf
  Next

  ' Return the last token.
  str.next_token$ = Mid$(s$, st%, i% - st%)
  If str.next_token$ = "" And skip% Then str.next_token$ = sys.NO_DATA$
  st% = Len(s$) + 2
End Function

Function str.rpad$(s$, x%)
  str.rpad$ = s$
  If Len(s$) < x% Then str.rpad$ = s$ + Space$(x% - Len(s$))
End Function
