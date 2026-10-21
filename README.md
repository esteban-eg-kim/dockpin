# <img src="docs/logo/dockpin-512.png" alt="" width="40"> dockpin

**English** · [한국어](README.ko.md)

**Keep the macOS Dock on one display.**

With more than one display, macOS moves the Dock to whichever screen you push the
cursor against the bottom of. Reach for a window near the bottom of your second
monitor and the Dock jumps over. There is no setting to turn this off.

dockpin is a small menu bar app that stops it. Pick the display the Dock belongs
on; the Dock edges of the other displays stop waking the Dock. Hold `Option` when
you do want to move it.

## Install

```sh
brew install --cask esteban-eg-kim/tap/dockpin
```

Or download `dockpin-x.y.z.zip` from [Releases](https://github.com/esteban-eg-kim/dockpin/releases),
move `dockpin.app` to `/Applications`, and run once:

```sh
xattr -dr com.apple.quarantine /Applications/dockpin.app
```

dockpin is not notarized (no paid Apple Developer account), so without that line
macOS refuses to open it. The source is all here; you can also [build it yourself](#build).

Requires macOS 13 or later.

## Use

1. Open dockpin. It asks for **Accessibility** access: System Settings ›
   Privacy & Security › Accessibility › turn on dockpin. It uses it to filter mouse
   movement and, when you pick a display, to move the cursor there. It never looks
   at the keyboard, so Input Monitoring is not needed.
2. Click the pin in the menu bar and choose the display under **Keep the Dock on**.
   On first run it picks the display the Dock is on now.

| Menu item | What it does |
|---|---|
| Pin the Dock | Turn dockpin on or off. The pin icon is crossed out while off. |
| Keep the Dock on | The display the Dock stays on. Picking one moves the Dock there right away. |
| Hold ⌥ to Let It Move | While `Option` is held, the Dock moves the normal way. |
| Open at Login | Start dockpin when you log in. |

## How it works

The Dock moves when it sees the cursor pressing against a display's Dock edge.
dockpin installs a mouse event tap and drops the mouse-moved events that land in a
4-point strip along that edge on every display except the pinned one. The pointer
itself still moves; the Dock just never sees the push.

To move the Dock when you pick a display, dockpin does what you would: it hides the
pointer, runs it into that display's Dock edge for half a second, and puts it back.
It pushes on a stretch of edge with no display beyond it, so the push can't slip
onto a neighbour. The same happens when the pinned display is plugged back in.

Only the *outer* part of an edge is guarded. Where another display is attached
below (or beside, for a left/right Dock), the cursor crosses over as usual. The
Dock's side (bottom, left, right) and display changes are picked up on their own.

## Limitations

- Apps on the other displays don't get hover events in that 4-point strip.
- Hot corners at the Dock edge of the other displays don't fire.
- macOS ties these permissions to the app's signature. dockpin is ad-hoc signed,
  so after an upgrade you may need to remove it from the Accessibility list (`−`)
  and add it back.
- If the pinned display is unplugged, dockpin keeps the Dock where it is until the
  display comes back, then moves it home.
- With Dock auto-hide on, dockpin can't tell which display the Dock is on, so it
  only moves the Dock when you pick a display.

## Build

Needs only the Xcode Command Line Tools (`xcode-select --install`).

```sh
scripts/test.sh               # geometry tests (swift test, CLT-friendly)
ARCHS=arm64 scripts/bundle.sh # → build/dockpin.app
open build/dockpin.app
```

Each ad-hoc build gets a new signature, which resets the Accessibility grant. To
keep it, sign every build with one self-signed code signing certificate:
`SIGN_ID="<name or SHA-1>" scripts/bundle.sh`. If `codesign` fails with
`errSecInternalComponent` (it can't ask for the key), keep the identity in its own
keychain and add `SIGN_KEYCHAIN=<path>` and `SIGN_KEYCHAIN_PASSWORD=<password>`.
Put these in `.env.signing` (git-ignored) to make them the default.

`swift run` works for the menu, but Open at Login needs the bundled app.

## Related

[DockAnchor](https://github.com/bwya77/DockAnchor) solves the same problem with
more features (profiles, moving the Dock back automatically). dockpin aims to be
smaller: one menu, and it leaves edges shared between displays open.

## License

MIT
