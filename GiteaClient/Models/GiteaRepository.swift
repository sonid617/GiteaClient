import Foundation

struct GiteaRepository: Codable, Identifiable, Hashable {
    let id: Int
    let owner: GiteaUser
    let name: String
    let fullName: String
    let description: String?
    let isPrivate: Bool
    let fork: Bool?
    let htmlUrl: String?
    let sshUrl: String?
    let cloneUrl: String?
    let starsCount: Int
    let forksCount: Int
    let watchersCount: Int?
    let openIssuesCount: Int?
    let defaultBranch: String?
    let hasIssues: Bool?
    let hasWiki: Bool?
    let language: String?
    let updatedAt: String?
    let topics: [String]?

    enum CodingKeys: String, CodingKey {
        case id, owner, name, description, fork, language, topics
        case fullName = "full_name"
        case isPrivate = "private"
        case htmlUrl = "html_url"
        case sshUrl = "ssh_url"
        case cloneUrl = "clone_url"
        case starsCount = "stars_count"
        case forksCount = "forks_count"
        case watchersCount = "watchers_count"
        case openIssuesCount = "open_issues_count"
        case defaultBranch = "default_branch"
        case hasIssues = "has_issues"
        case hasWiki = "has_wiki"
        case updatedAt = "updated"
    }
}

struct GiteaSearchResult: Codable {
    let data: [GiteaRepository]
    let ok: Bool?
}
