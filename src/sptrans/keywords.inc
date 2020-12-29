' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("map")
sys.provides("keywords")
If sys.err$ <> "" Then Error sys.err$

Dim keywords$(map.new%(1000)) Length 20
map.init(keywords$())

Sub keywords.load(f$)
  Open f$ For Input As #1

  Local s$
  Do
    Line Input #1, s$
    If Len(s$) > 0 And Left$(s$, 1) <> "'" Then
      map.put(keywords$(), LCase$(s$), s$)
    EndIf
  Loop While Not Eof(#1)

  Close #1
End Sub

Function keywords.contains(s$)
  keywords.contains = map.get$(keywords$(), LCase$(s$)) <> sys.NO_DATA$
End Function

Function keywords.get$(s$)
  keywords.get$ = map.get$(keywords$(), LCase$(s$))
End Function

