import Foundation
import Combine

@MainActor
final class UsageStore: ObservableObject {
    static let didUpdateNotification = Notification.Name("UsageStoreDidUpdate")

    @Published var usage: UsageData? = nil
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var refreshInterval: Int = UserDefaults.standard.integer(forKey: "refreshInterval") == 0
        ? 60
        : UserDefaults.standard.integer(forKey: "refreshInterval")

    var refreshIntervalLabel: String {
        switch refreshInterval {
        case 30:   return "30s"
        case 60:   return "1 min"
        case 300:  return "5 min"
        case 600:  return "10 min"
        case 1800: return "30 min"
        default:   return "\(refreshInterval)s"
        }
    }

    private var refreshTimer: Timer?

    func start() {
        Task { await refresh() }
        scheduleTimer()
    }

    func setRefreshInterval(_ seconds: Int) {
        refreshInterval = seconds
        UserDefaults.standard.set(seconds, forKey: "refreshInterval")
        scheduleTimer()
    }

    private func scheduleTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(refreshInterval), repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    func refresh() async {
        isLoading = true
        error = nil
        do {
            let token = try KeychainService.readOAuthToken()
            usage = try await UsageService.fetch(token: token)
            NotificationCenter.default.post(name: Self.didUpdateNotification, object: self)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
