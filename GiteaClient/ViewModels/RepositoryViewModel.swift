import Foundation

@MainActor
final class RepositoryViewModel: ObservableObject {
    @Published var repos: [GiteaRepository] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentPage = 1
    @Published var hasMore = true

    private let api: GiteaAPIClient

    init(api: GiteaAPIClient) {
        self.api = api
    }

    func loadMyRepos(reset: Bool = false) async {
        if reset { currentPage = 1; repos = []; hasMore = true }
        guard hasMore, !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let fetched = try await api.myRepos(page: currentPage)
            repos.append(contentsOf: fetched)
            hasMore = fetched.count >= 50
            currentPage += 1
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

@MainActor
final class RepoDetailViewModel: ObservableObject {
    @Published var repo: GiteaRepository?
    @Published var branches: [GiteaBranch] = []
    @Published var commits: [GiteaCommit] = []
    @Published var contents: [GiteaContent] = []
    @Published var isStarred = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedBranch: String?

    private let api: GiteaAPIClient
    let owner: String
    let repoName: String

    init(api: GiteaAPIClient, owner: String, repoName: String) {
        self.api = api
        self.owner = owner
        self.repoName = repoName
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            async let repoTask = api.repo(owner: owner, name: repoName)
            async let starTask = api.isStarred(owner: owner, name: repoName)
            let (r, starred) = try await (repoTask, starTask)
            repo = r
            isStarred = starred
            selectedBranch = r.defaultBranch
            await loadContents(path: "")
            await loadBranches()
            await loadCommits()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadContents(path: String, ref: String? = nil) async {
        do {
            let branch = ref ?? selectedBranch
            contents = try await api.contents(owner: owner, repo: repoName, path: path, ref: branch)
            contents.sort { a, b in
                if a.isDirectory != b.isDirectory { return a.isDirectory }
                return a.name < b.name
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadBranches() async {
        do {
            branches = try await api.branches(owner: owner, repo: repoName)
        } catch {}
    }

    func loadCommits() async {
        do {
            commits = try await api.commits(owner: owner, repo: repoName, branch: selectedBranch, page: 1)
        } catch {}
    }

    func toggleStar() async {
        do {
            if isStarred {
                try await api.unstarRepo(owner: owner, name: repoName)
            } else {
                try await api.starRepo(owner: owner, name: repoName)
            }
            isStarred.toggle()
            if let r = repo {
                repo = GiteaRepository(
                    id: r.id, owner: r.owner, name: r.name, fullName: r.fullName,
                    description: r.description, isPrivate: r.isPrivate, fork: r.fork,
                    htmlUrl: r.htmlUrl, sshUrl: r.sshUrl, cloneUrl: r.cloneUrl,
                    starsCount: r.starsCount + (isStarred ? 1 : -1),
                    forksCount: r.forksCount, watchersCount: r.watchersCount,
                    openIssuesCount: r.openIssuesCount, defaultBranch: r.defaultBranch,
                    hasIssues: r.hasIssues, hasWiki: r.hasWiki, language: r.language,
                    updatedAt: r.updatedAt, topics: r.topics
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var repos: [GiteaRepository] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var query: String = ""
    @Published var currentPage = 1
    @Published var hasMore = true

    private let api: GiteaAPIClient

    init(api: GiteaAPIClient) {
        self.api = api
    }

    func search(reset: Bool = false) async {
        if reset { currentPage = 1; repos = []; hasMore = true }
        guard hasMore, !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let fetched = try await api.exploreRepos(query: query, page: currentPage)
            repos.append(contentsOf: fetched)
            hasMore = fetched.count >= 20
            currentPage += 1
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
