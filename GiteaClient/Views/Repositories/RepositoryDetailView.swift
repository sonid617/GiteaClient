import SwiftUI

struct RepoDetailView: View {
    let owner: String
    let repoName: String

    @StateObject private var vm: RepoDetailViewModel
    @State private var showBranchPicker = false

    init(owner: String, repoName: String) {
        self.owner = owner
        self.repoName = repoName
        _vm = StateObject(wrappedValue: RepoDetailViewModel(
            api: AppState.shared.api!, owner: owner, repoName: repoName))
    }

    var body: some View {
        VStack(spacing: 0) {
            CompactHeader(
                title: repoName,
                trailing: AnyView(
                    Button {
                        Task { await vm.toggleStar() }
                    } label: {
                        Image(systemName: vm.isStarred ? "star.fill" : "star")
                            .font(.system(size: 20))
                            .foregroundColor(vm.isStarred ? Color.appWarn : Color.appText2)
                    }
                    .buttonStyle(.plain)
                )
            )

            Group {
                if let repo = vm.repo {
                    repoContent(repo)
                } else if let err = vm.error {
                    ErrorView(message: err) { Task { await vm.load() } }
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBg)
        }
        .background(Color.appBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { await vm.load() }
    }

    private func repoContent(_ repo: GiteaRepository) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Repo info
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Text(repo.owner.login.prefix(2).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(avatarColor(for: repo.owner.login))
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(repo.fullName)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)
                            if let desc = repo.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.appText2)
                                    .lineLimit(2)
                            }
                        }
                    }

                    HStack(spacing: 16) {
                        repoStat(icon: "star.fill", iconColor: Color.appWarn, value: "\(repo.starsCount) stars")
                        repoStat(icon: "tuningfork", iconColor: Color.appText2, value: "\(repo.forksCount) forks")
                        if let lang = repo.language {
                            HStack(spacing: 5) {
                                Circle().fill(languageColor(lang)).frame(width: 9, height: 9)
                                Text(lang)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.appText2)
                            }
                        }
                    }

                    if let topics = repo.topics, !topics.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(topics, id: \.self) { topic in
                                    Text(topic)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.accentColor)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Branch picker
                    Button {
                        showBranchPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.system(size: 14))
                                .foregroundColor(Color.appText2)
                            Text(vm.selectedBranch ?? repo.defaultBranch ?? "main")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("Branch")
                                .font(.system(size: 12))
                                .foregroundColor(Color.appText2)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.appText2)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .designCard()
                }

                // Code section
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "Code")
                    VStack(spacing: 0) {
                        NavigationLink(destination: FileExplorerView(owner: owner, repoName: repoName, path: "", branch: vm.selectedBranch ?? repo.defaultBranch ?? "main")) {
                            NavRow(icon: "folder.fill", label: "Browse Files")
                        }
                        Divider().padding(.leading, 50)
                        NavigationLink(destination: CommitListView(owner: owner, repoName: repoName, branch: vm.selectedBranch ?? repo.defaultBranch ?? "main")) {
                            NavRow(icon: "chevron.left.forwardslash.chevron.right", label: "Commits")
                        }
                        Divider().padding(.leading, 50)
                        NavigationLink(destination: ReadmeView(owner: owner, repoName: repoName)) {
                            NavRow(icon: "doc.text.fill", label: "README")
                        }
                        Divider().padding(.leading, 50)
                        NavigationLink(destination: ReleasesView(owner: owner, repoName: repoName)) {
                            NavRow(icon: "tag.fill", label: "Releases", isLast: true)
                        }
                    }
                    .designCard()
                }

                // Activity section
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "Activity")
                    VStack(spacing: 0) {
                        NavigationLink(destination: IssueListView(owner: owner, repoName: repoName)) {
                            NavRow(
                                icon: "circle.fill",
                                iconColor: Color.appOpen,
                                label: "Issues",
                                detail: repo.openIssuesCount.map { "\($0)" }
                            )
                        }
                        Divider().padding(.leading, 50)
                        NavigationLink(destination: PRListView(owner: owner, repoName: repoName)) {
                            NavRow(icon: "arrow.triangle.pull", iconColor: Color.appOpen, label: "Pull Requests", isLast: true)
                        }
                    }
                    .designCard()
                }

                // Recent commits
                if !vm.commits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Recent Commits")
                        VStack(spacing: 0) {
                            ForEach(Array(vm.commits.prefix(5).enumerated()), id: \.element.id) { idx, commit in
                                let isLast = idx == min(vm.commits.count, 5) - 1
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(commit.shortMessage)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    HStack {
                                        Text(commit.author?.login ?? commit.commit.author?.name ?? "")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.appText2)
                                        Spacer()
                                        Text(commit.shortSha)
                                            .font(.system(size: 11.5, design: .monospaced))
                                            .foregroundColor(Color.appText3)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                if !isLast { Divider() }
                            }
                        }
                        .designCard()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .refreshable { await vm.load() }
        .confirmationDialog("Switch Branch", isPresented: $showBranchPicker) {
            ForEach(vm.branches) { branch in
                Button(branch.name) {
                    vm.selectedBranch = branch.name
                    Task { await vm.loadCommits() }
                }
            }
        }
    }

    private func repoStat(icon: String, iconColor: Color, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(iconColor)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(Color.appText2)
        }
    }
}

// MARK: - Nav Row

struct NavRow: View {
    let icon: String
    var iconColor: Color = .accentColor
    let label: String
    var detail: String? = nil
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 26)
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.primary)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(Color.appText2)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.appText3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.appCard)
        .contentShape(Rectangle())
    }
}

// MARK: - Commit List

struct CommitListView: View {
    let owner: String
    let repoName: String
    let branch: String

    @State private var commits: [GiteaCommit] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var page = 1
    @State private var hasMore = true

    var body: some View {
        VStack(spacing: 0) {
            CompactHeader(title: "Commits")

            Group {
                if isLoading && commits.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = error, commits.isEmpty {
                    ErrorView(message: err) { Task { await load(reset: true) } }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(commits) { commit in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(commit.shortMessage)
                                        .font(.system(size: 14.5, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    HStack {
                                        Text((commit.author?.login ?? commit.commit.author?.name) ?? "")
                                            .font(.system(size: 12.5))
                                            .foregroundColor(Color.appText2)
                                        Spacer()
                                        Text(commit.shortSha)
                                            .font(.system(size: 11.5, design: .monospaced))
                                            .foregroundColor(Color.appText3)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .overlay(Divider(), alignment: .bottom)
                                .onAppear {
                                    if commit.id == commits.last?.id { Task { await load() } }
                                }
                            }
                            if isLoading {
                                ProgressView().padding()
                            }
                        }
                    }
                    .refreshable { await load(reset: true) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBg)
        }
        .background(Color.appBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { await load(reset: true) }
    }

    private func load(reset: Bool = false) async {
        if reset { page = 1; commits = []; hasMore = true }
        guard hasMore, !isLoading else { return }
        isLoading = true
        do {
            let fetched = try await AppState.shared.api!.commits(owner: owner, repo: repoName, branch: branch, page: page)
            commits.append(contentsOf: fetched)
            hasMore = fetched.count >= 30
            page += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }
}
