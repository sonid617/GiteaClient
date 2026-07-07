import SwiftUI

struct ReleasesView: View {
    let owner: String
    let repoName: String

    @State private var releases: [GiteaRelease] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var page = 1
    @State private var hasMore = true

    var body: some View {
        VStack(spacing: 0) {
            CompactHeader(title: "Releases")

            Group {
                if isLoading && releases.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = error, releases.isEmpty {
                    ErrorView(message: err) { Task { await load(reset: true) } }
                } else if releases.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tag")
                            .font(.system(size: 40))
                            .foregroundColor(Color.appText3)
                        Text("No releases yet")
                            .font(.system(size: 14))
                            .foregroundColor(Color.appText2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(releases) { release in
                                releaseRow(release)
                                    .onAppear {
                                        if release.id == releases.last?.id { Task { await load() } }
                                    }
                            }
                            if isLoading { ProgressView().padding() }
                        }
                    }
                    .refreshable { await load(reset: true) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBg)
        }
        .background(Color.appBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { await load(reset: true) }
    }

    private func releaseRow(_ release: GiteaRelease) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
                Text(release.tagName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                if release.prerelease {
                    Text("Pre-release")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Color.appWarn)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.appWarn.opacity(0.15))
                        .clipShape(Capsule())
                }
                if release.draft {
                    Text("Draft")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Color.appText2)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.appCardAlt)
                        .clipShape(Capsule())
                }
            }
            if !release.name.isEmpty && release.name != release.tagName {
                Text(release.name)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(.primary)
            }
            if let body = release.body, !body.isEmpty {
                Text(body)
                    .font(.system(size: 13))
                    .foregroundColor(Color.appText2)
                    .lineLimit(3)
                    .lineSpacing(2)
            }
            Text("\(release.author.login) · \(relativeDate(release.createdAt))")
                .font(.system(size: 12))
                .foregroundColor(Color.appText3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(Divider(), alignment: .bottom)
    }

    private func load(reset: Bool = false) async {
        if reset { page = 1; releases = []; hasMore = true }
        guard hasMore, !isLoading else { return }
        isLoading = true
        do {
            let fetched = try await AppState.shared.api!.releases(owner: owner, repo: repoName, page: page)
            releases.append(contentsOf: fetched)
            hasMore = fetched.count >= 20
            page += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    private func relativeDate(_ iso: String) -> String {
        let fmts: [ISO8601DateFormatter] = [ISO8601DateFormatter(), {
            let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f
        }()]
        for fmt in fmts {
            if let date = fmt.date(from: iso) {
                let rel = RelativeDateTimeFormatter(); rel.unitsStyle = .abbreviated
                return rel.localizedString(for: date, relativeTo: Date())
            }
        }
        return iso
    }
}
