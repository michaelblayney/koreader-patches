# koreader-patches

My KOReader user patches, built for a Kindle Paperwhite 12th gen (KOReader v2026.07).

## What's here

- `patches/` go on the e-reader.
  - `2-my-folder-cover.lua`: folder tiles in the Mosaic file browser get a folder tab (with the
    folder name, toggled by "Show folder name"), coloured from the top of the cover,
    stacked sheets behind (top and right), thin borders and a rounded-square book count badge.
    Settings for sizes and colours are in the `Folder = {...}` block near the top.
    Menu toggles: file browser settings → Mosaic and detailed list settings.
  - `2-no-focus-underline.lua`: removes the black underline KOReader puts under the folder
    you just came back out of (and any other focus underline) in the Mosaic and list views.
- `desktop/` is for the desktop emulator only.
  - `2-desktop-hide-shortcuts.lua`: hides the Q/W/E keyboard shortcut labels so the
    file browser looks like it does on an e-reader. Does nothing on a device.
  - `2-desktop-eink-look.lua`: makes the emulator window look like an e-ink screen
    (16 grey levels, ordered dithering, tinted paper, grey ink). Needs `EMULATE_BB_TYPE=BB8`.
    `EINK_LOOK=lit` (default, frontlight on), `unlit` (frontlight off) or `plain` (off).
    Tune the presets in the `Presets = {...}` block.

## Installing on the device

Copy a patch into the `koreader/patches/` folder on the device (create it if missing),
then restart KOReader. On a Kindle that's `/mnt/us/koreader/patches/`.

Over KOReader's SSH server (gear tab → Network → SSH server):

```
scp -O -P 2222 patches/2-my-folder-cover.lua root@<kindle-ip>:/mnt/us/koreader/patches/
```

`-O` is needed because KOReader's SSH server doesn't support the newer scp protocol.

A broken patch only shows an "Error applying patch" popup; remove the file to undo.

`2-my-folder-cover.lua` replaces sebdelsol's `2-browser-folder-cover.lua`. Don't run both:
the original draws the tiles first and this one then skips them.

## Developing on the desktop

KOReader's Linux AppImage runs as an emulator, which is much faster for trying changes.

1. Download the AppImage from the [KOReader releases](https://github.com/koreader/koreader/releases).
   Pick the version closest to the one on your device.
2. Match your device's screen, scaled down to fit your monitor. KOReader sizes its UI by DPI,
   so scaling width, height and DPI by the same factor gives an exact miniature. For a
   Paperwhite 12th gen (1272x1696 at 300 dpi), at 50%:
   ```
   EMULATE_READER_W=636 EMULATE_READER_H=848 EMULATE_READER_DPI=150 ./koreader-*.AppImage
   ```
3. Symlink the patches into the emulator's patch folder, so edits here are picked up on restart:
   ```
   mkdir -p ~/.config/koreader/patches
   ln -s "$PWD"/patches/*.lua "$PWD"/desktop/*.lua ~/.config/koreader/patches/
   ```

### CachyOS: emulator crashes on startup as a "Kobo"

KOReader decides it's running on a Kobo if `/usr/bin/hwdetect` exists, and CachyOS ships an
unrelated tool at that path. The crash ends in `frontend/device/kobo/device.lua ... getCodeName`.
Workaround: extract the AppImage (`--appimage-extract`), remove the `/usr/bin/hwdetect` check
from `kobo_test_stat` in `squashfs-root/usr/lib/koreader/frontend/device.lua`, and launch
`squashfs-root/AppRun` instead.
