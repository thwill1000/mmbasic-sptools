' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("map2")
sys.provides("symbols")
If sys.err$ <> "" Then Error sys.err$
'!endif

Const sym.MAX_FILES% = 32
Const sym.MAX_FUNCTIONS% = 256
Const sym.MAX_NAMES% = 4096
Const sym.MAX_NAME_LEN% = 33
Const sym.MAX_PATH_LEN% = 128
Const sym.MAX_REFERENCES = 255
Const sym.REFERENCES_SIZE_KB% = 32

' Files table/map data:
'   K is case-sensitive file path
'   V is "<file index>"
Dim sym.files$(map2.new%(sym.MAX_FILES%)) Length sym.MAX_PATH_LEN% + 8

' Functions table/map data:
'   K is lower-case function name
'   V is "<function name>,<file index>,<line number>,<reference offset>,<name id>"
Dim sym.functions$(map2.new%(sym.MAX_FUNCTIONS%)) Length 80

' Names table/map data:
'   K is lower-case name
'   V is a unique id; integer >= 0
Dim sym.names$(map2.new%(sym.MAX_NAMES%)) Length sym.MAX_NAME_LEN% + 8

' References table data:
'   Entries are unsigned 32-bit integers
'   Each entry is a "name id"
'   &hFFFFFFFF delimits the end of the references data for a function
Dim sym.references%(array.new%(sym.REFERENCES_SIZE_KB% * 1024 \ 8))
Const sym.P_REF_BASE% = Peek(VarAddr sym.references%())
Const sym.P_REF_LIMIT% = sym.P_REF_BASE + sym.REFERENCES_SIZE_KB% * 1024 - 4

' Offset of start of entries for the CURRENT function in the 'References' table.
Dim sym.ref_offset%

' Offset to the 4-bit element after the last entry in the 'Reference' table.
Dim sym.ref_end%

Sub sym.init(max_functions%, max_names%, references_size_kb%)
  If max_functions% > 0 Then
    Erase sym.MAX_FUNCTIONS%
    Erase sym.functions$()
    Dim sym.MAX_FUNCTIONS% = max_functions%
    Dim sym.functions$(map2.new%(sym.MAX_FUNCTIONS%)) Length 80
  EndIf

  If max_names% > 0 Then
    Erase sym.MAX_NAMES%
    Erase sym.names$()
    Dim sym.MAX_NAMES% = max_names%
    Dim sym.names$(map2.new%(sym.MAX_NAMES%)) Length sym.MAX_NAME_LEN% + 8
  EndIf

  If references_size_kb% > 0 Then
    Erase sym.REFERENCES_SIZE_KB%
    Erase sym.references$
    Erase sym.P_REF_BASE%
    Erase sym.P_REF_LIMIT%
    Dim sym.REFERENCES_SIZE_KB% = references_size_kb%
    Dim sym.references%(array.new%(sym.REFERENCES_SIZE_KB% * 1024 \ 8))
    Dim sym.P_REF_BASE% = Peek(VarAddr sym.references%())
    Dim sym.P_REF_LIMIT% = sym.P_REF_BASE% + sym.REFERENCES_SIZE_KB% * 1024 - 4
  EndIf

  map2.init(sym.files$(), sym.MAX_PATH_LEN%)
  map2.init(sym.functions$(), sym.MAX_NAME_LEN%)
  map2.init(sym.names$(), sym.MAX_NAME_LEN%)
  ' WARNING! I won't be surprised if this is overrunning.
  Memory Set sym.P_REF_BASE%, &hFF, sym.REFERENCES_SIZE_KB% * 1024
  sym.ref_offset% = 0
  sym.ref_end% = 0
End Sub

' Adds a file to the 'Files' table.
'
'  - The same file$ may be aded multiple times,
'    subsequent calls just return the reference to the existing table entry.
'
' @param  file$  the file path.
' @return        sys.FAILURE on error, otherwise
'                'file index' for the new or existing table entry.
Function sym.add_file%(file$)
  If map2.is_full%(sym.files$()) Then
    Local msg$ = "Too many files, max " + Str$(sym.MAX_FILES%)
    sym.add_file% = sys.error%(sys.FAILURE, msg$)
    Exit Function
  EndIf

  If Len(file$) > sym.MAX_PATH_LEN% Then
    Local msg$ = "Path too long, max " + Str$(sym.MAX_PATH_LEN%) + " characters"
    sym.add_file% = sys.error%(sys.FAILURE, msg$)
    Exit Function
  EndIf

  Const sz% = map2.size%(sym.files$())
  sym.add_file% = Val(map2.put_if_absent$(sym.files$(), file$, Str$(sz%)))
End Function

' Adds a function (or subroutine) to the 'Functions' table.
'
'  - Also adds the fn_name$ to the 'Names' table and the file$ to the 'files'
'    table.
'  - Until the next call to add_function%() any calls to
'    add_reference%() will be adding references from this function.
'
' @param  fn_name$  function name including type suffix.
' @param  file$     the path to the file containing the function.
' @param  line%     the line on which the function starts in file$.
' @return           sys.FAILURE on error, otherwise "name id" for the function.
Function sym.add_function%(fn_name$, file$, line%)
  If map2.is_full%(sym.functions$()) Then
    Local msg$ = "Too many FUNCTION/SUBs, max " + Str$(sym.MAX_FUNCTIONS%)
    sym.add_function% = sys.error%(sys.FAILURE, msg$)
    Exit Function
  EndIf

  sym.add_function% = sym.add_name%(fn_name$)
  If sym.add_function% < 0 Then Exit Function

  Const file_ref% = sym.add_file%(file$)
  If file_ref% < 0 Then sym.add_function% = file_ref% : Exit Function

  Local v$ = map2.get$(sym.functions$(), LCase$(fn_name$))
  If v$ <> sys.NO_DATA$ Then
    sym.add_function% = sys.error%(sys.FAILURE, "Duplicate FUNCTION/SUB")
    Exit Function
  EndIf

  If map2.size%(sym.functions$()) > 0 Then
    If sym.P_REF_BASE% + sym.ref_end% + 4 > sym.P_REF_LIMIT% Then
      sym.add_function% = sys.error%(sys.FAILURE, "Too many references")
      Exit Function
    EndIf
    Inc sym.ref_end%, 4 ' To leave a &hFFFFFFFF delimiter
    sym.ref_offset% = sym.ref_end%
  EndIf

  v$ = fn_name$ + "," + Str$(file_ref%) + "," + Str$(line%) + ","
  Cat v$, Str$(sym.ref_offset%) + "," + Str$(sym.add_function%)
  map2.put(sym.functions$(), LCase$(fn_name$), v$)
End Function

' Adds a name to the 'Names' table.
'
'  - The same name may be added multiple times,
'    subsequent calls just return the "name id" of the existing table entry.
'
' @param  name$  the name.
' @return        sys.FAILURE on error, otherwise
'                "name id" for the new or existing table entry.
Function sym.add_name%(name$)
  If map2.is_full%(sym.names$()) Then
    Local msg$ = "Too many names, max " + Str$(sym.MAX_NAMES%)
    sym.add_name% = sys.error%(sys.FAILURE, msg$)
    Exit Function
  EndIf

  ' Ignore # prefix.
  Local name_$ = Choice(Left$(name$, 1) = "#", Mid$(name$, 2), name$)

  If Len(name_$) > sym.MAX_NAME_LEN% Then
    Local msg$ = "Name too long, max " + Str$(sym.MAX_NAME_LEN%) + " characters"
    sym.add_name% = sys.error%(sys.FAILURE, msg$)
    Exit Function
  EndIf

  Const sz% = map2.size%(sym.names$())
  sym.add_name% = Val(map2.put_if_absent$(sym.names$(), LCase$(name_$), Str$(sz%)))
End Function

' Adds an entry to the 'References' table for the last added function.
'
'  - Also adds the name to the 'Names' table.
'  - Adding multiple references to the same name is a no-op.
'
' @param  name$  the name to add a reference to.
' @return        sys.FAILURE on error, otherwise the "name id".
Function sym.add_reference%(name$)
  sym.add_reference% = sym.add_name%(name$)
  If sym.add_reference% < 0 Then Exit Function

  Local p%
  For p% = sym.P_REF_BASE% + sym.ref_offset% To sym.P_REF_LIMIT% Step 4
    Select Case Peek(Word p%)
      Case &hFFFFFFFF : Exit For
      Case sym.add_reference% : Exit Function ' Already present.
      Case >= &hFF000000
        p% = sym.P_REF_BASE% + (Peek(Word p%) And &h00FFFFFF) - 4
    End Select
  Next

  If p% < (sym.P_REF_BASE% + sym.ref_end%) Then
    ' We are inserting a reference from a function other than the last one.
    Inc sym.ref_end%, 4                     ' Terminate last entry with &hFFFFFFFF
    Poke Word p%, &hFF000000 + sym.ref_end% ' Replace end of function entry with link.
    sym.ref_offset% = sym.ref_end%          ' Move offset to the end of the table.
    p% = sym.P_REF_BASE% + sym.ref_offset%  ' Move pointer to the end of the table.
  EndIf

  If p% > sym.P_REF_LIMIT% Then
    sym.add_reference% = sys.error%(sys.FAILURE, "Too many references")
  Else
    Poke Word p%, sym.add_reference%
  EndIf

  Inc sym.ref_end%, 4
End Function

' Gets the integer id corresponding to a name.
'
' @param   name$  the name.
' @return         the integer id, or sys.FAILURE.
Function sym.name_to_id%(name$)
  ' Ignore # prefix.
  Const name_$ = Choice(Left$(name$, 1) = "#", Mid$(name$, 2), name$)
  Const  id_data$ = map2.get$(sym.names$(), LCase$(name_$))
  If id_data$ = sys.NO_DATA$ Then
    sym.name_to_id% = sys.error%(sys.FAILURE, "Name not found")
  Else
    sym.name_to_id% = Val(id_data$)
  EndIf
End Function

' Gets the "function data" for a named function.
'
' @param       fn_name$  the function name including type suffix.
' @param[out]  fn_data$  the retrieved function data.
' @return                the function's "name id", or sys.FAILURE.
Function sym.name_to_fn%(fn_name$, fn_data$)
  fn_data$ = map2.get$(sym.functions$(), LCase$(fn_name$))
  If fn_data$ = sys.NO_DATA$ Then
    sym.name_to_fn% = sys.error%(sys.FAILURE, "FUNCTION/SUB not found")
  Else
    sym.name_to_fn% = Val(Field$(fn_data$, 5))
  EndIf
End Function

' Gets a function from an id.
'
' @param   id%  the function/name id.
' @return       the retrieved function data,
'               or sys.NO_DATA% if not a function.
Function sym.id_to_fn$(id%)
  Local i%
  For i% = 0 To map2.size%(sym.functions$()) - 1
    sym.id_to_fn$ = Mid$(sym.functions$(i%), sym.MAX_NAME_LEN + 1)
    If id% = Val(Field$(sym.id_to_fn$, 5, ",")) Then Exit Function
  Next
  sym.id_to_fn$ = sys.NO_DATA$
End Function

' Gets the names referenced by a named function.
'
' @param       fn_name$  the function name including type suffix.
' @param[out]  names$()  referenced names are copied into this array.
' @return                the number of references,
'                        or sys.FAILURE if function not found.
Function sym.get_references%(fn_name$, names$())
  Local ids%(array.new%(sym.MAX_REFERENCES))
  sym.get_references% = sym.get_referenced_ids%(sym.name_to_id%(fn_name$), ids%())
  If sym.get_references% < -1 Then Exit Function
  Local i%
  For i% = 0 To sym.get_references% - 1
    names$(i%) = sym.id_to_name$(ids%(i%))
    If names$(i%) = sys.NO_DATA$ Then
      sym.get_references% = sys.FAILURE
      Exit Function
    EndIf
  Next

  If i% > 0 And i% <= array.capacity%(names$()) Then Sort names$(), , , 0, i%
End Function

' Gets the ids referenced by a named function.
'
' @param       fn_id%    the function id.
' @param[out]  ids%()    referenced ids are copied into this array.
'                        If the array is too small then it will be filled and
'                        any additional references will be counted (for the
'                        return value) but not returned.
' @return                the number of references,
'                        or sys.FAILURE if function not found.
Function sym.get_referenced_ids%(fn_id%, ids%())
  Local fn_data$ = sym.id_to_fn$(fn_id%)
  If fn_data$ = sys.NO_DATA$ Then
    sym.get_referenced_ids% = sys.error%(sys.FAILURE, "FUNCTION/SUB not found")
    Exit Function
  EndIf

  Local i%, p%, ref%
  For p% = sym.P_REF_BASE% + Val(Field$(fn_data$, 4)) To sym.P_REF_LIMIT% Step 4
    ref% = Peek(Word p%)
    If ref% = &hFFFFFFFF Then Exit For ' End of references table.
    If ref% And &hFF000000 Then ' Follow link.
      p% = sym.P_REF_BASE% + (ref% And &h00FFFFFF)
      ref% = Peek(Word p%)
    EndIf
    If i% <= Bound(ids%(), 1) Then ids%(i%) = ref%
    Inc i%
  Next

  sym.get_referenced_ids% = i%
End Function

' Gets a name from its id.
'
' @param  id   the named id.
' @return      the corresponding lower-case name, or sys.NO_DATA$ if not found.
Function sym.id_to_name$(id%)
  Local i%
  For i% = 0 To map2.size%(sym.names$()) - 1
    If Val(Mid$(sym.names$(i%), sym.MAX_NAME_LEN)) = id% Then
      sym.id_to_name$ = str.trim$(Left$(sym.names$(i%), sym.MAX_NAME_LEN%))
      Exit Function
    EndIf
  Next
  sym.id_to_name$ = sys.NO_DATA$
  Local ignored% = sys.error%(sys.FAILURE, "Invalid id")
End Function

Function sym.get_files%(files_$())
  Local i%, ub% = Bound(files_$(), 1)
  For i% = 0 To map2.size%(sym.files$()) - 1
    If i% <= ub% Then files_$(i%) = str.trim$(Left$(sym.files$(i%), sym.MAX_PATH_LEN%))
  Next
  sym.get_files% = i%
End Function

Function sym.get_names%(names$())
  Local i%, ub% = Bound(names$(), 1)
  For i% = 0 To map2.size%(sym.names$()) - 1
    If i% <= ub% Then names$(i%) = str.trim$(Left$(sym.names$(i%), sym.MAX_NAME_LEN%))
  Next
  sym.get_names% = i%
End Function

Function sym.get_functions%(functions$())
  Local i%, ub% = Bound(functions$(), 1)
  For i% = 0 To map2.size%(sym.functions$()) - 1
    If i% <= ub% Then functions$(i%) = Mid$(sym.functions$(i%), sym.MAX_NAME_LEN% + 1)
  Next
  sym.get_functions% = i%
End Function

Function sym.switch_function%(fn_name$)
  Local fn_data$
  sym.switch_function% = sym.name_to_fn%(fn_name$, fn_data$)
  If sym.switch_function% < 0 Then Exit Function
  sym.ref_offset% = Val(Field$(fn_data$, 4))
End Function

Function sym.dump_files%()
  map2.dump(sym.files$())
End Function

Function sym.dump_names%(fnbr%)
  map2.dump(sym.names$(), fnbr%)
End Function

Function sym.dump_functions%(fnbr%)
  map2.dump(sym.functions$(), fnbr%)
End Function

Sub sym.dump_references_raw(fnbr%, start%, num%)
  Local i% = 1, p%, ff_count%
  For p% = sym.P_REF_BASE% + 4 * start% To sym.P_REF_LIMIT% Step 4
    Print #fnbr%, "[" Str$(start% + i% - 1, 4) "] " Hex$(Peek(Word p%))
    If i% = num% Then Exit For
    Inc i%
    If Peek(Word p%) = &hFFFFFFFF Then Inc ff_count% Else ff_count% = 0
    If ff_count% = 5 Then Exit For
  Next
End Sub

Function sym.dump_references%(fnbr%)
  Const lb% = Bound(sym.functions$(), 0), ub% = Bound(sym.functions$(), 1)
  Const sz% = Val(Field$(sym.functions$(ub%), 2)), width% = Len(Str$(sz%))
  Local i%
  For i% = lb% To lb% + sz% - 1
    Print #fnbr%, "[" Str$(i%, width%) "] ";
    Print #fnbr%, Field$(sym.functions$(i%), 1, " ")
    sym.dump_references% = sym.dump_references_from_fn%(fnbr%, i%)
    If sym.dump_references% <> sys.SUCCESS Then Exit For
  Next
  Print #fnbr%, "END"
End Function

Function sym.dump_references_from_fn%(fnbr%, idx%)
  Const fn_name$ = Field$(sym.functions$(idx%), 1, " ")
  Local refs$(array.new%(sym.MAX_REFERENCES)) Length sym.MAX_NAME_LEN%
  Local result% = sym.get_references%(fn_name$, refs$())
  Select Case result%
    Case sys.FAILURE
      sym.dump_references_from_fn% = sys.FAILURE
      Exit Function
    Case > sym.MAX_REFERENCES
      sys.err$ = "Too many references from " + fn_name$ + ", maximum "
      Cat sys.err$, Str$(sym.MAX_REFERENCES) + ", found " + Str$(result%)
      sym.dump_references_from_fn% = sys.FAILURE
      Exit Function
  End Select
  Local i%
  For i% = Bound(refs$(), 0) To Bound(refs$(), 1)
    If refs$(i%) = "" Then Exit For
    Print #fnbr%, "        " refs$(i%);
    Print #fnbr%, Choice(map2.get$(sym.functions$(), refs$(i%)) = sys.NO_DATA, "", "()")
  Next
End Function
