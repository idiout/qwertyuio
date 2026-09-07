# Game Remote (v2 — customizable tabs + per-command packets)

Landscape iOS app with a customizable side tab bar. Each tab holds custom
command buttons; each command has its own editable IP, port, and packet
payload, sent as a raw UDP datagram when tapped.

## Files

- `GameRemote/Models.swift` — `RemoteTab` / `CommandItem` data models
- `GameRemote/Store.swift` — persistence (UserDefaults) + tab/command CRUD
- `GameRemote/NetworkSender.swift` — sends the UDP packet (text or hex payload)
- `GameRemote/CommandEditorView.swift` — add/edit-command sheet
- `GameRemote/ContentView.swift` — main landscape UI (sidebar + command grid)
- `GameRemote/GameRemoteApp.swift` — app entry point
- `GameRemote/Info.plist` — landscape lock, ATS exception, local network usage string

## How it works

- **Sidebar (left)**: lists your tabs. Tap `+` to add one (prompts for a
  name). Tap **Edit** to enter layout-edit mode — a `⋯` menu appears next to
  each tab for **Rename** / **Delete**. Tap **Done** to exit edit mode.
- **Main area (right)**: shows the selected tab's commands as a grid.
  Tap **Add Command** to create one — you set its **name**, **IP**,
  **port**, and **packet**. In edit mode, each command tile also shows
  **Edit** / **Delete**.
- **Packet field**: type plain text (sent as UTF-8), or space/comma-separated
  hex bytes like `AA BB 01` or `0xAA,0xBB` to send raw bytes instead.
- Tapping a command tile sends that packet via **UDP** to its IP:port and
  shows a brief toast confirming success or failure.
- Everything (tabs, commands, names) is saved automatically and reloads on
  next launch.

## Why UDP instead of a shared WebSocket

Since each command now targets its own IP/port/payload independently, a
single shared connection doesn't fit — UDP send-and-forget matches "fire this
exact packet at this exact target" much better. If your game client instead
expects a **persistent** connection (TCP or WebSocket) with these packets
sent over it rather than as standalone datagrams, let me know — the sending
logic lives entirely in `NetworkSender.swift`, so it's a small, contained
change to swap in TCP or a WebSocket instead.

## Server-side note

Your game client needs to listen for UDP packets on whatever port(s) you
configure per-command, and act on the payload. A minimal Python example:

```python
import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", 8080))

while True:
    data, addr = sock.recvfrom(1024)
    print(f"Got packet from {addr}: {data}")
    # Match on the payload and trigger your game action here.
```

## Building it

Same as before — either:

1. **Drop into Xcode directly** (if you get access to a Mac): create a new
   SwiftUI iOS App project targeting iOS 15.0+, delete Xcode's default
   `ContentView.swift`/`GameRemoteApp.swift`, and drag in all the files from
   this `GameRemote/` folder.
2. **Build via GitHub Actions** (no Mac needed): push this whole folder to a
   GitHub repo (`project.yml` + `.github/workflows/build-ipa.yml` are
   included), run the "Build IPA" workflow from the Actions tab, and download
   the resulting `.ipa` artifact.

Then install it on your iPod via **TrollStore** — no code signing needed.

## Ideas for later

- Reorder tabs via drag (currently add/rename/delete only)
- Reorder commands within a tab
- TCP or WebSocket sending mode as an alternative to UDP
- Export/import your whole tab+command config as JSON, to back it up or
  share a layout between devices
