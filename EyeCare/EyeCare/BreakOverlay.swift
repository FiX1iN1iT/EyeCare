//
//  BreakOverlay.swift
//  EyeCare
//

import SwiftUI
import AppKit

/// Окно без рамки, которое может принимать клики по кнопкам.
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

/// Показывает размытые обои на всех экранах на время перерыва.
final class BreakOverlayController {
    private static let fadeDuration: TimeInterval = 0.8

    private var windows: [NSWindow] = []

    func show(timer: BreakTimer) {
        hide(animated: false)

        for screen in NSScreen.screens {
            let window = OverlayWindow(contentRect: screen.frame,
                                       styleMask: .borderless,
                                       backing: .buffered,
                                       defer: false,
                                       screen: screen)
            window.level = .screenSaver
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.isReleasedWhenClosed = false
            window.alphaValue = 0
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

            // Подложка на случай, если обои прочитать не удалось.
            let blur = NSVisualEffectView()
            blur.material = .fullScreenUI
            blur.blendingMode = .behindWindow
            blur.state = .active

            let content = NSHostingView(rootView: BreakOverlayView(timer: timer, wallpaper: Self.wallpaper(for: screen)))
            content.translatesAutoresizingMaskIntoConstraints = false
            blur.addSubview(content)
            NSLayoutConstraint.activate([
                content.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
                content.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
                content.topAnchor.constraint(equalTo: blur.topAnchor),
                content.bottomAnchor.constraint(equalTo: blur.bottomAnchor),
            ])

            window.contentView = blur
            window.setFrame(screen.frame, display: true)
            window.orderFrontRegardless()
            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeKey()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            windows.forEach { $0.animator().alphaValue = 1 }
        }
    }

    func hide(animated: Bool = true) {
        let closing = windows
        windows = []

        guard animated else {
            closing.forEach { $0.orderOut(nil) }
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            closing.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: {
            closing.forEach { $0.orderOut(nil) }
        }
    }

    private static func wallpaper(for screen: NSScreen) -> NSImage? {
        guard let url = NSWorkspace.shared.desktopImageURL(for: screen) else { return nil }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              !isDirectory.boolValue else { return nil }
        return NSImage(contentsOf: url)
    }
}

struct BreakOverlayView: View {
    @ObservedObject var timer: BreakTimer
    let wallpaper: NSImage?

    @State private var appeared = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 28) {
                Text(timer.now, format: .dateTime.hour().minute())
                    .font(.system(size: 120, weight: .thin, design: .rounded))
                    .monospacedDigit()

                VStack(spacing: 6) {
                    Text("Отдохните и посмотрите вдаль")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(timer.remainingText)
                        .font(.system(size: 64, weight: .medium, design: .rounded))
                        .monospacedDigit()
                }

                Button("Пропустить перерыв") { timer.skipBreak() }
                    .controlSize(.large)
                    .buttonStyle(.bordered)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 12)
            .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) { appeared = true }
        }
    }

    @ViewBuilder
    private var background: some View {
        if let wallpaper {
            GeometryReader { geo in
                Image(nsImage: wallpaper)
                    .resizable()
                    .scaledToFill()
                    // Небольшое увеличение, чтобы размытие не давало прозрачных краёв.
                    .scaleEffect(1.1)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .blur(radius: appeared ? 50 : 0)
                    .clipped()
                    .overlay(Color.black.opacity(appeared ? 0.3 : 0))
            }
        }
    }
}
