unit uKeyValueDM;

interface

uses
  SysUtils;

type
  TKeyValue = class
    private
      FKey: string;
      FValue: string;
    public
      property Key: string read FKey write FKey;
      property Value: string read FValue write FValue;
  end;
implementation

end.
