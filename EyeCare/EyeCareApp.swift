//
//  EyeCareApp.swift
//  EyeCare
//

import SwiftUI

@main
struct EyeCareApp: App {
    @StateObject private var timer = BreakTimer()

    private var menuBarIcon: String {
        if timer.phase == .onBreak { return "eye.slash" }
        if timer.isSmartPaused { return "phone.pause" }
        if timer.isPaused { return "pause" }
        return "eye"
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(timer: timer)
        } label: {
            Image(systemName: menuBarIcon)
            if timer.phase != .onBreak {
                Text(timer.menuBarText)
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
