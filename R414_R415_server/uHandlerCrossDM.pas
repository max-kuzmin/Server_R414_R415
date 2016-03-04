unit uHandlerCrossDM;

interface

uses
  uClientDM,
  Generics.Collections,
  IdTCPConnection,
  SyncObjs,
  SysUtils,
  uRequestDM,
  uCrossDM,
  uHandlerClientDM;

type

  THandlerCross = class (THandlerClient)
    private
        FOnAddCross: TAddRemoveUpdateClientEvent;
        FOnRemoveCross: TAddRemoveUpdateClientEvent;
        FonUpdateCross: TAddRemoveUpdateClientEvent;
        procedure FindLinkedStation;
    public
        function RegistrationClient(Request: TRequest;Connection: TIdTCPConnection): Boolean;
        function RemoveClient(Connection: TIdTCPConnection):Boolean;
        procedure SendDisconnectClient(Cross: TCross);
        function FindByConnection (Connection: TIdTCPConnection): TCross;

        function SendParamsLinkedStationByConnection
        (Connection: TIdTCPConnection; Request: TRequest): Boolean;
        function SendParamsLinkedCrossByConnection
        (Connection: TIdTCPConnection; Request: TRequest): Boolean;

        procedure Update;
        procedure SendUserNameToStation(Station: TClient);
        procedure SendUserNameToCross(Cross: TCross);
        procedure SendUserNameAnotherCrossToCross(Cross: TCross);
        procedure SendTextMessageLinkedStation(Cross: TCross; txtMeessage:string);
        procedure sendSetUstSvaziLinkedStation(Cross: TCross; ustSvaz: string);
        property onAddCross: TAddRemoveUpdateClientEvent
          read FOnAddCross
          write FOnAddCross;
        property onRemoveCross: TAddRemoveUpdateClientEvent
          read FOnRemoveCross
          write FOnRemoveCross;
        property onUpdateCross: TAddRemoveUpdateClientEvent
          read FonUpdateCross
          write FonUpdateCross;

  end;

implementation

uses
uStationR414DM;


  procedure THandlerCross.sendSetUstSvaziLinkedStation(Cross: TCross; ustSvaz: string);
  var Request: TRequest;
  begin
   if Cross <> nil then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_UST_SVAZI;
      Request.AddKeyValue(KEY_TYPE, 'r415');            // Тип клиента

      Request.AddKeyValue(KEY_SVAZ_SET, ustSvaz);

      if Cross.LinkedStation <> nil then
      begin
        Cross.LinkedStation.SendMessage(Request);
      end;
      Request.Destroy;
    end;
  end;


    /// <summary>
  /// Передает клиенту текстовое сообщение для чата
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  /// <param name="txtMeessage">Текстовое сообщение для отправки</param>
  procedure THandlerCross.SendTextMessageLinkedStation(Cross: TCross; txtMeessage:string);
  var Request: TRequest;
  begin
    if Cross <> nil then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_TEXT_MESSAGE;
      Request.AddKeyValue(KEY_TYPE, 'r415');            // Тип клиента

      Request.AddKeyValue(KEY_TEXT,txtMeessage);        // Наши ключ и значение
      if Cross.LinkedStation <> nil then
      begin
        Cross.LinkedStation.SendMessage(Request);
      end;
      Request.Destroy;
    end;
  end;



    /// <summary>
  /// Сообщение с ником станции для кросса
  /// </summary>
  procedure THandlerCross.SendUserNameToCross(Cross: TCross);
  var Request: TRequest;
  begin
    if ((Cross <> nil) and (Cross.LinkedStation <> nil)) then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_STATION_PARAMS;
      Request.AddKeyValue(KEY_TYPE, CLIENT_STATION_R414);
      Request.AddKeyValue(KEY_CONNECTED, BoolToStr(KEY_CONNECTED_TRUE));
      Request.AddKeyValue(KEY_USERNAME, (Cross.LinkedStation as TStationR414).UserName);
      Cross.SendMessage(Request);
      Request.Destroy;
    end;
  end;

      /// <summary>
  /// Сообщение с ником кросса для станции
  /// </summary>
    procedure THandlerCross.SendUserNameToStation(Station: TClient);
  var Request: TRequest;
  begin
    if ((Station <> nil) and ((Station as TStationR414).Cross <> nil)) then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_STATION_PARAMS;
      Request.AddKeyValue(KEY_TYPE, CLIENT_CROSS);
      Request.AddKeyValue(KEY_CONNECTED, BoolToStr(KEY_CONNECTED_TRUE));
      Request.AddKeyValue(KEY_USERNAME, (Station as TStationR414).Cross.UserName);
      (Station as TStationR414).SendMessage(Request);
      Request.Destroy;
    end;
  end;


  /// <summary>
  /// Сообщение с ником чужого кросса для кросса
  /// </summary>

    procedure THandlerCross.SendUserNameAnotherCrossToCross(Cross: TCross);
  var Request: TRequest;
  begin
    if ((Cross <> nil) and (Cross.LinkedCross <> nil)) then
    begin
      Request := TRequest.Create;
      Request.Name := REQUEST_NAME_STATION_PARAMS;
      Request.AddKeyValue(KEY_TYPE, CLIENT_CROSS);
      Request.AddKeyValue(KEY_CONNECTED, BoolToStr(KEY_CONNECTED_TRUE));
      Request.AddKeyValue(KEY_USERNAME, (Cross.LinkedCross as TCross).UserName);
      Cross.SendMessage(Request);
      Request.Destroy;
    end;
  end;


    /// <summary>
  /// Ищет не связанные станции и производит их связывание.
  /// </summary>
  procedure THandlerCross.FindLinkedStation;
  var
    i, j: Integer;
  begin
    for i := 0 to Count - 1 do
    begin
      for j := 0 to Count - 1 do
      begin
          if (Clients.Items[j] is TStationR414) and ((Clients.Items[j] as TStationR414).Cross = nil)
            and (Clients.Items[i] is TCross) and ((Clients.Items[i] as TCross).LinkedStation = nil)
            and (i <> j) then
          begin
            Section.Enter;

            (Clients.Items[j] as TStationR414).Cross :=
              (Clients.Items[i] as TCross);
            (Clients.Items[i] as TCross).LinkedStation :=
              (Clients.Items[j] as TStationR414);

            //связываем кроссы двух станций
            if (((Clients.Items[j] as TStationR414).LinkedStation<>nil) and ((Clients.Items[j] as TStationR414).LinkedStation.Cross<>nil)) then
            begin
              (Clients.Items[i] as TCross).LinkedCross := ((Clients.Items[j] as TStationR414).LinkedStation.Cross as TCross);
              ((Clients.Items[j] as TStationR414).LinkedStation.Cross as TCross).LinkedCross:= (Clients.Items[i] as TCross);

              SendUserNameAnotherCrossToCross(Clients.Items[i] as TCross);
              onUpdateCross(Clients.Items[i] as TCross);

              SendUserNameAnotherCrossToCross((Clients.Items[i] as TCross).LinkedCross);
              onUpdateCross((Clients.Items[i] as TCross).LinkedCross);
            end;


            SendUserNameToStation(Clients.Items[j] as TStationR414);
            SendUserNameToCross(Clients.Items[i] as TCross);

            onUpdateCross((Clients.Items[j] as TStationR414));
            onUpdateCross((Clients.Items[i] as TCross));

            Section.Leave;
            Break;
          end;
      end;
    end;
  end;

  /// <summary>
  /// Производит обновление.
  /// </summary>
  procedure THandlerCross.Update;
  begin
    FindLinkedStation;
  end;

  /// <summary>
  /// Передает станции сообщение об отключении кросса.
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  procedure THandlerCross.SendDisconnectClient(Cross: TCross);
  var
    Request: TRequest;
  begin
    Request := TRequest.Create;
    Request.Name := REQUEST_NAME_STATION_PARAMS;
    Request.AddKeyValue(KEY_TYPE, CLIENT_CROSS);

    Request.AddKeyValue(KEY_USERNAME, Cross.UserName);
    Request.AddKeyValue(KEY_CONNECTED, BoolToStr(KEY_CONNECTED_FALSE));

    if Cross.LinkedStation <> nil then
    begin
      Cross.LinkedStation.SendMessage(Request);
    end;
    if Cross.LinkedCross <> nil then
    begin
      Cross.LinkedCross.SendMessage(Request);
    end;
  end;


      /// <summary>
  /// Производит поиск клиента по подключению.
  /// </summary>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  function THandlerCross.FindByConnection (Connection: TIdTCPConnection):
     TCross;
  var
    Client: TClient;
  begin
    Client := inherited FindByConnection(Connection);
    if ((Client <> nil) and (Client is TCross)) then
    begin
      Exit((Client as TCross))
    end;
    Exit(nil);
  end;



    /// <summary>
  /// Передает данные станции.
  /// </summary>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  /// <param name="Request">Запрос полученный от главной станции.</param>
  function THandlerCross.SendParamsLinkedStationByConnection
        (Connection: TIdTCPConnection; Request: TRequest): Boolean;
  var
    Cross: TCross;
  begin
    Cross := FindByConnection(Connection);
    if (Cross <> nil)
      and (Cross.LinkedStation <> nil)
      then
    begin
      Cross.LinkedStation.SendMessage(Request);
      Exit(True);
    end;
    Exit(False);
  end;


   /// <summary>
  /// Передает данные кроссу.
  /// </summary>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  /// <param name="Request">Запрос полученный от главной станции.</param>
  function THandlerCross.SendParamsLinkedCrossByConnection
        (Connection: TIdTCPConnection; Request: TRequest): Boolean;
  var
    Cross: TCross;
  begin
    Cross := FindByConnection(Connection);
    if (Cross <> nil)
      and (Cross.LinkedCross <> nil)
      then
    begin
      Cross.LinkedCross.SendMessage(Request);
      Exit(True);
    end;
    Exit(False);
  end;




    /// <summary>
  /// Производит удаление кросса из списка.
  /// </summary>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  function THandlerCross.RemoveClient(Connection: TIdTCPConnection):
    Boolean;
  var
    bCross: TCross;
  begin
    bCross := FindByConnection(Connection);
    if bCross <> nil then
    begin
      if bCross.LinkedStation <> nil then
      begin
        (bCross.LinkedStation as TStationR414).Cross := nil;
        SendDisconnectClient(bCross);
        onUpdateCross(bCross.LinkedStation);
      end;

      onRemoveCross(bCross);
      Clients.Remove(bCross);
      Update;
      Exit(True);
    end;
    Exit(False);
  end;

  function THandlerCross.RegistrationClient(Request: TRequest;
    Connection: TIdTCPConnection): Boolean;
  var
    cross: TCross;
    Name: string;
  begin
    Name := Request.GetValue('username');
    cross := TCross.Create;
    if (Connection <> nil)
      and (Length(Name) > 0)
      and (CheckUserName(Name)) then
    begin
      cross.UserName := Name;
      cross.Connection := Connection;
      Clients.Add(cross);
      SendOkClient(cross);
      onAddCross(cross);
      Update;
      Exit(True);

    end;
    Exit(False);
  end;


  end.
