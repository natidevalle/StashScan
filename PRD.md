# Product Requirements Document — StashScan

Home Inventory & Container Labelling for iOS

| Field | Value |
|---|---|
| Version | 1.1 |
| Date | April 2026 |
| Platform | iOS (SwiftUI) |
| Printer | Phomemo Q02E (BLE) |
| Status | In Development |

---

## 1. Overview

StashScan is a retrieval-first home inventory app for iOS. The core job-to-be-done is answering the question: **"where did I put it?"** Users label physical containers with QR codes, describe their contents, and assign them to a location hierarchy. When they need to find something, they either scan a QR code or search the app.

The app is designed around the reality that home storage is heterogeneous — containers vary in shape (boxes, bags, drawers, bins) and are nested inside zones and locations. The hierarchy is 4 levels deep: **Location → Zone → Container → Items**.

Printing is handled natively via Bluetooth LE to a Phomemo Q02E thermal printer. No third-party SDK is required; the printer communicates over a documented BLE GATT profile.

---

## 2. Goals & Non-Goals

### Goals

- Answer "where is it?" in under 10 seconds — either via QR scan or search.
- Support a 4-level physical hierarchy with flexible container shapes and types.
- Make labelling fast: add container → describe → print label in one flow.
- Allow quick edits at point of retrieval (contents change when you open a box).
- Provide a JSON export for backup and peace of mind.

### Non-Goals (v1)

- Item-level QR codes — items are text/photo lists inside containers, not individually scanned.
- Multi-user or shared inventory.
- Cloud sync or third-party integrations.
- Barcode scanning for retail products or auto-population from product databases.
- Android support.

---

## 3. User & Context

Single user. The primary context is a home with multiple storage areas — basement shelves, Kallax units, closets, garage — containing a mix of container types including cardboard boxes, plastic bins, fabric bags, and drawer organizers.

The user's pain point is not cataloguing for its own sake, but **retrieval friction**: remembering which of many similar-looking containers holds a specific item, especially containers that are rarely accessed.

Usage pattern is sporadic and task-driven. The app is opened either to add a new container during an organisation session, or to find something specific during retrieval. It is not a daily-use app.

---

## 4. Data Model

The core hierarchy is four levels. Every level is a named entity that can be created, edited, and deleted independently.

| Level | Examples | Has QR Code | Has Photo |
|---|---|---|---|
| Location | Basement, Spare Room, Garage | No | Optional |
| Zone | IKEA Kallax unit, Shelf B, Wardrobe | No | Optional |
| Container | Blue bin, Brown box, IKEA bag | Yes | Yes (optional) |
| Item | Extension cables, Winter gloves, Drill bits | No (v1) | No (v1) |

### Container Entity

The Container is the primary entity. It holds all meaningful data.

- `id` — UUID, generated on creation
- `name` — user-defined string (e.g. "Blue IKEA bag #2")
- `type` — enum: Box, Bag, Bin, Drawer, Shelf, Other
- `notes` — free text notes
- `photo` — optional image filename (full path reconstructed at runtime from Documents directory)
- `locationId` — foreign key to Location
- `zoneId` — foreign key to Zone
- `qrCode` — UUID, same as container id, encoded as QR
- `createdAt` — timestamp
- `updatedAt` — timestamp (bumped manually on any edit or item change)
- `items` — relationship to Item entities (cascade delete)

### Item Entity

Items are first-class SwiftData `@Model` entities.

- `id` — UUID
- `name` — user-defined string
- `quantity` — optional Int (nil = unspecified, 0 = valid quantity)
- `container` — inverse relationship to Container

### Storage

All data stored locally using SwiftData. No remote database. JSON export is a manual one-way push via iOS share sheet, not a sync.

---

## 5. Features

### 5.1 Hierarchy Management

Users can create, rename, and delete Locations, Zones, Containers, and Items. The home screen displays the hierarchy as a browsable tree. Deleting a Location or Zone requires confirmation and shows a count of affected containers.

- Create / edit / delete Location
- Create / edit / delete Zone (must belong to a Location)
- Create / edit / delete Container (must belong to a Zone)
- Create / edit / delete Item (must belong to a Container)
- Edit item name and quantity
- Move container to a different Zone or Location
- Move item to a different Container
- Optional photo on Location and Zone for visual identification

### 5.2 Container Detail

The container detail screen is the core information view. It is reached either by browsing the hierarchy, searching, or by scanning a QR code.

- Full location path displayed at top (e.g. Basement → Kallax → Blue bin)
- Container type badge (Box, Bag, etc.)
- Optional photo
- Item list — tap any item to open Edit Item sheet; swipe left for Move or Delete actions
- Free text notes field
- Last updated timestamp
- Actions: Edit container, Move container, Print Label, Delete container

### 5.3 QR Code Generation & Label Printing

Every container gets a unique QR code on creation. The QR code encodes the container's UUID. Labels are printed to the Phomemo Q02E via CoreBluetooth.

- QR code auto-generated on container creation
- Label layout: QR code + container name + location path
- Print from container detail screen
- Printer connection: scan for paired Q02E, connect, send image over BLE
- One-time pairing setup prompt for first-time users
- Reprint label at any time from container detail

### 5.4 QR Code Scanning

Users open the camera/scan view to scan a container label. The app resolves the UUID, finds the container, and opens the detail screen. If the QR code is not found in the local database, a clear error is shown.

- Native iOS camera scanner (AVFoundation)
- Instant navigation to container detail on successful scan
- Error state for unrecognised QR codes
- Scan tab accessible from anywhere in the app via bottom tab bar

### 5.5 Search

Full-text search across container names, item lists, and notes. Search is a dedicated tab and returns results with the full location path shown for each result.

- Search indexes: container name, item list entries, notes, zone name, location name
- Results show: container name, matching item (if item-level match), full path
- Tap result navigates to container detail
- No minimum character count — search-as-you-type

### 5.6 Item Edit & Move

Items inside containers can be edited and moved without deleting and re-adding.

- Tap item row to open Edit Item sheet
- Edit item name and/or quantity
- Move item to any container in any location/zone via cascading picker sheet
- Swipe left on item row reveals Move and Delete actions
- Move from Edit Item sheet saves pending edits before opening Move sheet
- Quantity is optional — nil means unspecified, 0 is a valid quantity

### 5.7 JSON Export & Import

A manual export/import using iOS native share sheet and document picker. Intended as a backup, not a sync. Accessible from Settings.

- Export: serialises all locations, zones, containers, and items to JSON; shared via iOS share sheet
- Import: reads a previously exported JSON file via document picker; restores full hierarchy
- No authentication required
- Triggered from Settings

---

## 6. Navigation & Screen Map

| Screen | Reached From | Primary Actions |
|---|---|---|
| Home / Locations | App launch | Browse locations, tap to drill down, open Settings |
| Location Detail | Home | View zones, add zone, edit location |
| Zone Detail | Location Detail | View containers, add container, edit zone |
| Container Detail | Zone Detail or QR Scan or Search | View items, edit container, move container, print label, delete |
| Edit Container sheet | Container Detail | Edit name, type, notes, photo |
| Move Container sheet | Container Detail | Cascading location/zone picker, confirm move |
| Edit Item sheet | Container Detail (tap item row) | Edit name, quantity; access Move Item sheet |
| Move Item sheet | Container Detail (swipe Move) or Edit Item sheet | Cascading location/zone/container picker, confirm move |
| Scan | Tab bar | Point camera, resolve QR, navigate to Container Detail |
| Search | Tab bar | Type query, view results, navigate to Container Detail |
| Print Preview | Container Detail | Preview label layout, connect printer, print |
| Settings | Home (nav bar gear icon) | JSON export/import, printer setup, app info |

---

## 7. Printer Integration

### Device

Phomemo Q02E. Connects via Bluetooth Low Energy. No third-party SDK. Communication uses the Q02E's BLE GATT profile, which is compatible with the reverse-engineered protocol used by the T02/M02 family.

### BLE Profile

- Service UUID: `FF00`
- Write characteristic: `FF02`
- Notify characteristic: `FF03` (requires encrypted channel — one-time iOS pairing required)
- Implementation reference: [github.com/jeffrafter/phomemo](https://github.com/jeffrafter/phomemo) (Swift/CoreBluetooth)

### Label Format

- Default layout: QR code (left) + container name (bold) + location path (small text)
- Label dimensions constrained by Q02E paper width
- Image rendered as UIImage, converted to monochrome bitmap, sent over BLE
- No cloud rendering — all label generation is on-device

### Setup Flow (First Use)

1. App detects no paired printer on first print attempt
2. Shows setup sheet: "Pair your Phomemo Q02E in Settings → Bluetooth first"
3. After pairing, app auto-discovers and connects
4. Printer preference persisted — reconnects automatically on subsequent uses

---

## 8. Technical Notes

### Stack

| Concern | Approach |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Data Persistence | SwiftData (local only, no cloud) |
| Bluetooth | CoreBluetooth (native, no third-party library) |
| QR Generation | CoreImage CIFilter (QRCodeGenerator) — on-device |
| QR Scanning | AVFoundation — native camera |
| Export / Import | JSON via iOS share sheet and document picker |
| Image Storage | Local filesystem (FileManager), filenames stored in SwiftData |

### Data Persistence Notes

- All data is local-only. No iCloud sync.
- Images stored as files in app's Documents directory; SwiftData stores filename only, full path reconstructed at runtime.
- On container deletion, associated image file is also deleted (hard delete with filesystem cleanup before cascade).
- Item is a first-class SwiftData `@Model` with an inverse relationship to Container — moving an item reassigns `item.container` and SwiftData handles both containers' item arrays automatically.
- `updatedAt` is bumped manually after any edit or move — nothing updates it automatically.

### Navigation

- Uses `NavigationLink(value:)` + `navigationDestination(for:)` throughout — no legacy `NavigationLink(destination:)`.
- Custom back buttons on all drill-down screens using `.navigationBarBackButtonHidden(true)` + `ToolbarItem`.
- 3-tab bottom navigation: Home | Search | Scan.

### QR Code Strategy

- QR content = container UUID only (e.g. `550e8400-e29b-41d4-a716-446655440000`).
- All metadata resolved by lookup — labels do not embed location paths.
- Moving a container requires no reprint. The QR remains valid.

---

## 9. Out of Scope — v2 Candidates

| Feature | Why Deferred |
|---|---|
| Item-level QR codes | Adds printing overhead; data model already supports it |
| iCloud / CloudKit sync | Solo use in v1; architecture supports adding later |
| Multi-user / sharing | Not needed for solo home use |
| Widget (last scanned) | Nice-to-have, not core to retrieval job |
| Container history log | Useful but adds complexity; timestamps cover 80% of need |
| Bulk label printing | Useful for initial setup sessions; low priority for MVP |
| Bulk item move | Deferred; single item move covers primary use case |
| Drag-and-drop between containers | Deferred; move sheet covers the need |
| Barcode scanning (retail) | Different use case; not retrieval-focused |

---

## 10. Open Questions

- **Deletion behaviour:** soft delete (archive) or hard delete? Currently hard delete — soft delete would prevent accidental data loss but adds complexity.
- **Search ranking:** exact match first, or recency-weighted?

---

*StashScan PRD v1.1 — April 2026*
