import Foundation

struct GiteaUser: Codable, Identifiable, Hashable {
    let id: Int
    let login: String
    let fullName: String
    let email: String?
    let avatarUrl: String
    let description: String?
    let website: String?
    let followersCount: Int?
    let followingCount: Int?
    let starredReposCount: Int?
    let created: String?

    enum CodingKeys: String, CodingKey {
        case id, login, email, description, website, created
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case starredReposCount = "starred_repos_count"
    }

    var displayName: String {
        fullName.isEmpty ? login : fullName
    }
}
