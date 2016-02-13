unit uServerDM;

interface

uses
  IdContext,
  IdTCPStream,
  SyncObjs,
  SysUtils,
  IdTCPConnection,
  Generics.Collections,
  uClientDM,
  IdTCPServer,
  IdGlobal,
  IdSocketHandle,
  Classes,
  uRequestDM,
  uHandlerStationR414DM,
  uHandlerStationR415DM,
  uHandlerCrossDM,
  uStationR414DM,
  uStationR415DM,
  uCrossDM,Dialogs;


type
  TAddRemoveUpdateClient = procedure (StationR414: TStationR414;
    StationR415: TStationR415; Cross: TCross) of object;

  TServer = class
    private
      Connections: TList<TIdTCPConnection>;

      FOnAddClient: TAddRemoveUpdateClient;
      FOnRemoveClient: TAddRemoveUpdateClient;
      FonUpdateClient: TAddRemoveUpdateClient;

      HandlerStationR414: THandlerStationR414;
      HandlerStationR415: THandlerStationR415;
      HandlerCross: THandlerCross;

      Section: TCriticalSection;
      TCPServer: TIdTCPServer;

      Clients: TList<TClient>;

      procedure ServerConnect(AContext: TIdContext);
      procedure ServerDisconnect(AContext: TIdContext);
      procedure ServerExecute(AContext: TIdContext);
      procedure MessageParser(Connection: TIdTCPConnection;
        StrRequest : string);
      procedure RegisterClient (Connection : TIdTCPConnection;
        Request: TRequest);
      procedure SendMessage(Connection: TIdTCPConnection;
        Request: TRequest);overload;
      function SendMessage(Client: TClient; Request: TRequest):
        Boolean; overload;
      procedure AddClient(Connection: TIdTCPConnection);
      procedure Clear;
    public
      constructor Create (Port : TIdPort; MaxConnections : Integer);
      function GetStatusServer : Boolean;
      property StatusServer : Boolean read GetStatusServer;
      procedure StartServer;
      procedure StopServer;
      function ReadPort: Integer;
      procedure WritePort(Value: Integer);
      function ReadMaxConnections: Integer;
      procedure WriteMaxConnections(Value: Integer);

      procedure DoOnAddClient(Client: TClient);
      procedure DoOnRemoveClient(Client: TClient);
      procedure DoOnUpdateClient(Client: TClient);

      property Port: Integer read ReadPort write WritePort;
      property MaxConnections: Integer read ReadMaxConnections
        write WriteMaxConnections;

      property onAddClient: TAddRemoveUpdateClient
      read FOnAddClient write FOnAddClient;
      property onRemoveClient: TAddRemoveUpdateClient
      read FOnRemoveClient write FOnRemoveClient;
      property onUpdateClient: TAddRemoveUpdateClient
      read FonUpdateClient write FonUpdateClient;

  end;

implementation
  /// <summary>
  /// Конструктор класса.
  /// </summary>
  /// <param name="Port">Порт сервера.</param>
  /// <param name="MaxConnections">Максимальное количество подключений.</param>
  constructor TServer.Create (Port : TIdPort; MaxConnections : Integer);
  begin
    TCPServer := TIdTCPServer.Create(nil);
    if (Port > 0) and (Port < 65535) then
      TCPServer.DefaultPort := Port
    else
      TCPServer.DefaultPort := 2106;

    if MaxConnections > 0 then
      TCPServer.MaxConnections := MaxConnections
    else
      TCPServer.MaxConnections:= 1;
    Section := TCriticalSection.Create;

    Connections := TList<TIdTCPConnection>.Create;
    Clients:= TList<TClient>.Create();

    HandlerStationR414 := THandlerStationR414.Create(Clients);
    HandlerStationR415 := THandlerStationR415.Create(Clients);
    HandlerCross := THandlerCross.Create(Clients);

    TCPServer.OnConnect := ServerConnect;
    TCPServer.OnDisconnect := ServerDisconnect;
    TCPServer.OnExecute := ServerExecute;

    HandlerStationR414.onAddStationR414 := DoOnAddClient;
    HandlerStationR414.onRemoveStationR414 := DoOnRemoveClient;
    HandlerStationR414.onUpdateStationR414 := DoOnUpdateClient;

    HandlerStationR415.onAddStationR415 := DoOnAddClient;
    HandlerStationR415.onRemoveStationR415 := DoOnRemoveClient;
    HandlerStationR415.onUpdateStationR415 := DoOnUpdateClient;

    HandlerCross.onAddCross := DoOnAddClient;
    HandlerCross.onRemoveCross := DoOnRemoveClient;
    HandlerCross.onUpdateCross := DoOnUpdateClient;
  end;

  /// <summary>
  /// Задает порт сервера.
  /// </summary>
  /// <param name="Value">Значение.</param>
  procedure TServer.WritePort(Value: Integer);
  begin
    TCPServer.DefaultPort := Value;
  end;

  /// <summary>
  /// Возвращает порт сервера.
  /// </summary>
  function TServer.ReadPort;
  begin
    Exit(TCPServer.DefaultPort);
  end;

  /// <summary>
  /// Задает количество соединений сервера.
  /// </summary>
  /// <param name="Value">Значение.</param>
  procedure TServer.WriteMaxConnections(Value: Integer);
  begin
    TCPServer.MaxConnections := Value;
  end;

  /// <summary>
  /// Возвращает максимальное количство подключений.
  /// </summary>
  function TServer.ReadMaxConnections;
  begin
    Exit(TCPServer.MaxConnections);
  end;


  /// <summary>
  /// Вызывает событие onAddClient.
  /// </summary>
  /// <param name="StationR415">Объект класса TStationR415.</param>
  procedure TServer.DoOnAddClient(Client: TClient);
  begin
    if (Client is TStationR414) then onAddClient(Client as TStationR414, nil, nil)
    else if (Client is TStationR415) then onAddClient(nil, Client as TStationR415, nil)
    else  if (Client is TCross) then onAddClient(nil, nil, Client as TCross);
  end;


  /// <summary>
  /// Вызывает событие onRemoveClient.
  /// </summary>
  /// <param name="StationR415">Объект класса TClient.</param>
  procedure TServer.DoOnRemoveClient(Client: TClient);
  begin
    if (Client is TStationR414) then onRemoveClient(Client as TStationR414, nil, nil)
    else if (Client is TStationR415) then onRemoveClient(nil, Client as TStationR415, nil)
    else  if (Client is TCross) then onRemoveClient(nil, nil, Client as TCross);
  end;

  /// <summary>
  /// Вызывает событие onUpdateClient.
  /// </summary>
  /// <param name="StationR414">Объект класса TClient.</param>
  procedure TServer.DoOnUpdateClient(Client: TClient);
  begin
    if (Client is TStationR414) then onUpdateClient(Client as TStationR414, nil, nil)
    else if (Client is TStationR415) then onUpdateClient(nil, Client as TStationR415, nil)
    else  if (Client is TCross) then onUpdateClient(nil, nil, Client as TCross);
  end;


  /// <summary>
  /// Отправляет сообщение клиенту.
  /// </summary>
  /// <param name="Client">
  /// Объект класса TClient.
  /// Клиент, которому необходимо отправить сообщение.
  /// </param>
  /// <param name="Request">
  /// Объект класса TRequest.
  /// Запрос для передачи клиенту.
  /// </param>
  function TServer.SendMessage(Client: TClient; Request: TRequest): Boolean;
  begin
    if Client <> nil then
    begin
      Client.SendMessage(Request);
      Exit(True);
    end;
    Exit(False);
  end;

   /// <summary>
  /// Преобразует запрос в текстовое представление и передает клиенту.
  /// </summary>
  /// <param name="Connection">Соединение с пользователем.</param>
  /// <param name="Request">Объектное представление запроса.</param>
  procedure TServer.SendMessage(Connection: TIdTCPConnection;
        Request: TRequest);
  var
    Client: TClient;
  begin
    if (Request <> nil)
      and (Connection <> nil) then
    begin
      Client := HandlerStationR414.FindByConnection(Connection);

      if Client = nil then
      begin
        Connection.IOHandler.WriteLn(Request.ConvertToText,
          TIdTextEncoding.UTF8);
        Exit;
      end;

      if SendMessage(Client, Request) then Exit;
    end;
  end;

  /// <summary>
  /// Возвращает статус сервера.
  /// </summary>
  function TServer.GetStatusServer : Boolean;
  begin
    Exit(TCPServer.Active);
  end;

  /// <summary>
  /// Запускает сервер.
  /// </summary>
  procedure TServer.StartServer;
  begin
    Clear;
    TCPServer.Active:= True;
  end;

  /// <summary>
  /// Производит очистку списка клиентов.
  /// </summary>
  procedure TServer.Clear;
  begin
    Clients.Clear;
  end;

  /// <summary>
  /// Останавливает сервер.
  /// </summary>
  procedure TServer.StopServer;
  begin
    Clear;
    TCPServer.Scheduler.AcquireYarn;
    TCPServer.Scheduler.ActiveYarns.Clear;
    TCPServer.Active:= False;
  end;

  /// <summary>
  /// Обработчик подключения клиента к серверу.
  /// </summary>
  /// <param name="AContext">Контекст потока.</param>
  procedure TServer.ServerConnect(AContext: TIdContext);
  begin
    AContext.Connection.IOHandler.DefStringEncoding := TIdTextEncoding.UTF8;
    //AddClient(AContext.Connection);
  end;

  /// <summary>
  /// Обработчик отключения клиента от сервера.
  /// </summary>
  /// <param name="AContext">Контекст потока.</param>
  procedure TServer.ServerDisconnect(AContext: TIdContext);
  begin
    HandlerStationR414.RemoveClient(AContext.Connection);
    HandlerStationR415.RemoveClient(AContext.Connection);
    HandlerCross.RemoveClient(AContext.Connection);
  end;

  /// <summary>
  /// Обработчик действий клиента.
  /// </summary>
  /// <param name="AContext">Контекст потока.</param>
  procedure TServer.ServerExecute(AContext: TIdContext);
  begin
    try
      if AContext.Connection.Connected
        and (AContext.Connection.IOHandler <> nil)
        and (AContext.Connection.IOHandler.Connected) then
        MessageParser(AContext.Connection,
          AContext.Connection.IOHandler.ReadLn(TIdTextEncoding.UTF8));
    except

    end;
  end;

  /// <summary>
  /// Добавляет нового клиента в список. Добавление производится по соединению.
  /// </summary>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  procedure TServer.AddClient(Connection: TIdTCPConnection);//TODO: Проверить эту процедуру.
  begin
    try
      Section.Enter;
      Connections.Add(Connection);
      Section.Leave;
    except
      Connection.Disconnect;
    end;
  end;

  /// <summary>
  /// Регистрация клиентов.
  /// </summary>
  /// <param name="Connection">Объект соединения.</param>
  /// <param name="Name">Имя пользователя.</param>
  procedure TServer.RegisterClient (Connection : TIdTCPConnection;
    Request: TRequest);
  var
    Response: TRequest;
    ClientType: string;
  begin
    Response := TRequest.Create;
    ClientType := Request.GetValue('type');
    if Request.GetValue('username') <> '' then
    begin
      if ClientType = CLIENT_STATION_R414 then
      begin
         if HandlerStationR414.RegistrationClient(Request, Connection) then
        Exit;
      end;

      if ClientType = CLIENT_STATION_R415 then
      begin
        if HandlerStationR415.RegistrationClient(Request, Connection) then
        Exit;
      end;

      if ClientType = CLIENT_CROSS then
      begin
        if HandlerCross.RegistrationClient(Request, Connection) then
        Exit;
      end;
    end;

    Response.Name := REQUEST_NAME_ERROR;
    SendMessage(Connection, Response);
  end;

  /// <summary>
  /// Парсер сообщений.
  /// </summary>
  /// <param name="Connection">Объект соединения.</param>
  /// <param name="strMessage">Сообщение полученное от пользователя.</param>
  procedure TServer.MessageParser(Connection: TIdTCPConnection;
    StrRequest : string);
  var
    Request, Response: TRequest;
	PairedStationR414: TStationR414;
  begin
    if Length(StrRequest) > 0 then
    begin
      try
        Response := TRequest.Create;
        Request := TRequest.Create;
        Request.ConvertToKeyValueList(StrRequest);

        if (Request.Name = REQUEST_NAME_REGISTRATION) then
        begin
          RegisterClient(Connection, Request);
        end
        else
        if(Request.Name = REQUEST_NAME_STATION_PARAMS) then
        begin
          if not (HandlerStationR414.SendParamsLinkedStationByHeadConnection(Connection,
            Request)) then
            begin
              Response.Name := REQUEST_NAME_ERROR;
              SendMessage(Connection, Response);
            end;
        end
        else if Request.Name = REQUEST_NAME_GET_ALL_STATIONS then
        begin
          SendMessage(Connection, HandlerStationR414.GetAllClients);
        end
        else
        //обработка текстового сообщения для чата
        if Request.Name = REQUEST_NAME_TEXT_MESSAGE then
        begin
          HandlerStationR415.SendTextMessageLinkedStation(
            HandlerStationR415.FindByConnection(Connection),
            Request.GetValue(KEY_TEXT));
        end
        else
        //обработка пересылки волн
        if Request.Name = REQUEST_NAME_WAVES then
        begin
          HandlerStationR415.SendWavesLinkedStation(
            HandlerStationR415.FindByConnection(Connection),
            Request.GetValue(KEY_TRANSMITTER_WAVE_A),
            Request.GetValue(KEY_RECEIVER_WAVE_A));
        end
        else
        //пересылка готовности ко вхождению в связь
        if Request.Name = REQUEST_NAME_UST_SVAZI then
        begin
          HandlerStationR415.sendSetUstSvaziLinkedStation(
            HandlerStationR415.FindByConnection(Connection),
            Request.GetValue(KEY_SVAZ_SET)
            );
        end
        else

        if Request.Name = REQUEST_NAME_GEN_ACT then
        begin
          HandlerStationR415.sendStateOfGenerate(
            HandlerStationR415.FindByConnection(Connection),
            Request.GetValue(KEY_GENERATE));
        end
        else

        if Request.Name =   REQ_NAME_GEN_ACT  then
        begin

        end
        else

        if Request.Name = REQ_NAME_FINISH_ACT then
        begin
          HandlerStationR415.IsFinished(
            HandlerStationR415.FindByConnection(Connection),
            Request.GetValue(KEY_FINISH));
        end
		
		else if (Request.Name = REQUEST_NAME_TEXT_MESSAGE) then
        begin
			Response.Name:= REQUEST_NAME_TEXT_MESSAGE;
			Response.AddKeyValue(KEY_TEXT, Request.GetValue(KEY_TEXT));
			PairedStationR414:= HandlerStationR414.FindByConnection(Connection).LinkedStation;
			if not (PairedStationR414 = nil) then  begin
					 SendMessage(PairedStationR414, Request);
			end;
		end;

      except

      end;
    end;
  end;

end.
