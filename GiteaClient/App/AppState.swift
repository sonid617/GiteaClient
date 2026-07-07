import Foundation

enum AppScreen {
    case serverURL
    case login
    case main
}

@MainActor
final class AppState: ObservableObject {
    @Published var screen: AppScreen = .serverURL
    @Published var currentUser: GiteaUser?
    @Published var api: GiteaAPIClient?
    @Published var pendingServerURL: String = ""

    static let shared = AppState()
    private init() { restoreSession() }

    private func restoreSession() {
        guard
            let serverURL = KeychainHelper.shared.read(forKey: "serverURL"),
            let token = KeychainHelper.shared.read(forKey: "token")
        else { return }
        api = GiteaAPIClient(serverURL: serverURL, token: token)
        screen = .main
        Task { await loadCurrentUser() }
    }

    func signIn(serverURL: String, token: String, user: GiteaUser) {
        KeychainHelper.shared.save(serverURL, forKey: "serverURL")
        KeychainHelper.shared.save(token, forKey: "token")
        api = GiteaAPIClient(serverURL: serverURL, token: token)
        currentUser = user
        screen = .main
    }

    func signOut() {
        KeychainHelper.shared.delete(forKey: "serverURL")
        KeychainHelper.shared.delete(forKey: "token")
        api = nil
        currentUser = nil
        screen = .serverURL
    }

    private func loadCurrentUser() async {
        guard let api else { return }
        do {
            currentUser = try await api.currentUser()
        } catch {
            signOut()
        }
    }
}
