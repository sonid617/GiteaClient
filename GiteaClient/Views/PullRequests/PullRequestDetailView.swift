import SwiftUI

struct PRDetailView: View {
    let owner: String
    let repoName: String
    let index: Int

    @StateObject private var vm: PRDetailViewModel

    init(owner: String, repoName: String, index: Int) {
        self.owner = owner
        self.repoName = repoName
        self.index = index
        _vm = StateObject(wrappedValue: PRDetailViewModel(api: AppState.shared.api!, owner: owner, repoName: repoName, index: index))
    }

    var body: some View {
        VStack(spacing: 0) {
            CompactHeader(title: "PR #\(index)")

            Group {
                if vm.isLoading && vm.pr == nil {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = vm.error, vm.pr == nil {
                    ErrorView(message: err) { Task { await vm.load() } }
                } else if let pr = vm.pr {
                    prContent(pr)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBg)
        }
        .background(Color.appBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { await vm.load() }
    }

    private func prContent(_ pr: GiteaPullRequest) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                prHeader(pr)
                Divider()
                if let body = pr.body, !body.isEmpty {
                    MarkdownText(text: body).font(.body).padding()
                    Divider()
                }
                mergeSection(pr)
                commentsSection
                commentInput
            }
        }
    }

    private func prHeader(_ pr: GiteaPullRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(pr.title).font(.title3).fontWeight(.semibold)

            HStack(spacing: 8) {
                prStatePill(pr)
                AsyncAvatarView(url: pr.user.avatarUrl, size: 18)
                Text(pr.user.login).font(.caption).foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                branchChip(pr.head.label, isHead: true)
                Image(systemName: "arrow.right").font(.caption).foregroundColor(.secondary)
                branchChip(pr.base.label, isHead: false)
            }

            if let additions = pr.additions, let deletions = pr.deletions {
                HStack(spacing: 12) {
                    Text("+\(additions)").foregroundColor(.green).font(.caption).fontWeight(.semibold)
                    Text("-\(deletions)").foregroundColor(.red).font(.caption).fontWeight(.semibold)
                    if let files = pr.changedFiles {
                        Text("\(files) files changed").font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            if !pr.labels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) { ForEach(pr.labels) { LabelBadgeView(label: $0) } }
                }
            }
        }
        .padding()
    }

    private func branchChip(_ name: String, isHead: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.branch").font(.caption2)
            Text(name).font(.caption).lineLimit(1)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(isHead ? Color.accentColor.opacity(0.15) : Color(.systemGray5))
        .foregroundColor(isHead ? .accentColor : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func prStatePill(_ pr: GiteaPullRequest) -> some View {
        let color: Color = pr.merged ? .purple : (pr.state == "open" ? .green : .red)
        let label = pr.merged ? "Merged" : pr.state.capitalized
        return HStack(spacing: 4) {
            Image(systemName: pr.stateIcon)
            Text(label)
        }
        .font(.caption).fontWeight(.semibold)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func mergeSection(_ pr: GiteaPullRequest) -> some View {
        if pr.state == "open" && !pr.merged {
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                HStack {
                    if pr.mergeable == true {
                        Button(action: { Task { await vm.merge() } }) {
                            HStack {
                                if vm.isMerging { ProgressView().tint(.white) }
                                else { Image(systemName: "arrow.triangle.merge") }
                                Text("Merge Pull Request")
                            }
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(vm.isMerging)
                    } else {
                        Label("Cannot be merged automatically", systemImage: "xmark.circle")
                            .font(.caption).foregroundColor(.orange)
                    }
                }
                .padding()
                Divider()
            }
        }
    }

    private var commentsSection: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(vm.comments) { comment in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        AsyncAvatarView(url: comment.user.avatarUrl, size: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(comment.user.login).font(.subheadline).fontWeight(.semibold)
                            Text(relativeDate(comment.createdAt)).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    MarkdownText(text: comment.body).font(.body)
                }
                .padding()
                Divider()
            }
        }
    }

    private var commentInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            HStack(alignment: .bottom, spacing: 8) {
                if let user = AppState.shared.currentUser {
                    AsyncAvatarView(url: user.avatarUrl, size: 32)
                }
                ZStack(alignment: .topLeading) {
                    if vm.newComment.isEmpty {
                        Text("Leave a comment…").foregroundColor(.secondary)
                            .padding(.horizontal, 4).padding(.vertical, 8)
                    }
                    TextEditor(text: $vm.newComment)
                        .frame(minHeight: 44, maxHeight: 120)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Button(action: { Task { await vm.submitComment() } }) {
                    Image(systemName: vm.isSending ? "hourglass" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(vm.newComment.isEmpty ? .secondary : .accentColor)
                }
                .disabled(vm.newComment.isEmpty || vm.isSending)
            }
            .padding()
        }
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
