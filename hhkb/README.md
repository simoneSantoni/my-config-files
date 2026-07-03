# HHKB Studio keymap config

Keymap profiles and tooling notes for the **HHKB Studio** (PFU Limited, model
**PD-ID100B**, US layout). Managed with
[`yuja/hhkb-studio-tools`](https://github.com/yuja/hhkb-studio-tools).

| | |
|---|---|
| Model | PD-ID100B (HHKB Studio, US) |
| Firmware | B009 (bootloader 0.16.9) |
| Serial | CRWT001845 |
| Tool | `hhkb-studio-tools` — `cargo install --git https://github.com/yuja/hhkb-studio-tools` → `~/.cargo/bin/hhkb-studio-tools` |
| Connections | USB-C (wired) + Bluetooth (4 slots). **Config can only be read/written over USB.** |

---

## Files in this directory

| File | What it is |
|------|------------|
| `current-profile-0.toml` | **Live profile 0** — the everyday typing profile (all customizations applied) |
| `current-profile-1.toml` | Live profile 1 — function/media-heavy secondary profile |
| `current-profile-2.toml` | Live profile 2 — factory defaults |
| `current-profile-3.toml` | Live profile 3 — factory defaults |
| `profile-backup.toml` | **Factory/known-good snapshot** taken before any remapping (Delete, Fn, Alt/Meta). Restore target. |
| `profile-0-decoded.txt` … `profile-3-decoded.txt` | Human-readable `show-profile` renders of each profile (all 4 layers) |
| `keyboard-info.txt` | `hhkb-studio-tools info` snapshot (firmware, serial, DIP switches) |

Each profile is 4 layers; each layer is a flat array of **120 scancodes** laid out
as **15 columns × 8 rows**. Layer 0 is the base layer; layers 1–3 are the Fn1/Fn2/Fn3
function layers. The keyboard stores **4 independent profiles**, switched on the
keyboard itself.

---

## Customizations vs. factory (profile 0)

Diff of `current-profile-0.toml` against `profile-backup.toml` — 5 cells changed:

| Layer / cell | Physical key | Factory | Now | Why |
|---|---|---|---|---|
| L0 cell 28 | Top-right big key (above Return) | `Delete` | **`Backspace`** | Prefer Backspace there (HHKB-classic) |
| L1 cell 28 | same key, on Fn layer | `Backspace` | **`Delete`** | Delete still reachable via **Fn + that key** |
| L0 cell 63 | **Left ◇** (left of space) | `LMeta/◇` | **`Fn1`** | Left ◇ acts as the Fn1 layer key |
| L0 cell 68 | right-side, *outer* | `RMeta/◇` | **`RAlt`** | part of the right Alt/Meta swap ↓ |
| L0 cell 69 | **right key next to space** | `RAlt` | **`RMeta/◇`** | put ◇/Super next to space (2026-06-26) |

> **Gotcha about cells 68/69:** in `show-profile`'s rendered layout the *next-to-space*
> slot prints on the **left** of the two right-side modifiers, but physically the key
> **immediately right of the spacebar is cell 69** (the render's right/outer slot).
> Verified empirically: setting cell 69 = `RMeta` is what makes the key beside space
> behave as Super/◇.

### Base layer (profile 0) — current

```
|Esc |1 ! |2 @ |3 # |4 $ |5 % |6 ^ |7 & |8 * |9 ( |0 ) |- _ |= + |\ | |` ~ |
|Tab   |Q  |W  |E  |R  |T  |Y  |U  |I  |O  |P  |[ { |] } | Backspace  |
|LControl|A |S |D |F |G |H |J |K |L |; : |' " |   Return         |
|LShift    |Z |X |C |V |B |N |M |, < |. > |/ ? | RShift   | Fn1 |
       |LAlt| Fn1 |        Space        | RAlt | RMeta |     <- RMeta is next to space
```

(Fn1 = Left ◇ and the key right of RShift. Mouse buttons / gesture pads / pointing-stick
live on rows 5–7 and the Fn layers — see `profile-0-decoded.txt` for the full render.)

### Other profiles
- **Profile 1** — base layer is media/function oriented (Power, F1–F12, volume, KP, arrows on Fn). Still factory on the Alt/Meta keys.
- **Profiles 2 & 3** — identical to `profile-backup.toml` (factory defaults).

---

## Reading & writing the config

> ⚠️ The config (vendor) HID interface is **exposed only over the wired USB
> connection**. Over Bluetooth the keyboard shows only its plain keyboard interface,
> so config "reads" return live keypresses (looks like random garbage) and `info`
> comes back blank.

### 1. Get onto USB (the keyboard often stays in Bluetooth mode)
Plug in a **USB-C data cable** (not charge-only), directly into the machine. If it
doesn't enumerate — or enumerates for ~2 s then drops back to Bluetooth — switch the
keyboard to wired mode from the keyboard itself:

```
Fn + Control + 0      # selects USB / wired
Fn + Control + 1..4   # selects a Bluetooth slot
```

Confirm: `lsusb | grep 04fe` shows `04fe:0016 PFU HHKB-Studio`, and five USB hidraw
nodes appear (`hidraw1`–`hidraw5`, bus `0003`).

### 2. Find the config interface (number is NOT stable across replugs)
It's the **vendor interface, HID usage page `0xFF60`** (report descriptor begins
`0660ff…`). Identify it by probing — the node that returns a real product name is the one:

```bash
for n in 1 2 3 4 5; do
  echo "== hidraw$n =="; hhkb-studio-tools info --device /dev/hidraw$n 2>&1 | head -2
done
# the one printing "Product name: HHKB-Studio" is the config interface (e.g. /dev/hidraw2)
```
(The other vendor node, usage page `0xFF31` / `0631ff…`, is a decoy and just hangs.)

### 3. Grant access (ACLs reset on every replug)
```bash
sudo setfacl -m u:simon:rw /dev/hidraw1 /dev/hidraw2 /dev/hidraw3 /dev/hidraw4 /dev/hidraw5
```

### 4. Read / inspect / write
```bash
DEV=/dev/hidraw2   # whichever probed as the config interface

# read a profile to a file (omit --index for the current profile)
hhkb-studio-tools read-profile --device $DEV --index 0 -o current-profile-0.toml

# pretty-print with the physical layout
hhkb-studio-tools show-profile -i current-profile-0.toml

# write a profile back
hhkb-studio-tools write-profile --device $DEV --index 0 -i current-profile-0.toml

# keyboard info / firmware / DIP switches / current profile
hhkb-studio-tools info --device $DEV
```

After writing, **read it back and diff** to confirm it took; then the change persists on
the keyboard and works over Bluetooth too (BT just can't *edit* config).

### Restore to factory / known-good
```bash
hhkb-studio-tools write-profile --device $DEV --index 0 -i profile-backup.toml
```

---

## Scancode format (for editing the TOML by hand)

Each cell is a big-endian `u16`. Most are standard **USB HID usage codes** in the low
byte; HHKB-specific functions use higher values:

| Code | Meaning |
|---|---|
| `0x0000` | none / reserved |
| `0x0001` | error-rollover (used as a "dead"/blank cell on Fn layers) |
| `0x0004`–`0x001d` | A–Z · `0x001e`–`0x0027` = 1–0 |
| `0x002a` Backspace · `0x002c` Space · `0x004c` Delete · `0x0028` Return | |
| `0x00e0`–`0x00e7` | LCtrl, LShift, LAlt, LMeta(◇) / RCtrl, RShift, RAlt, RMeta(◇) |
| `0x00f4`/`f5`/`f6` | mouse L/M/R click · `0x00f9`–`fc` mouse wheel |
| `0x5101`/`5102`/`5103` | Fn1 / Fn2 / Fn3 layer keys |
| `0x5f8c`/`5f8d` | Alt-Tab left/right · `0x5f9e`–`5fa7` gesture/pointing-stick speed |

Full mapping: `scancode.rs` in the `hhkb-studio-tools` source.

**Editing by hand:** flat array index = `row*15 + col` (row 0 = top alpha row, row 4 =
bottom modifier row). Bottom-row key cells are **62** (left-outer Alt), **63** (Left ◇/Fn1),
**65** (Space), **68** (right-outer), **69** (right key next to space).

---

## DIP switches

`info` reports `DIP Sw: 000011` (SW1→SW6, MSB first). These are physical switches on the
underside and are **not** settable in software — only readable. They affect firmware-level
behaviors (e.g. Mac/Windows mode, which influences whether ◇ or Alt sits next to space at
the hardware level). The Alt/Meta arrangement here is handled in the **keymap**, not via DIP.
