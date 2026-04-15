//
//  ShadowTermCustomizations.swift
//  SwiftTerm (ShadowTerm fork)
//
//  Per-feature toggles for fork-local behavior changes. Every customization
//  defaults to active (= ShadowTerm behavior) so the package behaves as
//  before unless the host app flips a UserDefault. The master kill switch
//  `useUpstreamBehaviorKey` overrides every per-feature flag and forces
//  upstream paths everywhere ... handy for A/B comparison.
//

import Foundation

public enum ShadowTermCustomizations {
    /// Master kill switch. When `true`, every customization falls back to
    /// the upstream SwiftTerm code path regardless of the per-feature flags.
    public static let useUpstreamBehaviorKey = "wiki.qaq.shadowterm.useUpstreamSwiftTerm"

    /// Individually toggleable customizations. The raw value is the
    /// UserDefaults key. Each defaults to `true` (= ShadowTerm behavior)
    /// when the key is absent.
    public enum Feature: String, CaseIterable {
        /// Tmux DCS passthrough handler + relaxed OSC 52 clipboard parsing.
        case clipboardSync = "wiki.qaq.shadowterm.cust.clipboardSync"
        /// iOS scroll view tracks `displayBuffer.yDisp` instead of always
        /// snapping to the bottom on `updateScroller`.
        case scrollToYDisp = "wiki.qaq.shadowterm.cust.scrollToYDisp"
        /// Smart caret visibility (only scrolls when the cursor leaves the
        /// visible viewport, with padding) instead of upstream's
        /// scroll-to-bottom on every render. Reuses the legacy key.
        case smartCursor = "wiki.qaq.shadowterm.smartCursorVisibility"
        /// Allow `processSizeChange` through when `resizeLocked` is set but
        /// the terminal hasn't received its first proper dimensions yet.
        case initialResizeBypass = "wiki.qaq.shadowterm.cust.initialResizeBypass"
        /// Discard the iOS terminal layer's cached contents on
        /// `didBecomeActiveNotification` so background → foreground
        /// transitions don't show stale tiles.
        case foregroundRedraw = "wiki.qaq.shadowterm.cust.foregroundRedraw"
        /// Use a width-based heuristic (>=768pt = wide) for the iOS
        /// keyboard accessory bar height instead of `userInterfaceIdiom`.
        case wideAccessoryBar = "wiki.qaq.shadowterm.cust.wideAccessoryBar"
    }

    /// `true` when ShadowTerm's customizations are allowed at all. When
    /// `false`, every per-feature check returns `false`.
    public static var enabled: Bool {
        !UserDefaults.standard.bool(forKey: useUpstreamBehaviorKey)
    }

    /// `true` when a specific customization should run. Master flag
    /// overrides; otherwise reads the per-feature key with default `true`.
    public static func isEnabled(_ feature: Feature) -> Bool {
        guard enabled else { return false }
        return UserDefaults.standard.object(forKey: feature.rawValue) as? Bool ?? true
    }
}
