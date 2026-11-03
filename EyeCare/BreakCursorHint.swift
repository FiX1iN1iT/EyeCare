//
//  BreakCursorHint.swift
//  EyeCare
//

import SwiftUI
import AppKit

/// Плашка «Перерыв начнется через …», которая следует за указателем мыши.
final class BreakCursorHintController {
    private static let size = NSSize(width: 300, height: 44)
    /// Смещение от указателя, чтобы плашка его не закрывала.
    private static let offset = NSPoint(x: 18, y: -18)

    private var panel: NSPanel?
    private var followTimer: Timer?

    func show(timer: BreakTimer) {
        guard panel == nil else { return }

        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: Self.size),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        // Плашка не должна мешать кликам под указателем.
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = NSHostingView(rootView: BreakCursorHintView(timer: timer))
        panel.alphaValue = 0
        self.panel = panel

        follow()
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            panel.animator().alphaValue = 1
        }

        let followTimer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.follow() }
        }
        RunLoop.main.add(followTimer, forMode: .common)
        self.followTimer = followTimer
    }

    func hide() {
        followTimer?.invalidate()
        followTimer = nil
        guard let panel else { return }
        self.panel = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            panel.animator().alphaValue = 0
        } completionHandler: {
            panel.orderOut(nil)
        }
    }

    private func follow() {
        guard let panel else { return }
        let mouse = NSEvent.mouseLocation
        let size = Self.size
        var origin = NSPoint(x: mouse.x + Self.offset.x, y: mouse.y + Self.offset.y - size.height)

        // Не выходим за пределы экрана, на котором сейчас указатель.
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
            let bounds = screen.visibleFrame
            if origin.x + size.width > bounds.maxX { origin.x = mouse.x - Self.offset.x - size.width }
            origin.y = max(origin.y, bounds.minY)
        }
        panel.setFrameOrigin(origin)
    }
}

private struct BreakCursorHintView: View {
    @ObservedObject var timer: BreakTimer

    var body: some View {
        HStack(spacing: 6) {
            Text("Перерыв начнется через")
            Text(timer.remainingText)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: Capsule())
    }
}
