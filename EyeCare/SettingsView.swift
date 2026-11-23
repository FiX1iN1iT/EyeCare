//
//  SettingsView.swift
//  EyeCare
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "eye")
                    .font(.system(size: 30))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading) {
                    Text("EyeCare").font(.title2.bold())
                    Text("Забота о глазах во время работы")
                        .foregroundStyle(.secondary)
                }
            }

            Form {
                Section("Перерывы") {
                    Stepper(value: $settings.workMinutes, in: AppSettings.workMinutesRange) {
                        LabeledContent("Время до перерыва", value: "\(settings.workMinutes) мин")
                    }
                    Stepper(value: $settings.breakSeconds, in: AppSettings.breakSecondsRange, step: 10) {
                        LabeledContent("Длительность перерыва", value: Self.breakText(settings.breakSeconds))
                    }
                    Toggle("Умная пауза при подключении к звонку", isOn: $settings.smartPauseEnabled)
                    Text("Останавливает таймер, когда звонок использует микрофон — даже если он выключен.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Menu Bar") {
                    Picker("Стиль таймера", selection: $settings.menuBarStyle) {
                        ForEach(MenuBarStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
        }
        .padding(20)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }

    private static func breakText(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        switch (m, s) {
        case (0, _): return "\(s) сек"
        case (_, 0): return "\(m) мин"
        default: return "\(m) мин \(s) сек"
        }
    }
}

/// Окно настроек, которое можно открыть откуда угодно (в том числе с экрана перерыва).
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func show(aboveOverlay: Bool = false) {
        let window = window ?? makeWindow()
        self.window = window
        window.level = aboveOverlay ? NSWindow.Level(NSWindow.Level.screenSaver.rawValue + 1) : .normal
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func lowerLevel() {
        window?.level = .normal
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
        window.title = "EyeCare"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
