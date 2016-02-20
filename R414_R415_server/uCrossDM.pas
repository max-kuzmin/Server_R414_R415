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
      FLinkedCross : TCross;

    public
      property Head: Boolean read FHead write FHead;
      property LinkedStation : TClient read FLinkedStation
        write FLinkedStation;
      property LinkedCross : TCross read FLinkedCross
        write FLinkedCross;

  end;

implementation

end.
