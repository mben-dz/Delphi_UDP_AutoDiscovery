# Delphi UDP AutoDiscovery 🚀

## A simple, cross-platform demo (VCL + FMX) showing how to automatically discover a server on the same LAN using **UDP Broadcast** with Indy components.  



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
- **Timers** to control discovery message sending

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
  3. Sends it **directly back to the client’s listening port `22049`**.

➡️ This ensures the client receives only the relevant reply without looping broadcasts.

---

### 2. Client Setup
- Creates a UDP client that:
  - Binds to the **local LAN IPv4** (not a virtual adapter).
  - Broadcasts discovery message on **port `3434`**.
- Creates a UDP server (`fUDPServerRead`) that:
  - Listens on **port `22049`** for server replies.
  - Extracts server IP and logs it.

---

### 3. Discovery Flow  

1. Client sends:  
`Discovery|Hello, I'm Here, is there Any UDP Broadcaster there?`
→ to `255.255.255.255:3434`.  

2. Server receives & replies:
`DISCOVERY|192.168.1.100`
→ back to client’s listening port `22049`.

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

3. Pre-bound ports – server always replies on 22049, no guessing ephemeral ports.

4. Thread-safe async processing – logs and UI updates don’t block networking.

5. Bound to the real LAN adapter – avoids binding to virtual adapters (e.g. VirtualBox).  

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
 - Add TCP auto-connect after discovery.  
 - Extend to IPv6 networks.  
 - Build UI to list all servers discovered.  
  
👨‍💻 Author:  
Maintained & Developed by mben-dz  
Contact: mben.13011@gmail.com  
  
Mit Licence: Feel free to fork and improve & use it on your projects...  
