import Foundation
import Security

struct OAuthCredentials: Codable {
    struct ClaudeAiOauth: Codable {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Double?
    }
    let claudeAiOauth: ClaudeAiOauth
}

enum KeychainError: LocalizedError {
    case notFound
    case invalidData
    case decodeFailed(String)

    var errorDescription: String? {
        switch self {
        case .notFound:            return "No credentials found. Run claude /login in Terminal first."
        case .invalidData:         return "Invalid Keychain data format."
        case .decodeFailed(let m): return "Decode failed: \(m)"
        }
    }
}

struct KeychainService {
    static func readOAuthToken() throws -> String {
        var query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      "Claude Code-credentials",
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip,
        ]

        var item: CFTypeRef?
        var status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            query[kSecAttrService as String] = "Claude Code"
            status = SecItemCopyMatching(query as CFDictionary, &item)
        }

        guard status == errSecSuccess else { throw KeychainError.notFound }
        guard let data = item as? Data else { throw KeychainError.invalidData }

        do {
            let creds = try JSONDecoder().decode(OAuthCredentials.self, from: data)
            return creds.claudeAiOauth.accessToken
        } catch {
            throw KeychainError.decodeFailed(error.localizedDescription)
        }
    }
}
