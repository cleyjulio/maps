unit map.example;

interface

uses
   System.Types, System.UITypes, System.JSON, System.SysUtils, System.Math, System.Generics.Collections, System.Sensors.Components, System.Classes,
   System.Sensors,

   FMX.Maps, FMX.StdCtrls, FMX.Controls, FMX.Forms, FMX.Objects,

   FireDAC.Comp.Client, FireDAC.Stan.Param;

  Type TMapExample = class

  type TTesterecord = Record
  End;

  TPolyArray = TArray<TMapPolygon>;
  TMarkersArray = Array of TMapMarker;
  TLineArray = Array of TMapPolyline;

  private

  class function CenterPolyline(arrPoints: TArray<TMapCoordinate>): TMapCoordinate;
  class procedure MkrName(coords: TMapCoordinate; Name: String; Map: TMapView; RecNameTh: TRectangle; lblNameTh: TLabel; var Names: TMarkersArray);
  class procedure LineDistance(coord1, coord2: TMapCoordinate; Map: TMapView; var aList: TLineArray);
  class function ReadJson(number: smallint): TJSONObject;

  public

  class function SetSensor(Sensor: TLocationSensor): TLocationSensor;

  class procedure ChangeMarker(Mkr: TMapMarker; Map: TMapView; RecNameTh: TRectangle; lblNameTh: TLabel; var Names: TMarkersArray);

  class function RemovePolygons(var aList: TPolyArray): TPolyArray;
  class function RemoveMarkers(var mList: TMarkersArray): TMarkersArray;
  class procedure SetVisibleMarkers(mList: TMarkersArray; Visible: Boolean);
  class procedure SetVisibleLine(mList: TLineArray; Visible: Boolean);
  class function RemoveLine(aList: TLineArray): TLineArray;

  class procedure Distance(LookAt, Position: TMapCoordinate; Map: TMapView; lblDistancia: TLabel; var aList: TLineArray); overload;

  class procedure ShowPolygon(LookAt, Position: TMapCoordinate; var arrPoints: TArray<TMapCoordinate>; Map: TMapView;
  RecNameTh: TRectangle; LblDistance, lblNameTh: TLabel; var arrPols: TArray<TMapPolygon>; var aList: array of TMapPolyline;
  var Names: TMapExample.TMarkersArray);

  class procedure BuildPolygon(var Map: TMapView; RecNameTh: TRectangle; LblDistance, lblNameTh: TLabel;
  Name: String; LookAt, Position: TMapCoordinate; var arrPols: TPolyArray;
  var arrPoints: TArray<TMapCoordinate>; var aList: array of TMapPolyline;
  var Names: TMarkersArray);

end;

implementation

uses System.IOUtils;

{ TMapsttivos }

class procedure TMapExample.BuildPolygon(var Map: TMapView; RecNameTh: TRectangle; LblDistance, lblNameTh: TLabel; Name: String; LookAt,
  Position: TMapCoordinate; var arrPols: TPolyArray; var arrPoints: TArray<TMapCoordinate>; var aList: array of TMapPolyline;
  var Names: TMarkersArray);

var descPolygon: TMapPolygonDescriptor;
begin

  try

    Map.BeginUpdate;

    {polygon (utiliza os pontos lidos do Json)}
    descPolygon := TMapPolygonDescriptor.Create(arrPoints);

    {Caracteristicas}
    descPolygon.StrokeColor := TAlphaColor($96FFA500);
    descPolygon.StrokeWidth := 6;
    descPolygon.Geodesic := false;
    descPolygon.ZIndex := 0.0;
    descPolygon.fillcolor := TAlphaColor($96FFA500);

    {Adicionar ao mapa}
    arrPols := arrPols + [Map.AddPolygon(descPolygon)];

    {centralizar o mapa (calculado aprox. a partir dos pontos)}
    LookAt := CenterPolyline(arrPoints);
    Map.Location := LookAt;
    Map.Zoom := 13;

    {Adiciona o nome do talhao ao poligono}
    MkrName(LookAt, Name, Map, RecNameTh, lblNameTh, Names);

    Map.EndUpdate;

  except
    Map.Visible := false;
  end;

end;

class function TMapExample.CenterPolyline(arrPoints: TArray<TMapCoordinate>): TMapCoordinate;
var
  tLat, tLon: double;
  i, j: integer;
begin

  i := Length(arrPoints);
  tLat := 0;
  tLon := 0;

  for j := Low(arrPoints) to High(arrPoints) do
  begin

    tLat := tLat + arrPoints[j].Latitude;
    tLon := tLon + arrPoints[j].Longitude;

  end;

  Result.Latitude := tLat / i;
  Result.Longitude := tLon / i;

end;

class procedure TMapExample.ChangeMarker(Mkr: TMapMarker; Map: TMapView; RecNameTh: TRectangle; lblNameTh: TLabel; var Names: TMarkersArray);
var Mkr_New: TMapMarkerDescriptor;
    i: smallint;
    s: string;
begin

  Map.BeginUpdate;

  Mkr_New := Mkr.Descriptor;
  Mkr.Remove;
  i := Pos('S', Mkr_New.Snippet);

  if i > 0 then
  begin
    s := Mkr_New.Snippet;
    RecNameTh.Fill.color := TAlphaColorRec.White;
    Delete(s, i, 1);
    Mkr_New.Snippet := s;
  end
  else
  begin

    RecNameTh.Fill.color := TAlphaColorRec.Yellow;
    Mkr_New.Snippet := Mkr_New.Snippet + 'S';

  end;

  lblNameTh.Text := Mkr.Descriptor.Title;

  Mkr_New.Icon := RecNameTh.MakeScreenshot;
  Names := Names + [Map.AddMarker(Mkr_New)];

  Map.EndUpdate;

end;

class function TMapExample.ReadJson(number: smallint): TJSONObject;
var arq: TStringList;
    s: String;
begin

  //Ler JSON KML
  arq := TStringList.Create;
  arq.LoadFromFile(TPath.GetDocumentsPath + PathDelim + 'th' + number.ToString + '.json');
  s := arq.Text;
  Result := TJSONObject.ParseJSONValue(s) as TJSONObject;
  arq.Free;

end;

class function TMapExample.RemoveLine(aList: TLineArray): TLineArray;
var i: integer;
begin

  if High(aList) > -1 then
    for i := 0 to High(aList) do
      if Assigned(aList[i]) then
        aList[i].Remove;

  result := aList;

end;

class procedure TMapExample.Distance(LookAt, Position: TMapCoordinate; Map: TMapView; lblDistancia: TLabel; var aList: TLineArray);
const
  diameter = 2 * 6371.0;
var
  dx, dy, dz, r, long1, lat1, lat2: double;
  unidade: string;
begin

  long1 := degtorad(LookAt.Longitude - Position.Longitude);
  lat1 := degtorad(LookAt.Latitude);
  lat2 := degtorad(Position.Latitude);

  dz := sin(lat1) - sin(lat2);
  dx := cos(long1) * cos(lat1) - cos(lat2);
  dy := sin(long1) * cos(lat1);

  r := (arcsin(sqrt(sqr(dx) + sqr(dy) + sqr(dz)) / 2) * diameter) * 1000;

  if r >= 1000 then
  begin
    r := r / 1000;
    unidade := ' Km';
  end
  else
    unidade := ' m';

  lblDistancia.Text := FormatFloat('#,##0.00', r) + unidade;

  LineDistance(LookAt, Position, Map, aList);

end;

class procedure TMapExample.LineDistance(coord1, coord2: TMapCoordinate; Map: TMapView; var aList: TLineArray);
var AB : TMapPolylineDescriptor;
begin

  AB := TMapPolylineDescriptor.Create([coord1, coord2]);
  AB.StrokeColor := TAlphaColorRec.Blue;
  AB.Geodesic := True;
  AB.StrokeWidth := 5;

  SetLength(aList, Length(aList) + 1);
  aList[high(aList)] := Map.AddPolyline(AB);

end;

class procedure TMapExample.MkrName(coords: TMapCoordinate; Name: String; Map: TMapView; RecNameTh: TRectangle;
  lblNameTh: TLabel; var Names: TMarkersArray);

var MyMarker : TMapMarkerDescriptor;
begin

  Map.BeginUpdate;
  Map.Visible := True;
  Map.Location := TMapCoordinate(coords);
  MyMarker := TMapMarkerDescriptor.Create(coords, Name);
  MyMarker.Title := Name;
  MyMarker.Draggable := false;
  MyMarker.Visible := True;
  lblNameTh.Text := Name;
  RecNameTh.Fill.color := TAlphaColorRec.White;
  MyMarker.Icon := RecNameTh.MakeScreenshot;

  Names := Names + [Map.AddMarker(MyMarker)];

  Map.EndUpdate;

end;

class function TMapExample.RemoveMarkers(var mList: TMarkersArray): TMarkersArray;
var i: integer;
begin

  try

    for i := 0 to Pred(Length(mList)) do
    begin
      mList[i].Remove;
      mList[i] := nil;
    end;

  except
  end;

  Result := mList;

end;

class function TMapExample.RemovePolygons(var aList: TPolyArray): TPolyArray;
var i: integer;
begin

  Result := aList;
  try

    for i := 0 to Pred(Length(aList)) do
    begin
        aList[i].Remove;
        aList[i].Free;
        aList[i] := nil;
    end;

  except
  end;

  Result := aList;

end;

class function TMapExample.SetSensor(Sensor: TLocationSensor): TLocationSensor;
begin

  Sensor.Accuracy := 0.0001;
  Sensor.Distance := 0.0001;
  Sensor.ActivityType := TLocationActivityType.Automotive;
  Sensor.LocationChange := TLocationChangeType.lctSmall;
  Sensor.Optimize := True;
  Sensor.UsageAuthorization := TLocationUsageAuthorization.WhenInUse;
  Sensor.Active := True;
  Result := Sensor;

end;

class procedure TMapExample.SetVisibleLine(mList: TLineArray; Visible: Boolean);
var i: integer;
begin

  try

    for i := 0 to Pred(Length(mList)) do
      mList[i].SetVisible(Visible);

  except
  end;

end;

class procedure TMapExample.SetVisibleMarkers(mList: TMarkersArray; Visible: Boolean);
var i: integer;
begin

  try

    for i := 0 to Pred(Length(mList)) do
      mList[i].SetVisible(Visible);

  except
  end;

end;

class procedure TMapExample.ShowPolygon(LookAt, Position: TMapCoordinate; var arrPoints: TArray<TMapCoordinate>; Map: TMapView;
  RecNameTh: TRectangle; LblDistance, lblNameTh: TLabel; var arrPols: TArray<TMapPolygon>; var aList: array of TMapPolyline;
  var Names: TMapExample.TMarkersArray);

  var Kml, Coordenada, Look: TJSONObject;
  Coordenadas: TJsonArray;
  i, j: integer;
  name: String;

begin

  Kml := nil;

  try

    for i := 1 to 2 do
    begin

      Kml := ReadJson(i);

      if Assigned(Kml) then
      begin

        Look := (Kml.GetValue('kml') As TJSONObject).GetValue('lookAt') As TJSONObject;

        LookAt.Latitude := StringReplace(Look.GetValue('latitude').Value, '.', ',', [rfReplaceAll]).ToDouble;
        LookAt.Longitude := StringReplace(Look.GetValue('longitude').Value, '.', ',', [rfReplaceAll]).ToDouble;
        Name := (Kml.GetValue('kml') As TJSONObject).GetValue('nome').ToString;
        Coordenadas := (Kml.GetValue('kml') As TJSONObject).GetValue('coordenadas') As TJsonArray;

        SetLength(arrPoints, Coordenadas.Count);

        for j := 0 to Coordenadas.Count - 1 do
        begin

          Coordenada := Coordenadas.Items[j] As TJSONObject;
          arrPoints[j].Latitude := StringReplace(Coordenada.GetValue('latitude').Value, '.', ',', [rfReplaceAll]).ToDouble;
          arrPoints[j].Longitude := StringReplace(Coordenada.GetValue('longitude').Value, '.', ',', [rfReplaceAll]).ToDouble;

        end;

        BuildPolygon(Map, RecNameTh, LblDistance, lblNameth, Name, LookAt, Position, arrPols, arrPoints, aList, Names);

        end;

    end;

    Kml.Free;

  except
    Kml.Free;
  end;

end;

end.
