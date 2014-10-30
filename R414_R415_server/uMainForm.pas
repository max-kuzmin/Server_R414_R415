unit uMainForm;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  IdTCPServer,
  IdContext,
  IdBaseComponent,
  IdComponent,
  IdCustomTCPServer,
  uServerDM,
  ComCtrls,
  StdCtrls,
  Grids,
  DateUtils,
  uClientDM,
  uStationR414DM,
  uStationR415DM,
  uCrossDM;

type
  TMainForm = class(TForm)
    pgc: TPageControl;
    tsSettingsAndEventLog: TTabSheet;
    grpEventLog: TGroupBox;
    grpSettings: TGroupBox;
    btnStartStopServer: TButton;
    tsUserTable: TTabSheet;
    mmoEventLog: TMemo;
    strngrdUsers: TStringGrid;
    edtPort: TEdit;
    lblPort: TLabel;
    lblMaxConnection: TLabel;
    edtMaxConnections: TEdit;
    procedure btnStartStopServerClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    Server: TServer;
    procedure InitGrid;
    procedure AddRow(StationR414: TStationR414);
    procedure RemoveRow(UserName: string);
    procedure AddClient(StationR414: TStationR414; StationR415: TStationR415;
      Cross: TCross);
    procedure RemoveClient(StationR414: TStationR414; StationR415: TStationR415;
      Cross: TCross);
    procedure UpdateClient(StationR414: TStationR414; StationR415: TStationR415;
      Cross: TCross);
    procedure GridRowFixed;
    procedure UpdateRow(StationR414: TStationR414);
    procedure UpdateGridRow(Row: Integer; StationR414: TStationR414);
    procedure ClearGridUsers;
    procedure UpdateCells(Col: Integer; Row: Integer; Value: string);
    procedure WriteLog(Log : string);
    function GetPort (var Port: Integer): Boolean;
    function GetMaxConnections (var MaxConnections: Integer): Boolean;
    function GetUserNameByObjects(StationR414: TStationR414;
      StationR415: TStationR415; Cross: TCross): string;

  end;

var
  MainForm: TMainForm;
  Server: TServer;

implementation

{$R *.dfm}

  /// <summary>
  /// ������ ���������� ������������� �����.
  /// </summary>
  procedure TMainForm.GridRowFixed;
  begin
    if (strngrdUsers.RowCount = 2) and (strngrdUsers.FixedRows = 1) then
      strngrdUsers.FixedRows := 0;
  end;

  /// <summary>
  /// ������� ������� �� �������.
  /// </summary>
  procedure TMainForm.ClearGridUsers;
  var i : Integer;
  begin
    for i := 1 to strngrdUsers.RowCount - 1 do
    begin
       GridRowFixed;
       strngrdUsers.RowCount := strngrdUsers.RowCount - 1
    end;
  end;

  /// <summary>
  /// ��������� ����� ������ � ������� ��������.
  /// </summary>
  /// <param name="StationR414">������ ������ TStationR414.</param>
  procedure TMainForm.AddRow(StationR414: TStationR414);
  begin
    strngrdUsers.RowCount := strngrdUsers.RowCount + 1;
     strngrdUsers.Cells[0, strngrdUsers.RowCount - 1] :=
      IntToStr(strngrdUsers.RowCount - 1);
    UpdateGridRow(strngrdUsers.RowCount - 1, StationR414);
    strngrdUsers.Cells[6,strngrdUsers.RowCount - 1] := TimeToStr(Time);
    if (strngrdUsers.RowCount >= 2) and (strngrdUsers.FixedRows <> 1) then
        strngrdUsers.FixedRows := 1;
  end;

  /// <summary>
  /// ��������� ������ �������.
  /// </summary>
  /// <param name="Col">����� �������.</param>
  /// <param name="Row">����� ������.</param>
  /// <param name="Value">�������� ��� ������ � ������.</param>
  procedure TMainForm.UpdateCells(Col: Integer; Row: Integer; Value: string);
  begin
    if Value <> '' then
    begin
      strngrdUsers.Cells[Col, Row] := Value;
    end
    else
    begin
      strngrdUsers.Cells[Col, Row]:='����������';
    end;
  end;

  /// <summary>
  /// ��������� ������ ������� � �������� ������.
  /// </summary>
  /// <param name="Row">����� ������.</param>
  /// <param name="StationR414">������ ������ TStationR414.</param>
  procedure TMainForm.UpdateGridRow(Row: Integer; StationR414: TStationR414);
  begin
    if StationR414 <> nil then
    begin
      UpdateCells(1, Row, StationR414.UserName);
      UpdateCells(2, Row, StationR414.IP);

      if StationR414.LinkedStation <> nil then
      begin
        UpdateCells(3, Row, StationR414.LinkedStation.UserName);
      end
      else
      begin
        UpdateCells(3, Row, '����������');
      end;

      if StationR414.StationR415 <> nil then
      begin
        UpdateCells(4, Row, StationR414.StationR415.UserName);
      end
      else
      begin
        UpdateCells(4, Row, '����������');
      end;

      if StationR414.Cross <> nil then
      begin
        UpdateCells(5, Row, StationR414.Cross.UserName);
      end
      else
      begin
        UpdateCells(5, Row, '����������');
      end;
    end;
  end;

  /// <summary>
  /// ���������� ����� ������� � ������� � ���������� ������.
  /// </summary>
  /// <param name="StationR414">������ ������ TStationR414.</param>
  procedure TMainForm.UpdateRow(StationR414: TStationR414);
  var
    i:Integer;
  begin
    for i := 0 to strngrdUsers.RowCount - 1 do
    begin
      if strngrdUsers.Cells[1, i] = StationR414.UserName then
      begin
        UpdateGridRow(i, StationR414);
        Break;
      end;
    end;
  end;

  /// <summary>
  /// ������� ������ � ������� �� ��������� �������.
  /// </summary>
  /// <param name="UserName">�������� �������.</param>
  procedure TMainForm.RemoveRow (UserName: string);
  var i,j: Integer;
  begin
    for i := 1 to strngrdUsers.RowCount - 1 do
    begin
      if  strngrdUsers.Cells[1,i] = UserName then
      begin
        for j := i + 1 to strngrdUsers.RowCount -1 do
        begin
          strngrdUsers.Rows[j -1] := strngrdUsers.Rows[j];
          strngrdUsers.Cells[0,j-1] := IntToStr(j - 1);
        end;
        GridRowFixed;
        strngrdUsers.RowCount := strngrdUsers.RowCount - 1;
        Break;
      end;
    end;
  end;

  /// <summary>
  /// ���������� ��������� � ������ �������.
  /// </summary>
  /// <param name="Log">��������� ��� ������ � ������ �������.</param>
  procedure TMainForm.WriteLog (Log : string);
  begin
    mmoEventLog.Lines.Add(TimeToStr(time) + ' ' + log);
  end;

  /// <summary>
  /// ���������� ��� ������������.
  /// </summary>
  /// <param name="StationR414">������ ������ TStationR414.</param>
  /// <param name="StationR415">������ ������ TStationR41.</param>
  /// <param name="Cross">������ ������ TCross.</param>
  function TMainForm.GetUserNameByObjects(StationR414: TStationR414;
    StationR415: TStationR415; Cross: TCross): string;
  begin
    if StationR415 <> nil then
      Exit('(�415) ' + StationR415.UserName)
    else if StationR414 <> nil  then
      Exit('(�414) ' + StationR414.UserName)
    else if Cross <> nil then
      Exit('(�����) ' + Cross.UserName)
    else
     Exit('');
  end;

  /// <summary>
  /// ���������� ������� "onAddClient".
  /// </summary>
  /// <param name="StationR414">������ ������ TStationR414.</param>
  /// <param name="StationR415">������ ������ TStationR41.</param>
  /// <param name="Cross">������ ������ TCross.</param>
  procedure TMainForm.AddClient(StationR414: TStationR414;
    StationR415: TStationR415; Cross: TCross);
  var UserName: string;
  begin
    WriteLog('����������� ������: ' + GetUserNameByObjects(StationR414,
      StationR415, Cross) + '.');
    if StationR414 <> nil  then
      AddRow(StationR414);
  end;

  /// <summary>
  /// ���������� ������� "onRemoveClient".
  /// </summary>
  /// <param name="StationR414">������ ������ TStationR414.</param>
  /// <param name="StationR415">������ ������ TStationR41.</param>
  /// <param name="Cross">������ ������ TCross.</param>
  procedure TMainForm.RemoveClient(StationR414: TStationR414;
    StationR415: TStationR415; Cross: TCross);
  begin
    WriteLog('���������� ������: ' + GetUserNameByObjects(StationR414,
      StationR415, Cross) + '.');
    if StationR414 <> nil  then
      RemoveRow(StationR414.UserName);
  end;

  /// <summary>
  /// ���������� ������� "onUpdateClient".
  /// </summary>
  /// <param name="StationR414">������ ������ TStationR414.</param>
  /// <param name="StationR415">������ ������ TStationR41.</param>
  /// <param name="Cross">������ ������ TCross.</param>
  procedure TMainForm.UpdateClient(StationR414: TStationR414;
    StationR415: TStationR415; Cross: TCross);
  begin
    WriteLog('���������� ������ �������: ' + GetUserNameByObjects(StationR414,
      StationR415, Cross) + '.');
    if StationR414 <> nil  then
      UpdateRow(StationR414);
  end;

  /// <summary>
  /// ���������� �������� ������������ ����� ������ ����� �������.
  /// </summary>
  /// <param name="Port">����� ����� (���������� �� ������).</param>
  /// <returns>���������� Boolean.
  /// True ���� ������� ������ �������, False � ��������� �������.
  /// </returns>
  function TMainForm.GetPort (var Port: Integer): Boolean;
  begin
    if TryStrToInt(edtPort.Text, Port) then
      if (Port > 0) and (Port < 65535) then
      begin
        Exit(True);
      end;
    Application.MessageBox(PChar('�� ����� ����� ���� �������.'),
      PChar('������'), MB_OK);
    Exit(False);
  end;

  /// <summary>
  /// ���������� �������� ������������
  /// ����� ������������� ���������� �����������.
  /// </summary>
  /// <param name="MaxConnections">
  /// ������������ ���������� �����������.
  /// (���������� �� ������).
  /// </param>
  /// <returns>
  /// ���������� Boolean.
  /// True ���� ������� ������ �������, False � ��������� �������.
  /// </returns>
  function TMainForm.GetMaxConnections (var MaxConnections: Integer): Boolean;
  begin
    if TryStrToInt(edtMaxConnections.Text, MaxConnections) then
      if (MaxConnections > 0) and (MaxConnections < 65535) then
      begin
        Exit(True);
      end;
    Application.MessageBox(
      PChar('������. �� ����� ������ ������������ ���������� �����������.'),
      PChar('������'), MB_OK);
    Exit(False);
  end;

  /// <summary>
  /// ���������� ������� �� ������ "StartStopServer".
  /// </summary>
  procedure TMainForm.btnStartStopServerClick(Sender: TObject);
  var
    bPort, bMaxConnections: Integer;
  begin
    if GetPort(bPort) and GetMaxConnections(bMaxConnections) then
      if not Server.GetStatusServer then
      begin
        mmoEventLog.Clear;
        Server.Port := bPort;
        Server.MaxConnections := bMaxConnections;
        ClearGridUsers;
        Server.StartServer;
        btnStartStopServer.Caption := '���������� ������';
        WriteLog('������ �������.');
        edtPort.Enabled := False;
        edtMaxConnections.Enabled := False;
      end
      else
      begin
        edtPort.Enabled := True;
        edtMaxConnections.Enabled := True;
        Server.StopServer;
        btnStartStopServer.Caption := '��������� ������';
        WriteLog('������ ����������.');
      end;
  end;

  /// <summary>
  /// ������ ��������� ��������� ������� ��������.
  /// </summary>
  procedure TMainForm.InitGrid;
  begin
    strngrdUsers.Cols[0].SetText(PChar('�����'));
    strngrdUsers.Cols[1].SetText(PChar('��������'));
    strngrdUsers.Cols[2].SetText(PChar('IP'));
    strngrdUsers.Cols[3].SetText(PChar('����������� �������'));
    strngrdUsers.Cols[4].SetText(PChar('�415'));
    strngrdUsers.Cols[5].SetText(PChar('�����'));
    strngrdUsers.Cols[6].SetText(PChar('����� �����������'));
  end;

  /// <summary>
  /// ���������� �������� �����.
  /// </summary>
  procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
  begin
    if Server.StatusServer then
      Server.StopServer;
  end;

  /// <summary>
  /// ���������� �������� ����� (���������� �������� �� �������).
  /// </summary>
  procedure TMainForm.FormCreate(Sender: TObject);
  begin
    InitGrid;
    Server := TServer.Create(2106, 500);
    Server.onAddClient :=  Self.AddClient;
    Server.onRemoveClient := Self.RemoveClient;
    Server.onUpdateClient := UpdateClient;
  end;
end.