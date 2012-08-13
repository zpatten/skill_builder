unit AddVar;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls;

type
  TAddVarForm = class(TForm)
    gbVariable: TGroupBox;
    lInfo: TLabel;
    eDescription: TEdit;
    eValue: TEdit;
    lDescription: TLabel;
    lValue: TLabel;
    bOK: TButton;
    bCancel: TButton;
    procedure bCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bOKClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AddVarForm: TAddVarForm;

implementation

uses Main;

{$R *.DFM}

procedure TAddVarForm.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TAddVarForm.FormCreate(Sender: TObject);
begin
  eDescription.Text := '';
  eValue.Text := '';
end;

procedure TAddVarForm.bOKClick(Sender: TObject);
var
  VariableItem: TListItem;
begin
  if eValue.Text = '' then begin
    ShowMessage('You must enter something in the Value field...');
    Exit;
  end;
  try
    StrToInt(eValue.Text);
  except
    on EConvertError do begin
      ShowMessage('You must enter a numeric value...');
      Exit;
    end;
  end;
  VariableItem := MainForm.lvVariable.Items.Add;
  with VariableItem do begin
    if eDescription.Text = '' then eDescription.Text := 'Unlabeled';
    Caption := IntToStr(MainForm.lvVariable.Items.Count);
    SubItems.Add(eDescription.Text);
    SubItems.Add(eValue.Text);
  end;
  MainForm.ScriptChanged := TRUE;
  Close;
end;

end.
