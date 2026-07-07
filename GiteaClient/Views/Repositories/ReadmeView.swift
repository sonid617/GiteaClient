import SwiftUI

struct ReadmeView: View {
    let owner: String
    let repoName: String

    @State private var content: String?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            CompactHeader(title: "README")

            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = error {
                    ErrorView(message: err) { Task { await load() } }
                } else if let text = content {
                    ScrollView {
                        MarkdownText(text: text)
                            .font(.system(size: 14.5))
                            .foregroundColor(.primary)
                            .lineSpacing(3)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(Color.appText3)
                        Text("No README found")
                            .font(.system(size: 14))
                            .foregroundColor(Color.appText2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func load() async {
        isLoading = true
        error = nil
        do {
            let readme = try await AppState.shared.api!.readme(owner: owner, repo: repoName)
            content = readme.decodedContent
        } catch GiteaAPIError.notFound {
            content = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
