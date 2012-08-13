unit AddCord;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, SendKey, ComCtrls;

type
  TAddCordForm = class(TForm)
    Timer: TTimer;
    gbCordinates: TGroupBox;
    lInfo: TLabel;
    lCordinates: TLabel;
    eDescription: TEdit;
    bCancel: TButton;
    lDescription: TLabel;
    procedure TimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bCancelClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AddCordForm: TAddCordForm;

implementation

{$R *.DFM}

uses Main;

procedure TAddCordForm.TimerTimer(Sender: TObject);
var
  MouseItem: TListItem;
  DisplayDC: HDC;
begin
  lCordinates.Caption := 'X='+IntToStr(SendKey.MouseX)+'/Y='+IntToStr(SendKey.MouseY);
  if Clicked then begin
    StopRecording;
    Timer.Enabled := FALSE;
    DisplayDC := CreateDC(PChar('DISPLAY'), Nil, Nil, Nil);
    if DisplayDC <> 0 then begin
      ShowMessage('The pixel color at cordinates '+IntToStr(SendKey.MouseX)+','+IntToStr(SendKey.MouseY)+' is '+IntToStr(GetPixel(DisplayDC, SendKey.MouseX, SendKey.MouseY))+'.');
      DeleteDC(DisplayDC);
    end;
    MouseItem := MainForm.lvMouse.Items.Add;
    with MouseItem do begin
      if eDescription.Text = '' then eDescription.Text := 'Unlabeled';
      Caption := IntToStr(MainForm.lvMouse.Items.Count);
      SubItems.Add(eDescription.Text);
      SubItems.Add(IntToStr(SendKey.MouseX));
      SubItems.Add(IntToStr(SendKey.MouseY));
    end;
    MainForm.ScriptChanged := TRUE;
    Close;
  end;
end;

procedure TAddCordForm.FormCreate(Sender: TObject);
begin
  eDescription.Text := '';
  lCordinates.Caption := '';
  StartRecording;
end;

procedure TAddCordForm.bCancelClick(Sender: TObject);
begin
  StopRecording;
  Close;
end;


end.
