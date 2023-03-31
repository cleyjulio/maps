unit uApp;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.StrUtils, System.Permissions,

  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.StdCtrls, FMX.DialogService,

  map.example, ufrMap

  {$IFDEF ANDROID}
  ,Posix.Unistd, Androidapi.Helpers, Androidapi.JNI.JavaTypes, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNIBridge, Androidapi.JNI.Os
  {$ENDIF}
  ;


type
  TfrmApp = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    var frMap : TfrMap;
    procedure onTerminateMap(Sender: TObject);

    { Public declarations }
  end;

var
  frmApp: TfrmApp;

implementation

{$R *.fmx}


{$IFDEF ANDROID}
function PermissoesAndroid(tipo : string) : Boolean;
const
  permFineLocation = 'android.permission.ACCESS_FINE_LOCATION';
  permCoarse = 'android.permission.ACCESS_COARSE_LOCATION';
  permBatt = 'android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS';
  permRead = 'android.permission.READ_EXTERNAL_STORAGE';
  permWrite = 'android.permission.WRITE_EXTERNAL_STORAGE';
  permBlue  = 'android.permission.BLUETOOTH';
  permWakeLock = 'android.permission.WAKE_LOCK';
var  permissao, msg : String;
     R : boolean;
begin


  case AnsiIndexStr(UpperCase(tipo), ['PERMFINELOCATION', 'PERMCOARSE', 'PERMBATT', 'PERMREAD', 'PERMWRITE', 'PERMBLUE', 'PERMWAKELOCK']) of

    0 : begin
          permissao := permFineLocation;
          msg := 'Permissão de acesso à localização não foi concedida!'
        end;
    1 : begin
          permissao := permCoarse;
          msg := 'Permissão de acesso à localização aproximada não foi concedida!';
        end;
    2 : begin
          permissao := permBatt;
          msg := 'Permissão para ignorar as opções de otimização de bateria não foi concedida!';
        end;
    3 : begin
          permissao := permRead;
          msg := 'Permissão para ler em armazenamento externo não foi concedida!'
        end;
    4 : begin
          permissao := permWrite;
          msg := 'Permissão para gravar em armazenamento externo não foi concedida!';
        end;
    5 : begin
          permissao := permBlue;
          msg := 'Permissão para acesso ao bluetooth não foi concedida!';
        end;
    6 : begin
          permissao := permWakeLock;
          msg := 'Permissão para o controle da tela acesa não foi concedida!';
        end;

  end;

  PermissionsService.RequestPermissions([permissao],
    procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      if (Length(AGrantResults) = 1) and (AGrantResults[0] = TPermissionStatus.Granted) then
        R := true
      else
      begin
       TDialogService.ShowMessage(msg);
       R := False;
      end;
    end);

    Result := R;

end;
{$ENDIF}

procedure TfrmApp.Button1Click(Sender: TObject);
var LTThread : TThread;
begin


  frMap := TfrMap.Create(Self);

  frMap.Parent := Self;
  frMap.Align := TAlignLayout.Contents;

  frMap.MapView.Visible := false;
  frMap.LocationSensor.Active := True;

  LTThread := TThread.CreateAnonymousThread(procedure()
  begin

    LTThread.Synchronize(tthread.CurrentThread, procedure()
    begin

      TMapExample.ShowPolygon(frMap.LookAt, frMap.Position, frMap.outLinePolygon.Points, frMap.MapView, frMap.RecNameArea, frMap.lblDistance,
        frMap.lblNameTh, frMap.mapPolygon, frMap.LineDistance, frMap.Names);

    end)

  end);

  LTThread.OnTerminate := OnTerminateMap;
  LTThread.Start;

end;

procedure TfrmApp.FormCreate(Sender: TObject);
begin
  {$IFDEF ANDROID}
  PermissoesAndroid('permFineLocation');
  {$ENDIF}
end;

procedure TfrmApp.onTerminateMap(Sender: TObject);
begin

  if Sender is tthread then
  begin
    if Assigned(TThread(Sender).FatalException) then
    begin
      ShowMessage(Exception(TThread(Sender).FatalException).Message);
      exit;
    end;
  end;

  if Assigned(frMap) then
    frMap.Mapview.Visible := True;

end;

end.
