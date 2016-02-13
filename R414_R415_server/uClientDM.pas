unit uClientDM;

interface

uses
  IdTCPConnection,
  uRequestDM,
  IdGlobal;

type
  TClient = class
    private
      FIP : string;
      FUserName : string;
      FConnection : TIdTCPConnection;

    public
      procedure SendMessage(MessageStr: string); overload;
      procedure SendMessage(Request: TRequest); overload;
      procedure WriteConnection (Value : TIdTCPConnection);
      property IP: string read FIP write FIP;
      property UserName: string read FUserName write FUserName;
      property Connection : TIdTCPConnection
        read FConnection write WriteConnection;
  end;

  TAddRemoveUpdateClientEvent =
      procedure(Client: TClient) of object;

implementation

  procedure TClient.WriteConnection(Value: TIdTCPConnection);
  begin
    FConnection:= Value;
    FIP:= Connection.Socket.Binding.IP;
  end;

  /// <summary>
  /// ���������� ��������� ��������� �������.
  /// </summary>
  /// <param name="MessageStr">����� ���������.</param>
  procedure TClient.SendMessage(MessageStr: string);
  begin
    if (Length(MessageStr) > 0) and (Connection <> nil) then
    begin
      Connection.IOHandler.WriteLn(MessageStr, TIdTextEncoding.UTF8);
    end;
  end;

  /// <summary>
  /// ����������� ������ � ��������� ������������� � �������� �������.
  /// </summary>
  /// <param name="Request">��������� ������������� �������.</param>
  procedure TClient.SendMessage(Request: TRequest);
  begin
    if(Request <> nil) then
    begin
      SendMessage(Request.ConvertToText);
    end;
  end;
end.
