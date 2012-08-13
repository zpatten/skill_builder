unit Global;

interface

uses SysUtils, Dialogs, Classes, Windows;

var
  ScriptFile: Text;

function GetColor(X, Y: Integer): LongInt;
procedure SetValue(Index: Integer; Value: LongInt);
function GetValue(Index: Integer): LongInt;
procedure GetCordinates(Index: Integer; var X, Y: Integer);
function GetNumber(TempStr, What: string): Integer;
procedure ReadScriptFile;
procedure WriteScriptFile(SaveAs: Boolean);
procedure UpdateStatus(StatusStr: string);

implementation

uses Main;

function GetColor(X, Y: Integer): LongInt;
var
  DisplayDC: HDC;
begin
  Result := 0;
  DisplayDC := CreateDC(PChar('DISPLAY'), Nil, Nil, Nil);
  if DisplayDC <> 0 then begin
    Result := GetPixel(DisplayDC, X, Y);
    DeleteDC(DisplayDC);
  end;
end;

procedure SetValue(Index: Integer; Value: LongInt);
begin
  MainForm.lvVariable.Items[Index-1].SubItems[1] := IntToStr(Value);
end;

function GetValue(Index: Integer): LongInt;
begin
  Result := StrToInt(Trim(MainForm.lvVariable.Items[Index-1].SubItems[1]));
end;

procedure GetCordinates(Index: Integer; var X, Y: Integer);
begin
  X := StrToInt(Trim(MainForm.lvMouse.Items[Index-1].SubItems[1]));
  Y := StrToInt(Trim(MainForm.lvMouse.Items[Index-1].SubItems[2]));
end;

function GetNumber(TempStr, What: string): Integer;
var
  Index,
  NumberLen: Integer;
begin
  Result := 0;
  What := LowerCase(What);
  Index := Pos(What, TempStr)+Length(What);
  if (Index = 0) then begin
    ShowMessage('Invalid Item: "'+What+'" is not in "'+TempStr+'"');
    Exit;
  end;
  NumberLen := 1;
  if TempStr[Index+1] in ['0'..'9'] then begin
    NumberLen := 2;
    if TempStr[Index+2] in ['0'..'9'] then begin
      NumberLen := 3;
      if TempStr[Index+3] in ['0'..'9'] then begin
        NumberLen := 4;
        if TempStr[Index+4] in ['0'..'9'] then NumberLen := 5;
      end;
    end;
  end;
  Result := StrToInt(Trim(Copy(TempStr, Index, NumberLen)));
end;

procedure AddCordinate(Cordinates: string);
var
  TempStr: string;
  SpacePos: Integer;
  Description: string;
  X, Y: string;
begin
  SpacePos := Pos(' ', Cordinates);
  X := Copy(Cordinates, 1, SpacePos-1);
  TempStr := Copy(Cordinates, SpacePos+1, Length(Cordinates)-SpacePos+1);
  SpacePos := Pos(' ', TempStr);
  Y := Copy(TempStr, 1, SpacePos-1);
  TempStr := Copy(TempStr, SpacePos+1, Length(TempStr)-SpacePos+1);
  Description := Trim(TempStr);

  with MainForm.lvMouse.Items.Add do begin
    Caption := IntToStr(MainForm.lvMouse.Items.Count);
    SubItems.Add(Description);
    SubItems.Add(X);
    SubItems.Add(Y);
  end;
end;

procedure AddMacro(MacroStr: string);
var
  PipePos: Integer;
  Description: string;
  Macro: string;
begin
  PipePos := Pos('|', MacroStr);
  Description := Copy(MacroStr, 1, PipePos-1);
  Macro := Copy(MacroStr, PipePos+1, Length(MacroStr)-PipePos+1);

  with MainForm.lvMacro.Items.Add do begin
    Caption := IntToStr(MainForm.lvMacro.Items.Count);
    SubItems.Add(Description);
    SubItems.Add(Macro);
  end;
end;

procedure AddVariable(VariableStr: string);
var
  PipePos: Integer;
  Description: string;
  Variable: string;
begin
  PipePos := Pos('|', VariableStr);
  Description := Copy(VariableStr, 1, PipePos-1);
  Variable := Copy(VariableStr, PipePos+1, Length(VariableStr)-PipePos+1);

  with MainForm.lvVariable.Items.Add do begin
    Caption := IntToStr(MainForm.lvVariable.Items.Count);
    SubItems.Add(Description);
    SubItems.Add(Variable);
  end;
end;

procedure ReadScriptFile;
var
  SBSScript: TStringList;
  CurrentLine: string;
  I: Integer;
  Notes, Script, Cordinates, Macros, Variables: Integer;
begin
  AssignFile(ScriptFile, MainForm.OpenDialog.FileName);
  {$I-} Reset(ScriptFile); {$I+}
  if (IOResult <> 0) then begin
    ShowMessage('Could not open script file: "'+MainForm.OpenDialog.FileName+'"');
    Exit;
  end;

  SBSScript := TStringList.Create;
  while not(EOF(ScriptFile)) do begin
    ReadLn(ScriptFile, CurrentLine);
    SBSScript.Add(CurrentLine);
  end;
  CloseFile(ScriptFile);

  Notes := 0;
  Script := 0;
  Cordinates := 0;
  Macros := 0;
  Variables := 0;

  for I := 0 to (SBSScript.Count-1) do begin
    if Pos('{NOTES}', SBSScript.Strings[I]) <> 0 then Notes := I;
    if Pos('{SCRIPT}', SBSScript.Strings[I]) <> 0 then Script := I;
    if Pos('{CORDINATES}', SBSScript.Strings[I]) <> 0 then Cordinates := I;
    if Pos('{MACROS}', SBSScript.Strings[I]) <> 0 then Macros := I;
    if Pos('{VARIABLES}', SBSScript.Strings[I]) <> 0 then Variables := I;
  end;

  // Process Notes...
  for I := Notes+1 to Script-1 do MainForm.eNotes.Lines.Add(SBSScript.Strings[I]);
  for I := Script+1 to Cordinates-1 do MainForm.eScript.Lines.Add(SBSScript.Strings[I]);
  for I := Cordinates+1 to Macros-1 do AddCordinate(SBSScript.Strings[I]);
  for I := Macros+1 to Variables-1 do AddMacro(SBSScript.Strings[I]);
  for I := Variables+1 to SBSScript.Count-1 do AddVariable(SBSScript.Strings[I]);

  SBSScript.Free;

  MainForm.Caption := CFormCaption+' - '+ExtractFileName(MainForm.OpenDialog.FileName);

  MainForm.ScriptChanged := FALSE;
end;

procedure WriteScriptFile(SaveAs: Boolean);
var
  FileName: string;
  I: Integer;
begin
  if SaveAs then
    FileName := MainForm.SaveDialog.FileName
  else
    FileName := MainForm.OpenDialog.FileName;
  AssignFile(ScriptFile, FileName);
  {$I-} Rewrite(ScriptFile); {$I+}
  if (IOResult <> 0) then begin
    ShowMessage('Could not save script file: "'+FileName+'"');
    Exit;
  end;

  WriteLn(ScriptFile, '{NOTES}');
  for I := 0 to MainForm.eNotes.Lines.Count-1 do
    WriteLn(ScriptFile, MainForm.eNotes.Lines.Strings[I]);

  WriteLn(ScriptFile, '{SCRIPT}');
  for I := 0 to MainForm.eScript.Lines.Count-1 do
    WriteLn(ScriptFile, MainForm.eScript.Lines.Strings[I]);

  WriteLn(ScriptFile, '{CORDINATES}');
  for I := 0 to MainForm.lvMouse.Items.Count-1 do
    with MainForm.lvMouse.Items[I] do
      WriteLn(ScriptFile, SubItems[1]+' '+SubItems[2]+' '+SubItems[0]);

  WriteLn(ScriptFile, '{MACROS}');
  for I := 0 to MainForm.lvMacro.Items.Count-1 do
    with MainForm.lvMacro.Items[I] do
      WriteLn(ScriptFile, SubItems[0]+'|'+SubItems[1]);

  WriteLn(ScriptFile, '{VARIABLES}');
  for I := 0 to MainForm.lvVariable.Items.Count-1 do
    with MainForm.lvVariable.Items[I] do
      WriteLn(ScriptFile, SubItems[0]+'|'+SubItems[1]);

  CloseFile(ScriptFile);

  MainForm.Caption := CFormCaption+' - '+ExtractFileName(FileName);
end;

procedure UpdateStatus(StatusStr: string);
begin
  MainForm.StatusBar.Panels[0].Text := StatusStr;
end;

end.
