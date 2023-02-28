' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.07

Option Base 0
Option Default None
Option Explicit

#Include "../splib/system.inc"
#Include "../splib/array.inc"
#Include "../splib/file.inc"
#Include "../splib/map.inc"
#Include "../splib/string.inc"
#Include "../common/sptools.inc"

Const KEYWORDS_INC$ = spt.INSTALL_DIR$ + "/src/sptrans/keywords.inc"
Const KEYWORDS_TXT$ = spt.RESOURCES_DIR$ + "/keywords.txt"

Const IN_FNBR% = 1
Const OUT_FNBR% = 2
Const TXT_FNBR% = 3

Dim line_in$, line_out$

' Pre-process 'keywords.txt' to determine metrics.
Dim num_keywords%, max_keyword_len%
Open KEYWORDS_TXT$ For Input As TXT_FNBR%
Do
  Line Input #TXT_FNBR%, line_in$
  If Len(line_in$) > 0 And Left$(line_in$, 1) <> "'" Then
    Inc num_keywords%
    max_keyword_len% = Max(max_keyword_len%, Len(line_in$))
    EndIf
  EndIf
Loop While Not Eof(TXT_FNBR%)
Close TXT_FNBR%

' Copy input to output until reach DATA section.
Open KEYWORDS_INC$ + ".tmp" For Output As OUT_FNBR%
Open KEYWORDS_INC$ For Input As IN_FNBR%
Do
  Line Input #IN_FNBR%, line_in$
  Print #OUT_FNBR%, line_in$
Loop While Left$(line_in$, 14) <> "keywords.data:"

' Replace DATA section with keywords read from text file.
Open KEYWORDS_TXT$ For Input As TXT_FNBR%
Print #OUT_FNBR%, "Data " Str$(num_keywords%) ", " Str$(max_keyword_len%)
Do
  Line Input #TXT_FNBR%, line_in$
  If Len(line_in$) > 0 And Left$(line_in$, 1) <> "'" Then
    If Len(line_out$) = 0 Then
      line_out$ = "Data " + str.quote$(line_in$)
    Else If Len(line_out$ + "," + str.quote$(line_in$)) > 80 Then
      Print #OUT_FNBR%, line_out$
      line_out$ = "Data " + str.quote$(line_in$)
    Else
      Cat line_out$, "," + str.quote$(line_in$)
    EndIf
  EndIf
Loop While Not Eof(TXT_FNBR%)
Print #OUT_FNBR%, line_out$

Close OUT_FNBR%
Close IN_FNBR%
Close TXT_FNBR%

' Copy over original 'keywords.inc' file.
Copy KEYWORDS_INC$ + ".tmp" To KEYWORDS_INC$

End
