unit uStationR415DM;

interface

uses
  uClientDM;
const
  CLIENT_STATION_R415 = 'r415';
  STATION_STATUS_MAIN = 'main';
  STATION_STATUS_SUBORDINATE = 'subordinate';

type
  TStationR415 = class (TClient)
    private
      FHead: Boolean;
      FCross: TClient;
      FStationR415: TClient;
      FLinkedStation : TStationR415;
      FFinish : boolean;
    public
      property Head: Boolean read FHead write FHead;
      property Cross: TCLient read FCross write FCross;
      property StationR415: TCLient read FStationR415 write FStationR415;
      property LinkedStation : TStationR415 read FLinkedStation
        write FLinkedStation;
      property AnotherFinish: boolean read FFinish write FFinish;
  end;
implementation

end.
