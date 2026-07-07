import Foundation

struct GiteaContent: Codable, Identifiable, Hashable {
    let type: String
    let name: String
    let path: String
    let sha: String?
    let size: Int?
    let url: String?
    let htmlUrl: String?
    let content: String?
    let encoding: String?

    var id: String { path }

    enum CodingKeys: String, CodingKey {
        case type, name, path, sha, size, url, content, encoding
        case htmlUrl = "html_url"
    }

    var isDirectory: Bool { type == "dir" }
    var isFile: Bool { type == "file" }

    var fileIcon: String {
        if isDirectory { return "folder.fill" }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "md", "markdown": return "doc.text"
        case "json": return "curlybraces"
        case "yaml", "yml": return "list.bullet.rectangle"
        case "png", "jpg", "jpeg", "gif", "svg", "webp": return "photo"
        case "pdf": return "doc.richtext"
        case "sh", "bash", "zsh": return "terminal"
        case "py": return "doc.plaintext"
        case "js", "ts", "jsx", "tsx": return "doc.plaintext"
        case "html", "htm": return "chevron.left.forwardslash.chevron.right"
        default: return "doc"
        }
    }

    var decodedContent: String? {
        guard let content, encoding == "base64" else { return content }
        let cleaned = content.replacingOccurrences(of: "\n", with: "")
        guard let data = Data(base64Encoded: cleaned) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
