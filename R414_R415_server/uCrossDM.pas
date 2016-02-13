unit uCrossDM;

interface

uses
  uClientDM;

const
  CLIENT_CROSS = 'cross';
  STATION_STATUS_MAIN = 'main';
  STATION_STATUS_SUBORDINATE = 'subordinate';
type
  TCross = class (TClient)
    private
      FHead: Boolean;
      FLinkedStation : TClient;

    public
      property Head: Boolean read FHead write FHead;
      property LinkedStation : TClient read FLinkedStation
        write FLinkedStation;

  end;

implementation

end.
