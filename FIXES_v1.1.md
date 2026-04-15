# StashScan — Fix List v1.1

> Consumed by Claude Code during development sessions.
> Work through fixes in priority order. Each fix includes the acceptance criteria Claude should verify before marking it done.

---

## How to use this file

- Fix one issue at a time
- After each fix, verify the acceptance criteria listed under that issue
- Do not combine fixes across different screens in a single change unless explicitly noted
- Mark each issue `[x]` when complete

---

## Priority 1 — Blocking bugs (fix first)

### [ ] FIX-01 — Tab bar covers scrollable content

**Problem:** The bottom navigation bar (height ~83pt including safe area on modern iPhones) sits over the last item in any scroll view. Affected screens: Search results list, Container Detail scroll view (Delete Container action is partially hidden).

**Fix:** Add `.safeAreaInset(edge: .bottom)` padding to every ScrollView and List that sits behind the tab bar. The inset value should equal the tab bar height. Alternatively, ensure all root-level scroll content uses `.ignoresSafeArea(.keyboard)` correctly and that the TabView's safe area is propagated.

**Screens affected:** Home (search results), Container Detail

**Acceptance criteria:**
- The last search result is fully visible and tappable without scrolling past a dead zone
- "Delete Container" in the Actions section is fully visible without needing to scroll further than expected
- No content is clipped by the tab bar on any screen

---

### [ ] FIX-02 — No keyboard dismiss mechanism on item entry

**Problem:** When the item entry field is active (keyboard visible), there is no way to dismiss the keyboard other than tapping outside — and on Container Detail, tapping outside does not reliably dismiss because the scroll view captures the tap. Users can get stuck with the keyboard open.

**Fix:** Add a keyboard toolbar with a Done button using `.toolbar` modifier:

```swift
.toolbar {
    ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") {
            focusedField = nil
        }
    }
}
```

Apply this to the item name text field and the quantity field in the Container Detail view.

**Acceptance criteria:**
- A "Done" button appears in the keyboard toolbar whenever the item entry field is focused
- Tapping Done dismisses the keyboard and commits the current field value
- The keyboard does not dismiss mid-entry when scrolling the container detail view

---

## Priority 2 — Spec violations (visual and functional)

### [ ] FIX-03 — Location icon is wrong SF Symbol

**Problem:** The Location entity uses a circle-i icon (likely `info.circle`) instead of the specified `mappin.circle` (outline). This breaks the visual hierarchy language where each entity level has a distinct icon.

**Fix:** Replace the icon used for Location rows throughout the app with `mappin.circle` (outline, no fill). Check every place a Location is rendered: Home screen list rows, location path display on Container Detail, and search results.

**Icon reference (all outline, no fill):**

| Entity | SF Symbol |
|--------|-----------|
| Location | `mappin.circle` |
| Zone | `square.dashed` |
| Container | `shippingbox` |
| Item | `tag` |

**Acceptance criteria:**
- Home screen location rows show `mappin.circle`
- Location path on Container Detail (`Hallway > Kallax`) uses `mappin.circle` before the text
- No `info.circle` icons remain in the hierarchy views

---

### [ ] FIX-04 — Container name duplicated in nav bar and hero

**Problem:** The container name appears both as the navigation bar title (e.g. "Basket") and as bold text in the hero section below. This is redundant and creates visual noise.

**Fix:** Remove the navigation bar title from the Container Detail screen. The large bold name in the hero section is the primary heading. The back button label (`‹ Kallax`) already provides sufficient navigation context.

```swift
.navigationTitle("") // or .navigationBarTitleDisplayMode(.inline) with empty string
```

**Acceptance criteria:**
- Container Detail nav bar shows only the back button (left) and pencil/edit button (right)
- No container name text appears in the navigation bar area
- The hero section bold name remains as the primary heading

---

### [ ] FIX-05 — Home tab stays highlighted when navigating into hierarchy

**Problem:** The Home tab in the bottom navigation bar remains highlighted (blue, filled icon) when the user has navigated into Location Detail, Zone Detail, or Container Detail. Per spec, the Home tab selected state applies only on the root Home screen.

**Fix:** Track navigation depth and deselect the Home tab when any child view is active. In SwiftUI's `TabView`, this typically requires binding the tab selection to a state variable and updating it via `onAppear`/`onDisappear` on child views, or using the navigation stack's path depth.

**Acceptance criteria:**
- Home tab icon is filled/blue only when the root Home screen (location list) is the visible screen
- Home tab icon is outline/grey on Location Detail, Zone Detail, Container Detail, Settings, and Search results
- Scan tab behaviour is unchanged

---

### [ ] FIX-06 — Search back control lacks button affordance

**Problem:** The `<` chevron to the left of the search input text appears as an inline character rather than a tappable button. It has insufficient visual weight, no padding, and no pill/button treatment. Users may not recognise it as interactive.

**Fix:** Style the search dismiss control to match the pill-shaped back buttons used throughout the app (`‹ Locations`, `‹ Kallax`). It should have the same background pill, the same chevron + label pattern (label: "Locations"), and be clearly distinct from the search input field.

**Acceptance criteria:**
- The back control in search shows `‹ Locations` (or equivalent parent label) in the standard pill style
- Tapping it dismisses search and returns to the location list
- The control is visually distinct from the search input

---

### [ ] FIX-07 — No-photo placeholder height is disproportionate

**Problem:** When a container has no photo, the placeholder area (camera icon + "Tap to add photo") takes up the same height as a real photo (~130–140pt). This pushes the container name, items, and actions below the fold unnecessarily.

**Fix:** Reduce the no-photo placeholder height to approximately 80pt — enough to be tappable and visible, but not dominating. Keep the camera icon and label. The real photo should still render at full bleed ~130–140pt when present.

**Acceptance criteria:**
- Containers without photos show a compact placeholder, approximately 80pt tall
- Containers with photos show the full-bleed image at ~130–140pt
- The placeholder is tappable and triggers the camera/library picker

---

### [ ] FIX-08 — Label preview card does not size to content

**Problem:** The label preview card in Print Label has a fixed height. For containers with short names and no notes, there is large empty whitespace below the content within the card border. The preview should reflect the actual printed label proportions.

**Fix:** Make the label preview card height dynamic — sized to its content plus consistent padding. Do not use a fixed frame height on the preview container. The label layout (QR left, text right) should determine the card height.

**Acceptance criteria:**
- Label preview card height matches its content with consistent internal padding (~16pt)
- No large empty whitespace below notes/path text in the preview
- Preview proportions are a reasonable approximation of the physical printed label

---

## Priority 3 — Polish and missing features

### [ ] FIX-09 — Settings back button has no label

**Problem:** The Settings screen back button shows only `‹` with no parent label. Every other back button in the app shows the parent screen name (`‹ Locations`, `‹ Kallax`, etc.).

**Fix:** The Settings back button should read `‹ Locations` (since it is always accessed from the Home/Locations screen).

**Acceptance criteria:**
- Settings back button reads `‹ Locations`
- Style matches all other back buttons in the app

---

### [ ] FIX-10 — Settings missing Printer Setup and App Info sections

**Problem:** Settings currently shows only Export & Backup. The spec requires three sections: Export & Backup, Printer Setup, and App Info.

**Fix:** Add the following two sections:

**Printer Setup section:**
- Row: "Paired printer" — shows "Phomemo Q02E" if previously connected, "None" if not
- Row: "How to pair" — static instructional text or expandable: "Open Settings → Bluetooth and pair your Phomemo Q02E before first use"

**App Info section:**
- Row: App version (read from bundle, e.g. "StashScan 1.1.0")
- Row: "Acknowledgements" or equivalent (can be placeholder for now)

**Acceptance criteria:**
- Settings screen has three sections: Export & Backup, Printer, About
- Printer section shows last connected printer name or "Not set"
- About section shows the current app version string from the bundle

---

### [ ] FIX-11 — Zone list rows show no container count

**Problem:** Zone rows in Location Detail show only the zone name and a chevron. Adding a container count (`9 containers`) would give users immediate value without an extra tap — especially useful when scanning a long list to find the right zone.

**Fix:** Add a muted secondary label to each zone row showing the count of containers within that zone. Format: `N container` / `N containers`. Show `0 containers` rather than hiding the count.

**Acceptance criteria:**
- Each zone row shows a container count as secondary text (muted, smaller font)
- Count updates immediately when containers are added or deleted
- Singular/plural handled correctly ("1 container", "2 containers")

---

### [ ] FIX-12 — Type pill visual contrast is low on white background

**Problem:** The container type pill (e.g. "Bin", "Drawer") uses an outlined style with no fill on a white card background. The border is very light and the pill can be difficult to read, particularly for longer type names.

**Fix:** Replace the outlined pill with a lightly filled pill using the app's secondary background colour token. Suggested: `Color(.systemGray6)` fill with no border, or a very subtle tinted fill. Text weight and size unchanged.

**Acceptance criteria:**
- Type pill is clearly readable against the white card background
- Fill is subtle — does not compete with the container name or other metadata
- Style is consistent across Container Detail, Zone list rows (if type is shown), and Search results

---

## Resolved — no action needed

These issues from the initial evaluation were addressed or clarified by subsequent screenshots:

- **Print error/timeout state** — handled. Not connected, scanning, and error+retry states all implemented correctly (Images 3–5 of second batch).
- **Home screen title missing** — resolved. "Locations" heading now present in nav bar.
- **Print button active before ready** — confirmed disabled (greyed out) while connecting/scanning. Correct.

---

*StashScan Fix List v1.1 — April 2026*
