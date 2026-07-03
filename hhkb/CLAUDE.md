# CLAUDE.md — hhkb/

Guidance for working with the HHKB Studio keymap config in this directory. See
`README.md` for the full user-facing reference; this file is the short "things that
will bite you" version.

## What this is

Keymap profiles for an **HHKB Studio (PD-ID100B, US)**, managed with
`hhkb-studio-tools` (`~/.cargo/bin/hhkb-studio-tools`, from
`github.com/yuja/hhkb-studio-tools`). These `.toml` files are exact dumps of the
keyboard's stored profiles — **the keyboard is the source of truth**, this repo is a
versioned snapshot + restore point. There is no symlink/deploy step; changes are
pushed to the keyboard with `write-profile`, not by editing a live config file.

## The #1 gotcha: USB-only, and the keyboard hides on Bluetooth

`hhkb-studio-tools` only works over the **wired USB** vendor interface. If you try to
read/write while the keyboard is on Bluetooth you get **silent garbage** (reads return
live keypresses; `info` returns empty strings) — not an error. Symptoms of "on
Bluetooth": `info` fields blank, repeated reads return *different* data, only
`hidraw1` is an HHKB node and its sysfs `HID_ID` bus is `0005`.

To get usable:
1. Connect a USB-C **data** cable (charge-only cables look identical and fail the same way).
2. If it doesn't enumerate (or enumerates ~2 s then drops back to BT), press
   **Fn + Control + 0** on the keyboard to force wired mode.
3. Verify: `lsusb | grep 04fe` → `04fe:0016`; five `hidraw` nodes on bus `0003`.

## Finding the config interface

Over USB the keyboard exposes 5 hidraw nodes; **numbering is not stable across
replugs**. The config one is the vendor interface with **HID usage page `0xFF60`**
(report descriptor starts `0660ff…`). Don't hardcode a number — probe:

```bash
for n in 1 2 3 4 5; do echo "hidraw$n:"; hhkb-studio-tools info --device /dev/hidraw$n 2>&1 | head -1; done
```

The node returning `Product name: HHKB-Studio` is it (recently `/dev/hidraw2`). The
`0xFF31` vendor node (`0631ff…`) is a decoy and hangs — don't use it.

## Permissions

hidraw nodes are `root:root` and ACLs **reset on every replug**. The user (`simon`)
is **not** in the `input` group, so `/dev/input/event*` (evdev) is not readable —
don't try to sniff keys that way. Use the ACL'd hidraw nodes:

```bash
sudo setfacl -m u:simon:rw /dev/hidraw1 /dev/hidraw2 /dev/hidraw3 /dev/hidraw4 /dev/hidraw5
```

## Data model

- 4 profiles × 4 layers × 120 scancodes. Layer 0 = base; layers 1–3 = Fn1/Fn2/Fn3.
- Each layer = flat `u16` array, **15 cols × 8 rows**, index = `row*15 + col`.
- Row 0 = alpha/number row, row 1 = Tab row, row 4 = bottom modifier row, rows 5–7 =
  mouse buttons / gesture pads / pointing-stick / scroll.
- Scancodes: low-byte USB HID for normal keys; `0x00e0`–`e7` = L/R Ctrl/Shift/Alt/Meta;
  `0x5101`–`5103` = Fn layer keys; `0x5f8c`+ = HHKB gestures. `0x0001` = inert/blank.

## Bottom-row cell map (the part most likely to be edited)

| cell | physical key |
|---|---|
| 62 | left-outer (LAlt) |
| 63 | Left ◇ (here: Fn1) |
| 65 | Space |
| 68 | right-**outer** modifier |
| 69 | right modifier **next to the spacebar** |

⚠️ Counter-intuitive: `show-profile` renders cell 68 to the *left* of cell 69 (so 68
looks "next to space"), but **physically cell 69 is the key beside the spacebar**.
Confirmed empirically (2026-06-26): writing `RMeta` (`0x00e7`) to **cell 69** put
Super/◇ next to space; `RAlt` (`0x00e6`) went to cell 68. Modifier identity lives in
**layer 0 only** — layers 1–3 hold other functions on those cells, so only edit layer 0
for Alt/Meta changes.

## Safe edit loop

```bash
DEV=/dev/hidraw2                                  # whatever probed as config iface
hhkb-studio-tools read-profile --device $DEV --index 0 -o /tmp/p0.toml   # back up first
cp /tmp/p0.toml /tmp/p0-edit.toml                 # edit the copy
hhkb-studio-tools show-profile -i /tmp/p0-edit.toml                      # eyeball it
hhkb-studio-tools write-profile --device $DEV --index 0 -i /tmp/p0-edit.toml
hhkb-studio-tools read-profile --device $DEV --index 0 -o /tmp/verify.toml
diff /tmp/p0-edit.toml /tmp/verify.toml           # must be identical
```

Then have the user **test by feel** — that's the only reliable oracle, since evdev
isn't readable here. Restore point: `profile-backup.toml` (factory/pre-remap).

## Keeping this repo in sync

After any `write-profile`, re-dump the affected profile to `current-profile-N.toml`
and regenerate `profile-N-decoded.txt` (`show-profile -i … > …`) so the repo matches
the keyboard.
