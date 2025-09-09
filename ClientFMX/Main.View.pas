unit Main.View;
// Run the Server first in-order our Demo works..
interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Layouts,
  FMX.Memo.Types,
  FMX.Controls.Presentation,
  FMX.ScrollBox,
  FMX.Memo, FMX.Objects,

//
  IdBaseComponent, IdComponent, IdGlobal, IdSocketHandle,
//
  IdUDPBase, IdUDPClient, IdUDPServer;

type
  TMainView = class(TForm)
    Lyt_Root: TLayout;
    Lyt_Top: TLayout;
    Lyt_Bottom: TLayout;
    Lyt_TitleApp: TLayout;
    Lyt_Toolbar: TLayout;
    MemoLog: TMemo;
    TimerSendBroadcastHelp: TTimer;
    TxtTitleApp: TText;
    procedure TimerSendBroadcastHelpTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    fUDPClient: TIdUDPClient;
    fUDPServerRead: TIdUDPServer;

    fRouterDeviceIPv4Host,
    fServerBroadcastHost: string;

    procedure UDPSendBroadcastHelp(const aBMsg: string);

    procedure UDPServerOnRead(
      aThread: TIdUDPListenerThread;
      const aData: TIdBytes; aBinding: TIdSocketHandle);

    procedure Log(const aSender, aLog: string);
  end;

var
  MainView: TMainView;
// On Mobile you must handle permission first!!
// This three bellow uses for our broadcast works:
// ACCESS_NETWORK_STATE,ACCESS_WIFI_STATE,INTERNET
//
//This bellow my deployed manifest permissions list:
(*
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CALL_PHONE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_PHONE_STATE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
*)
implementation
uses
  System.Generics.Collections
  {$IFDEF MSWINDOWS}
, Winapi.Windows
, Winapi.Winsock2
, Winapi.IpHlpApi
, Winapi.IpTypes
  {$ENDIF}
  {$IFDEF ANDROID}
, Androidapi.JNIBridge
, Androidapi.JNI.JavaTypes
, Androidapi.JNI.Net
, Androidapi.JNI.Java.Net
, Androidapi.JNI.GraphicsContentViewText
, Androidapi.Helpers
  {$ENDIF};

{$R *.fmx}

function GetPrimaryIPv4: string;
{$IFDEF MSWINDOWS}
var
  LDestAddr: ULONG;
  LBestIfIndex: DWORD;
  LAdapterInfo, LpAdapter: PIP_ADAPTER_ADDRESSES;
  LOutBufLen: ULONG;
  LRetVal: ULONG;
  LpUnicast: PIP_ADAPTER_UNICAST_ADDRESS;
  LPSockAddrIn: PSockAddrIn;
 {$ENDIF}
{$IFDEF ANDROID}
var
  NetworkInterfaces: JEnumeration;
  NetIf: JNetworkInterface;
  AddrEnum: JEnumeration;
  InetAddr: JInetAddress;
{$ENDIF}
begin
  Result := '127.0.0.1'; // fallback

{$IFDEF MSWINDOWS}

  // remote target to determine the best interface
  LDestAddr := inet_addr(PAnsiChar(AnsiString('8.8.8.8')));

  if GetBestInterface(LDestAddr, LBestIfIndex) <> NO_ERROR then
    Exit;

  // first call to learn required buffer size
  LOutBufLen := 0;
  LRetVal := GetAdaptersAddresses(AF_INET, 0, nil, nil, @LOutBufLen);
  if (LRetVal <> ERROR_BUFFER_OVERFLOW) and (LOutBufLen = 0) then
    Exit;

  GetMem(LAdapterInfo, LOutBufLen);
  try
    LRetVal := GetAdaptersAddresses(AF_INET, 0, nil, LAdapterInfo, @LOutBufLen);
    if LRetVal = NO_ERROR then
    begin
      LpAdapter := LAdapterInfo;
      while LpAdapter <> nil do
      begin
        // NOTE: IfIndex is inside the Union field in this Delphi declaration
        if LpAdapter^.Union.IfIndex = LBestIfIndex then
        begin
          LpUnicast := LpAdapter^.FirstUnicastAddress;
          while LpUnicast <> nil do
          begin
            if (LpUnicast^.Address.lpSockaddr.sa_family = AF_INET) then
            begin
              LPSockAddrIn := PSockAddrIn(LpUnicast^.Address.lpSockaddr);
              Result := string(inet_ntoa(LPSockAddrIn^.sin_addr));
              Exit;
            end;
            LpUnicast := LpUnicast^.Next; // <-- you were missing this
          end;
        end;
        LpAdapter := LpAdapter^.Next;
      end;
    end;
  finally
    FreeMem(LAdapterInfo);
  end;
 {$ENDIF}

 {$IFDEF ANDROID}

  NetworkInterfaces := TJNetworkInterface.JavaClass.getNetworkInterfaces;
  while NetworkInterfaces.hasMoreElements do
  begin
    NetIf := TJNetworkInterface.Wrap(NetworkInterfaces.nextElement);
    if (NetIf = nil) or not(NetIf.isUp) or NetIf.isLoopback then
      Continue;

    AddrEnum := NetIf.getInetAddresses;
    while AddrEnum.hasMoreElements do
    begin
      InetAddr := TJInetAddress.Wrap(AddrEnum.nextElement);
      if (InetAddr <> nil) and (not InetAddr.isLoopbackAddress) then
      begin
        // only pick IPv4 (skip IPv6)
        if (InetAddr.getHostAddress.indexOf(StringToJString(':')) < 0) then
        begin
          Result := JStringToString(InetAddr.getHostAddress);
          Exit;
        end;
      end;
    end;
  end;
  {$ENDIF}
end;

{ TMainView }

procedure TMainView.Log(const aSender, aLog: string);
begin
  TThread.Queue(nil, procedure begin
    if Assigned(MemoLog) then begin
      MemoLog
        .Lines
        .Add(Format('[%s]%s ->:%s', [FormatDateTime('hh:nn:ss', Now), aSender, aLog]));
      MemoLog.GoToTextEnd;
    end;
  end);
end;

procedure TMainView.FormCreate(Sender: TObject);
begin
  fRouterDeviceIPv4Host := GetPrimaryIPv4();
  fServerBroadcastHost := '127.0.0.1';

// create UDP client for Sending Broadcast Discovery Help to All Devices in any interface
// with this Message for ex:
// (Hello, I'm Here, is there Any UDP Broadcaster there ?)
//then our Udp Server Broadcaster is Listenning then will reply faster..
  fUDPClient := TIdUDPClient.Create(Self);
  try
    fUDPClient.BroadcastEnabled := True;
    fUDPClient.Port := 3434;   // send to server port
    fUDPClient.BoundPort := 0; // let OS choose ephemeral
    fUDPClient.BoundIP := fRouterDeviceIPv4Host;  // force binding to real LAN IP
    fUDPClient.Host := '255.255.255.255'; //Broadcast Host ..
  finally
    fUDPClient.Active := True;
  end;

// create UDP server for listening Udp Server Broadcaster Reply
// Like this : ( 'DISCOVERY|UDPServerIPAdresse' )
// Then Bingo, our TCP Client can easilly now use that serverIP Automatically..
  fUDPServerRead := TIdUDPServer.Create(Self);
  try
    fUDPServerRead.DefaultPort := 22049; // This mustbe Always diff from the broadcast port !!
    fUDPServerRead.OnUDPRead := UDPServerOnRead;
    fUDPServerRead.Bindings.Clear;
    with fUDPServerRead.Bindings.Add do
    begin
      IP := fRouterDeviceIPv4Host; // Listen just from RouterDeviceiIPv4Host Interface ..
      Port := 22049;
    end;
    fUDPServerRead.BroadcastEnabled := False; // No need to be true here...
  finally
    fUDPServerRead.Active := True;
  end;

  TxtTitleApp.Text := TxtTitleApp.Text +': '+ GetPrimaryIPv4();
  TimerSendBroadcastHelp.Enabled := True;
end;

procedure TMainView.UDPSendBroadcastHelp(const aBMsg: string);
var
  LBMsg: TIdBytes;
begin
  LBMsg := IndyTextEncoding_UTF8.GetBytes(aBMsg);
  fUDPClient.Send(aBMsg);
end;

procedure TMainView.TimerSendBroadcastHelpTimer(Sender: TObject);
begin
  UDPSendBroadcastHelp('Discovery|Hello, I''m Here, is there Any UDP Broadcaster there?');
  TimerSendBroadcastHelp.Enabled := False;
  // Note:
  // The timer can loop for every 2Sec ..
  // Since my setup here in both Server/Client is
  // So Logic, no need for a loop
  // But if something happen on your devices
  // Try the loop timer or send me your situation problem here:
  // mben.13011@gmail.com
end;

procedure TMainView.UDPServerOnRead(
  aThread: TIdUDPListenerThread;
  const aData: TIdBytes; aBinding: TIdSocketHandle);
var
  LMsg: string;
begin
  fServerBroadcastHost := aBinding.PeerIP;
  Log('UDP Has', 'packet received from ' + fServerBroadcastHost);

  LMsg := IndyTextEncoding_UTF8.GetString(aData);
  Log('UDP Server', LMsg);
end;

end.
