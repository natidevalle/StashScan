# StashScan

Home inventory and container labelling for iOS.

StashScan answers one question: **where did I put it?** Label your physical storage containers with QR codes, describe their contents, and find anything in under 10 seconds — either by scanning a label or searching the app.

---

## Features

- **4-level hierarchy** — organise storage as Location → Zone → Container → Item (e.g. Basement → Kallax → Blue bin → Extension cables)
- **QR code labels** — every container gets a unique QR code; scan it to jump straight to its contents
- **Bluetooth printing** — print labels directly to a Phomemo Q02E thermal printer over BLE, no third-party SDK
- **Full-text search** — search across container names, item lists, and notes
- **Quick edit on scan** — update a container's contents at point of retrieval, one tap away
- **Item edit & move** — fix typos, update quantities, and move items between containers without re-entry
- **JSON export/import** — back up and restore your inventory via the iOS share sheet

---

## Screenshots

<img src=".github/screenshots/1 - Home.png" width="250" /><img src=".github/screenshots/2 - Zones.png" width="250" /><img src=".github/screenshots/3 - Containers.png" width="250" />
<img src=".github/screenshots/4 - Container Details.png" width="250" />
<img src=".github/screenshots/5 - Search.png" width="250" />
<img src=".github/screenshots/6 - Search full.png" width="250" />
<img src=".github/screenshots/7 - Settings.png" width="250" />
<img src=".github/screenshots/8 - Print.png" width="250" />

---

## Requirements

- iOS 26.3+
- Xcode 16+
- Phomemo Q02E thermal printer (optional — app is fully functional without it)

---

## Tech Stack

| Concern | Approach |
|---|---|
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Data | SwiftData (local only, no cloud) |
| Bluetooth | CoreBluetooth (native) |
| QR generation | CoreImage |
| QR scanning | AVFoundation |

---

## Getting Started

1. Clone the repo
   ```bash
   git clone https://github.com/natidevalle/StashScan.git
   ```
2. Open `StashScan.xcodeproj` in Xcode
3. Select your target device (iOS 26.3+)
4. Build and run — no API keys or configuration required

---

## Printer Setup

StashScan prints to the **Phomemo Q02E** via Bluetooth LE.

1. Pair the printer in **iOS Settings → Bluetooth** first
2. On your first print attempt, the app will guide you through the one-time setup
3. After pairing, the app reconnects automatically

The BLE implementation uses the Q02E's GATT profile (service `FF00`, write characteristic `FF02`), compatible with the T02/M02 family. No third-party SDK required.

---

## Data & Privacy

All data is stored locally on device using SwiftData. No cloud sync, no accounts, no telemetry.

---

## Project Structure

```
StashScan/
├── Models/          # SwiftData models (Location, Zone, Container, Item)
├── Views/           # SwiftUI screens and components
├── PRD.md           # Product requirements
└── DESIGN_SYSTEM.md # Visual and interaction spec
```

---

## Status

V1 feature complete and in active use. Currently on a UI polish and bug fix pass.

## Backlog
1. UX improvements
2. Item photos
3. More useful homescreen
4. Export to spreadsheet
5. Visual identity

## Credits & Disclaimers

Designed and developed by Nati Devalle using Claude Code for personal use.
Nati doesn't know anything about app development, so the app code might be just AI slop. You've been warned.
It works, tho!
