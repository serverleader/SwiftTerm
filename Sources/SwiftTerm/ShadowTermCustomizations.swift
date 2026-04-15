//
//  ShadowTermCustomizations.swift
//  SwiftTerm (ShadowTerm fork)
//
//  Master toggle for fork-local behavior changes. When `enabled` is true
//  (default), all ShadowTerm-specific code paths are active. When false,
//  the fork falls back to upstream SwiftTerm behavior so the two can be
//  A/B compared from app config without rebuilding.
//

import Foundation

public enum ShadowTermCustomizations {
    /// UserDefaults key. Set to `true` to disable ShadowTerm customizations
    /// and run upstream SwiftTerm behavior. Defaults to `false` (off → use ours).
    public static let useUpstreamBehaviorKey = "wiki.qaq.shadowterm.useUpstreamSwiftTerm"

    /// `true` when ShadowTerm-specific customizations should be active.
    public static var enabled: Bool {
        !UserDefaults.standard.bool(forKey: useUpstreamBehaviorKey)
    }
}
