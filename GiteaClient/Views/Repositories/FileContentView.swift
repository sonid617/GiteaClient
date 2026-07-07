import SwiftUI

struct FileContentView: View {
    let owner: String
    let repoName: String
    let path: String
    let branch: String

    @State private var content: GiteaContent?
    @State private var isLoading = false
    @State private var error: String?

    private var fileName: String {
        path.components(separatedBy: "/").last ?? path
    }

    var body: some View {
        VStack(spacing: 0) {
            CompactHeader(title: fileName)

            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = error {
                    ErrorView(message: err) { Task { await load() } }
                } else if let file = content {
                    fileBody(file)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBg)
        }
        .background(Color.appBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { await load() }
    }

    @ViewBuilder
    private func fileBody(_ file: GiteaContent) -> some View {
        if isImageFile(file.name) {
            ScrollView {
                if let url = file.htmlUrl.flatMap(URL.init) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFit()
                        default: ProgressView()
                        }
                    }
                    .padding(16)
                }
            }
        } else if let text = file.decodedContent {
            ScrollView([.horizontal, .vertical]) {
                Text(text)
                    .font(.system(size: 12.5, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .textSelection(.enabled)
            }
            .background(Color.appCardAlt)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(16)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.appText3)
                Text("Binary file")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appText2)
                if let size = file.size {
                    Text(formatSize(size))
                        .font(.system(size: 12))
                        .foregroundColor(Color.appText3)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func isImageFile(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["png", "jpg", "jpeg", "gif", "webp", "svg"].contains(ext)
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            content = try await AppState.shared.api!.fileContent(owner: owner, repo: repoName, path: path, ref: branch)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}
