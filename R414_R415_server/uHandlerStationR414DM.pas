unit uHandlerStationR414DM;

interface

uses
  uClientDM,
  Generics.Collections,
  IdTCPConnection,
  SyncObjs,
  SysUtils,
  uRequestDM,
  uStationR414DM,
  uHandlerClientDM;

type
   TAddRemoveUpdateStationR414Event =
    procedure(StationR414: TStationR414) of object;

  THandlerStationR414 = class (THandlerClient)
    private


      FOnAddStationR414: TAddRemoveUpdateStationR414Event;
      FOnRemoveStationR414: TAddRemoveUpdateStationR414Event;
      FonUpdateStationR414: TAddRemoveUpdateStationR414Event;

      procedure FindLinkedStation;
    public
      procedure Update;
      function FindByConnection (Connection: TIdTCPConnection): TStationR414;
        overload;
      function RegistrationClient(Request: TRequest;
        Connection: TIdTCPConnection):
        Boolean;
      function RemoveClient(Connection: TIdTCPConnection): Boolean;
      function SendParamsLinkedStationByHeadConnection
        (Connection: TIdTCPConnection; Request: TRequest): Boolean;
      procedure SendDisconnectClient(StationR414: TStationR414);
      procedure SendUserNameLinkedStation(StationR414: TStationR414);
      procedure SendTypeStation(StationR414: TStationR414);
        procedure SendChatMessage(StationR414:
    TStationR414; Response: TRequest);

      property onAddStationR414: TAddRemoveUpdateStationR414Event
        read FOnAddStationR414
        write FOnAddStationR414;
      property onRemoveStationR414: TAddRemoveUpdateStationR414Event
        read FOnRemoveStationR414
        write FOnRemoveStationR414;
      property onUpdateStationR414: TAddRemoveUpdateStationR414Event
        read FonUpdateStationR414
        write FonUpdateStationR414;
  end;

implementation

  /// <summary>
  /// Передает клиенту сообщение о типе клиента(главный/подчиненный).
  /// </summary>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  procedure THandlerStationR414.SendTypeStation(StationR414: TStationR414);
  var Request: TRequest;
  begin
    if StationR414 <> nil then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_STATION_PARAMS;
      Request.AddKeyValue(KEY_TYPE, VALUE_SERVER);
      if StationR414.Head then
        Request.AddKeyValue(KEY_STATUS, STATION_STATUS_MAIN)
      else
        Request.AddKeyValue(KEY_STATUS,STATION_STATUS_SUBORDINATE);
      StationR414.SendMessage(Request);
      Request.Destroy;
    end;
  end;

  /// <summary>
  /// Передает клиенту сообщение с позывным сопряженной станции.
  /// </summary>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  procedure THandlerStationR414.SendUserNameLinkedStation(StationR414:
    TStationR414);
  var Request: TRequest;
  begin
    if StationR414 <> nil then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_STATION_PARAMS;
      Request.AddKeyValue(KEY_TYPE, CLIENT_STATION_R414);
      Request.AddKeyValue(KEY_CONNECTED, BoolToStr(KEY_CONNECTED_TRUE));
      Request.AddKeyValue(KEY_USERNAME, StationR414.LinkedStation.UserName);
      StationR414.SendMessage(Request);
      Request.Destroy;
    end;
  end;

  /// <summary>
  /// Передает клиенту сообщение о отключении клиента.
  /// </summary>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  procedure THandlerStationR414.SendDisconnectClient(StationR414: TStationR414);
  var
    Request: TRequest;
  begin
    Request := TRequest.Create;
    Request.Name := REQUEST_NAME_STATION_PARAMS;
    Request.AddKeyValue(KEY_TYPE, CLIENT_STATION_R414);

    Request.AddKeyValue(KEY_USERNAME, StationR414.UserName);
    Request.AddKeyValue(KEY_CONNECTED, BoolToStr(KEY_CONNECTED_FALSE));
    if StationR414.LinkedStation <> nil then
    begin
      StationR414.LinkedStation.SendMessage(Request);
    end;
  end;

  /// <summary>
  /// Производит поиск клиента по подключению.
  /// </summary>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  function THandlerStationR414.FindByConnection (Connection: TIdTCPConnection):
     TStationR414;
  var
    Client: TClient;
  begin
    Client := inherited FindByConnection(Connection);
    if Client <> nil then
    begin
      Exit((Client as TStationR414))
    end;
    Exit(nil);
  end;

  /// <summary>
  /// Производит удаление станции из списка.
  /// </summary>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  function THandlerStationR414.RemoveClient(Connection: TIdTCPConnection):
    Boolean;
  var
    bStation: TStationR414;
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
        onUpdateStationR414(bStation.LinkedStation);
      end;

      onRemoveStationR414(bStation);
      Clients.Remove(bStation);
      Update;
      Exit(True);
    end;
    Exit(False);
  end;

  /// <summary>
  /// Передает данные от главной станции подчиненной.
  /// </summary>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  /// <param name="Request">Запрос полученный от главной станции.</param>
  function THandlerStationR414.SendParamsLinkedStationByHeadConnection
        (Connection: TIdTCPConnection; Request: TRequest): Boolean;
  var
    StationR414: TStationR414;
  begin
    StationR414 := FindByConnection(Connection);
    if (StationR414 <> nil)
      and (StationR414.LinkedStation <> nil)
      //and (StationR414.Head)
      then
    begin
      StationR414.LinkedStation.SendMessage(Request);
      Exit(True);
    end;
    Exit(False);
  end;

  /// <summary>
  /// Добавляет в список новую станцию (объект класса TStationR414).
  /// </summary>
  /// <param name="Name">Имя пользователя (позывной станции).</param>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  function THandlerStationR414.RegistrationClient(Request: TRequest;
    Connection: TIdTCPConnection): Boolean;
  var
    bStationR414: TStationR414;
    Name: string;
    ClientType: string;
  begin
    Name := Request.GetValue('username');
    bStationR414 := TStationR414.Create;
    if (Connection <> nil)
      and (Length(Name) > 0)
      and (CheckUserName(Name)) then
    begin
      bStationR414.UserName := Name;
      bStationR414.Connection := Connection;
      Clients.Add(bStationR414);
      SendOkClient(bStationR414);
      onAddStationR414(bStationR414);
      Update;
      Exit(True);

    end;
    Exit(False);
  end;

  /// <summary>
  /// Производит обновление.
  /// </summary>
  procedure THandlerStationR414.Update;
  begin
    FindLinkedStation;
  end;

  /// <summary>
  /// Ищет не связанные станции и производит их связывание.
  /// </summary>
  procedure THandlerStationR414.FindLinkedStation;
  var
    i, j: Integer;
  begin
    for i := 0 to Count - 1 do
    begin
      if (Clients.Items[i] as TStationR414).LinkedStation = nil then
      begin
        for j := 0 to Count - 1 do
        begin
          if ((Clients.Items[j]as TStationR414).LinkedStation = nil)
            and (Clients.Items[i] <> Clients.Items[j])
            and (i <> j) then
          begin
            Section.Enter;

            (Clients.Items[j] as TStationR414).LinkedStation :=
              (Clients.Items[i] as TStationR414);
            (Clients.Items[i] as TStationR414).LinkedStation :=
              (Clients.Items[j] as TStationR414);

            (Clients.Items[j] as TStationR414).Head := True;
            SendTypeStation((Clients.Items[j] as TStationR414));

            (Clients.Items[i] as TStationR414).Head := False;
            SendTypeStation((Clients.Items[i] as TStationR414));

            SendUserNameLinkedStation((Clients.Items[j] as TStationR414));

            SendUserNameLinkedStation((Clients.Items[i] as TStationR414));

            onUpdateStationR414((Clients.Items[j] as TStationR414));
            onUpdateStationR414((Clients.Items[i] as TStationR414));

            Section.Leave;
            Break;
          end;
        end;
      end;
    end;
  end;

      /// <summary>
  /// Передает клиенту сообщение
  /// </summary>
  /// <param name="StationR414">Объект класса TStationR414.</param>
  procedure THandlerStationR414.SendChatMessage(StationR414:
    TStationR414; Response: TRequest);
  begin
    if StationR414 <> nil then
    begin
      StationR414.SendMessage(Response);
    end;
  end;

end.
