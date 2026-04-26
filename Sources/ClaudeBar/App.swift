import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var panel: NSPanel!
    let store = UsageStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenuBarIcon(nil)

        if let button = statusItem.button {
            button.action = #selector(togglePanel)
            button.target = self
            button.sendAction(on: .leftMouseUp)
        }

        // Build panel (no titlebar, no arrow, exact position)
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 400),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.delegate = self

        let hostingView = NSHostingView(
            rootView: ContentView(closeAction: { [weak self] in self?.closePanel() })
                .environmentObject(store)
        )
        hostingView.frame = NSRect(x: 0, y: 0, width: 280, height: 400)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        store.start()

        NotificationCenter.default.addObserver(
            forName: UsageStore.didUpdateNotification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateMenuBarIcon(self?.store.usage)
            }
        }

        // Close panel when clicking elsewhere
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.closePanel()
            }
        }
    }

    func updateMenuBarIcon(_ usage: UsageData?) {
        guard let button = statusItem.button else { return }
        if let usage = usage {
            func color(for pct: Double) -> NSColor {
                if pct >= 90 { return NSColor(red: 226/255, green: 75/255, blue: 74/255, alpha: 1) }
                if pct >= 80 { return NSColor(red: 239/255, green: 159/255, blue: 39/255, alpha: 1) }
                return NSColor(red: 29/255, green: 158/255, blue: 117/255, alpha: 1)
            }
            let labelFont = NSFont.systemFont(ofSize: 12, weight: .medium)
            let dotFont   = NSFont.systemFont(ofSize: 12)
            let label = NSAttributedString(string: "Claude  ", attributes: [
                .foregroundColor: NSColor.labelColor,
                .font: labelFont,
            ])
            let dot1 = NSAttributedString(string: "●", attributes: [
                .foregroundColor: color(for: usage.sessionPct),
                .font: dotFont,
            ])
            let space = NSAttributedString(string: "  ", attributes: [
                .font: NSFont.systemFont(ofSize: 12),
            ])
            let dot2 = NSAttributedString(string: "●", attributes: [
                .foregroundColor: color(for: usage.weeklyPct),
                .font: dotFont,
            ])
            let full = NSMutableAttributedString()
            full.append(label); full.append(dot1); full.append(space); full.append(dot2)
            button.image = nil
            button.imagePosition = .noImage
            button.attributedTitle = full
        } else {
            button.attributedTitle = NSAttributedString(string: "")
            button.title = ""
            let img = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Claude")
            img?.isTemplate = true
            button.image = img
            button.imagePosition = .imageOnly
        }
    }

    @objc func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            openPanel()
        }
    }

    func openPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }

        // Calculate position: right below the button, right-aligned
        let buttonRect = button.convert(button.bounds, to: nil)
        let screenRect = buttonWindow.convertToScreen(buttonRect)

        let panelWidth: CGFloat = 280
        let panelX = screenRect.maxX - panelWidth
        let panelY = screenRect.minY - 4  // 4pt gap below bar

        panel.setFrameTopLeftPoint(NSPoint(x: panelX, y: panelY))
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func closePanel() {
        panel.orderOut(nil)
    }
}

@main
struct ClaudeBarApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
