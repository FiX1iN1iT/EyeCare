//
//  AppSettings.swift
//  EyeCare
//

import Foundation
import Combine

enum MenuBarStyle: String, CaseIterable, Identifiable {
    /// «05:35»
    case clock
    /// «6 мин»
    case minutes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clock: "05:35"
        case .minutes: "5 мин"
        }
    }
}

/// Пользовательские настройки, сохраняются в UserDefaults.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    static let workMinutesRange = 1...120
    static let breakSecondsRange = 10...600

    @Published var workMinutes: Int {
        didSet { defaults.set(workMinutes, forKey: Key.workMinutes) }
    }
    @Published var breakSeconds: Int {
        didSet { defaults.set(breakSeconds, forKey: Key.breakSeconds) }
    }
    @Published var menuBarStyle: MenuBarStyle {
        didSet { defaults.set(menuBarStyle.rawValue, forKey: Key.menuBarStyle) }
    }
    @Published var smartPauseEnabled: Bool {
        didSet { defaults.set(smartPauseEnabled, forKey: Key.smartPauseEnabled) }
    }

    var workDuration: TimeInterval { TimeInterval(workMinutes * 60) }
    var breakDuration: TimeInterval { TimeInterval(breakSeconds) }

    private enum Key {
        static let workMinutes = "workMinutes"
        static let breakSeconds = "breakSeconds"
        static let menuBarStyle = "menuBarStyle"
        static let smartPauseEnabled = "smartPauseEnabled"
    }

    private let defaults = UserDefaults.standard

    private init() {
        defaults.register(defaults: [
            Key.workMinutes: 20,
            Key.breakSeconds: 60,
            Key.menuBarStyle: MenuBarStyle.clock.rawValue,
            Key.smartPauseEnabled: true,
        ])
        workMinutes = defaults.integer(forKey: Key.workMinutes)
        breakSeconds = defaults.integer(forKey: Key.breakSeconds)
        menuBarStyle = MenuBarStyle(rawValue: defaults.string(forKey: Key.menuBarStyle) ?? "") ?? .clock
        smartPauseEnabled = defaults.bool(forKey: Key.smartPauseEnabled)
    }
}
