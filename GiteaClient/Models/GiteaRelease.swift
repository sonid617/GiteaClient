import Foundation

struct GiteaRelease: Codable, Identifiable {
    let id: Int
    let tagName: String
    let name: String
    let body: String?
    let draft: Bool
    let prerelease: Bool
    let createdAt: String
    let author: GiteaUser

    enum CodingKeys: String, CodingKey {
        case id, name, body, draft, prerelease, author
        case tagName = "tag_name"
        case createdAt = "created_at"
    }
}
