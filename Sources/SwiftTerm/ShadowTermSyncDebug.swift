//
//  ShadowTermSyncDebug.swift
//  SwiftTerm (ShadowTerm fork)
//
//  Upstream's DEC 2026 synchronized-output work (merged 2026-06) calls
//  `SyncDebug.log(...)` throughout AppleTerminalView.swift and Terminal.swift
//  but, at the upstream `main` commit we synced from, never defines the
//  `SyncDebug` type ... so upstream itself wouldn't compile standalone. This
//  no-op shim provides the symbol so the fork builds.
//
//  REMOVE THIS when upstream adds its own `SyncDebug` definition (a future
//  upstream sync will conflict here and surface it). The `@autoclosure` means
//  the interpolated log strings are never even evaluated, so this is free.
//

enum SyncDebug {
    @inline(__always)
    static func log(_ message: @autoclosure () -> String) {}
}
