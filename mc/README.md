# Midnight Commander

`skins/ef-elea-light.ini` is a true-colour Midnight Commander skin based on
the palette of Emacs `ef-elea-light` from ef-themes 2.2.0.

Run `../scripts/link-configs.sh` from this directory (or
`scripts/link-configs.sh` from the repository root) to link the skin into
`~/.local/share/mc/skins/`. The linker preserves any existing file in its
timestamped backup directory.

Preview it without changing MC's preferences:

```bash
mc --skin=ef-elea-light
```

To make it persistent, choose **Options → Appearance → Ef Elea Light** inside
MC. True colour requires MC 4.8.19 or newer built with S-Lang 2.3.1 or newer,
plus a terminal with `COLORTERM=truecolor` (or `24bit`).
