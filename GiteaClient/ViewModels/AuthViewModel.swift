import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var serverURL: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    var canProceedWithURL: Bool {
        let trimmed = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && (trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://"))
    }

    func validateServerURL() async -> Bool {
        let url = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else {
            errorMessage = "Please enter a server URL"
            return false
        }
        guard url.hasPrefix("http://") || url.hasPrefix("https://") else {
            errorMessage = "URL must start with http:// or https://"
            return false
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        guard let reqURL = URL(string: "\(url)/api/v1/version") else {
            errorMessage = "Invalid URL"
            return false
        }
        do {
            let (_, response) = try await URLSession.shared.data(from: reqURL)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                errorMessage = "Could not connect to Gitea server"
                return false
            }
            return true
        } catch {
            errorMessage = "Could not reach server: \(error.localizedDescription)"
            return false
        }
    }

    func login() async {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter username and password"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let token = try await GiteaAPIClient.createToken(
                serverURL: serverURL,
                username: username,
                password: password
            )
            let api = GiteaAPIClient(serverURL: serverURL, token: token)
            let user = try await api.currentUser()
            AppState.shared.signIn(serverURL: serverURL, token: token, user: user)
        } catch let error as GiteaAPIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
