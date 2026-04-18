# StashScan — Design System

> This file is the single source of truth for all visual and interaction decisions.
> Claude Code must reference this file before implementing any UI. When in doubt, this file overrides gut instinct.

| Field | Value |
| --- | --- |
| Version | 1.1 — Icons updated to match app implementation |
| Date | April 2026 |
| Status | Source of truth for all UI decisions |

---

## 1. Principles

1. **Readability first.** Font size and spacing take precedence over visual density. Never sacrifice legibility for compactness.
2. **Size hierarchy, not weight hierarchy.** Information hierarchy is expressed through size and colour, not bold/heavy weights. Semibold is reserved for one purpose only (see Typography).
3. **iOS-native patterns.** Follow established iOS conventions for navigation, gestures, and controls. Do not invent custom interaction patterns.
4. **Consistency over cleverness.** Every repeating element — paths, icons, back buttons, section headers — must be implemented identically everywhere it appears. No one-off variations.
5. **Calm and functional.** The app is a tool, not an experience. Restraint is the aesthetic.

---

## 2. Colour

### 2.1 Accent — Clay

The brand accent. A dusty, muted clay — warm but not orange, earthy not vibrant.

```swift
// Add to Assets.xcassets as "Accent"
// Light mode
static let accent = Color(red: 0.702, green: 0.404, blue: 0.286) // #B3673A (approx)

// Define as asset with light/dark variants:
```

| Token | Light | Dark | Usage |
| --- | --- | --- | --- |
| `accent` | `#B3673A` | `#C97F55` | Primary interactive elements, active tab, action buttons |
| `accentMuted` | `#E8D5C8` | `#3D2416` | Accent backgrounds, pill fills, subtle tints |
| `accentForeground` | `#6B3318` | `#F0D5C2` | Text on accentMuted backgrounds |

**Rules:**
- Accent is used sparingly. It should appear on: active tab bar icon, primary CTA buttons, tappable action rows (Move, Print), Add item row, search result highlights.
- Accent is never used on destructive actions (red only), body text, or decorative elements.
- In dark mode, the accent lightens to remain legible against dark surfaces.

### 2.2 Semantic Colours

```swift
// Destructive
static let destructive = Color.red // system red, both modes

// Success (printer connected)
static let success = Color(red: 0.20, green: 0.60, blue: 0.40) // muted green
// Dark: Color(red: 0.35, green: 0.75, blue: 0.55)
```

### 2.3 Surface Colours

Use iOS semantic colours throughout. Do not hardcode greys.

| Token | SwiftUI | Usage |
| --- | --- | --- |
| `background` | `Color(.systemBackground)` | Root screen backgrounds |
| `secondaryBackground` | `Color(.secondarySystemBackground)` | Page/screen fill behind cards |
| `tertiaryBackground` | `Color(.tertiarySystemBackground)` | Card backgrounds |
| `groupedBackground` | `Color(.systemGroupedBackground)` | Grouped list backgrounds |
| `separator` | `Color(.separator)` | Dividers between rows |

### 2.4 Text Colours

| Token | SwiftUI | Usage |
| --- | --- | --- |
| `textPrimary` | `Color(.label)` | All primary text |
| `textSecondary` | `Color(.secondaryLabel)` | Metadata, paths, timestamps, counts |
| `textTertiary` | `Color(.tertiaryLabel)` | Placeholders, hints |
| `textAccent` | `accent` | Tappable rows, active elements |

**Rule:** Never hardcode `Color.black` or `Color.white` for text. Always use semantic label colours so dark mode works automatically.

---

## 3. Typography

Font: **SF Pro** (system default, `.body`, `.caption`, etc.)

### 3.1 Scale

| Role | SwiftUI Style | Size (pt) | Weight | Usage |
| --- | --- | --- | --- | --- |
| `screenTitle` | `.largeTitle` | 34 | Regular | Screen heading (Hallway, Basket, Settings) |
| `sectionHeader` | — | 12 | Regular | ALL CAPS section labels (ITEMS, ACTIONS) |
| `rowTitle` | `.body` | 17 | Semibold | Container names in lists, item names in search results |
| `rowBody` | `.body` | 17 | Regular | Item names in container detail, general list rows |
| `rowMeta` | `.subheadline` | 15 | Regular | Location paths, container type, secondary info |
| `caption` | `.caption1` | 12 | Regular | Timestamps, counts, hints |
| `label` | `.callout` | 16 | Regular | Action row labels (Move Container, Print Label) |
| `buttonPrimary` | `.body` | 17 | Regular | Primary CTA button labels |

**Rules:**
- Semibold (`rowTitle`) is used **only** in list contexts where scan-reading speed matters: container names in zone lists, item names in search results. Nowhere else.
- Never use Bold (700) or Heavy anywhere in the UI.
- Never go below 12pt for any visible text. 12pt (`caption`) is the floor.
- `screenTitle` is always Regular weight. Resist the urge to make it bold.
- `sectionHeader` (ITEMS, ACTIONS) is always 12pt Regular ALL CAPS with `textSecondary` colour.

### 3.2 Line Spacing

Use SwiftUI defaults. Do not override `lineSpacing` unless a specific multi-line component requires it (e.g. notes field, which may use `.lineSpacing(4)`).

---

## 4. Spacing

Base unit: **4pt**. All spacing values are multiples of 4.

| Token | Value | Usage |
| --- | --- | --- |
| `spacing2` | 8pt | Tight gaps: icon-to-label, badge internal padding |
| `spacing3` | 12pt | Row internal vertical padding |
| `spacing4` | 16pt | Standard section padding, card internal padding |
| `spacing5` | 20pt | Between sections on a screen |
| `spacing6` | 24pt | Large gaps, screen-level top padding |

**Rule:** Do not use arbitrary spacing values. If a gap isn't in this table, round to the nearest multiple of 4.

---

## 5. Icons

All icons use **SF Symbols, outline style only**. No filled variants except the active tab bar icon.

### 5.1 Entity Icons

These icons define the visual language of the hierarchy. They must be applied consistently everywhere an entity is represented.

| Entity | SF Symbol | Notes |
| --- | --- | --- |
| Location (list item) | `map` | Outline only |
| Zone | `viewfinder` | Used in list rows and empty state |
| Container | `archivebox` | Outline only |
| Item | `tag` | Outline only |

### 5.2 UI Icons

| Purpose | SF Symbol | Colour |
| --- | --- | --- |
| Back button chevron | `chevron.left` | `textPrimary` |
| Edit / pencil | `pencil` | `textPrimary` |
| Add / plus (nav bar) | `plus` | `textPrimary` |
| Add item (inline) | `plus.circle` | `accent` |
| Location list item | `map` | `textSecondary` |
| Location path (inline) | `location` | `textSecondary` |
| Timestamp (inline) | `clock` | `textSecondary` |
| Move container / item | `arrow.up.right.square` | `accent` |
| Print label | `printer` | `accent` |
| Delete | `trash` | `destructive` |
| Export backup | `arrow.up.doc` | `accent` |
| Import backup | `arrow.down.doc` | `accent` |
| Search | `magnifyingglass` | `textSecondary` |
| Settings / gear (nav bar button on Home) | `gearshape` | `textPrimary` |
| Home tab (inactive) | `house` | `textSecondary` |
| Home tab (active) | `house.fill` | `accent` |
| Scan tab (inactive) | `qrcode.viewfinder` | `textSecondary` |
| Scan tab (active) | `qrcode.viewfinder` | `accent` |
| Printer connected | `printer.fill` | `success` |
| Info | `info.circle` | `textSecondary` |

**Rules:**
- Icon size in list rows: 20pt (`Image(systemName:).font(.system(size: 20))`)
- Icon size inline in metadata (path, timestamp): 14pt
- Icon size in action rows: 22pt
- Never mix filled and outline variants of the same icon in the same context
- Entity icons (`map`, `viewfinder`, `archivebox`, `tag`) are always `textSecondary` in list rows, never accent
- Settings is a nav bar button on the Home screen only — it is not a tab bar item

---

## 6. Navigation

### 6.1 Back Button

Every screen except the root Home screen has a custom back button. No exceptions.

**Implementation:**
```swift
.navigationBarBackButtonHidden(true)
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button(action: { dismiss() }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .regular))
                Text(parentName) // e.g. "Locations", "Hallway", "Kallax"
                    .font(.body)
            }
            .foregroundColor(.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
    }
}
```

**Parent name rules:**
- Location Detail → "Locations"
- Zone Detail → Location name (e.g. "Hallway")
- Container Detail → Zone name (e.g. "Kallax")
- Settings → "Locations"
- Print Label → Container name (e.g. "Basket")
- Edit Container sheet → no back button (Cancel/Save modal pattern)
- New Location / New Zone sheets → no back button (Cancel/Save modal pattern)

### 6.2 Screen Title

Every screen has a large title displayed as a heading below the nav bar area. Use `.navigationTitle` with `.navigationBarTitleDisplayMode(.large)` for drill-down screens.

**Exception:** Container Detail does not use `.navigationTitle`. The container name in the hero section is the visual heading. The nav bar must be empty of a title on this screen.

### 6.3 Tab Bar

Two tabs only: **Home** and **Scan**.

| State | Home | Scan |
| --- | --- | --- |
| Active (root screen only) | `house.fill`, `accent` | `qrcode.viewfinder`, `accent` |
| Inactive | `house`, `textSecondary` | `qrcode.viewfinder`, `textSecondary` |

**Rule:** The Home tab is only in the active/filled state when the root Locations list is the visible screen. On all child screens the Home tab is inactive.

---

## 7. Components

### 7.1 List Rows

**Standard hierarchy row** (Location, Zone, Container in lists):
```
[entity icon 20pt, textSecondary]  [name, rowTitle/rowBody 17pt]  [chevron.right, textTertiary]
```
- Row height: minimum 48pt (touch target)
- Horizontal padding: 16pt
- Vertical padding: 12pt top and bottom
- Separator: `Color(.separator)`, inset 16pt from leading edge (not full bleed)
- Chevron: `chevron.right`, 14pt, `textTertiary`

**Container count badge on zone rows:**
```
[zone icon]  [zone name, rowTitle]  [N containers, caption, textSecondary]  [chevron]
```

### 7.2 Location Path

Used on: Container Detail hero, Search result rows, Label preview.

**Format:** `Location > Zone` (two levels only in most contexts). Use ` > ` as the separator (space, greater-than, space). Never use `→` or `/`.

**Implementation:**
```swift
HStack(spacing: 4) {
    Image(systemName: "location")
        .font(.system(size: 14))
        .foregroundColor(.secondaryLabel)
    Text("\(locationName) > \(zoneName)")
        .font(.subheadline) // 15pt Regular
        .foregroundColor(.secondaryLabel)
}
```

**Rules:**
- Always uses `location` icon at 14pt in `textSecondary`
- Always uses `.subheadline` (15pt Regular) in `textSecondary`
- Always formatted as `Location > Zone`
- No bold, no accent colour, no variation in any context

### 7.3 Timestamp

Used on: Container Detail hero.

```swift
HStack(spacing: 4) {
    Image(systemName: "clock")
        .font(.system(size: 14))
        .foregroundColor(.secondaryLabel)
    Text(container.updatedAt.formatted(date: .abbreviated, time: .shortened))
        // Renders as: "13 Apr 2026, 18:30"
        .font(.caption) // 12pt Regular
        .foregroundColor(.secondaryLabel)
}
```

### 7.4 Type Pill / Badge

Used on: Container Detail hero (container type).

```swift
Text(container.type.displayName) // "Bin", "Drawer", etc.
    .font(.caption) // 12pt Regular
    .foregroundColor(Color(red: 0.533, green: 0.286, blue: 0.176)) // accentForeground light
    .padding(.horizontal, 10)
    .padding(.vertical, 4)
    .background(Color(red: 0.910, green: 0.835, blue: 0.784)) // accentMuted light
    .clipShape(Capsule())
```

Use the accent colour family (muted fill, accent foreground text). Never use a border-only outlined pill.

### 7.5 Section Headers

Used above grouped content blocks (ITEMS, ACTIONS, EXPORT & BACKUP).

```swift
Text("ITEMS") // Always ALL CAPS
    .font(.system(size: 12, weight: .regular))
    .foregroundColor(.secondaryLabel)
    .padding(.horizontal, 16)
    .padding(.top, 20)
    .padding(.bottom, 6)
```

Gap between section header and the card/list below: 6pt. No more.

### 7.6 Action Rows

Used in the Actions section of Container Detail and in sheets (e.g. Move to…).

```swift
// Standard action row
Button(action: { }) {
    HStack(spacing: 12) {
        Image(systemName: "arrow.up.right.square")
            .font(.system(size: 22))
            .foregroundColor(.accent)
            .frame(width: 28)
        Text("Move Container")
            .font(.callout) // 16pt Regular
            .foregroundColor(.accent)
        Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
}

// Destructive action row (Delete)
// Same structure, Color.red for both icon and label
```

### 7.7 Primary CTA Button

Used in Print Label (Connect to Printer).

```swift
Button(action: { }) {
    HStack(spacing: 8) {
        Image(systemName: "printer")
            .font(.system(size: 18))
        Text("Connect to Printer")
            .font(.body) // 17pt Regular
    }
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .background(Color.accent)
    .clipShape(RoundedRectangle(cornerRadius: 12))
}
```

### 7.8 Cards

```swift
// Standard card container
VStack(spacing: 0) {
    // content
}
.background(Color(.secondarySystemBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
```

Corner radius: **12pt** for all cards. Do not use other values.

### 7.9 Empty State

```swift
VStack(spacing: 12) {
    Image(systemName: "viewfinder") // Use relevant entity icon — see table below
        .font(.system(size: 48))
        .foregroundColor(.tertiaryLabel)
    Text("No Zones")
        .font(.headline) // 17pt — exception to weight rule, standard iOS empty state
        .foregroundColor(.primary)
    Text("Tap + to add the first zone.")
        .font(.subheadline) // 15pt
        .foregroundColor(.secondaryLabel)
        .multilineTextAlignment(.center)
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
```

| Screen | Empty State Icon | Notes |
| --- | --- | --- |
| Location Detail (no zones) | `viewfinder` | Zone entity icon |
| Zone Detail (no containers) | `viewfinder` | Zone entity icon, consistent with zone list rows |
| Home (no locations) | `map` | Location entity icon |
| Container Detail (no items) | `tag` | Item entity icon |

---

## 8. Search

### 8.1 Search Bar

```swift
// Active search state
HStack(spacing: 8) {
    // Back button — same pill style as navigation back buttons
    Button(action: dismissSearch) {
        HStack(spacing: 4) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .regular))
            Text("Locations")
                .font(.body)
        }
        .foregroundColor(.primary)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }

    // Search input
    HStack {
        Image(systemName: "magnifyingglass")
            .foregroundColor(.secondaryLabel)
            .font(.system(size: 16))
        TextField("Search items, containers, notes...", text: $query)
            .font(.body)
        if !query.isEmpty {
            Button(action: { query = "" }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondaryLabel)
            }
        }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 10))
}
```

### 8.2 Search Result Rows

```swift
// Item result
HStack(spacing: 12) {
    Image(systemName: "tag")
        .font(.system(size: 20))
        .foregroundColor(.secondaryLabel)
        .frame(width: 24)
    VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 4) {
            Text(itemName)
                .font(.body).fontWeight(.semibold) // rowTitle: Semibold
                .foregroundColor(.primary)
            if quantity > 1 {
                Text("×\(quantity)")
                    .font(.body)
                    .foregroundColor(.secondaryLabel)
            }
        }
        Text("\(containerName) · \(locationName) > \(zoneName)")
            .font(.subheadline)
            .foregroundColor(.secondaryLabel)
    }
    Spacer()
    Image(systemName: "chevron.right")
        .font(.system(size: 14))
        .foregroundColor(.tertiaryLabel)
}
.padding(.horizontal, 16)
.padding(.vertical, 12)

// Container result — same structure, use archivebox icon, no quantity
```

---

## 9. Container Detail

### 9.1 Photo Hero

```swift
// With photo
AsyncImage or Image from filesystem
    .frame(maxWidth: .infinity)
    .frame(height: 140)
    .clipped()
    .contentShape(Rectangle()) // not tappable on detail screen

// Without photo (placeholder)
ZStack {
    Color(.secondarySystemBackground)
    VStack(spacing: 8) {
        Image(systemName: "camera")
            .font(.system(size: 24))
            .foregroundColor(.tertiaryLabel)
        Text("Tap to add photo")
            .font(.subheadline)
            .foregroundColor(.tertiaryLabel)
    }
}
.frame(maxWidth: .infinity)
.frame(height: 80) // Compact — not the same height as a real photo
.onTapGesture { showPhotoPicker = true }
```

### 9.2 Hero Info Block

The block below the photo. No card wrapper — rendered directly on the screen background.

```swift
VStack(alignment: .leading, spacing: 6) {
    HStack(alignment: .firstTextBaseline) {
        Text(container.name)
            .font(.title2) // 22pt Regular
            .foregroundColor(.primary)
        Spacer()
        TypePill(type: container.type)
    }

    // Location path
    LocationPath(location: location, zone: zone)

    // Timestamp
    TimestampRow(date: container.updatedAt)
}
.padding(.horizontal, 16)
.padding(.vertical, 12)
```

**Rule:** No card/rounded rect wrapper around this block. It sits on the screen background. The photo and this block together form the hero.

---

## 10. Consistency Checklist

Before shipping any screen, verify:

- [ ] All back buttons use the pill + chevron + parent name pattern
- [ ] All location paths use `location` icon + `Location > Zone` format + `.subheadline` + `textSecondary`
- [ ] All entity icons use the correct SF Symbol (`map` for location list / `viewfinder` for zone / `archivebox` for container / `tag` for item)
- [ ] No hardcoded black/white text — all text uses semantic label colours
- [ ] No text below 12pt
- [ ] No Bold or Heavy font weights — Regular everywhere except Semibold for rowTitle in list/search
- [ ] All cards use 12pt corner radius
- [ ] All section headers are 12pt Regular ALL CAPS in `textSecondary`
- [ ] Tab bar Home active state (`house.fill`) only on root Locations screen
- [ ] Bottom scroll content clears the tab bar safe area inset
- [ ] Accent colour (`#B3673A` light / `#C97F55` dark) applied only to interactive/active elements
- [ ] Settings is a nav bar button on Home, not a tab

---

## 11. App Icon

### Concept

Three QR finder squares arranged in an L — top-left, top-right, bottom-left. The bottom-right corner is intentionally empty. The negative space makes the icon feel incomplete-but-intentional, which is appropriate for a scanning and retrieval tool. Not a real scannable QR code.

### Colours — locked

| Element | Value |
| --- | --- |
| Background | `#B3673A` (clay accent) |
| Finder squares — outer ring | `#F5EFE8` (warm sand), no fill |
| Finder squares — inner dot | `#F5EFE8` (warm sand), filled |

Background is the clay accent. Graphic elements are warm sand. Inverted from the in-app usage — the icon reads as a coloured mark on the home screen rather than disappearing into a light wallpaper.

### Geometry — 1024×1024 master

All values in px at 1024×1024. The squircle mask is applied by iOS — do not clip or round the artwork corners manually.

```
Canvas: 1024 × 1024

Each finder square outer ring:
  Size:          179 × 179 px
  Corner radius: 32 px
  Stroke:        32 px, no fill
  Colour:        #F5EFE8

Each finder square inner dot:
  Size:          90 × 90 px
  Corner radius: 16 px
  Fill:          #F5EFE8

Positions (top-left corner of each outer ring):
  Top-left square:     x=163,  y=163
  Top-right square:    x=682,  y=163
  Bottom-left square:  x=163,  y=682

Inner dot offset from outer ring top-left: +44px x, +44px y
  Top-left dot:        x=207,  y=207
  Top-right dot:       x=726,  y=207
  Bottom-left dot:     x=207,  y=726

Gap between squares: ~340 px (centre-to-centre: ~521 px)
Bottom-right corner:  empty
```

### SVG master (use for Xcode export)

```svg
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <rect width="1024" height="1024" fill="#B3673A"/>
  <!-- Top-left finder square -->
  <rect x="163" y="163" width="179" height="179" rx="32" fill="none" stroke="#F5EFE8" stroke-width="32"/>
  <rect x="207" y="207" width="90" height="90" rx="16" fill="#F5EFE8"/>
  <!-- Top-right finder square -->
  <rect x="682" y="163" width="179" height="179" rx="32" fill="none" stroke="#F5EFE8" stroke-width="32"/>
  <rect x="726" y="207" width="90" height="90" rx="16" fill="#F5EFE8"/>
  <!-- Bottom-left finder square -->
  <rect x="163" y="682" width="179" height="179" rx="32" fill="none" stroke="#F5EFE8" stroke-width="32"/>
  <rect x="207" y="726" width="90" height="90" rx="16" fill="#F5EFE8"/>
</svg>
```

### Xcode export steps

1. Save the SVG above as `AppIcon-master.svg`
2. Export as PNG at 1024×1024: `File → Export As → PNG`
3. In Xcode, open `Assets.xcassets → AppIcon`
4. Drag the 1024×1024 PNG into the single slot (Xcode generates all other sizes)
5. Do not add the squircle mask to the artwork — iOS applies it automatically

### Sizes reference

| Context | Size |
| --- | --- |
| App Store | 1024×1024 |
| Home screen (@3x) | 180×180 |
| Spotlight (@3x) | 120×120 |
| Settings (@3x) | 87×87 |
| Notification (@3x) | 60×60 |

All generated automatically from the 1024px master by Xcode.

Dark mode app icons are not supported on iOS — one version only.

---

*StashScan Design System v1.1 — April 2026 — Icons updated to match app implementation*
