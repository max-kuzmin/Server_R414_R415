program Station_R414_Server;

uses
  Forms,
  Windows,
  uMainForm in 'uMainForm.pas' {MainForm},
  uServerDM in 'uServerDM.pas',
  uClientDM in 'uClientDM.pas',
  uKeyValueDM in 'uKeyValueDM.pas',
  uRequestDM in 'uRequestDM.pas',
  uHandlerStationR414DM in 'uHandlerStationR414DM.pas',
  uStationR414DM in 'uStationR414DM.pas',
  uStationR415DM in 'uStationR415DM.pas',
  uCrossDM in 'uCrossDM.pas',
  uHandlerStationR415DM in 'uHandlerStationR415DM.pas',
  uHandlerCrossDM in 'uHandlerCrossDM.pas',
  uHandlerClientDM in 'uHandlerClientDM.pas';

{$R *.res}

var
  hwnd: THandle;

begin
  hwnd := FindWindow('TMainForm', 'Радиорелейная станция Р414 (сервер)');
  if hwnd = 0 then
  begin
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TMainForm, MainForm);
  Application.Run;
  end
  else
  begin
   Application.MessageBox(PChar('Приложение уже запущено.'),
    PChar('Ошибка'), MB_OK);
  end;
end.
