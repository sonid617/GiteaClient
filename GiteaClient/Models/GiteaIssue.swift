import Foundation

struct GiteaLabel: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let color: String
    let description: String?
}

struct GiteaMilestone: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String?
    let state: String
    let openIssues: Int
    let closedIssues: Int

    enum CodingKeys: String, CodingKey {
        case id, title, description, state
        case openIssues = "open_issues"
        case closedIssues = "closed_issues"
    }
}

struct GiteaIssue: Codable, Identifiable, Hashable {
    let id: Int
    let number: Int
    let user: GiteaUser
    let title: String
    let body: String?
    let state: String
    let labels: [GiteaLabel]
    let assignees: [GiteaUser]?
    let milestone: GiteaMilestone?
    let comments: Int
    let createdAt: String
    let updatedAt: String
    let htmlUrl: String
    let pullRequest: GiteaIssuePR?

    enum CodingKeys: String, CodingKey {
        case id, number, user, title, body, state, labels, assignees, milestone, comments
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case htmlUrl = "html_url"
        case pullRequest = "pull_request"
    }

    var isPullRequest: Bool { pullRequest != nil }

    var stateColor: String {
        switch state {
        case "open": return "2da44e"
        case "closed": return "cf222e"
        default: return "8250df"
        }
    }
}

struct GiteaIssuePR: Codable, Hashable {
    let merged: Bool?
    let mergedAt: String?

    enum CodingKeys: String, CodingKey {
        case merged
        case mergedAt = "merged_at"
    }
}

struct GiteaComment: Codable, Identifiable, Hashable {
    let id: Int
    let user: GiteaUser
    let body: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, user, body
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
