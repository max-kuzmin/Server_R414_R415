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


  THandlerStationR414 = class (THandlerClient)
    private


      FOnAddStationR414: TAddRemoveUpdateClientEvent;
      FOnRemoveStationR414: TAddRemoveUpdateClientEvent;
      FonUpdateStationR414: TAddRemoveUpdateClientEvent;

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

      property onAddStationR414: TAddRemoveUpdateClientEvent
        read FOnAddStationR414
        write FOnAddStationR414;
      property onRemoveStationR414: TAddRemoveUpdateClientEvent
        read FOnRemoveStationR414
        write FOnRemoveStationR414;
      property onUpdateStationR414: TAddRemoveUpdateClientEvent
        read FonUpdateStationR414
        write FonUpdateStationR414;
  end;

implementation

uses
uCrossDM;

  /// <summary>
  /// �������� ������� ��������� � ���� �������(�������/�����������).
  /// </summary>
  /// <param name="StationR414">������ ������ TStationR414.</param>
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
  /// �������� ������� ��������� � �������� ����������� �������.
  /// </summary>
  /// <param name="StationR414">������ ������ TStationR414.</param>
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
  /// �������� ������� ��������� � ���������� �������.
  /// </summary>
  /// <param name="StationR414">������ ������ TStationR414.</param>
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
  /// ���������� ����� ������� �� �����������.
  /// </summary>
  /// <param name="Connection">������ ������ TIdTCPConnection.</param>
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
  /// ���������� �������� ������� �� ������.
  /// </summary>
  /// <param name="Connection">������ ������ TIdTCPConnection.</param>
  function THandlerStationR414.RemoveClient(Connection: TIdTCPConnection):
    Boolean;
  var
    bStation: TStationR414;
    Request: TRequest;
  begin
    bStation := FindByConnection(Connection);
    if bStation <> nil then
    begin
      bStation.Head := False;
      if bStation.LinkedStation <> nil then
      begin
        bStation.LinkedStation.Head := False;
        bStation.LinkedStation.LinkedStation := nil;
        SendDisconnectClient(bStation);
        bStation.LinkedStation.Head := False;
        onUpdateStationR414(bStation.LinkedStation);
      end

      else if bStation.Cross <> nil then
      begin
          (bStation.Cross as TCross).LinkedStation := nil;

          //��������� ������ �� ���������� �������
          Request := TRequest.Create;
          Request.Name := REQUEST_NAME_STATION_PARAMS;
          Request.AddKeyValue(KEY_TYPE, CLIENT_STATION_R414);
          Request.AddKeyValue(KEY_USERNAME, bStation.UserName);
          Request.AddKeyValue(KEY_CONNECTED, BoolToStr(KEY_CONNECTED_FALSE));
          (bStation.Cross as TCross).SendMessage(Request);

          onUpdateStationR414(bStation.Cross);
      end;

      onRemoveStationR414(bStation);
      Clients.Remove(bStation);
      Update;
      Exit(True);
    end;
    Exit(False);
  end;

  /// <summary>
  /// �������� ������ �� ������� ������� �����������.
  /// </summary>
  /// <param name="Connection">������ ������ TIdTCPConnection.</param>
  /// <param name="Request">������ ���������� �� ������� �������.</param>
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
  /// ��������� � ������ ����� ������� (������ ������ TStationR414).
  /// </summary>
  /// <param name="Name">��� ������������ (�������� �������).</param>
  /// <param name="Connection">������ ������ TIdTCPConnection.</param>
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
  /// ���������� ����������.
  /// </summary>
  procedure THandlerStationR414.Update;
  begin
    FindLinkedStation;
  end;

  /// <summary>
  /// ���� �� ��������� ������� � ���������� �� ����������.
  /// </summary>
  procedure THandlerStationR414.FindLinkedStation;
  var
    i, j: Integer;
    Request: TRequest;
  begin
    for i := 0 to Count - 1 do
    begin
        for j := 0 to Count - 1 do
        begin
          if (Clients.Items[j] is TStationR414) and ((Clients.Items[j] as TStationR414).LinkedStation = nil)
            and (Clients.Items[i] is TStationR414) and ((Clients.Items[i] as TStationR414).LinkedStation = nil)
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

            onUpdateStationR414((Clients.Items[i] as TStationR414));
            onUpdateStationR414((Clients.Items[j] as TStationR414));

            Section.Leave;
            Break;
          end
          //���������� � �������
          else if (Clients.Items[j] is TCross) and ((Clients.Items[j] as TCross).LinkedStation = nil)
            and (Clients.Items[i] is TStationR414) and ((Clients.Items[i] as TStationR414).Cross = nil)
            and (i <> j) then
          begin
            Section.Enter;

            (Clients.Items[i] as TStationR414).Cross :=
              (Clients.Items[j] as TCross);
            (Clients.Items[j] as TCross).LinkedStation :=
              (Clients.Items[i] as TStationR414);

            //��������� � ����� ��� �������
            Request := TRequest.Create;
            Request.Name := REQUEST_NAME_STATION_PARAMS;
            Request.AddKeyValue(KEY_TYPE, CLIENT_CROSS);
            Request.AddKeyValue(KEY_CONNECTED, BoolToStr(KEY_CONNECTED_TRUE));
            Request.AddKeyValue(KEY_USERNAME, (Clients.Items[i] as TStationR414).Cross.UserName);
            (Clients.Items[i] as TStationR414).SendMessage(Request);
            Request.Destroy;

            //��������� � ����� ��� �������
            Request := TRequest.Create;
            Request.Name := REQUEST_NAME_STATION_PARAMS;
            Request.AddKeyValue(KEY_TYPE, CLIENT_STATION_R414);
            Request.AddKeyValue(KEY_CONNECTED, BoolToStr(KEY_CONNECTED_TRUE));
            Request.AddKeyValue(KEY_USERNAME, (Clients.Items[j] as TCross).LinkedStation.UserName);
            (Clients.Items[j] as TCross).SendMessage(Request);
            Request.Destroy;


            onUpdateStationR414((Clients.Items[j] as TCross));
            onUpdateStationR414((Clients.Items[i] as TStationR414));

            Section.Leave;
            Break;
          end;
      end;
    end;
  end;

      /// <summary>
  /// �������� ������� ���������
  /// </summary>
  /// <param name="StationR414">������ ������ TStationR414.</param>
  procedure THandlerStationR414.SendChatMessage(StationR414:
    TStationR414; Response: TRequest);
  begin
    if StationR414 <> nil then
    begin
      StationR414.SendMessage(Response);
    end;
  end;

end.
