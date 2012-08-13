unit AddMacro;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls;

type
  TAddMacroForm = class(TForm)
    gbMacro: TGroupBox;
    bOK: TButton;
    bCancel: TButton;
    lInfo: TLabel;
    eDescription: TEdit;
    eMacro: TEdit;
    lDescription: TLabel;
    lMacro: TLabel;
    procedure bCancelClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AddMacroForm: TAddMacroForm;

implementation

uses Main;

{$R *.DFM}

procedure TAddMacroForm.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TAddMacroForm.bOKClick(Sender: TObject);
var
  MacroItem: TListItem;
begin
  if eMacro.Text = '' then begin
    ShowMessage('You must enter something in the Macro field...');
    Exit;
  end;
  MacroItem := MainForm.lvMacro.Items.Add;
  with MacroItem do begin
    if eDescription.Text = '' then eDescription.Text := 'Unlabeled';
    Caption := IntToStr(MainForm.lvMacro.Items.Count);
    SubItems.Add(eDescription.Text);
    SubItems.Add(eMacro.Text);
  end;
  MainForm.ScriptChanged := TRUE;
  Close;
end;

procedure TAddMacroForm.FormCreate(Sender: TObject);
begin
  eDescription.Text := '';
  eMacro.Text := '';
end;

end.
