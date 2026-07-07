import Foundation

@MainActor
final class IssueListViewModel: ObservableObject {
    @Published var issues: [GiteaIssue] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var stateFilter: String = "open"
    @Published var currentPage = 1
    @Published var hasMore = true

    private let api: GiteaAPIClient
    let owner: String
    let repoName: String

    init(api: GiteaAPIClient, owner: String, repoName: String) {
        self.api = api
        self.owner = owner
        self.repoName = repoName
    }

    func load(reset: Bool = false) async {
        if reset { currentPage = 1; issues = []; hasMore = true }
        guard hasMore, !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let fetched = try await api.issues(owner: owner, repo: repoName, state: stateFilter, page: currentPage)
            issues.append(contentsOf: fetched)
            hasMore = fetched.count >= 20
            currentPage += 1
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

@MainActor
final class IssueDetailViewModel: ObservableObject {
    @Published var issue: GiteaIssue?
    @Published var comments: [GiteaComment] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var error: String?
    @Published var newComment: String = ""

    private let api: GiteaAPIClient
    let owner: String
    let repoName: String
    let number: Int

    init(api: GiteaAPIClient, owner: String, repoName: String, number: Int) {
        self.api = api
        self.owner = owner
        self.repoName = repoName
        self.number = number
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            async let issueTask = api.issue(owner: owner, repo: repoName, number: number)
            async let commentsTask = api.issueComments(owner: owner, repo: repoName, number: number)
            let (i, c) = try await (issueTask, commentsTask)
            issue = i
            comments = c
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func submitComment() async {
        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        do {
            let comment = try await api.createComment(owner: owner, repo: repoName, number: number, body: newComment)
            comments.append(comment)
            newComment = ""
        } catch {
            self.error = error.localizedDescription
        }
        isSending = false
    }

    func toggleState() async {
        guard let issue else { return }
        do {
            let updated: GiteaIssue
            if issue.state == "open" {
                updated = try await api.closeIssue(owner: owner, repo: repoName, number: number)
            } else {
                updated = try await api.reopenIssue(owner: owner, repo: repoName, number: number)
            }
            self.issue = updated
        } catch {
            self.error = error.localizedDescription
        }
    }
}

@MainActor
final class PRListViewModel: ObservableObject {
    @Published var pullRequests: [GiteaPullRequest] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var stateFilter: String = "open"
    @Published var currentPage = 1
    @Published var hasMore = true

    private let api: GiteaAPIClient
    let owner: String
    let repoName: String

    init(api: GiteaAPIClient, owner: String, repoName: String) {
        self.api = api
        self.owner = owner
        self.repoName = repoName
    }

    func load(reset: Bool = false) async {
        if reset { currentPage = 1; pullRequests = []; hasMore = true }
        guard hasMore, !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let fetched = try await api.pullRequests(owner: owner, repo: repoName, state: stateFilter, page: currentPage)
            pullRequests.append(contentsOf: fetched)
            hasMore = fetched.count >= 20
            currentPage += 1
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

@MainActor
final class PRDetailViewModel: ObservableObject {
    @Published var pr: GiteaPullRequest?
    @Published var comments: [GiteaComment] = []
    @Published var isLoading = false
    @Published var isMerging = false
    @Published var isSending = false
    @Published var error: String?
    @Published var newComment: String = ""

    private let api: GiteaAPIClient
    let owner: String
    let repoName: String
    let index: Int

    init(api: GiteaAPIClient, owner: String, repoName: String, index: Int) {
        self.api = api
        self.owner = owner
        self.repoName = repoName
        self.index = index
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            async let prTask = api.pullRequest(owner: owner, repo: repoName, index: index)
            async let commentsTask = api.issueComments(owner: owner, repo: repoName, number: index)
            let (p, c) = try await (prTask, commentsTask)
            pr = p
            comments = c
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func submitComment() async {
        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        do {
            let comment = try await api.createComment(owner: owner, repo: repoName, number: index, body: newComment)
            comments.append(comment)
            newComment = ""
        } catch {
            self.error = error.localizedDescription
        }
        isSending = false
    }

    func merge() async {
        isMerging = true
        do {
            try await api.mergePR(owner: owner, repo: repoName, index: index)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
        isMerging = false
    }
}
