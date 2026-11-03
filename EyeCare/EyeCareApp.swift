//
//  EyeCareApp.swift
//  EyeCare
//

import SwiftUI

@main
struct EyeCareApp: App {
    @StateObject private var timer = BreakTimer()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(timer: timer)
        } label: {
            Image(systemName: timer.phase == .onBreak ? "eye.slash" : "eye")
            if timer.phase != .onBreak {
                Text(timer.menuBarText)
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
