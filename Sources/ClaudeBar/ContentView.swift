import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: UsageStore
    @State private var showSettings = false
    var closeAction: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider().opacity(0.4)
            if showSettings {
                SettingsView(showSettings: $showSettings)
            } else if let err = store.error {
                errorView(err)
            } else if let usage = store.usage {
                usageView(usage)
            } else {
                loadingView
            }
        }
        .frame(width: 280)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "#CF8E6D"))
                    .frame(width: 7, height: 7)
                Text("Claude Usage")
                    .font(.system(size: 13, weight: .medium))
            }
            Spacer()
            if store.isLoading {
                ProgressView().scaleEffect(0.55).frame(width: 14, height: 14)
            } else {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: showSettings ? "gearshape.fill" : "gearshape")
                    .font(.system(size: 11))
                    .foregroundColor(showSettings ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            Button { closeAction() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Fetching usage…")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }

    func errorView(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: errorIcon(msg))
                .font(.system(size: 26))
                .foregroundColor(errorColor(msg))
            Text(errorTitle(msg))
                .font(.system(size: 13, weight: .medium))
            Text(errorDesc(msg))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await store.refresh() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }

    func errorIcon(_ msg: String) -> String {
        if msg.contains("429") || msg.contains("rate_limit") { return "clock.arrow.circlepath" }
        if msg.contains("401") || msg.contains("403")        { return "key.slash" }
        if msg.contains("找不到") || msg.contains("login")   { return "person.crop.circle.badge.exclamationmark" }
        return "wifi.exclamationmark"
    }

    func errorColor(_ msg: String) -> Color {
        if msg.contains("429") || msg.contains("rate_limit") { return Color(hex: "#EF9F27") }
        if msg.contains("401") || msg.contains("403")        { return Color(hex: "#E24B4A") }
        return Color(hex: "#EF9F27")
    }

    func errorTitle(_ msg: String) -> String {
        if msg.contains("429") || msg.contains("rate_limit") { return "Rate limited" }
        if msg.contains("401") || msg.contains("403")        { return "Authentication failed" }
        if msg.contains("找不到") || msg.contains("login")   { return "No credentials found" }
        if msg.contains("Network") || msg.contains("network"){ return "Network error" }
        return "Unable to fetch data"
    }

    func errorDesc(_ msg: String) -> String {
        if msg.contains("429") || msg.contains("rate_limit") { return "Wait a moment and retry, or increase the refresh interval" }
        if msg.contains("401") || msg.contains("403")        { return "Run claude /login in Terminal to re-authenticate" }
        if msg.contains("找不到") || msg.contains("login")   { return "Run claude /login in Terminal first" }
        if msg.contains("Network") || msg.contains("network"){ return "Check your connection and try again" }
        return "Please try again later"
    }

    func usageView(_ usage: UsageData) -> some View {
        VStack(spacing: 14) {
            UsageGauge(
                title: "Session",
                subtitle: "5-hour window",
                pct: usage.sessionPct,
                resetsAt: usage.sessionResetsAt
            )
            Divider().opacity(0.3)
            UsageGauge(
                title: "Weekly",
                subtitle: "7-day window",
                pct: usage.weeklyPct,
                resetsAt: usage.weeklyResetsAt
            )
            if let sonnet = usage.weeklySonnetPct {
                Divider().opacity(0.3)
                UsageGauge(
                    title: "Sonnet",
                    subtitle: "Weekly",
                    pct: sonnet,
                    resetsAt: usage.weeklyResetsAt
                )
            }
            if let updated = store.usage?.fetchedAt {
                HStack {
                    Text("Updated at \(updated, style: .time)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .opacity(0.5)
                    Spacer()
                    Text("Every \(store.refreshIntervalLabel)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .opacity(0.4)
                }
            }
        }
        .padding(14)
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: UsageStore
    @Binding var showSettings: Bool

    let intervals: [(label: String, seconds: Int)] = [
        ("30 seconds", 30),
        ("1 minute",   60),
        ("5 minutes",  300),
        ("10 minutes", 600),
        ("30 minutes", 1800),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Auto-refresh interval")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                VStack(spacing: 2) {
                    ForEach(intervals, id: \.seconds) { item in
                        Button {
                            store.setRefreshInterval(item.seconds)
                        } label: {
                            HStack {
                                Text(item.label)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                Spacer()
                                if store.refreshInterval == item.seconds {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color(hex: "#1D9E75"))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                store.refreshInterval == item.seconds
                                    ? Color.secondary.opacity(0.1)
                                    : Color.clear
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().opacity(0.3)

            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                        .font(.system(size: 11))
                    Text("Quit ClaudeBar")
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
    }
}

struct UsageGauge: View {
    let title: String
    let subtitle: String
    let pct: Double
    let resetsAt: Date?

    var color: Color {
        if pct >= 90 { return Color(hex: "#E24B4A") }
        if pct >= 80 { return Color(hex: "#EF9F27") }
        return Color(hex: "#1D9E75")
    }

    var resetText: String {
        guard let date = resetsAt else { return "" }
        let diff = date.timeIntervalSinceNow
        if diff <= 0 { return "Resetting soon" }
        let totalMinutes = Int(diff) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let days = hours / 24
        let remainHours = hours % 24
        if days >= 1 {
            if remainHours > 0 { return "Resets in \(days)d \(remainHours)h" }
            return "Resets in \(days)d"
        }
        if hours > 0 { return "Resets in \(hours)h \(minutes)m" }
        return "Resets in \(minutes)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(pct.rounded()))%")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(color)
                    if !resetText.isEmpty {
                        Text(resetText)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(6, geo.size.width * pct / 100), height: 6)
                        .animation(.easeOut(duration: 0.4), value: pct)
                }
            }
            .frame(height: 6)
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.blendingMode = .behindWindow
        v.state = .active
        v.material = .popover
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}
