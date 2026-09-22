// macarchy-overlay: a Handy-style pill at the bottom of the screen, painted from
// the active theme. `ws --voice` uses it for "listening", "transcribing" and the
// result, so voice control has the same kind of feedback Handy's own dictation has.
//
//   macarchy-overlay listen [title] [detail]   stays up until SIGTERM/SIGINT
//   macarchy-overlay [--ttl SECONDS]           one state per stdin line:
//                                              "<state>\t<title>\t<detail>", state in listen|busy|ok|fail|none
//                                              exits SECONDS after stdin closes (default 3)
//
// Build: home/.config/macarchy/swift/build (install.sh runs it when swiftc exists).
import AppKit

// ----- theme ----------------------------------------------------------------
func themeColors() -> [String: NSColor] {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    var out: [String: NSColor] = [:]
    guard let text = try? String(contentsOfFile: home + "/.config/theme/current/colors.sh", encoding: .utf8) else { return out }
    let re = try! NSRegularExpression(pattern: #"^\s*(?:export\s+)?([A-Z0-9_]+)=["']?#?([0-9a-fA-F]{6})"#, options: .anchorsMatchLines)
    for m in re.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
        let name = String(text[Range(m.range(at: 1), in: text)!])
        let hex = String(text[Range(m.range(at: 2), in: text)!])
        var v: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&v)
        out[name] = NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: 1)
    }
    return out
}
let theme = themeColors()
func color(_ name: String, _ fallback: NSColor) -> NSColor { theme[name] ?? fallback }
let bg = color("BG", NSColor(white: 0.1, alpha: 1))
let fg = color("FG", NSColor(white: 0.92, alpha: 1))
let muted = color("MUTED", NSColor(white: 0.6, alpha: 1))
let red = color("RED", .systemRed), green = color("GREEN", .systemGreen), yellow = color("YELLOW", .systemYellow)

// ----- pill -----------------------------------------------------------------
final class Pill {
    let panel: NSPanel
    let dot = NSView()
    let title = NSTextField(labelWithString: "")
    let detail = NSTextField(wrappingLabelWithString: "")
    let stack = NSStackView()

    init() {
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.alphaValue = 0

        let root = NSView()
        root.wantsLayer = true
        root.layer?.backgroundColor = bg.withAlphaComponent(0.94).cgColor
        root.layer?.borderColor = muted.withAlphaComponent(0.45).cgColor
        root.layer?.borderWidth = 1
        panel.contentView = root

        dot.wantsLayer = true
        dot.layer?.cornerRadius = 5
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 10).isActive = true

        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.textColor = fg
        title.lineBreakMode = .byTruncatingTail
        title.maximumNumberOfLines = 1
        detail.font = .monospacedSystemFont(ofSize: 11.5, weight: .regular)
        detail.textColor = muted
        detail.maximumNumberOfLines = 4
        detail.preferredMaxLayoutWidth = 520

        let text = NSStackView(views: [title, detail])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 2
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 10
        stack.addView(dot, in: .leading)
        stack.addView(text, in: .leading)
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -10),
        ])
    }

    func set(state: String, title t: String, detail d: String) {
        title.stringValue = t
        detail.stringValue = d
        detail.isHidden = d.isEmpty
        title.preferredMaxLayoutWidth = 520
        let pulse: Bool
        switch state {
        case "listen": dot.layer?.backgroundColor = red.cgColor; pulse = true
        case "busy": dot.layer?.backgroundColor = yellow.cgColor; pulse = true
        case "ok": dot.layer?.backgroundColor = green.cgColor; pulse = false
        case "fail": dot.layer?.backgroundColor = red.cgColor; pulse = false
        default: dot.layer?.backgroundColor = NSColor.clear.cgColor; pulse = false
        }
        dot.isHidden = state == "none"
        dot.layer?.removeAllAnimations()
        if pulse {
            let a = CABasicAnimation(keyPath: "opacity")
            a.fromValue = 1.0; a.toValue = 0.25; a.duration = 0.7
            a.autoreverses = true; a.repeatCount = .infinity
            a.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            dot.layer?.add(a, forKey: "pulse")
        }
        layout()
        if panel.alphaValue == 0 {
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in ctx.duration = 0.18; panel.animator().alphaValue = 1 }
        }
    }

    func layout() {
        guard let root = panel.contentView else { return }
        root.layoutSubtreeIfNeeded()
        var size = root.fittingSize
        size.width = max(size.width, 240)
        root.layer?.cornerRadius = min(size.height / 2, 22)
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let vf = screen.visibleFrame
        let origin = NSPoint(x: vf.midX - size.width / 2, y: vf.minY + 28)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    func fadeOutAndQuit() {
        NSAnimationContext.runAnimationGroup({ ctx in ctx.duration = 0.2; panel.animator().alphaValue = 0 }) { NSApp.terminate(nil) }
    }
}

// ----- main -----------------------------------------------------------------
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let pill = Pill()

var args = Array(CommandLine.arguments.dropFirst())
var ttl = 3.0
if let i = args.firstIndex(of: "--ttl"), i + 1 < args.count { ttl = Double(args[i + 1]) ?? ttl; args.removeSubrange(i...(i + 1)) }

func onSignal(_ sig: Int32) {
    signal(sig, SIG_IGN)
    let src = DispatchSource.makeSignalSource(signal: sig, queue: .main)
    src.setEventHandler { pill.fadeOutAndQuit() }
    src.resume()
    _ = Unmanaged.passRetained(src as AnyObject)
}
onSignal(SIGTERM); onSignal(SIGINT); onSignal(SIGHUP)

if args.first == "listen" {
    pill.set(state: "listen", title: args.count > 1 ? args[1] : "Listening…", detail: args.count > 2 ? args[2] : "alt-w again to run")
} else {
    DispatchQueue.global().async {
        while let line = readLine() {
            let parts = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
            let state = parts.count > 0 ? parts[0] : "none"
            let t = parts.count > 1 ? parts[1] : ""
            let d = parts.count > 2 ? parts[2].replacingOccurrences(of: "\\n", with: "\n") : ""
            DispatchQueue.main.async { pill.set(state: state, title: t, detail: d) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ttl) { pill.fadeOutAndQuit() }
    }
}
app.run()
