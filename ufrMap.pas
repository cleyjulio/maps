unit ufrMap;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Sensors, System.Sensors.Components,

  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, FMX.Maps,

  map.example, Skia, Skia.FMX;

type
  TfrMap = class(TFrame)
    MapView: TMapView;
    RecInfo: TRectangle;
    lblDistance: TLabel;
    Label1: TLabel;
    RecNameArea: TRectangle;
    lblNameTh: TLabel;
    Layout6: TLayout;
    Label5: TLabel;
    lblAltitude: TLabel;
    Line5: TLine;
    SwitchMarkers: TSwitch;
    Label2: TLabel;
    LocationSensor: TLocationSensor;
    BarraTitulo: TRectangle;
    procedure FramePainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure MapViewMarkerClick(Marker: TMapMarker);
    procedure LocationSensorLocationChanged(Sender: TObject; const OldLocation, NewLocation: TLocationCoord2D);
    procedure FramePaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure SwitchMarkersSwitch(Sender: TObject);
    procedure btnBackClick(Sender: TObject);

  public
    {MANIPULAÇÃO DE MAPA}
    LookAt, Position: TMapCoordinate;
    outLinePolygon: TMapPolygonPolyvertex;
    mapPolygon: TMapExample.TPolyArray;
    LineDistance: TMapExample.TLineArray;
    Names: TMapExample.TMarkersArray;
    procedure CloseMap;

  end;

implementation

{$R *.fmx}

procedure TfrMap.btnBackClick(Sender: TObject);
begin
  CloseMap;
end;

procedure TfrMap.CloseMap;
begin

  try

    LocationSensor.Active := False;
    MapView.DestroyComponents;
    MapView.Destroy;
    FreeAndNil(Self);

  except
    Self.Visible := False;
  end;

end;

procedure TfrMap.FramePaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  LocationSensor.Active := True;
end;

procedure TfrMap.FramePainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin

  RecNameArea.Visible := False;

end;

procedure TfrMap.LocationSensorLocationChanged(Sender: TObject; const OldLocation, NewLocation: TLocationCoord2D);
begin

  Position.Latitude := NewLocation.Latitude;
  Position.Longitude := NewLocation.Longitude;
  lblAltitude.Text := FormatFloat('#,##0.00', LocationSensor.Sensor.Altitude) + ' m';

end;

procedure TfrMap.MapViewMarkerClick(Marker: TMapMarker);
begin

  if not RecInfo.Visible then
    RecInfo.Visible := True;

  TMapExample.ChangeMarker(Marker, MapView, RecNameArea, lblNameTh, Names);
  lblDistance.Text := '';
  TMapExample.Distance(Marker.Descriptor.Position, Position, MapView, lblDistance, LineDistance);

end;

procedure TfrMap.SwitchMarkersSwitch(Sender: TObject);
begin
  TMapExample.SetVisibleMarkers(Names, SwitchMarkers.IsChecked);
end;

end.
