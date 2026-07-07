import Foundation

enum GiteaAPIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case notFound
    case serverError(Int, String?)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .unauthorized: return "Invalid credentials or token expired"
        case .notFound: return "Resource not found"
        case .serverError(let code, let msg): return msg ?? "Server error \(code)"
        case .decodingError(let e): return "Parse error: \(e.localizedDescription)"
        case .networkError(let e): return e.localizedDescription
        case .unknown: return "Unknown error"
        }
    }
}

struct GiteaTokenResponse: Codable {
    let id: Int
    let name: String
    let sha1: String
}

struct GiteaErrorResponse: Codable {
    let message: String?
}

final class GiteaAPIClient {
    let serverURL: String
    private let token: String
    private let session: URLSession

    init(serverURL: String, token: String) {
        self.serverURL = serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.token = token
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    private var baseURL: String { "\(serverURL)/api/v1" }

    private func request(_ path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw GiteaAPIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return req
    }

    private func fetch<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        let req = try request(path, method: method, body: body)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw GiteaAPIError.unknown }
        switch http.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                throw GiteaAPIError.decodingError(error)
            }
        case 401: throw GiteaAPIError.unauthorized
        case 404: throw GiteaAPIError.notFound
        default:
            let msg = (try? JSONDecoder().decode(GiteaErrorResponse.self, from: data))?.message
            throw GiteaAPIError.serverError(http.statusCode, msg)
        }
    }

    private func fetchVoid(_ path: String, method: String, body: Data? = nil) async throws {
        let req = try request(path, method: method, body: body)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw GiteaAPIError.unknown }
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 { throw GiteaAPIError.unauthorized }
            let msg = (try? JSONDecoder().decode(GiteaErrorResponse.self, from: data))?.message
            throw GiteaAPIError.serverError(http.statusCode, msg)
        }
    }

    // MARK: - Auth

    static func createToken(serverURL: String, username: String, password: String) async throws -> String {
        let base = serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let tokenName = "GiteaClient-iOS-\(Int(Date().timeIntervalSince1970))"
        guard let url = URL(string: "\(base)/api/v1/users/\(username)/tokens") else {
            throw GiteaAPIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let creds = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        req.setValue("Basic \(creds)", forHTTPHeaderField: "Authorization")
        struct TokenRequest: Encodable {
            let name: String
            let scopes: [String]
        }
        let tokenRequest = TokenRequest(name: tokenName, scopes: [
            "read:user", "write:user",
            "read:repository", "write:repository",
            "read:issue", "write:issue",
            "read:notification", "write:notification",
            "read:organization"
        ])
        req.httpBody = try? JSONEncoder().encode(tokenRequest)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: config)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw GiteaAPIError.unknown }
        switch http.statusCode {
        case 200...201:
            let token = try JSONDecoder().decode(GiteaTokenResponse.self, from: data)
            return token.sha1
        case 401: throw GiteaAPIError.unauthorized
        default:
            let msg = (try? JSONDecoder().decode(GiteaErrorResponse.self, from: data))?.message
            throw GiteaAPIError.serverError(http.statusCode, msg)
        }
    }

    // MARK: - User

    func currentUser() async throws -> GiteaUser {
        try await fetch("/user")
    }

    func user(username: String) async throws -> GiteaUser {
        try await fetch("/users/\(username)")
    }

    func userFollowers(username: String, page: Int = 1) async throws -> [GiteaUser] {
        try await fetch("/users/\(username)/followers?limit=30&page=\(page)")
    }

    func userFollowing(username: String, page: Int = 1) async throws -> [GiteaUser] {
        try await fetch("/users/\(username)/following?limit=30&page=\(page)")
    }

    // MARK: - Repositories

    func userRepos(page: Int = 1) async throws -> [GiteaRepository] {
        let result: GiteaSearchResult = try await fetch("/repos/search?limit=50&page=\(page)&sort=updated")
        return result.data
    }

    func myRepos(page: Int = 1) async throws -> [GiteaRepository] {
        let result: GiteaSearchResult = try await fetch("/repos/search?limit=50&page=\(page)&sort=updated")
        return result.data
    }

    func exploreRepos(query: String = "", page: Int = 1) async throws -> [GiteaRepository] {
        let q = query.isEmpty ? "" : "&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        let result: GiteaSearchResult = try await fetch("/repos/search?limit=20&page=\(page)&sort=updated\(q)")
        return result.data
    }

    func repo(owner: String, name: String) async throws -> GiteaRepository {
        try await fetch("/repos/\(owner)/\(name)")
    }

    func reposForUser(username: String, page: Int = 1) async throws -> [GiteaRepository] {
        try await fetch("/users/\(username)/repos?limit=30&page=\(page)")
    }

    func starRepo(owner: String, name: String) async throws {
        try await fetchVoid("/user/starred/\(owner)/\(name)", method: "PUT")
    }

    func unstarRepo(owner: String, name: String) async throws {
        try await fetchVoid("/user/starred/\(owner)/\(name)", method: "DELETE")
    }

    func isStarred(owner: String, name: String) async throws -> Bool {
        let req = try request("/user/starred/\(owner)/\(name)")
        let (_, response) = try await session.data(for: req)
        return (response as? HTTPURLResponse)?.statusCode == 204
    }

    func forkRepo(owner: String, name: String, organization: String? = nil) async throws -> GiteaRepository {
        var body: [String: String] = [:]
        if let org = organization { body["organization"] = org }
        let data = try JSONEncoder().encode(body)
        return try await fetch("/repos/\(owner)/\(name)/forks", method: "POST", body: data)
    }

    // MARK: - Contents

    func contents(owner: String, repo: String, path: String = "", ref: String? = nil) async throws -> [GiteaContent] {
        var url = "/repos/\(owner)/\(repo)/contents/\(path)"
        if let ref { url += "?ref=\(ref)" }
        return try await fetch(url)
    }

    func fileContent(owner: String, repo: String, path: String, ref: String? = nil) async throws -> GiteaContent {
        var url = "/repos/\(owner)/\(repo)/contents/\(path)"
        if let ref { url += "?ref=\(ref)" }
        return try await fetch(url)
    }

    // MARK: - Branches

    func branches(owner: String, repo: String) async throws -> [GiteaBranch] {
        try await fetch("/repos/\(owner)/\(repo)/branches?limit=50")
    }

    // MARK: - Commits

    func commits(owner: String, repo: String, branch: String? = nil, page: Int = 1) async throws -> [GiteaCommit] {
        var url = "/repos/\(owner)/\(repo)/commits?limit=30&page=\(page)"
        if let branch { url += "&sha=\(branch)" }
        return try await fetch(url)
    }

    // MARK: - Issues

    func issues(owner: String, repo: String, state: String = "open", page: Int = 1) async throws -> [GiteaIssue] {
        try await fetch("/repos/\(owner)/\(repo)/issues?type=issues&state=\(state)&limit=20&page=\(page)")
    }

    func issue(owner: String, repo: String, number: Int) async throws -> GiteaIssue {
        try await fetch("/repos/\(owner)/\(repo)/issues/\(number)")
    }

    func issueComments(owner: String, repo: String, number: Int) async throws -> [GiteaComment] {
        try await fetch("/repos/\(owner)/\(repo)/issues/\(number)/comments?limit=50")
    }

    func createIssue(owner: String, repo: String, title: String, body: String, labels: [Int] = []) async throws -> GiteaIssue {
        struct CreateIssue: Encodable {
            let title: String
            let body: String
            let labels: [Int]
        }
        let payload = CreateIssue(title: title, body: body, labels: labels)
        let data = try JSONEncoder().encode(payload)
        return try await fetch("/repos/\(owner)/\(repo)/issues", method: "POST", body: data)
    }

    func createComment(owner: String, repo: String, number: Int, body: String) async throws -> GiteaComment {
        struct CreateComment: Encodable { let body: String }
        let data = try JSONEncoder().encode(CreateComment(body: body))
        return try await fetch("/repos/\(owner)/\(repo)/issues/\(number)/comments", method: "POST", body: data)
    }

    func closeIssue(owner: String, repo: String, number: Int) async throws -> GiteaIssue {
        struct PatchIssue: Encodable { let state: String }
        let data = try JSONEncoder().encode(PatchIssue(state: "closed"))
        return try await fetch("/repos/\(owner)/\(repo)/issues/\(number)", method: "PATCH", body: data)
    }

    func reopenIssue(owner: String, repo: String, number: Int) async throws -> GiteaIssue {
        struct PatchIssue: Encodable { let state: String }
        let data = try JSONEncoder().encode(PatchIssue(state: "open"))
        return try await fetch("/repos/\(owner)/\(repo)/issues/\(number)", method: "PATCH", body: data)
    }

    func labels(owner: String, repo: String) async throws -> [GiteaLabel] {
        try await fetch("/repos/\(owner)/\(repo)/labels?limit=50")
    }

    // MARK: - Pull Requests

    func pullRequests(owner: String, repo: String, state: String = "open", page: Int = 1) async throws -> [GiteaPullRequest] {
        try await fetch("/repos/\(owner)/\(repo)/pulls?state=\(state)&limit=20&page=\(page)")
    }

    func pullRequest(owner: String, repo: String, index: Int) async throws -> GiteaPullRequest {
        try await fetch("/repos/\(owner)/\(repo)/pulls/\(index)")
    }

    func mergePR(owner: String, repo: String, index: Int, mergeStyle: String = "merge", message: String = "") async throws {
        struct MergePayload: Encodable {
            let Do: String
            let merge_message_field: String
            enum CodingKeys: String, CodingKey {
                case Do = "Do"
                case merge_message_field = "merge_message_field"
            }
        }
        let payload = MergePayload(Do: mergeStyle, merge_message_field: message)
        let data = try JSONEncoder().encode(payload)
        try await fetchVoid("/repos/\(owner)/\(repo)/pulls/\(index)/merge", method: "POST", body: data)
    }

    // MARK: - Readme & Releases

    func readme(owner: String, repo: String) async throws -> GiteaContent {
        try await fetch("/repos/\(owner)/\(repo)/readme")
    }

    func releases(owner: String, repo: String, page: Int = 1) async throws -> [GiteaRelease] {
        try await fetch("/repos/\(owner)/\(repo)/releases?limit=20&page=\(page)")
    }

    // MARK: - Notifications

    func notifications(all: Bool = false, page: Int = 1) async throws -> [GiteaNotification] {
        try await fetch("/notifications?all=\(all)&limit=50&page=\(page)")
    }

    func markAllNotificationsRead() async throws {
        try await fetchVoid("/notifications", method: "PUT")
    }

    func markNotificationRead(id: String) async throws {
        try await fetchVoid("/notifications/threads/\(id)", method: "PATCH")
    }
}
