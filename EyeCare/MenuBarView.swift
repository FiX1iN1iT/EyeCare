//
//  MenuBarView.swift
//  EyeCare
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var timer: BreakTimer

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(timer.isPaused ? "Пауза" : "До перерыва")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(timer.remainingText)
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            HStack {
                Button(timer.isPaused ? "Продолжить" : "Пауза") { timer.togglePause() }
                Button("Сбросить") { timer.resetWork() }
            }

            Button("Начать перерыв сейчас") { timer.startBreakNow() }
                .buttonStyle(.borderedProminent)

            Divider()

            Button("Выйти") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .overlay(alignment: .topTrailing) {
            Button {
                SettingsWindowController.shared.show()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Настройки")
            .padding(8)
        }
        .frame(width: 240)
    }
}
