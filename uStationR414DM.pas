unit uStationR414DM;

interface

uses
  uClientDM;
const
  CLIENT_STATION_R414 = 'r414';
  STATION_STATUS_MAIN = 'main';
  STATION_STATUS_SUBORDINATE = 'subordinate';

type
  TStationR414 = class (TClient)
    private
      FHead: Boolean;
      FCross: TClient;
      FStationR415: TClient;
      FLinkedStation : TStationR414;
    public
      property Head: Boolean read FHead write FHead;
      property Cross: TCLient read FCross write FCross;
      property StationR415: TCLient read FStationR415 write FStationR415;
      property LinkedStation : TStationR414 read FLinkedStation
        write FLinkedStation;
  end;
implementation

end.
