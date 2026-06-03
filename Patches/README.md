# ShadowTerm SwiftTerm Patches

This directory documents the customizations the ShadowTerm fork carries on
top of upstream `migueldeicaza/SwiftTerm`. The patch is a snapshot of every
diff under `Sources/` between `upstream/main` and the current branch tip.

## Files

- `shadowterm-customizations.patch` ... unified diff vs `upstream/main`,
  generated with `git diff upstream/main..HEAD -- Sources/`. Apply with
  `git apply` or `patch -p1` if you ever need to recreate the fork from a
  clean upstream checkout.

## Customizations covered

All gated through `Sources/SwiftTerm/ShadowTermCustomizations.swift`.
Each is independently toggleable from app config (`Settings ... Diagnostics`
in mShadowTerm). The master `useUpstreamSwiftTerm` UserDefault forces every
feature off.

| Feature | UserDefaults key | Default | Site |
|---|---|---|---|
| Master kill switch | `wiki.qaq.shadowterm.useUpstreamSwiftTerm` | `false` | every gate |
| Tmux DCS + OSC 52 clipboard sync | `wiki.qaq.shadowterm.cust.clipboardSync` | `true` | `EscapeSequenceParser.dispatchDcs`, `Terminal.oscClipboard` |
| Scroll tracks `yDisp` | `wiki.qaq.shadowterm.cust.scrollToYDisp` | `true` | `iOSTerminalView.updateScroller` |
| Smart cursor visibility | `wiki.qaq.shadowterm.smartCursorVisibility` | `true` | `iOSTerminalView.ensureCaretIsVisible` |
| Initial-resize bypass | `wiki.qaq.shadowterm.cust.initialResizeBypass` | `true` | `AppleTerminalView.processSizeChange` |
| Wide accessory bar (>=768pt) | `wiki.qaq.shadowterm.cust.wideAccessoryBar` | `true` | `iOSTerminalView.setupAccessoryView` |
| Scroll-wheel reporting (gesture -> button 4/5) | `wiki.qaq.shadowterm.cust.scrollWheelReporting` | `true` | `iOSTerminalView` scroll gestures |

The user-facing "Hide on-screen keyboard" feature
(`wiki.qaq.shadowterm.hideOnScreenKeyboard`) lives at three additional
sites in `iOSTerminalView` (`sharedMouseEvent`, `canBecomeFirstResponder`,
`becomeFirstResponder`). It is gated by the master flag only ... it is a
real product feature, not a fork-vs-upstream A/B target.

## Hard behavior changes (not flag-gated)

These change a default outright because the upstream behavior is wrong for a
windowed/SSH terminal; there is no per-feature toggle.

- **DECCOLM disabled** ... `Terminal.allow80To132` defaults to `false` (and
  resets to `false` in `resetToInitialState`), matching xterm's
  `c132`/`allowColumnSwitching` default. With it on, a remote-emitted DECCOLM
  (`ESC[?3h/l`) resized the local terminal to 132/80 columns + full reset,
  which fired a PTY window-change that aborted GNU `screen` copy mode and
  garbled the screen on connect. Apps that genuinely want column switching
  still opt in via `DECSET 40` (`ESC[?40h`).

## Additive (always-on) API

Not gated by any flag because they are pure additions and have no upstream
equivalent to compare against:

- `TerminalView.applyEffectiveSize(_:)` ... public re-entry to
  `processSizeChange` for the keyboard-resize path.
- `TerminalView.resizeLocked` ... opt-in lock used by the host app (iOS + Mac).
- `TerminalView.renderedCellSize` ... public accessor exposing the internal
  `cellDimension` (the host's `[LAYOUT]` diagnostics read it).
- `TerminalView.altScreenBottomAnchor` ... bottom-anchors alternate-screen
  content via `contentInset.top`; used by the mosh framebuffer path
  (alt-screen with `yDisp == 0`, which `updateScroller` can't otherwise help).
- `SelectionService` and `selection` made `public` for app inspection.
- `ensureCaretIsVisible` made `@objc public` so the host can trigger it.
- `Terminal.TmuxPassthroughDcsHandler` class definition ... only registered
  when `clipboardSync` is on.
- iOS `_fontSmoothing` / `_lineSpacing` storage ... fixes upstream PR #531
  which referenced these from the cross-platform `AppleTerminalView`
  extension without declaring storage on iOS.

## Temporary shims

- `ShadowTermSyncDebug.swift` ... a no-op `SyncDebug` enum. Upstream's
  DEC 2026 synchronized-output work calls `SyncDebug.log(...)` throughout
  `AppleTerminalView`/`Terminal` but, at the `upstream/main` commit synced in
  2026-06, never defines the type (upstream WIP). **Remove this once upstream
  ships its own `SyncDebug`** ... a future upstream sync will conflict here
  and surface it.

## Regenerating the patch

```bash
cd /path/to/SwiftTerm
git fetch upstream
git diff upstream/main..HEAD -- Sources/ > Patches/shadowterm-customizations.patch
```

Commit the regenerated patch alongside the source changes whenever a
customization site moves or a new one is added.
