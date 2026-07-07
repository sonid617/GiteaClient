import SwiftUI

struct IssueDetailView: View {
    let owner: String
    let repoName: String
    let number: Int

    @StateObject private var vm: IssueDetailViewModel

    init(owner: String, repoName: String, number: Int) {
        self.owner = owner
        self.repoName = repoName
        self.number = number
        _vm = StateObject(wrappedValue: IssueDetailViewModel(api: AppState.shared.api!, owner: owner, repoName: repoName, number: number))
    }

    var body: some View {
        VStack(spacing: 0) {
            CompactHeader(
                title: "#\(number)",
                trailing: vm.issue.map { issue in
                    AnyView(
                        Button(issue.state == "open" ? "Close" : "Reopen") {
                            Task { await vm.toggleState() }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(issue.state == "open" ? Color.appDanger : Color.appOpen)
                        .buttonStyle(.plain)
                    )
                }
            )

            Group {
                if vm.isLoading && vm.issue == nil {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = vm.error, vm.issue == nil {
                    ErrorView(message: err) { Task { await vm.load() } }
                } else if let issue = vm.issue {
                    issueContent(issue)
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

    private func issueContent(_ issue: GiteaIssue) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                issueHeader(issue)
                commentsSection
                commentInput
            }
        }
        .refreshable { await vm.load() }
    }

    private func issueHeader(_ issue: GiteaIssue) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                statePill(issue)
            }

            Text(issue.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .lineSpacing(2)

            Text("#\(issue.number) opened by \(issue.user.login)")
                .font(.system(size: 13))
                .foregroundColor(Color.appText2)

            if !issue.labels.isEmpty {
                HStack(spacing: 5) {
                    ForEach(issue.labels) { LabelBadgeView(label: $0) }
                }
            }

            if let body = issue.body, !body.isEmpty {
                MarkdownText(text: body)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 0.5))
                    .padding(.top, 6)
            }

            SectionLabel(text: "Comments")
                .padding(.top, 10)
        }
        .padding(18)
    }

    private func statePill(_ issue: GiteaIssue) -> some View {
        HStack(spacing: 4) {
            Image(systemName: issue.state == "open" ? "circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 12))
            Text(issue.state.capitalized)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(issue.state == "open" ? Color.appOpen.opacity(0.15) : Color.purple.opacity(0.15))
        .foregroundColor(issue.state == "open" ? Color.appOpen : .purple)
        .clipShape(Capsule())
    }

    private var commentsSection: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(vm.comments) { comment in
                commentRow(comment)
                Divider()
            }
        }
    }

    private func commentRow(_ comment: GiteaComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(comment.user.login.prefix(2).uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(avatarColor(for: comment.user.login))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(comment.user.login)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(relativeDate(comment.createdAt))
                        .font(.system(size: 11.5))
                        .foregroundColor(Color.appText3)
                }
                MarkdownText(text: comment.body)
                    .font(.system(size: 13.5))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
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
                        Text("Leave a comment…")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
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
        let fmts = [ISO8601DateFormatter(), {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()]
        for fmt in fmts {
            if let date = fmt.date(from: iso) {
                let rel = RelativeDateTimeFormatter()
                rel.unitsStyle = .abbreviated
                return rel.localizedString(for: date, relativeTo: Date())
            }
        }
        return iso
    }
}
