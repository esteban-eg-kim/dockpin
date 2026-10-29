# <img src="docs/logo/dockpin-512.png" alt="" width="40"> dockpin

**English** · [한국어](README.ko.md) · [Website](https://xkorfun.github.io)

**Keep the macOS Dock on one display.**

With more than one display, macOS moves the Dock to whichever screen you push the
cursor against the bottom of. Reach for a window near the bottom of your second
monitor and the Dock jumps over. There is no setting to turn this off.

dockpin is a small menu bar app that stops it.

<p align="center">
  <img src="docs/media/demo-en.gif" alt="dockpin demo: the Dock stays put, moves when you pick a display, and moves with Option held" width="720">
</p>

<p align="center"><a href="docs/media/demo-en.mp4">Watch in full quality (MP4)</a></p>

## Features

- **The Dock stays put.** The Dock edges of your other displays stop pulling the
  Dock over. The pointer still moves freely.
- **Pick a display, the Dock moves there.** Right away, from the menu bar.
- **Hold `Option`** to move the Dock the usual way when you want to.
- **Knows your layout.** Edges shared with a neighbouring display stay open, so the
  pointer still crosses between stacked monitors. Bottom, left and right Docks.
- **Brings the Dock home** when macOS moves it by itself (displays waking from
  sleep) or the pinned display is plugged back in. Never on the lock screen.
- **A fallback display** for while the pinned one is unplugged.
- **Works with auto-hide.**
- **One permission, no network.** Accessibility only. No keyboard access, no data
  collected.

## Install

```sh
brew install --cask esteban-eg-kim/tap/dockpin
```

Or download `dockpin-x.y.z.zip` from [Releases](https://github.com/esteban-eg-kim/dockpin/releases),
move `dockpin.app` to `/Applications`, and run once:

```sh
xattr -dr com.apple.quarantine /Applications/dockpin.app
```

dockpin is signed but not notarized (no paid Apple Developer account), so without
that line macOS refuses to open it. Homebrew does it for you.

## Quick start

1. Open dockpin and allow it under System Settings › Privacy & Security ›
   **Accessibility** (macOS 27: **Device Control and Data Access**).
2. Click the pin in the menu bar and choose the display under **Keep the Dock on**.
3. That's it. Push against the bottom of another display: the Dock stays.

<p align="center"><img src="docs/img/menu.png" alt="The dockpin menu" width="560"></p>

The full guide covers every menu item, multi-display layouts, auto-hide and
troubleshooting: **[Manual](docs/manual.md)** ([한국어](docs/manual.ko.md)).

## How it works

The Dock moves when it sees the pointer pressing against a display's Dock edge.
dockpin drops the mouse moves that land in a 4-point strip along that edge on every
display except the pinned one, and only on the *outer* part of the edge.

<p align="center"><img src="docs/img/edges-en.png" alt="Guarded and open edges on a three-display desk" width="720"></p>

To move the Dock, dockpin does what you would: it runs the pointer into the pinned
display's Dock edge for half a second, then puts it back.

## Requirements

| | |
|---|---|
| macOS | 13 Ventura or later (tested on macOS 27) |
| Chips | Apple silicon and Intel (universal) |
| Permission | Accessibility |

## Build

Needs only the Xcode Command Line Tools (`xcode-select --install`).

```sh
scripts/test.sh               # unit tests
ARCHS=arm64 scripts/bundle.sh # → build/dockpin.app
open build/dockpin.app
```

See [Build from source](docs/manual.md#build-from-source) for keeping the
permission across rebuilds, and `docs/media/make.sh` for the pictures and video.

## Related

[DockAnchor](https://github.com/bwya77/DockAnchor) solves the same problem with
more features (profiles, moving the Dock back automatically). dockpin aims to be
smaller: one menu, and it leaves edges shared between displays open.

## License

MIT
