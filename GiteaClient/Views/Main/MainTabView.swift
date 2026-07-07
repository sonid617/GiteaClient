import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeTab: AppTab = .explore
    @State private var unreadCount = 0

    var body: some View {
        ZStack {
            ExploreView()
                .opacity(activeTab == .explore ? 1 : 0)
                .allowsHitTesting(activeTab == .explore)

            RepositoryListView()
                .opacity(activeTab == .repos ? 1 : 0)
                .allowsHitTesting(activeTab == .repos)

            NotificationsView(onUnreadChange: { unreadCount = $0 })
                .opacity(activeTab == .inbox ? 1 : 0)
                .allowsHitTesting(activeTab == .inbox)

            ProfileView(username: appState.currentUser?.login ?? "")
                .opacity(activeTab == .profile ? 1 : 0)
                .allowsHitTesting(activeTab == .profile)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(activeTab: $activeTab, unreadCount: unreadCount)
                .environmentObject(appState)
        }
    }
}
