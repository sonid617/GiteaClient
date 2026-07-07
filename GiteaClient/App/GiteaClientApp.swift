import SwiftUI

@main
struct GiteaClientApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        switch appState.screen {
        case .serverURL:
            ServerURLView()
        case .login:
            LoginView()
        case .main:
            MainTabView()
        }
    }
}
