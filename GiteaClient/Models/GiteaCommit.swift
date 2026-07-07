import Foundation

struct GiteaCommitDetail: Codable, Hashable {
    let message: String
    let author: GiteaCommitAuthor?
    let committer: GiteaCommitAuthor?
    let added: [String]?
    let removed: [String]?
    let modified: [String]?
}

struct GiteaCommitAuthor: Codable, Hashable {
    let name: String
    let email: String
    let date: String?
}

struct GiteaCommit: Codable, Identifiable, Hashable {
    let sha: String
    let created: String?
    let commit: GiteaCommitDetail
    let author: GiteaUser?
    let committer: GiteaUser?
    let htmlUrl: String?

    var id: String { sha }

    enum CodingKeys: String, CodingKey {
        case sha, created, commit, author, committer
        case htmlUrl = "html_url"
    }

    var shortSha: String { String(sha.prefix(7)) }

    var shortMessage: String {
        commit.message.components(separatedBy: "\n").first ?? commit.message
    }
}
