unit uHandlerStationR415DM;

interface

uses
  uClientDM,
  Generics.Collections,
  IdTCPConnection,
  SyncObjs,
  SysUtils,
  uRequestDM,
  uStationR415DM,
  uHandlerClientDM;

type

  THandlerStationR415 = class (THandlerClient)
    private
      FOnAddStationR415: TAddRemoveUpdateClientEvent;
      FOnRemoveStationR415: TAddRemoveUpdateClientEvent;
      FonUpdateStationR415: TAddRemoveUpdateClientEvent;
      procedure FindLinkedStation;
    public
      function RegistrationClient(Request: TRequest;Connection: TIdTCPConnection): Boolean;
      function RemoveClient(Connection: TIdTCPConnection):Boolean;
      procedure SendDisconnectClient(StationR415: TStationR415);
      function FindByConnection (Connection: TIdTCPConnection):TStationR415;
      procedure Update;
      procedure SendTypeStation(StationR415: TStationR415);
      procedure SendUserNameLinkedStation(StationR415:TStationR415);
      procedure IsFinished(StationR415: TStationR415; state: string);
      procedure SendTextMessageLinkedStation(StationR415: TStationR415; txtMeessage:string);
      procedure StationFinished(StationR415: TStationR415);
      procedure StationNoFinished(StationR415: TStationR415);
      procedure SendWavesLinkedStation(StationR415: TStationR415; prd:String;prm:String);
      procedure sendSetUstSvaziLinkedStation(StationR415: TStationR415; ustSvaz: string);
      procedure sendStateOfGenerate(StationR415: TStationR415; state: string);
      property onAddStationR415: TAddRemoveUpdateClientEvent
        read FOnAddStationR415
        write FOnAddStationR415;
      property onRemoveStationR415: TAddRemoveUpdateClientEvent
        read FOnRemoveStationR415
        write FOnRemoveStationR415;
      property onUpdateStationR415: TAddRemoveUpdateClientEvent
        read FonUpdateStationR415
        write FonUpdateStationR415;

  end;

implementation

  /// <summary>
  /// Узнаем что клиент закончил и сохраняем данные на сервере
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  procedure THandlerStationR415.IsFinished(StationR415: TStationR415; state: string);
  begin
    if StationR415 <> nil then
    begin

      if state = 'on' then
        StationR415.AnotherFinish := true
      else
        StationR415.AnotherFinish := false;
    end;
  end;

  /// <summary>
  /// Пересылаем инфу о генераторе сопряженной станции
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  procedure THandlerStationR415.sendStateOfGenerate(StationR415: TStationR415; state: string);
  var Request: TRequest;
  begin
    if StationR415 <> nil then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_GEN_ACT;
      Request.AddKeyValue(KEY_TYPE, 'r415');            // Тип клиента

      Request.AddKeyValue(KEY_GENERATE, state);

      if StationR415.LinkedStation <> nil then
      begin
        StationR415.LinkedStation.SendMessage(Request);
      end;
      Request.Destroy;
    end;
  end;

  procedure THandlerStationR415.sendSetUstSvaziLinkedStation(StationR415: TStationR415; ustSvaz: string);
  var Request: TRequest;
  begin
   if StationR415 <> nil then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_UST_SVAZI;
      Request.AddKeyValue(KEY_TYPE, 'r415');            // Тип клиента

      Request.AddKeyValue(KEY_SVAZ_SET, ustSvaz);

      if StationR415.LinkedStation <> nil then
      begin
        StationR415.LinkedStation.SendMessage(Request);
      end;
      Request.Destroy;
    end;
  end;

  procedure THandlerStationR415.SendWavesLinkedStation(StationR415: TStationR415;
    prd:String;prm:String);
  var Request: TRequest;
  begin
    if StationR415 <> nil then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_WAVES;
      Request.AddKeyValue(KEY_TYPE, 'r415');            // Тип клиента

      Request.AddKeyValue(KEY_TRANSMITTER_WAVE_A,prd);        // Наши ключ и значение
      Request.AddKeyValue(KEY_RECEIVER_WAVE_A,prm);

      if StationR415.LinkedStation <> nil then
      begin
        StationR415.LinkedStation.SendMessage(Request);
      end;
      Request.Destroy;
    end;

  end;

  /// <summary>
  /// Передает клиенту текстовое сообщение для чата
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  /// <param name="txtMeessage">Текстовое сообщение для отправки</param>
  procedure THandlerStationR415.SendTextMessageLinkedStation(StationR415: TStationR415;
    txtMeessage:string);
  var Request: TRequest;
  begin
    if StationR415 <> nil then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_TEXT_MESSAGE;
      Request.AddKeyValue(KEY_TYPE, 'r415');            // Тип клиента

      Request.AddKeyValue(KEY_TEXT,txtMeessage);        // Наши ключ и значение
      if StationR415.LinkedStation <> nil then
      begin
        StationR415.LinkedStation.SendMessage(Request);
      end;
      Request.Destroy;
    end;
  end;

  /// <summary>
  /// Передает клиенту сообщение о типе клиента(главный/подчиненный).
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  procedure THandlerStationR415.SendTypeStation(StationR415: TStationR415);
  var Request: TRequest;
  begin
    if StationR415 <> nil then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_STATION_PARAMS;
      Request.AddKeyValue(KEY_TYPE, VALUE_SERVER);
      if StationR415.Head then
        Request.AddKeyValue(KEY_STATUS, STATION_STATUS_MAIN)
      else
        Request.AddKeyValue(KEY_STATUS,STATION_STATUS_SUBORDINATE);
      StationR415.SendMessage(Request);
      Request.Destroy;
    end;
  end;

  /// <summary>
  /// Передает клиенту сообщение с позывным сопряженной станции.
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  procedure THandlerStationR415.SendUserNameLinkedStation(StationR415:
    TStationR415);
  var Request: TRequest;
  begin
    if StationR415 <> nil then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_STATION_PARAMS;
      Request.AddKeyValue(KEY_TYPE, CLIENT_STATION_R415);
      Request.AddKeyValue(KEY_CONNECTED, BoolToStr(KEY_CONNECTED_TRUE));
      Request.AddKeyValue(KEY_USERNAME, StationR415.LinkedStation.UserName);
      StationR415.SendMessage(Request);
      Request.Destroy;
    end;
  end;

  /// <summary>
  /// Сообщаем о том что настроились и сохраняем результат
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  procedure THandlerStationR415.StationFinished(StationR415: TStationR415);
  begin
    if StationR415 <> nil then
    begin
      StationR415.AnotherFinish := true;
    end;
  end;

  /// <summary>
  /// Сообщаем о том что станция расстроена и сохраняем результат
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  procedure THandlerStationR415.StationNoFinished(StationR415: TStationR415);
  begin
    if StationR415 <> nil then
    begin
      StationR415.AnotherFinish := false;
    end;
  end;


    /// <summary>
  /// Ищет не связанные станции и производит их связывание.
  /// </summary>
  procedure THandlerStationR415.FindLinkedStation;
  var
    i, j: Integer;
  begin
    for i := 0 to Count - 1 do
    begin
      if (Clients.Items[i] as TStationR415).LinkedStation = nil then
      begin
        for j := 0 to Count - 1 do
        begin
          if ((Clients.Items[j]as TStationR415).LinkedStation = nil)
            and (Clients.Items[i] <> Clients.Items[j])
            and (i <> j) then
          begin
            Section.Enter;

            (Clients.Items[j] as TStationR415).LinkedStation :=
              (Clients.Items[i] as TStationR415);
            (Clients.Items[i] as TStationR415).LinkedStation :=
              (Clients.Items[j] as TStationR415);

            (Clients.Items[j] as TStationR415).Head := True;
            SendTypeStation((Clients.Items[j] as TStationR415));

            (Clients.Items[i] as TStationR415).Head := False;
            SendTypeStation((Clients.Items[i] as TStationR415));

            SendUserNameLinkedStation((Clients.Items[j] as TStationR415));

            SendUserNameLinkedStation((Clients.Items[i] as TStationR415));

            onUpdateStationR415((Clients.Items[j] as TStationR415));
            onUpdateStationR415((Clients.Items[i] as TStationR415));

            Section.Leave;
            Break;
          end;
        end;
      end;
    end;
  end;

    /// <summary>
  /// Производит обновление.
  /// </summary>
  procedure THandlerStationR415.Update;
  begin
    FindLinkedStation;
  end;

   /// <summary>
  /// Передает клиенту сообщение о отключении клиента.
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  procedure THandlerStationR415.SendDisconnectClient(StationR415: TStationR415);
  var
    Request: TRequest;
  begin
    Request := TRequest.Create;
    Request.Name := REQUEST_NAME_STATION_PARAMS;
    Request.AddKeyValue(KEY_TYPE, CLIENT_STATION_R415);

    Request.AddKeyValue(KEY_USERNAME, StationR415.UserName);
    Request.AddKeyValue(KEY_CONNECTED, BoolToStr(KEY_CONNECTED_FALSE));
    if StationR415.LinkedStation <> nil then
    begin
      StationR415.LinkedStation.SendMessage(Request);
    end;
  end;

    /// <summary>
  /// Производит поиск клиента по подключению.
  /// </summary>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  function THandlerStationR415.FindByConnection (Connection: TIdTCPConnection):
     TStationR415;
  var
    Client: TClient;
  begin
    Client := inherited FindByConnection(Connection);
    if Client <> nil then
    begin
      Exit((Client as TStationR415))
    end;
    Exit(nil);
  end;

  /// <summary>
  /// Производит удаление станции из списка.
  /// </summary>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  function THandlerStationR415.RemoveClient(Connection: TIdTCPConnection):
    Boolean;
  var
    bStation: TStationR415;
  begin
    bStation := FindByConnection(Connection);
    if bStation <> nil then
    begin
      bStation.Head := False;
      if bStation.LinkedStation <> nil then
      begin
        bStation.LinkedStation.Head := False;
        bStation.LinkedStation.LinkedStation := nil;
      end;
      if bStation.LinkedStation <> nil then
      begin
        SendDisconnectClient(bStation);
        bStation.LinkedStation.Head := False;
        onUpdateStationR415(bStation.LinkedStation);
      end;

      onRemoveStationR415(bStation);
      Clients.Remove(bStation);
      Update;
      Exit(True);
    end;
    Exit(False);
  end;

function THandlerStationR415.RegistrationClient(Request: TRequest;
    Connection: TIdTCPConnection): Boolean;
  var
    bStationR415: TStationR415;
    Name: string;
  begin
    Name := Request.GetValue('username');
    bStationR415 := TStationR415.Create;
    if (Connection <> nil)
      and (Length(Name) > 0)
      and (CheckUserName(Name)) then
    begin
      bStationR415.UserName := Name;
      bStationR415.Connection := Connection;
      Clients.Add(bStationR415);
      SendOkClient(bStationR415);
      onAddStationR415(bStationR415);
      Update;
      Exit(True);

    end;
    Exit(False);
  end;

end.
