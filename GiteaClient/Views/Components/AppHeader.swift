import SwiftUI

// MARK: - App Tab

enum AppTab: Int, CaseIterable {
    case explore, repos, inbox, profile
}

// MARK: - Large Header (Explore, Repos)

struct LargeHeader: View {
    let title: String
    @Binding var searchText: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.accentColor)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    )
                Text(title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.primary)
                    .tracking(-0.5)
                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appText3)
                TextField(placeholder, text: $searchText)
                    .font(.system(size: 14))
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.appText3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.appCardAlt)
            .clipShape(RoundedRectangle(cornerRadius: 11))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.appBg)
    }
}

// MARK: - Compact Header (detail views)

struct CompactHeader: View {
    let title: String
    var trailing: AnyView? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .foregroundColor(.primary)

            Spacer()

            if let t = trailing {
                t.frame(width: 36, height: 36)
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
        .background(Color.appBg)
        .overlay(Divider(), alignment: .bottom)
    }
}

// MARK: - Inbox Header

struct InboxHeader: View {
    @Binding var showAll: Bool
    let onMarkAllRead: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Inbox")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.primary)
                    .tracking(-0.5)
                Spacer()
                Button(action: onMarkAllRead) {
                    Text("Mark all read")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                FilterChip(label: "All", active: showAll) { showAll = true }
                FilterChip(label: "Unread", active: !showAll) { showAll = false }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.appBg)
    }
}

// MARK: - Profile Header

struct ProfileHeader: View {
    let onSignOut: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: onSignOut) {
                Text("Sign Out")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.appDanger)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .background(Color.appBg)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var activeTab: AppTab
    var unreadCount: Int = 0
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            tabBtn(.explore, icon: "safari", label: "Explore")
            tabBtn(.repos, icon: "folder", label: "Repos")
            inboxBtn
            profileBtn
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            Color.appCard
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(Divider(), alignment: .top)
    }

    private func tabBtn(_ tab: AppTab, icon: String, label: String) -> some View {
        Button { activeTab = tab } label: {
            VStack(spacing: 3) {
                Image(systemName: activeTab == tab ? "\(icon).fill" : icon)
                    .font(.system(size: 23))
                Text(label)
                    .font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundColor(activeTab == tab ? .accentColor : Color(UIColor.systemGray2))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var inboxBtn: some View {
        Button { activeTab = .inbox } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: activeTab == .inbox ? "bell.fill" : "bell")
                        .font(.system(size: 23))
                        .foregroundColor(activeTab == .inbox ? .accentColor : Color(UIColor.systemGray2))
                    if unreadCount > 0 {
                        Circle()
                            .fill(Color.appDanger)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color.appCard, lineWidth: 1.5))
                            .offset(x: 1, y: -1)
                    }
                }
                Text("Inbox")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(activeTab == .inbox ? .accentColor : Color(UIColor.systemGray2))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var profileBtn: some View {
        let login = appState.currentUser?.login ?? "?"
        let initials = String(login.prefix(2).uppercased())
        let isActive = activeTab == .profile
        return Button { activeTab = .profile } label: {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2)
                        .frame(width: 29, height: 29)
                    Text(initials)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 23, height: 23)
                        .background(avatarColor(for: login))
                        .clipShape(Circle())
                }
                Text("Profile")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(isActive ? .accentColor : Color(UIColor.systemGray2))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
