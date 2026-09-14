import Foundation
import UIKit

@MainActor
final class KeyAuthService: ObservableObject {
    // Endpoint PHP de validação de Key informado pelo usuário.
    static let apiURL = URL(string: "https://desireteam.online/api_login.php")!
    // Identificador do modo configurado no painel PHP.
    static let modeID = 63

    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var expiresAt: String?

    private let keyStorage = "threeoneosfive.license.key"
    private let uidStorage = "threeoneosfive.device.uid"

    init() {
        if let savedKey = UserDefaults.standard.string(forKey: keyStorage), !savedKey.isEmpty {
            Task { await validate(key: savedKey, saveKey: false) }
        }
    }

    var savedKey: String {
        UserDefaults.standard.string(forKey: keyStorage) ?? ""
    }

    var deviceUID: String {
        if let stored = UserDefaults.standard.string(forKey: uidStorage), !stored.isEmpty {
            return stored
        }
        let value = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(value, forKey: uidStorage)
        return value
    }

    func login(key: String) async {
        await validate(key: key, saveKey: true)
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: keyStorage)
        isAuthenticated = false
        expiresAt = nil
        errorMessage = nil
    }

    private func validate(key: String, saveKey: Bool) async {
        let cleanedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty else {
            errorMessage = "Digite sua Key."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var components = URLComponents(url: Self.apiURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "key", value: cleanedKey),
            URLQueryItem(name: "uid", value: deviceUID),
            URLQueryItem(name: "mode_id", value: String(Self.modeID))
        ]

        guard let url = components?.url else {
            errorMessage = "Endereço da API inválido."
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                errorMessage = "Servidor indisponível. Tente novamente."
                return
            }

            let result = try JSONDecoder().decode(KeyAuthResponse.self, from: data)
            guard result.status.lowercased() == "success" else {
                errorMessage = result.message ?? "Key inválida ou expirada."
                return
            }

            if saveKey {
                UserDefaults.standard.set(cleanedKey, forKey: keyStorage)
            }
            expiresAt = result.expiresAt
            isAuthenticated = true
        } catch is DecodingError {
            errorMessage = "Resposta inválida da API."
        } catch {
            errorMessage = "Não foi possível conectar ao servidor."
        }
    }
}

private struct KeyAuthResponse: Decodable {
    let status: String
    let message: String?
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case status, message
        case expiresAt = "expires_at"
    }
}
