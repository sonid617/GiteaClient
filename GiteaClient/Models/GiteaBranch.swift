import Foundation

struct GiteaBranchCommit: Codable, Hashable {
    let id: String
    let message: String?
    let added: [String]?
    let removed: [String]?
    let modified: [String]?
    let timestamp: String?
}

struct GiteaBranch: Codable, Identifiable, Hashable {
    let name: String
    let commit: GiteaBranchCommit?
    let protected: Bool?

    var id: String { name }
}
