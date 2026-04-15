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
| Foreground redraw | `wiki.qaq.shadowterm.cust.foregroundRedraw` | `true` | `iOSTerminalView.setupForegroundRedraw` |
| Wide accessory bar (>=768pt) | `wiki.qaq.shadowterm.cust.wideAccessoryBar` | `true` | `iOSTerminalView.setupAccessoryView` |

The user-facing "Hide on-screen keyboard" feature
(`wiki.qaq.shadowterm.hideOnScreenKeyboard`) lives at three additional
sites in `iOSTerminalView` (`sharedMouseEvent`, `canBecomeFirstResponder`,
`becomeFirstResponder`). It is gated by the master flag only ... it is a
real product feature, not a fork-vs-upstream A/B target.

## Additive (always-on) API

Not gated by any flag because they are pure additions and have no upstream
equivalent to compare against:

- `TerminalView.applyEffectiveSize(_:)` ... public re-entry to
  `processSizeChange` for the keyboard-resize path.
- `TerminalView.resizeLocked` ... opt-in lock used by the host app.
- `SelectionService` and `selection` made `public` for app inspection.
- `ensureCaretIsVisible` made `@objc public` so the host can trigger it.
- `Terminal.TmuxPassthroughDcsHandler` class definition ... only registered
  when `clipboardSync` is on.
- iOS `_fontSmoothing` / `_lineSpacing` storage ... fixes upstream PR #531
  which referenced these from the cross-platform `AppleTerminalView`
  extension without declaring storage on iOS.

## Regenerating the patch

```bash
cd /path/to/SwiftTerm
git fetch upstream
git diff upstream/main..HEAD -- Sources/ > Patches/shadowterm-customizations.patch
```

Commit the regenerated patch alongside the source changes whenever a
customization site moves or a new one is added.
