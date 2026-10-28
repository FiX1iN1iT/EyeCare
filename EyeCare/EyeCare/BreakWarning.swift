//
//  BreakWarning.swift
//  EyeCare
//

import SwiftUI
import AppKit

/// Плашка в правом верхнем углу: «Перерыв через 00:59».
final class BreakWarningController {
    private static let animationDuration: TimeInterval = 0.4
    /// Плашка выезжает справа и уезжает обратно.
    private static let slideOffset: CGFloat = 40

    private var panel: NSPanel?

    func show(timer: BreakTimer) {
        guard panel == nil, let screen = NSScreen.main else { return }

        let size = NSSize(width: 290, height: 64)
        let frame = screen.visibleFrame
        let shown = NSRect(x: frame.maxX - size.width - 16, y: frame.maxY - size.height - 12,
                           width: size.width, height: size.height)

        let panel = NSPanel(contentRect: shown.offsetBy(dx: Self.slideOffset, dy: 0),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = NSHostingView(rootView: BreakWarningView(timer: timer))
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        self.panel = panel

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
            panel.animator().setFrame(shown, display: true)
        }
    }

    func hide() {
        guard let panel else { return }
        self.panel = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
            panel.animator().setFrame(panel.frame.offsetBy(dx: Self.slideOffset, dy: 0), display: true)
        } completionHandler: {
            panel.orderOut(nil)
        }
    }
}

private struct BreakWarningView: View {
    @ObservedObject var timer: BreakTimer

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye")
                .font(.title2)
            Text("Перерыв через")
            Text(timer.remainingText)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topLeading) {
            Button {
                timer.dismissWarning()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .background(.thinMaterial, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(6)
            .help("Закрыть")
        }
    }
}
