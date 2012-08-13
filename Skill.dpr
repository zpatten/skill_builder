program Skill;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  Global in 'Global.pas',
  AddCord in 'AddCord.pas' {AddCordForm},
  SendKey in 'SendKey.pas',
  AddMacro in 'AddMacro.pas' {AddMacroForm},
  AddVar in 'AddVar.pas' {AddVarForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Skill Builder v1.1';
  Application.CreateForm(TMainForm, MainForm);
//  Application.CreateForm(TAddMacroForm, AddMacroForm);
//  Application.CreateForm(TAddVarForm, AddVarForm);
  Application.Run;
end.
