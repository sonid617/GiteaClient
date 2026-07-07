import SwiftUI

struct ProfileView: View {
    let username: String

    @EnvironmentObject var appState: AppState
    @State private var user: GiteaUser?
    @State private var repos: [GiteaRepository] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedTab = 0
    @State private var showSignOut = false

    var isOwnProfile: Bool { username == appState.currentUser?.login }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    if isOwnProfile {
                        ProfileHeader(onSignOut: { showSignOut = true })
                    } else {
                        Color.appBg.frame(height: 8)
                    }

                    Group {
                        if let u = user {
                            profileContent(u)
                        } else if let err = error {
                            ErrorView(message: err) { Task { await load() } }
                        } else {
                            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBg)
                }
                .background(Color.appBg.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
                .task { await load() }

                // Sign out overlay
                if showSignOut {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { showSignOut = false }
                        .transition(.opacity)

                    signOutDialog
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: showSignOut)
        }
    }

    private var signOutDialog: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Sign Out")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Text("Are you sure you want to sign out?")
                    .font(.system(size: 13.5))
                    .foregroundColor(Color.appText2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            HStack(spacing: 10) {
                Button("Cancel") { showSignOut = false }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appCardAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Sign Out") { appState.signOut() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appDanger)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(20)
        }
        .frame(width: 260)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
    }

    private func profileContent(_ u: GiteaUser) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader(u)
                tabSelector
                tabContent(u)
            }
        }
        .refreshable { await load() }
    }

    private func profileHeader(_ u: GiteaUser) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(avatarColor(for: u.login))
                    .frame(width: 76, height: 76)
                Text(String(u.login.prefix(2).uppercased()))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text(u.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text("@\(u.login)")
                    .font(.system(size: 13))
                    .foregroundColor(Color.appText2)
                if let desc = u.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundColor(Color.appText2)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.top, 4)
                        .padding(.horizontal, 20)
                }
            }

            HStack(spacing: 28) {
                statItem(value: u.followersCount ?? 0, label: "Followers")
                statItem(value: u.followingCount ?? 0, label: "Following")
                if let stars = u.starredReposCount {
                    statItem(value: stars, label: "Stars")
                }
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color.appText2)
        }
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["Repositories", "Info"], id: \.self) { tab in
                let idx = tab == "Repositories" ? 0 : 1
                Button(action: { selectedTab = idx }) {
                    VStack(spacing: 0) {
                        Text(tab)
                            .font(.system(size: 14, weight: selectedTab == idx ? .semibold : .regular))
                            .foregroundColor(selectedTab == idx ? .accentColor : Color.appText2)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)
                        Rectangle()
                            .fill(selectedTab == idx ? Color.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .overlay(Divider(), alignment: .bottom)
    }

    @ViewBuilder
    private func tabContent(_ u: GiteaUser) -> some View {
        if selectedTab == 0 {
            LazyVStack(spacing: 10) {
                ForEach(repos) { repo in
                    NavigationLink(destination: RepoDetailView(owner: repo.owner.login, repoName: repo.name)) {
                        RepoRowView(repo: repo)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                if let email = u.email, !email.isEmpty {
                    infoRow(icon: "envelope", text: email)
                }
                if let website = u.website, !website.isEmpty {
                    infoRow(icon: "link", text: website, color: .accentColor)
                }
                if let created = u.created {
                    infoRow(icon: "calendar", text: "Joined \(formatDate(created))")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func infoRow(icon: String, text: String, color: Color = .primary) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.appText2)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(color)
        }
    }

    private func load() async {
        let resolvedUsername: String
        if !username.isEmpty {
            resolvedUsername = username
        } else if let current = AppState.shared.currentUser?.login, !current.isEmpty {
            resolvedUsername = current
        } else {
            guard let api = AppState.shared.api else { return }
            do {
                let u = try await api.currentUser()
                AppState.shared.currentUser = u
                resolvedUsername = u.login
            } catch {
                self.error = error.localizedDescription
                return
            }
        }
        isLoading = true
        error = nil
        do {
            let api = AppState.shared.api!
            async let userTask = api.user(username: resolvedUsername)
            async let reposTask = api.reposForUser(username: resolvedUsername)
            let (u, r) = try await (userTask, reposTask)
            user = u
            repos = r
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func formatDate(_ iso: String) -> String {
        let fmts: [ISO8601DateFormatter] = [ISO8601DateFormatter(), {
            let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f
        }()]
        for fmt in fmts {
            if let date = fmt.date(from: iso) {
                return date.formatted(date: .abbreviated, time: .omitted)
            }
        }
        return iso
    }
}
