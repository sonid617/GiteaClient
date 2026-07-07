import Foundation

struct GiteaPRBranch: Codable, Hashable {
    let label: String
    let ref: String
    let sha: String
    let repo: GiteaRepository?
}

struct GiteaPullRequest: Codable, Identifiable, Hashable {
    let id: Int
    let number: Int
    let state: String
    let title: String
    let body: String?
    let user: GiteaUser
    let head: GiteaPRBranch
    let base: GiteaPRBranch
    let mergeable: Bool?
    let merged: Bool
    let mergedAt: String?
    let requestedReviewers: [GiteaUser]?
    let labels: [GiteaLabel]
    let createdAt: String
    let updatedAt: String
    let htmlUrl: String
    let comments: Int
    let additions: Int?
    let deletions: Int?
    let changedFiles: Int?

    enum CodingKeys: String, CodingKey {
        case id, number, state, title, body, user, head, base, mergeable, merged, labels, comments, additions, deletions
        case mergedAt = "merged_at"
        case requestedReviewers = "requested_reviewers"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case htmlUrl = "html_url"
        case changedFiles = "changed_files"
    }

    var stateColor: String {
        if merged { return "8250df" }
        return state == "open" ? "2da44e" : "cf222e"
    }

    var stateIcon: String {
        if merged { return "arrow.triangle.merge" }
        return state == "open" ? "arrow.triangle.pull" : "xmark.circle"
    }
}
