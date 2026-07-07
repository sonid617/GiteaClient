import Foundation

struct GiteaNotificationSubject: Codable, Hashable {
    let title: String
    let url: String?
    let type: String
    let state: String?
}

struct GiteaNotification: Codable, Identifiable, Hashable {
    let id: String
    let repository: GiteaRepository
    let subject: GiteaNotificationSubject
    let unread: Bool
    let pinned: Bool
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, repository, subject, unread, pinned
        case updatedAt = "updated_at"
    }

    var typeIcon: String {
        switch subject.type {
        case "Issue": return "circle.badge.exclamationmark"
        case "Pull": return "arrow.triangle.pull"
        case "Commit": return "chevron.left.forwardslash.chevron.right"
        case "Repository": return "folder"
        default: return "bell"
        }
    }

    // Parse subject.url like: https://host/api/v1/repos/{owner}/{repo}/issues/{number}
    var parsedDestination: NotificationDestination? {
        guard let urlStr = subject.url, let url = URL(string: urlStr) else { return nil }
        let c = url.pathComponents
        // c = ["/", "api", "v1", "repos", owner, repo, "issues"/"pulls", number]
        guard c.count >= 8, c[3] == "repos", let number = Int(c[7]) else { return nil }
        let isPR = subject.type == "Pull" || c[6] == "pulls"
        return NotificationDestination(owner: c[4], repoName: c[5], number: number, isPullRequest: isPR)
    }
}

struct NotificationDestination {
    let owner: String
    let repoName: String
    let number: Int
    let isPullRequest: Bool
}
