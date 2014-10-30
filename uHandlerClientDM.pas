unit uHandlerClientDM;

interface

uses
  uClientDM,
  IdTCPConnection,
  Generics.Collections,
  uRequestDM,
  SyncObjs;

type
  THandlerClient = class
    protected
       Section: TCriticalSection;
       Clients: TList<TClient>;
    public
      constructor Create;
      function FindByConnection(Connection: TIdTCPConnection): TClient;
        overload;
      function CheckUserName(Name: string): Boolean;
      function GetCount: Integer;
      function GetAllClients: TRequest;
      property Count: Integer read GetCount;
      function GetClient(Index: Integer): TClient;
      procedure SendOkClient(Client: TClient);
      procedure Clear;
  end;

implementation

  /// <summary>
  /// Конструктор.
  /// </summary>
  constructor THandlerClient.Create;
  begin
    Clients := TList<TClient>.Create;
    Section := TCriticalSection.Create;
  end;

  /// <summary>
  /// Очистка списка списка станций.
  /// </summary>
  procedure THandlerClient.Clear;
  begin
    Clients.Clear;
  end;

  /// <summary>
  /// Передает клиенту сообщение о успешном выполнении операции.
  /// </summary>
  /// <param name="Client">Объект класса TClient.</param>
  procedure THandlerClient.SendOkClient(Client: TClient);
  var
    Request: TRequest;
  begin
    Request := TRequest.Create;
    Request.Name := REQUEST_NAME_OK;
    Client.SendMessage(Request);
    Request.Destroy;
  end;

  /// <summary>
  /// Производит поиск клиента по подключению.
  /// </summary>
  /// <param name="Connection">Объект класса TIdTCPConnection.</param>
  function THandlerClient.FindByConnection (Connection: TIdTCPConnection):
     TClient;
  var
    i:Integer;
  begin
    for i := 0 to Clients.Count - 1 do
    begin
      if Clients.Items[i].Connection = Connection then
        Exit(Clients.Items[i]);
    end;
    Exit(nil);
  end;

  /// <summary>
  /// Производит проверку существования пользователя по его имени.
  /// </summary>
  /// <param name="Name">Имя пользователя.</param>
  function THandlerClient.CheckUserName(Name: string): Boolean;
  var
    i:Integer;
  begin
    for i := 0 to Count - 1 do
    begin
      if Clients.Items[i].UserName = Name then
        Exit(False);
    end;
    Exit(True);
  end;

  /// <summary>
  /// Возвращает количество элементов в списке.
  /// </summary>
  function THandlerClient.GetCount: Integer;
  begin
    Exit(Clients.Count);
  end;

  /// <summary>
  /// Формирует список станций и отправляет клиенту.
  /// </summary>
  /// <param name="Connection">Соединение с клиентом.</param>
  function THandlerClient.GetAllClients: TRequest;
  var
    i:Integer;
    Response: TRequest;
  begin
    Response := TRequest.Create;
    Response.Name := REQUEST_NAME_GET_ALL_STATIONS;
    for i := 0 to Count - 1 do
    begin
      Response.AddKeyValue('username', Clients.Items[i].UserName);
    end;
    Exit(Response);
  end;

  /// <summary>
  /// Возвращает объект класса TStationR414 по номеру в списке.
  /// </summary>
  /// <param name="Index">Номер в списке.</param>
  function THandlerClient.GetClient(Index: Integer): TClient;
  begin
    try
      Exit(Clients.Items[Index]);
    except
      Exit(nil);
    end;
  end;

end.
