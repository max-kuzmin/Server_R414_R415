object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = #1056#1072#1076#1080#1086#1088#1077#1083#1077#1081#1085#1072#1103' '#1089#1090#1072#1085#1094#1080#1103' '#1056'414 ('#1089#1077#1088#1074#1077#1088')'
  ClientHeight = 333
  ClientWidth = 820
  Color = clBtnFace
  Constraints.MinHeight = 371
  Constraints.MinWidth = 836
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    820
    333)
  PixelsPerInch = 96
  TextHeight = 13
  object pgc: TPageControl
    Left = 8
    Top = 8
    Width = 804
    Height = 317
    ActivePage = tsSettingsAndEventLog
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    object tsSettingsAndEventLog: TTabSheet
      Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080' '#1080' '#1078#1091#1088#1085#1072#1083' '#1089#1086#1073#1099#1090#1080#1081
      DesignSize = (
        796
        289)
      object grpEventLog: TGroupBox
        Left = 3
        Top = 58
        Width = 790
        Height = 228
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = #1046#1091#1088#1085#1072#1083' '#1089#1086#1073#1099#1090#1080#1081
        TabOrder = 1
        DesignSize = (
          790
          228)
        object mmoEventLog: TMemo
          Left = 3
          Top = 19
          Width = 784
          Height = 206
          Anchors = [akLeft, akTop, akRight, akBottom]
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object grpSettings: TGroupBox
        Left = 0
        Top = 3
        Width = 793
        Height = 49
        Anchors = [akLeft, akTop, akRight]
        Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
        TabOrder = 0
        DesignSize = (
          793
          49)
        object lblPort: TLabel
          Left = 3
          Top = 19
          Width = 33
          Height = 16
          Caption = #1055#1086#1088#1090':'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
        end
        object lblMaxConnection: TLabel
          Left = 111
          Top = 19
          Width = 245
          Height = 16
          Caption = #1052#1072#1082#1089#1080#1084#1072#1083#1100#1085#1086#1077' '#1082#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1081':'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
        end
        object btnStartStopServer: TButton
          Left = 675
          Top = 16
          Width = 115
          Height = 25
          Anchors = [akTop, akRight]
          Caption = #1047#1072#1087#1091#1089#1090#1080#1090#1100' '#1089#1077#1088#1074#1077#1088
          TabOrder = 2
          OnClick = btnStartStopServerClick
        end
        object edtPort: TEdit
          Left = 42
          Top = 16
          Width = 63
          Height = 21
          NumbersOnly = True
          TabOrder = 0
          Text = '2106'
        end
        object edtMaxConnections: TEdit
          Left = 362
          Top = 16
          Width = 63
          Height = 21
          NumbersOnly = True
          TabOrder = 1
          Text = '50'
        end
      end
    end
    object tsUserTable: TTabSheet
      Caption = #1057#1087#1080#1089#1086#1082' '#1087#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1077#1081
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      DesignSize = (
        796
        289)
      object strngrdUsers: TStringGrid
        Left = 3
        Top = 3
        Width = 790
        Height = 283
        Anchors = [akLeft, akTop, akRight, akBottom]
        ColCount = 7
        FixedCols = 0
        RowCount = 1
        FixedRows = 0
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSizing, goColSizing, goRowSelect]
        TabOrder = 0
        ColWidths = (
          64
          130
          109
          127
          122
          117
          109)
        RowHeights = (
          24)
      end
    end
  end
end
