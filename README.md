# Delphi Super Fast Tethering UDP AutoDiscovery 🚀

## A simple, cross-platform demo (VCL + FMX) showing how to automatically discover a server on the same LAN using **UDP Broadcast** with Indy components.  

<img width="384" height="256" alt="Delphi UDP Broadcast Auto Discoverypng" src="https://github.com/user-attachments/assets/d56d0308-2076-4640-be63-74696c1047d1" />


https://github.com/user-attachments/assets/496bd6fb-3ddd-4a5f-8d29-c93f14463a53


---  
Please support My youtube Channel here:  
https://www.youtube.com/watch?v=LKOMBXJ3ijk
  
## 📌 Overview

This project demonstrates a lightweight, zero-configuration **auto-discovery mechanism**:
- The **Server** listens on a known UDP port (`3434`) for broadcast packets.
- A **Client** (VCL or FMX/Android) sends a broadcast message (`Discovery|Hello...`) on port `3434`.
- The **Server replies** directly to the client (on port `22049`) with its LAN IP address.
- The **Client receives the reply**, extracts the server’s IP, and can then connect via TCP or continue communication.

This makes it possible to build applications that can **find each other on the same LAN instantly** without manual IP setup.

---

## 🏗 Components Used

- **Indy UDP Components**
  - `TIdUDPServer`
  - `TIdUDPClient`
- **Cross-platform IP detection**
  - Windows: `GetAdaptersAddresses` API
  - Android: `Java.Net.NetworkInterface` enumeration
- **Thread-safe logging** via `TThread.Queue`
- **Timers** to control discovery message sending Loop if needed .

## My Design Philosophy here:
 - Server Side:  
   - Creates a UDP listener on a fixed port (3434 by default).  
   - Waits for broadcast requests with a specific keyword ( `"DISCOVERY|MySecretAppID" `).  
   - Responds to the client only if that client has a UDP server listening on another pre-defined port...  
   - The reply goes to that listening port, not back to the sender’s ephemeral port.  
  
 - Client Side (VCL / FMX):  
   - Uses a UDP server to listen for ServerApp replies on our pre-defined “port”.  
   - Uses a UDP client socket to broadcast a discovery request Help.  
   - The server is forced to reply on our Second agent Socket “UDP server”, and will only reply if the client has a listening UDP server on the agreed-upon port → this is our security + filtering mechanism here.  
   - After receiving the reply, the client knows the TCP server IP/port and can connect quickly.  

# Why it feels “super fast”:  
  - You don’t waste time scanning subnets.  
  - You don’t query all adapters manually. You just blast 255.255.255.255:3434 and whoever is alive responds.  
  - The “secret UDP server” acts as handshake validation, so random broadcasts don’t get replies.  
  - No retries, no handshakes, no multi-round protocols, no user help at all → just one broadcast, one reply.  

---  

## 🔌 How It Works (Step by Step)

### 1. Server Setup
- Binds a UDP server to **port `3434`** (`0.0.0.0`) → listens on all interfaces.
- On receiving a discovery message:
  1. Extracts the **client IP** and **message**.
  2. Prepares a reply like:  
     ```
     DISCOVERY|192.168.1.10
     ```
  3. Sends it **directly back to the agent Udp client’s listening port `22049`**.

➡️ This ensures only our clients receives in general the relevant reply based on second agent UDPServer and without looping broadcasts Methods.

---

### 2. Client Setup
- Creates a UDP client that:
  - Binds to the **local LAN IPv4** (not a virtual adapter) using TIdIPWatch or GStack WILL NOT HELP YOU HERE !!.
```
function GetIP : String;
begin
  TIdStack.IncUsage;
  try
    Result := GStack.LocalAddress;
  finally
    TIdStack.DecUsage;
  end;
end;

function GetLocalIp: string;
var
   IPW: TIdIPWatch;
begin
  IpW := TIdIPWatch.Create(nil);
  try
    if IpW.LocalIP <> '' then
      Result := IpW.LocalIP;
  finally
    IpW.Free;
  end;
end;
```
  - Broadcasts discovery message on **port `3434`**.
- Creates a UDP server (`fUDPServerRead`) that:
  - Listens on **port `22049`** for server replies.
  - Extracts server IP and logs it.

---

### 3. Discovery Flow  

1. Client sends:  
`DISCOVERY|MySecretAppID`
→ to `255.255.255.255:3434`.(this message could be encrypted here & you could add also your random port for your second agent UDPSERVER lISTENER Here..)  

2. Server receives & replies:
`DISCOVERY|192.168.1.100`
→ back to client’s Second Agent UDPServer that listening port is: `22049` (you could make it Random while send it inside the Discovery Request Help Above..).

3. Client receives server’s reply:
`UDP Server 192.168.1.100`


✅ **Bingo!** Client now knows server IP automatically.

---

## 📱 FMX Mobile Client (Android)

- Uses the same logic as VCL but with **Java APIs** to detect primary IPv4:
```pascal
NetIf := TJNetworkInterface.JavaClass.getNetworkInterfaces;
...
InetAddr.getHostAddress;
```
Requires Android permissions in AndroidManifest.xml:
```pascal
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```
⚡ Why is it so Fast?

1. Direct LAN broadcast – the message reaches all devices on the subnet instantly.

2. No loops or retries – client sends once, server replies once.

3. Pre-bound ports – server always replies on `22049`, no guessing ephemeral ports or you could make the port random as explained Above.

4. Thread-safe async processing – logs and UI updates don’t block networking.

5. Bound to the real LAN adapter – avoids binding to virtual adapters (e.g. VirtualBox) using TIdIPWatch or GStack WILL NOT HELP YOU HERE !!..  

🖥 Demo Setup  
  
1. Run the Server (VCL project) First:  
  It will show its IP in the title bar.  
  Waits for discovery broadcasts on port 3434.  
  
2. Run a Client (VCL or FMX) Second:  
  On startup, it sends a discovery broadcast.  
  Logs will show:  
```pascal  
[12:01:10] UDP Has -> packet received from 192.168.1.100
[12:01:10] UDP Server -> DISCOVERY|192.168.1.100
```
3. Result:  
  Client automatically learns server IP(from only the outbox port`22049` => Secured a little here).  
  Ready for further TCP/UDP communication.  
  
🔮 Use Cases  
 - Multiplayer game discovery (LAN parties).  
 - Local device pairing (desktop ↔ mobile).  
 - Smart home or IoT LAN communication.  
 - Enterprise apps that must auto-connect without user config.  
 - etc ...  
  
📂 Project Structure:  
  
Delphi_UDP_AutoDiscovery:  
│── Server/           # UDP Server (VCL)  
│   └── Main.View.pas  
│── Client/           # UDP Client (VCL)  
│   └── Main.View.pas  
│── ClientFMX/        # UDP Client (FMX Mobile/Android)  
│   └── Main.View.pas  
└── README.md         # This file  
  
📝 Notes:  
 Server and Client ports must be different:  
 - Server listens: `3434`  
 - Client listens: `22049`  
  
If you use VirtualBox/VMware, ensure the real LAN adapter IP is chosen.  
----  
On Android, always request runtime permissions if targeting SDK 30+.  
----  
  
🤝 Contributing:  
Feel free to fork and improve:  
 - Add Encryption discovery.  
 - Add TCP auto-connect after discovery.  
 - Extend to IPv6 networks.  
 - Build UI to list all servers discovered.
 - etc.. 
  
👨‍💻 Author:  
Maintained & Developed by mben-dz  
Contact: mben.13011@gmail.com  
  
Mit Licence: Feel free to fork and improve & use it on your projects...  
