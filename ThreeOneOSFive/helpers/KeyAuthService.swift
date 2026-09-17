import Foundation
import UIKit

@MainActor
final class KeyAuthService: ObservableObject {
    // Endpoint de validação
    static let apiURL = URL(string: "https://neocheats.shop/mod/CheckLogin.php")!

    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

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
        errorMessage = nil
    }

    private func validate(key: String, saveKey: Bool) async {
        let cleanedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty else {
            errorMessage = "Digite seu usuário."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var components = URLComponents(url: Self.apiURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "user", value: cleanedKey),
            URLQueryItem(name: "uid",  value: deviceUID)
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

            // Resposta é texto plano
            let body = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            // Seu PHP retorna o UID validado em caso de sucesso,
            // ou uma mensagem de erro em caso de falha.
            // Mensagens de erro conhecidas começam com texto específico:
            let errorPrefixes = [
                "Em manutenção",
                "Usuário inválido",
                "Dispositivo não permitido",
                "Usuário banido",
                "Usuário pausado",
                "Key expirada",
                "Configuração de dispositivo inválida",
                "ﾠ" // usuário não encontrado (espaço especial)
            ]

            let isError = errorPrefixes.contains(where: { body.lowercased().hasPrefix($0.lowercased()) })
                || body.isEmpty

            if isError {
                // Mensagem amigável para "não encontrado"
                if body == "ﾠ" || body.isEmpty {
                    errorMessage = "Usuário não encontrado."
                } else {
                    errorMessage = body
                }
                return
            }

            // Sucesso — body contém o UID validado
            if saveKey {
                UserDefaults.standard.set(cleanedKey, forKey: keyStorage)
            }
            isAuthenticated = true

        } catch {
            errorMessage = "Não foi possível conectar ao servidor."
        }
    }
}
