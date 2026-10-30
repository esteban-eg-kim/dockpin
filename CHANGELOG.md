# Changelog

## 0.1.1 (2026-10-30)

- README links the xkorfun site.
- New app icon in the macOS 26 Liquid Glass style: blue in light mode, graphite in
  dark mode, and it follows the tinted and clear icon styles. Earlier macOS versions
  get the light one. Source is `Resources/AppIcon.icon` (Icon Composer);
  `scripts/make-icon.sh` rebuilds it (needs Xcode, the app build itself does not).

## 0.1.0 (2026-10-29)

- First version: pin the Dock to one display from the menu bar.
- Picking a display moves the Dock there right away; so does plugging the pinned
  display back in.
- Guards only the outer part of each other display's Dock edge; edges shared with a
  neighbouring display stay open.
- Hold `Option` to move the Dock on purpose.
- Follows the Dock's side (bottom, left, right) and display changes automatically.
- Open at Login.
- Watches where the Dock is and fetches it back when macOS moves it by itself
  (displays waking from sleep), except after an Option move; also guards drags.
- Never moves the pointer on the lock screen or with the displays asleep; checks
  a second after unlock. Clears the Dock's hover magnification after a move.
- Finds the Dock by asking it (works with auto-hide), falling back to the screen layout.
- "If It's Unplugged": a fallback display while the pinned one is disconnected.
- Logs what it sees and does (`/usr/bin/log stream --predicate 'subsystem == "io.github.esteban-eg-kim.dockpin"'`).
- Manual in English and Korean, screenshots and a demo video
  (`docs/manual.md`, `docs/media/make.sh` regenerates the media).
