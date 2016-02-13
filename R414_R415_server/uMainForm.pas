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
    procedure AddRow(StationR414: TStationR414); overload;
    procedure AddRow(StationR415: TStationR415); overload;
    procedure AddRow(cross: TCross); overload;
    procedure RemoveRow(UserName: string);
    procedure AddClient(StationR414: TStationR414; StationR415: TStationR415;
      Cross: TCross);
    procedure RemoveClient(StationR414: TStationR414; StationR415: TStationR415;
      Cross: TCross);
    procedure UpdateClient(StationR414: TStationR414; StationR415: TStationR415;
      Cross: TCross);
    procedure GridRowFixed;
    procedure UpdateRow(StationR414: TStationR414; StationR415: TStationR415; cross: TCross);
    procedure UpdateGridRow(Row: Integer; StationR414: TStationR414; StationR415: TStationR415; cross: TCross);
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
  /// Задает количество фиксированных строк.
  /// </summary>
  procedure TMainForm.GridRowFixed;
  begin
    if (strngrdUsers.RowCount = 2) and (strngrdUsers.FixedRows = 1) then
      strngrdUsers.FixedRows := 0;
  end;

  /// <summary>
  /// Очищает таблицу от записей.
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
  /// Добавляет новую строку в таблицу клиентов.
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  procedure TMainForm.AddRow(StationR415: TStationR415);
  begin
    strngrdUsers.RowCount := strngrdUsers.RowCount + 1;
     strngrdUsers.Cells[0, strngrdUsers.RowCount - 1] :=
      IntToStr(strngrdUsers.RowCount - 1);
    UpdateGridRow(strngrdUsers.RowCount - 1,nil, StationR415, nil);
    strngrdUsers.Cells[7,strngrdUsers.RowCount - 1] := TimeToStr(Time);
    if (strngrdUsers.RowCount >= 2) and (strngrdUsers.FixedRows <> 1) then
        strngrdUsers.FixedRows := 1;
  end;

  /// <summary>
  /// Добавляет новую строку в таблицу клиентов.
  /// </summary>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  procedure TMainForm.AddRow(StationR414: TStationR414);
  begin
    strngrdUsers.RowCount := strngrdUsers.RowCount + 1;
     strngrdUsers.Cells[0, strngrdUsers.RowCount - 1] :=
      IntToStr(strngrdUsers.RowCount - 1);
    UpdateGridRow(strngrdUsers.RowCount - 1, StationR414,nil, nil);
    strngrdUsers.Cells[7,strngrdUsers.RowCount - 1] := TimeToStr(Time);
    if (strngrdUsers.RowCount >= 2) and (strngrdUsers.FixedRows <> 1) then
        strngrdUsers.FixedRows := 1;
  end;

  /// <summary>
  /// Добавляет новую строку в таблицу клиентов.
  /// </summary>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  procedure TMainForm.AddRow(cross: TCross);
  begin
    strngrdUsers.RowCount := strngrdUsers.RowCount + 1;
     strngrdUsers.Cells[0, strngrdUsers.RowCount - 1] :=
      IntToStr(strngrdUsers.RowCount - 1);
    UpdateGridRow(strngrdUsers.RowCount - 1, nil,nil, cross);
    strngrdUsers.Cells[7,strngrdUsers.RowCount - 1] := TimeToStr(Time);
    if (strngrdUsers.RowCount >= 2) and (strngrdUsers.FixedRows <> 1) then
        strngrdUsers.FixedRows := 1;
  end;

  /// <summary>
  /// Обновляет ячейку таблицы.
  /// </summary>
  /// <param name="Col">Номер столбца.</param>
  /// <param name="Row">Номер строки.</param>
  /// <param name="Value">Значение для записи в ячейку.</param>
  procedure TMainForm.UpdateCells(Col: Integer; Row: Integer; Value: string);
  begin
    if Value <> '' then
    begin
      strngrdUsers.Cells[Col, Row] := Value;
    end
    else
    begin
      strngrdUsers.Cells[Col, Row]:='Отсуствует';
    end;
  end;

  /// <summary>
  /// Обновляет данные клиента в заданной строке.
  /// </summary>
  /// <param name="Row">Номер строки.</param>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  procedure TMainForm.UpdateGridRow(Row: Integer; StationR414: TStationR414; StationR415: TStationR415; cross: TCross);
  begin
    if StationR414 <> nil then
    begin
      UpdateCells(1, Row, 'Р414');
      UpdateCells(2, Row, StationR414.UserName);
      UpdateCells(3, Row, StationR414.IP);

      if StationR414.LinkedStation <> nil then
      begin
        UpdateCells(4, Row, StationR414.LinkedStation.UserName);
      end
      else
      begin
        UpdateCells(4, Row, 'Отсуствует');
      end;

      if StationR414.StationR415 <> nil then
      begin
        UpdateCells(5, Row, StationR414.StationR415.UserName);
      end
      else
      begin
        UpdateCells(5, Row, 'Отсуствует');
      end;

      if StationR414.Cross <> nil then
      begin
        UpdateCells(6, Row, StationR414.Cross.UserName);
      end
      else
      begin
        UpdateCells(6, Row, 'Отсуствует');
      end;
    end;

    if StationR415 <> nil then
    begin
    UpdateCells(1, Row, 'Р415');
      UpdateCells(2, Row, StationR415.UserName);
      UpdateCells(3, Row, StationR415.IP);

      if StationR415.LinkedStation <> nil then
      begin
        UpdateCells(4, Row, StationR415.LinkedStation.UserName);
      end
      else
      begin
        UpdateCells(4, Row, 'Отсуствует');
      end;
    end;

    if cross <> nil then
    begin
      UpdateCells(1, Row, 'Кросс');
      UpdateCells(2, Row, cross.UserName);
      UpdateCells(3, Row, cross.IP);

      if cross.LinkedStation <> nil then
      begin
        UpdateCells(4, Row, cross.LinkedStation.UserName);
      end
      else
      begin
        UpdateCells(4, Row, 'Отсуствует');
      end;
    end;
  end;

  /// <summary>
  /// Производит поиск клиента в таблице и обновление данных.
  /// </summary>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  procedure TMainForm.UpdateRow(StationR414: TStationR414; StationR415: TStationR415; cross: TCross);
  var
    i:Integer;
  begin
    for i := 0 to strngrdUsers.RowCount - 1 do
    begin
     if StationR414 <> nil then
      if (strngrdUsers.Cells[2, i] = StationR414.UserName) then
      begin
        UpdateGridRow(i, StationR414,nil,nil);
        Break;
      end;

     if StationR415 <> nil then
      if (strngrdUsers.Cells[2, i] = StationR415.UserName) then
      begin
        UpdateGridRow(i,nil ,StationR415,nil);
        Break;
      end;

     if cross <> nil then
      if (strngrdUsers.Cells[2, i] = cross.UserName) then
      begin
        UpdateGridRow(i,nil ,nil,cross );
        Break;
      end;
    end;
  end;

  /// <summary>
  /// Удаляет запись в таблице по позывному станции.
  /// </summary>
  /// <param name="UserName">Позывной станции.</param>
  procedure TMainForm.RemoveRow (UserName: string);
  var i,j: Integer;
  begin
    for i := 1 to strngrdUsers.RowCount - 1 do
    begin
      if  strngrdUsers.Cells[2,i] = UserName then
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
  /// Записывает сообщение в журнал событий.
  /// </summary>
  /// <param name="Log">Сообщение для записи в журнал событий.</param>
  procedure TMainForm.WriteLog (Log : string);
  begin
    mmoEventLog.Lines.Add(TimeToStr(time) + ' ' + log);
  end;

  /// <summary>
  /// Возвращает имя пользователя.
  /// </summary>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  /// <param name="StationR415">Объект класса TStationR41.</param>
  /// <param name="Cross">Объект класса TCross.</param>
  function TMainForm.GetUserNameByObjects(StationR414: TStationR414;
    StationR415: TStationR415; Cross: TCross): string;
  begin
    if StationR415 <> nil then
      Exit('(Р415) ' + StationR415.UserName)
    else if StationR414 <> nil  then
      Exit('(Р414) ' + StationR414.UserName)
    else if Cross <> nil then
      Exit('(Кросс) ' + Cross.UserName)
    else
     Exit('');
  end;

  /// <summary>
  /// Обработчик события "onAddClient".
  /// </summary>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  /// <param name="StationR415">Объект класса TStationR41.</param>
  /// <param name="Cross">Объект класса TCross.</param>
  procedure TMainForm.AddClient(StationR414: TStationR414;
    StationR415: TStationR415; Cross: TCross);
  begin
    WriteLog('Подключился клиент: ' + GetUserNameByObjects(StationR414,
      StationR415, Cross) + '.');

    if StationR414 <> nil  then
      AddRow(StationR414);
    if StationR415 <> nil  then
      AddRow(StationR415);
    if Cross <> nil  then
      AddRow(Cross);
  end;

  /// <summary>
  /// Обработчик события "onRemoveClient".
  /// </summary>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  /// <param name="StationR415">Объект класса TStationR41.</param>
  /// <param name="Cross">Объект класса TCross.</param>
  procedure TMainForm.RemoveClient(StationR414: TStationR414;
    StationR415: TStationR415; Cross: TCross);
  begin
    WriteLog('Отключился клиент: ' + GetUserNameByObjects(StationR414,
      StationR415, Cross) + '.');
    if StationR414 <> nil  then
      RemoveRow(StationR414.UserName);
    if StationR415 <> nil  then
      RemoveRow(StationR415.UserName);
    if Cross <> nil  then
      RemoveRow(Cross.UserName);
  end;

  /// <summary>
  /// Обработчик события "onUpdateClient".
  /// </summary>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  /// <param name="Cross">Объект класса TCross.</param>
  procedure TMainForm.UpdateClient(StationR414: TStationR414;
    StationR415: TStationR415; Cross: TCross);
  begin
    WriteLog('Обновление данных клиента: ' + GetUserNameByObjects(StationR414,
      StationR415, Cross) + '.');

    if StationR414 <> nil  then
      UpdateRow(StationR414,nil,nil);

    if StationR415 <> nil  then
      UpdateRow(nil,StationR415,nil);

    if Cross <> nil  then
      UpdateRow(nil,nil,Cross);
  end;

  /// <summary>
  /// Производит проверку правильности ввода номера порта сервера.
  /// </summary>
  /// <param name="Port">Номер порта (передается по ссылке).</param>
  /// <returns>Возвращает Boolean.
  /// True если проврка прошла успешно, False в остальных случаях.
  /// </returns>
  function TMainForm.GetPort (var Port: Integer): Boolean;
  begin
    if TryStrToInt(edtPort.Text, Port) then
      if (Port > 0) and (Port < 65535) then
      begin
        Exit(True);
      end;
    Application.MessageBox(PChar('Не верно задан порт сервера.'),
      PChar('Ошибка'), MB_OK);
    Exit(False);
  end;

  /// <summary>
  /// Производит проверку правильности
  /// ввода максимального количества подключений.
  /// </summary>
  /// <param name="MaxConnections">
  /// Максимальное количество подключений.
  /// (передается по ссылке).
  /// </param>
  /// <returns>
  /// Возвращает Boolean.
  /// True если проврка прошла успешно, False в остальных случаях.
  /// </returns>
  function TMainForm.GetMaxConnections (var MaxConnections: Integer): Boolean;
  begin
    if TryStrToInt(edtMaxConnections.Text, MaxConnections) then
      if (MaxConnections > 0) and (MaxConnections < 65535) then
      begin
        Exit(True);
      end;
    Application.MessageBox(
      PChar('Ошибка. Не верно задано максимальное количество подключений.'),
      PChar('Ошибка'), MB_OK);
    Exit(False);
  end;

  /// <summary>
  /// Обработчик нажатия на кнопку "StartStopServer".
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
        btnStartStopServer.Caption := 'Остановить сервер';
        WriteLog('Сервер запущен.');
        edtPort.Enabled := False;
        edtMaxConnections.Enabled := False;
      end
      else
      begin
        edtPort.Enabled := True;
        edtMaxConnections.Enabled := True;
        Server.StopServer;
        btnStartStopServer.Caption := 'Запустить сервер';
        WriteLog('Сервер остановлен.');
      end;
  end;

  /// <summary>
  /// Задает начальные параметры таблицы клиентов.
  /// </summary>
  procedure TMainForm.InitGrid;
  begin
    strngrdUsers.Cols[0].SetText(PChar('Номер'));
    strngrdUsers.Cols[1].SetText(PChar('Тип'));
    strngrdUsers.Cols[2].SetText(PChar('Позывной'));
    strngrdUsers.Cols[3].SetText(PChar('IP'));
    strngrdUsers.Cols[4].SetText(PChar('Р414'));
    strngrdUsers.Cols[5].SetText(PChar('Р415'));
    strngrdUsers.Cols[6].SetText(PChar('Кросс'));
    strngrdUsers.Cols[7].SetText(PChar('Время подключения'));
  end;

  /// <summary>
  /// Обработчик закрытия формы.
  /// </summary>
  procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
  begin
    if Server.StatusServer then
      Server.StopServer;
  end;

  /// <summary>
  /// Обработчик создания формы (производит подписку на события).
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