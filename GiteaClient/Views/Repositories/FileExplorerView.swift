import SwiftUI

struct FileExplorerView: View {
    let owner: String
    let repoName: String
    let path: String
    let branch: String

    @State private var contents: [GiteaContent] = []
    @State private var isLoading = false
    @State private var error: String?

    private var title: String {
        path.isEmpty ? "Files" : (path.components(separatedBy: "/").last ?? path)
    }

    var body: some View {
        VStack(spacing: 0) {
            CompactHeader(title: title)

            Group {
                if isLoading && contents.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = error {
                    ErrorView(message: err) { Task { await load() } }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(contents) { item in
                                if item.isDirectory {
                                    NavigationLink(destination:
                                        FileExplorerView(owner: owner, repoName: repoName, path: item.path, branch: branch)
                                    ) {
                                        fileRow(item)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink(destination:
                                        FileContentView(owner: owner, repoName: repoName, path: item.path, branch: branch)
                                    ) {
                                        fileRow(item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
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

    private func fileRow(_ item: GiteaContent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.fileIcon)
                .font(.system(size: 16))
                .foregroundColor(item.isDirectory ? .accentColor : Color.appText2)
                .frame(width: 26)
            Text(item.name)
                .font(.system(size: 15))
                .foregroundColor(.primary)
            Spacer()
            if item.isFile, let size = item.size, size > 0 {
                Text(formatSize(size))
                    .font(.system(size: 12))
                    .foregroundColor(Color.appText3)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.appText3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .overlay(Divider(), alignment: .bottom)
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let items = try await AppState.shared.api!.contents(
                owner: owner, repo: repoName, path: path, ref: branch)
            contents = items.sorted { a, b in
                if a.isDirectory != b.isDirectory { return a.isDirectory }
                return a.name.lowercased() < b.name.lowercased()
            }
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
