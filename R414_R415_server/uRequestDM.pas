unit uRequestDM;

interface

uses
  uKeyValueDM,
  Generics.Collections;

const
  REQUEST_NAME_OK = 'ok';
  REQUEST_NAME_ERROR = 'error';
  REQUEST_NAME_REGISTRATION = 'registration';
  REQUEST_NAME_GET_ALL_STATIONS = 'getallstations';
  REQUEST_NAME_STATION_PARAMS = 'params';
  REQUEST_NAME_TEXT_MESSAGE = 'message';
  REQUEST_NAME_WAVES = 'wave';
  REQUEST_NAME_UST_SVAZI = 'svaz';
  REQ_NAME_GEN_ACT = 'gener';

  REQUEST_NAME_GEN_ACT = 'gener';
  REQ_NAME_FINISH_ACT = 'finish';
  KEY_FINISH = 'finish';

  KEY_TYPE = 'type';
  KEY_USERNAME = 'username';
  KEY_CONNECTED = 'connected';
  KEY_STATUS = 'status';
  KEY_TEXT = 'txt';
  KEY_SVAZ_SET = 'set';
  KEY_GENERATE = 'state';
  KEY_CONNECTED_FALSE = false;
  KEY_CONNECTED_TRUE = true;

  KEY_TRANSMITTER_WAVE_A = 'twavea';
  KEY_RECEIVER_WAVE_A = 'rwavea';

  VALUE_SERVER = 'server';
type
  TRequest = class
    private
      FKeyValueList: TList<TKeyValue>;
      FName: string;
    public
      property Name: string read FName write FName;
      function ReadCount: Integer;
      procedure AddKeyValue (Key: string; Value: string);
      property Count : Integer read ReadCount;
      function ConvertToText: string;
      function GetKeyValue(Index: Integer): TKeyValue;
      procedure ConvertToKeyValueList (Text: string);
      function GetValue(Key: string): string;
      constructor Create; reintroduce;
      destructor Destroy; override;
      procedure Clear;

  end;
implementation

  /// <summary>
  /// Производит очистку параметров запроса.
  /// </summary>
  procedure TRequest.Clear;
  begin
    FKeyValueList.Clear;
    Name := '';
  end;

  /// <summary>
  /// Деструктор.
  /// </summary>
  destructor TRequest.Destroy;
  begin
    FKeyValueList.Free;
    inherited;
  end;

  /// <summary>
  /// Преобразует текстовое представление запроса в объектное(парсер).
  /// </summary>
  /// <param name="Text">Тестовое представление запроса.</param>
  procedure TRequest.ConvertToKeyValueList(Text: string);
  var
    len: Integer;
    key: string;
  begin
    len := Pos(':', Text);
    if len > 0 then
    begin
      Name := Copy(Text, 1, len - 1);
      Delete(Text, 1, len);
      while True do
      begin
        if Length(Text) > 0 then
        begin
          len := Pos('=', Text);
          if len > 0 then
          begin
            key := Copy(Text, 1, len - 1);
            if Length(key) > 0 then
            begin
              Delete(Text, 1, len);
              len := Pos(',', Text);
              if len = 0 then
              begin
                AddKeyValue(key, Text);
                Break;
              end
              else
              begin
                AddKeyValue(key, Copy(Text, 1, len - 1));
                Delete(Text, 1, len);
                key := '';
              end;
            end
            else
            begin
              Break;
            end;
          end;
        end
        else
        begin
          Break;
        end;
      end;
    end;
  end;

  /// <summary>
  /// Возвращает значение по ключу.
  /// </summary>
  /// <param name="Key">Имя ключа.</param>
  function TRequest.GetValue(Key: string): string;
  var
    i:Integer;
  begin
    for i := 0 to Count - 1 do
    begin
      if Key = GetKeyValue(i).Key then
        Exit(GetKeyValue(i).Value);
    end;
    Exit('');
  end;

  /// <summary>
  /// Возвращает количество ключей.
  /// </summary>
  function TRequest.ReadCount: Integer;
  begin
    Exit(FKeyValueList.Count);
  end;

  /// <summary>
  /// Возвращает обеъкт класса TKeyValue по индексу в списке.
  /// </summary>
  function TRequest.GetKeyValue(Index: Integer): TKeyValue;
  begin
    if (Index >= 0) and (Index < Count) then
    begin
      Exit(FKeyValueList.Items[Index]);
    end
    else
      Exit(nil);
  end;

  /// <summary>
  /// Преобразует объектное представление запроса в строку.
  /// </summary>
  /// <returns>Текстовое представление запроса.</returns>
  function TRequest.ConvertToText;
  var
    i: Integer;
    strResult: string;
  begin
    if Length(Name) > 0 then
    begin
      strResult := Name + ':';
      for i := 0 to Count - 1 do
      begin
        if i >= 1 then
        begin
          strResult := strResult + ',';
        end;
        strResult := strResult + FKeyValueList.Items[i].Key + '='
          + FKeyValueList.Items[i].Value;
      end;
      Exit(strResult);
    end;
  end;

  /// <summary>
  /// Конструктор класса.
  /// </summary>
  constructor TRequest.Create;
  begin
    FKeyValueList := TList<TKeyValue>.Create;
  end;

  /// <summary>
  /// Добавляет новую запись ключ=значение в список.
  /// </summary>
  /// <param name="Key">Ключ.</param>
  /// <param name="Value">Значение.</param>
  procedure TRequest.AddKeyValue(Key: string; Value: string);
  var
    bKeyValue : TKeyValue;
  begin
    bKeyValue := TKeyValue.Create;
    bKeyValue.Key := Key;
    bKeyValue.Value:= Value;
    FKeyValueList.Add(bKeyValue);
  end;

end.
