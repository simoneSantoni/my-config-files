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

## Getting the tool (it has gone missing before)

`hhkb-studio-tools` lives at `~/.cargo/bin/hhkb-studio-tools` and is **not** packaged —
it is a `cargo install` from git. On 2026-08-07 it was gone along with the entire Rust
toolchain (no `~/.cargo`, no `cargo`/`rustc`, no distro `rust` package). Rebuild it
without root:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
~/.cargo/bin/cargo install --git https://github.com/yuja/hhkb-studio-tools
```

`zsh/.zshrc` now puts `~/.cargo/bin` on `PATH`; in a non-login shell (or an agent's
`Bash` tool) export it explicitly before use.

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
replugs**. The config one is the vendor interface with **HID usage page `0xFF60`**.
Don't hardcode a number — probe.

⚠️ Probing all five with `info` can **hang**: the `0xFF31` vendor node is a decoy that
never returns. Narrow the field via sysfs first — the two vendor interfaces are the
only ones with no `input/` subdirectory, so this rules out three of the five without
opening any device:

```bash
for n in $(ls /sys/class/hidraw | sed 's/hidraw//'); do
  d=$(readlink -f /sys/class/hidraw/hidraw$n/device)
  grep -q 04FE:0016 <<<"$d" || continue
  printf "hidraw%-3s input=[%s]\n" "$n" "$(ls $d/input 2>/dev/null | tr '\n' ' ')"
done
```

Then probe only the `input=[]` candidates, **always under `timeout`** so the decoy
can't wedge the shell:

```bash
for n in <candidates>; do echo "hidraw$n:"; timeout 6 hhkb-studio-tools info --device /dev/hidraw$n 2>&1 | head -1; done
```

The node returning `Product name: HHKB-Studio` is it (2026-06-26: `hidraw2`;
2026-08-07: `hidraw7`, with the five nodes enumerating as `hidraw6`–`hidraw10`).

Note: `report_descriptor` is **not** exposed under `/sys/class/hidraw/*/device/` on
this kernel, so you cannot identify the interface by its `0660ff…` descriptor prefix.

## Permissions

hidraw nodes are `root:root` and ACLs **reset on every replug**. The user (`simon`)
is **not** in the `input` group, so `/dev/input/event*` (evdev) is not readable —
don't try to sniff keys that way. Use the ACL'd hidraw nodes:

```bash
sudo setfacl -m u:simon:rw $(ls -d /dev/hidraw* )   # or just the five HHKB nodes
```

`sudo` here is **not** passwordless, so an agent cannot run this itself — hand the
command to the user (`! sudo setfacl …`) and wait. Re-granting is needed after every
replug, and the node numbers will have shifted by then.

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
