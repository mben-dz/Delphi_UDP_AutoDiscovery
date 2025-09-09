unit Main.View;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
//
  IdBaseComponent, IdComponent, IdGlobal, IdSocketHandle,
//
  IdUDPBase, IdUDPServer;

type
  TMainView = class(TForm)
    MemoLog: TMemo;
    procedure FormCreate(Sender: TObject);
  private
    fUDPServer: TIdUDPServer;
    fRouterDeviceIPv4Host: string;

    procedure UDPServerOnRead(
      aThread: TIdUDPListenerThread;
      const aData: TIdBytes; aBinding: TIdSocketHandle);

    procedure Log(const aSender, aLog: string);
  end;

implementation
uses
  Winapi.Winsock2, Winapi.IpHlpApi, Winapi.IpTypes;

{$R *.dfm}

function GetPrimaryIPv4: string;
var
  LDestAddr: ULONG;
  LBestIfIndex: DWORD;
  LAdapterInfo, LpAdapter: PIP_ADAPTER_ADDRESSES;
  LOutBufLen: ULONG;
  LRetVal: ULONG;
  LpUnicast: PIP_ADAPTER_UNICAST_ADDRESS;
  LPSockAddrIn: PSockAddrIn;
begin
  Result := '127.0.0.1';

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
end;

{ TMainView }

procedure TMainView.Log(const aSender, aLog: string);
begin
  TThread.Queue(nil, procedure begin
    if Assigned(MemoLog) then
      MemoLog
        .Lines
        .Add(Format('[%s]%s ->:%s', [FormatDateTime('hh:nn:ss', Now), aSender, aLog]));
  end);
end;

procedure TMainView.FormCreate(Sender: TObject);
begin
  fRouterDeviceIPv4Host := GetPrimaryIPv4();

// create UDP server for listening Udp Clients Broadcasts..
  fUDPServer := TIdUDPServer.Create(Self);
  fUDPServer.DefaultPort := 3434;
  fUDPServer.OnUDPRead := UDPServerOnRead;
  fUDPServer.Bindings.Clear;
  with fUDPServer.Bindings.Add do
  begin
    IP := '0.0.0.0'; // Listen from All Interfaces ..
    Port := 3434;
  end;
  fUDPServer.BroadcastEnabled := True;
  fUDPServer.Active := True;

  Caption := Caption + fRouterDeviceIPv4Host;
end;

procedure TMainView.UDPServerOnRead(
  aThread: TIdUDPListenerThread;
  const aData: TIdBytes; aBinding: TIdSocketHandle);
var
  LClientPeerIP: string;
  LMsg: string;

  LReply: string;
  LBytes: TIdBytes;
begin
  LClientPeerIP := aBinding.PeerIP;
  Log('UDP Has', 'packet received from ' + LClientPeerIP);

  LMsg := IndyTextEncoding_UTF8.GetString(aData);
  Log('UDP Client Said', LMsg);

  // Build Server reply..
  LReply := 'DISCOVERY|' + fRouterDeviceIPv4Host;

  // Convert string -> bytes
  LBytes := IndyTextEncoding_UTF8.GetBytes(LReply);

  // Send reply back to the sender (PeerIP + PeerPort)
  aBinding.SendTo(
    LClientPeerIP,
    22049,  // reply to the port the client used
    LBytes
  );
end;

end.
