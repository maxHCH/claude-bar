import Foundation

struct UsageData {
    let sessionPct: Double
    let sessionResetsAt: Date?
    let weeklyPct: Double
    let weeklyResetsAt: Date?
    let weeklySonnetPct: Double?
    let fetchedAt: Date
}

struct UsageResponse: Codable {
    struct Bucket: Codable {
        let utilization: Double?
        let resetsAt: String?
        enum CodingKeys: String, CodingKey {
            case utilization
            case resetsAt = "resets_at"
        }
    }
    let fiveHour: Bucket?
    let sevenDay: Bucket?
    let sevenDaySonnet: Bucket?

    enum CodingKeys: String, CodingKey {
        case fiveHour    = "five_hour"
        case sevenDay    = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
    }
}

enum APIError: LocalizedError {
    case httpError(Int, String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let msg): return "HTTP \(code): \(msg)"
        case .networkError(let msg):        return msg
        }
    }
}

struct UsageService {
    static func fetch(token: String) async throws -> UsageData {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw APIError.httpError(http.statusCode, msg)
        }

        let decoded = try JSONDecoder().decode(UsageResponse.self, from: data)

        let isoParser: (String?) -> Date? = { str in
            guard let str else { return nil }
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f.date(from: str) ?? ISO8601DateFormatter().date(from: str)
        }

        return UsageData(
            sessionPct:      decoded.fiveHour?.utilization ?? 0,
            sessionResetsAt: isoParser(decoded.fiveHour?.resetsAt),
            weeklyPct:       decoded.sevenDay?.utilization ?? 0,
            weeklyResetsAt:  isoParser(decoded.sevenDay?.resetsAt),
            weeklySonnetPct: decoded.sevenDaySonnet?.utilization,
            fetchedAt:       Date()
        )
    }
}
