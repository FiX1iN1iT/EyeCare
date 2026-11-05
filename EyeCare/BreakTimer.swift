//
//  BreakTimer.swift
//  EyeCare
//

import Foundation
import Combine

/// Таймер «работа → перерыв → работа».
final class BreakTimer: ObservableObject {
    enum Phase {
        case working
        case onBreak
    }

    let settings = AppSettings.shared

    @Published private(set) var phase: Phase = .working
    @Published private(set) var isPaused = false
    /// Оставшееся время текущей фазы, секунды.
    @Published private(set) var remaining: TimeInterval
    /// Текущее время — для часов на экране перерыва.
    @Published private(set) var now = Date()

    private var deadline: Date
    private var ticker: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let overlay = BreakOverlayController()
    private let warning = BreakWarningController()
    private var warningShown = false
    private let cursorHint = BreakCursorHintController()

    private static let cursorHintLead: TimeInterval = 10

    private static let warningLead: TimeInterval = 60
    private static let warningDuration: TimeInterval = 5

    init() {
        let work = AppSettings.shared.workDuration
        remaining = work
        deadline = Date().addingTimeInterval(work)

        let ticker = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker

        // Стиль в меню-баре зависит от настроек.
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Новое время до перерыва применяется сразу.
        settings.$workMinutes
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self, self.phase == .working else { return }
                self.startWork()
            }
            .store(in: &cancellables)
    }

    var workDuration: TimeInterval { settings.workDuration }

    var remainingText: String { Self.format(remaining) }

    /// Текст в строке меню в выбранном стиле.
    var menuBarText: String {
        switch settings.menuBarStyle {
        case .clock:
            return Self.format(remaining)
        case .minutes:
            return "\(max(1, Int((remaining / 60).rounded(.up)))) мин"
        }
    }

    static func format(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // MARK: - Actions

    func startBreakNow() {
        beginBreak()
    }

    func skipBreak() {
        endBreak()
    }

    func resetWork() {
        startWork()
    }

    /// Закрывает плашку-предупреждение; в этом цикле она больше не появится.
    func dismissWarning() {
        warning.hide()
    }

    /// Откладывает перерыв на `interval` секунд. Плашки скрываются и появятся снова
    /// в положенный момент (за минуту / за 10 секунд до перерыва).
    func extendWork(by interval: TimeInterval) {
        guard phase == .working else { return }
        deadline = deadline.addingTimeInterval(interval)
        remaining += interval
        warning.hide()
        cursorHint.hide()
        warningShown = false
    }

    func togglePause() {
        guard phase == .working else { return }
        if isPaused {
            deadline = Date().addingTimeInterval(remaining)
            isPaused = false
        } else {
            isPaused = true
            warning.hide()
            cursorHint.hide()
        }
    }

    // MARK: - Private

    private func tick() {
        now = Date()
        guard !isPaused else { return }

        remaining = max(0, deadline.timeIntervalSinceNow)
        updateWarning()
        updateCursorHint()
        if remaining <= 0 {
            switch phase {
            case .working: beginBreak()
            case .onBreak: endBreak()
            }
        }
    }

    /// За минуту до перерыва на 5 секунд показывает плашку с обратным отсчётом.
    private func updateWarning() {
        guard phase == .working, workDuration > Self.warningLead else { return }
        let elapsed = Self.warningLead - remaining
        if !warningShown, elapsed >= 0, elapsed < Self.warningDuration {
            warningShown = true
            warning.show(timer: self)
        } else if elapsed >= Self.warningDuration {
            warning.hide()
        }
    }

    /// За 10 секунд до перерыва показывает плашку у указателя мыши.
    private func updateCursorHint() {
        guard phase == .working, remaining > 0, remaining <= Self.cursorHintLead else { return }
        cursorHint.show(timer: self)
    }

    private func startWork() {
        warning.hide()
        cursorHint.hide()
        warningShown = false
        phase = .working
        isPaused = false
        deadline = Date().addingTimeInterval(workDuration)
        remaining = workDuration
    }

    private func beginBreak() {
        warning.hide()
        cursorHint.hide()
        phase = .onBreak
        isPaused = false
        deadline = Date().addingTimeInterval(settings.breakDuration)
        remaining = settings.breakDuration
        overlay.show(timer: self)
    }

    private func endBreak() {
        overlay.hide()
        SettingsWindowController.shared.lowerLevel()
        startWork()
    }
}
