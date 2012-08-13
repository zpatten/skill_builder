unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, Tabnotbk, Menus, AddCord, AddMacro, AddVar, Global,
  SendKey;

type
  TMainForm = class(TForm)
    tnScript: TTabbedNotebook;
    MainMenu: TMainMenu;
    FileMenu: TMenuItem;
    FileExit: TMenuItem;
    N2: TMenuItem;
    FileLoadScript: TMenuItem;
    FileNewScript: TMenuItem;
    N1: TMenuItem;
    FileSave: TMenuItem;
    FileSaveAs: TMenuItem;
    StatusBar: TStatusBar;
    lvMouse: TListView;
    bAddCordinate: TButton;
    bRemoveCordinate: TButton;
    bAddMacro: TButton;
    bRemoveMacro: TButton;
    lvMacro: TListView;
    bAddVariable: TButton;
    bRemoveVariable: TButton;
    lvVariable: TListView;
    eNotes: TRichEdit;
    eScript: TRichEdit;
    ExecuteMenu: TMenuItem;
    AboutMenu: TMenuItem;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure FileExitClick(Sender: TObject);
    procedure bAddCordinateClick(Sender: TObject);
    procedure bRemoveCordinateClick(Sender: TObject);
    procedure bAddMacroClick(Sender: TObject);
    procedure bRemoveMacroClick(Sender: TObject);
    procedure bAddVariableClick(Sender: TObject);
    procedure bRemoveVariableClick(Sender: TObject);
    procedure FileNewScriptClick(Sender: TObject);
    procedure FileLoadScriptClick(Sender: TObject);
    procedure eNotesChange(Sender: TObject);
    procedure eScriptChange(Sender: TObject);
    procedure ExecuteMenuClick(Sender: TObject);
    procedure FileSaveAsClick(Sender: TObject);
    procedure FileSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    ScriptChanged: Boolean;
  end;

const
  CFormCaption = 'Skill Builder';

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

procedure TMainForm.FileExitClick(Sender: TObject);
begin
  if ScriptChanged then ShowMessage('The script has been modified are you sure you want to exit?');
  Close;
end;

procedure TMainForm.bAddCordinateClick(Sender: TObject);
begin
  with TAddCordForm.Create(Self) do ShowModal;
end;

procedure TMainForm.bRemoveCordinateClick(Sender: TObject);
var
  I: Integer;
begin
  if (lvMouse.Selected <> nil) then begin
    ScriptChanged := TRUE;
    while (lvMouse.Selected <> nil) do lvMouse.Selected.Delete;
    for I := 0 to (lvMouse.Items.Count-1) do lvMouse.Items[I].Caption := IntToStr(I+1);
  end else
    ShowMessage('You must select a set of cordinates in order to use the Remove Cordinate button...');
end;

procedure TMainForm.bAddMacroClick(Sender: TObject);
begin
  with TAddMacroForm.Create(Self) do ShowModal;
end;

procedure TMainForm.bRemoveMacroClick(Sender: TObject);
var
  I: Integer;
begin
  if (lvMacro.Selected <> nil) then begin
    ScriptChanged := TRUE;
    while (lvMacro.Selected <> nil) do lvMacro.Selected.Delete;
    for I := 0 to (lvMacro.Items.Count-1) do lvMacro.Items[I].Caption := IntToStr(I+1);
  end else
    ShowMessage('You must select a macro in order to use the Remove Macro button...');
end;

procedure TMainForm.bAddVariableClick(Sender: TObject);
begin
  with TAddVarForm.Create(Self) do ShowModal;
end;

procedure TMainForm.bRemoveVariableClick(Sender: TObject);
var
  I: Integer;
begin
  if (lvVariable.Selected <> nil) then begin
    ScriptChanged := TRUE;
    while (lvVariable.Selected <> nil) do lvVariable.Selected.Delete;
    for I := 0 to (lvVariable.Items.Count-1) do lvVariable.Items[I].Caption := IntToStr(I+1);
  end else
    ShowMessage('You must select a variable in order to use the Remove Variable button...');
end;

procedure TMainForm.FileNewScriptClick(Sender: TObject);
begin
  if ScriptChanged then ShowMessage('The script has been changed are you sure you want to continue without saving?');
  lvMouse.Items.Clear;
  lvMacro.Items.Clear;
  lvVariable.Items.Clear;
  eScript.Lines.Clear;
  eNotes.Lines.Clear;
end;

procedure TMainForm.FileLoadScriptClick(Sender: TObject);
begin
  if ScriptChanged then ShowMessage('The script has been modified, are you sure you want to continue without saving?');
  if OpenDialog.Execute then begin
    lvMouse.Items.Clear;
    lvMacro.Items.Clear;
    lvVariable.Items.Clear;
    eScript.Lines.Clear;
    eNotes.Lines.Clear;
    ReadScriptFile;
  end;
end;

procedure TMainForm.eNotesChange(Sender: TObject);
begin
  ScriptChanged := TRUE;
end;

procedure TMainForm.eScriptChange(Sender: TObject);
begin
  ScriptChanged := TRUE;
end;

procedure TMainForm.ExecuteMenuClick(Sender: TObject);
var
  MouseDouble: Boolean;
  DragDesc,
  TempStr,
  CurrentLine: string;   // Current script line
  I,
  X, Y,
  RepeatStart,
  RepeatCount,
  DragItem,
  DragOne,
  DragTwo,
  MouseButton,
  TempInt,
  TempPos,
  CommentPos,            // Is there a comment on this line?
  CommandPos: Integer;
  H: hWnd;
begin
  eScript.ReadOnly := TRUE;
  H := FindWindow(nil, 'EVE');
  if (H <> 0) then begin
  SetForegroundWindow(H);
  Sleep(250);
  // Do script execution here...
  I := 0;
  RepeatStart := eScript.Lines.Count-1;
  RepeatCount := 0;
  repeat
    Self.Invalidate;
    CurrentLine := Trim(LowerCase(eScript.Lines.Strings[I]));
    CommentPos := Pos('//', CurrentLine);

    if CommentPos = 0 then CommentPos := 255;

    CommandPos := Pos('macro', CurrentLine);
    if (CommandPos <> 0) and (CommandPos < CommentPos) then begin
      // Build keyboard message and send it...
      TempInt := GetNumber(CurrentLine, '#');
      if TempInt <= lvMacro.Items.Count then begin
        UpdateStatus('Sending macro #'+IntToStr(TempInt)+'...');
        SendKeys(lvMacro.Items[TempInt-1].SubItems[1]);
        WaitForHook;
        Sleep(500);
      end else
        ShowMessage('ERROR (Line #'+IntToStr(I+1)+'): That macro does not exist...');
    end;

    CommandPos := Pos('wait', CurrentLine);
    if (CommandPos <> 0) and (CommandPos < CommentPos) then begin
      // Wait for specified amount of time...
      TempInt := GetNumber(CurrentLine, ' ');
      repeat
        UpdateStatus('Waiting for '+IntToStr(TempInt)+' seconds...');
        Sleep(1000);
        Dec(TempInt);
      until TempInt = 0;
    end;

    CommandPos := Pos('click', CurrentLine);
    if (CommandPos <> 0) and (CommandPos < CommentPos) then begin
      // Build mouse message and send it...
      TempPos := Pos(' ', CurrentLine);
      TempStr := Trim(Copy(CurrentLine, 1, TempPos-1));
      if TempStr = 'double' then begin
        MouseDouble := TRUE;
        TempStr := Copy(CurrentLine, TempPos+1, Length(CurrentLine)-TempPos+1);
      end else
        MouseDouble := FALSE;
      MouseButton := 0;
      if Pos('for', CurrentLine) <> 0 then begin
        if TempStr = 'left' then MouseButton := 3;
        if TempStr = 'right' then MouseButton := 5;
      end else begin
        if TempStr = 'left' then MouseButton := 0;
        if TempStr = 'right' then MouseButton := 1;
        if TempStr = 'middle' then MouseButton := 2;
      end;

      TempInt := GetNumber(CurrentLine, 'location #');
      if TempInt <= lvMouse.Items.Count then begin
        GetCordinates(TempInt, X, Y);
        UpdateStatus('Sending '+TempStr+' mouse click at cordinate #'+IntToStr(TempInt)+'...');
        if Pos('for', CurrentLine) <> 0 then begin
          TempInt := GetNumber(CurrentLine, 'for ');
          SendClicks(X, Y, FALSE, MouseButton);
          WaitForHook;
          Sleep(TempInt);
          SendClicks(X, Y, FALSE, MouseButton+1);
          WaitForHook;
          Sleep(500);
        end else begin
          SendClicks(X, Y, MouseDouble, MouseButton);
          WaitForHook;
          Sleep(500);
        end;
      end else
        ShowMessage('ERROR (Line #'+IntToStr(I+1)+'): Those mouse cordinates do not exist...');
    end;

    CommandPos := Pos('drag', CurrentLine);
    if (CommandPos <> 0) and (CommandPos < CommentPos) then begin
      // Drag object from location #x to location #x
      TempPos := Pos(' ', CurrentLine);
      TempStr := Trim(Copy(CurrentLine, TempPos+1, 3));
      if TempStr = 'all' then begin
        DragItem := 0;
        DragDesc := 'all';
      end else begin
        DragItem := GetNumber(CurrentLine, ' ');
        DragDesc := IntToStr(DragItem);
      end;
      DragOne := GetNumber(CurrentLine, 'Location #');
      TempPos := Pos('location #', CurrentLine)+Length('location #')+1;
      TempStr := Trim(Copy(CurrentLine, TempPos, Length(CurrentLine)-TempPos+1));
      DragTwo := GetNumber(TempStr, 'Location #');
      if (DragOne <= lvMouse.Items.Count) and (DragTwo <= lvMouse.Items.Count) then begin
        UpdateStatus('Drag '+DragDesc+' object(s) from cordinates #'+IntToStr(DragOne)+' to cordinates #'+IntToStr(DragTwo)+'...');
        GetCordinates(DragOne, X, Y);
        SendClicks(X, Y, FALSE, 3);
        WaitForHook;
        Sleep(1000);
        if DragItem = 0 then begin
          SendKeys('{ENTER}');
          WaitForHook;
          Sleep(1000);
        end else begin
          SendKeys(IntToStr(DragItem)+'{ENTER}');
          WaitForHook;
          Sleep(1000);
        end;
        GetCordinates(DragTwo, X, Y);
        SendClicks(X, Y, FALSE, 4);
        WaitForHook;
        Sleep(50);
//        ShowMessage('Drag '+IntToStr(DragItem)+' objects from location #'+IntToStr(DragOne)+' to location #'+IntToStr(DragTwo)+'...');
      end else
        ShowMessage('ERROR (Line #'+IntToStr(I+1)+'): Those mouse cordinates do not exist...');
    end;

    CommandPos := Pos('repeat ', CurrentLine);
    if (CommandPos <> 0) and (CommandPos < CommentPos) then begin
      // Setup a repeat loop
      RepeatStart := I;
      RepeatCount := GetNumber(CurrentLine, ' ')-1;
      StatusBar.Panels[1].Text := IntToStr(RepeatCount)+' loops left...';
    end;

    CommandPos := Pos('end repeat', CurrentLine);
    if (CommandPos <> 0) and (CommandPos < CommentPos) then begin
      if (RepeatCount > 0) then begin
        I := RepeatStart;
        Dec(RepeatCount);
        StatusBar.Panels[1].Text := IntToStr(RepeatCount)+' loops left...';
      end else
        StatusBar.Panels[1].Text := '';
    end;

    CommandPos := Pos('if', CurrentLine);
    if (CommandPos <> 0) and (CommandPos < CommentPos) then begin
      TempStr := Copy(CurrentLine, CommandPos+3, Length(CurrentLine)-CommandPos+3);
      if Pos('color', TempStr) <> 0 then begin
        TempInt := GetNumber(CurrentLine, 'Location #');
        GetCordinates(TempInt, X, Y);
        if Pos('not variable #', CurrentLine) <> 0 then begin
          TempInt := GetNumber(CurrentLine, 'Not Variable #');
          TempInt := GetValue(TempInt);
          if GetColor(X, Y) = TempInt then
            while Pos('end if', CurrentLine) = 0 do begin
              Inc(I);
              CurrentLine := Trim(LowerCase(eScript.Lines.Strings[I]));
            end;
        end else begin
          // is variable #
          TempInt := GetNumber(CurrentLine, 'Variable #');
          TempInt := GetValue(TempInt);
          if GetColor(X, Y) <> TempInt then
            while Pos('end if', CurrentLine) = 0 do begin
              Inc(I);
              CurrentLine := Trim(LowerCase(eScript.Lines.Strings[I]));
            end;
        end;
      end else begin
      end;
    end;

    CommandPos := Pos('set variable #', CurrentLine);
    if (CommandPos <> 0) and (CommandPos < CommentPos) then begin
      if Pos('color', CurrentLine) <> 0 then begin
        TempInt := GetNumber(CurrentLine, 'Location #');
        GetCordinates(TempInt, X, Y);
        TempInt := GetNumber(CurrentLine, 'Variable #');
        SetValue(TempInt, GetColor(X, Y));
      end else begin
      end;
    end;

    CommandPos := Pos('end script', CurrentLine);
    if (CommandPos <> 0) and (CommandPos < CommentPos) then I := eScript.Lines.Count;

    Inc(I);
  until I > (eScript.Lines.Count-1);
  end;
  eScript.ReadOnly := FALSE;
  MessageBeep(0);
  UpdateStatus('Done...');
end;

procedure TMainForm.FileSaveAsClick(Sender: TObject);
begin
  if SaveDialog.Execute then WriteScriptFile(TRUE);
end;

procedure TMainForm.FileSaveClick(Sender: TObject);
begin
  WriteScriptFile(FALSE);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption := CFormCaption;
end;

end.
