program Maps_Example;

uses
  System.StartUpCopy,
  FMX.Forms,
  uApp in 'uApp.pas' {frmApp},
  map.example in 'map.example.pas',
  ufrMap in 'ufrMap.pas' {frMap: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmApp, frmApp);
  Application.Run;
end.
