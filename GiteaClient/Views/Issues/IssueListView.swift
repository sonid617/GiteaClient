import SwiftUI

struct IssueListView: View {
    let owner: String
    let repoName: String

    @StateObject private var vm: IssueListViewModel
    @State private var showNewIssue = false

    init(owner: String, repoName: String) {
        self.owner = owner
        self.repoName = repoName
        _vm = StateObject(wrappedValue: IssueListViewModel(api: AppState.shared.api!, owner: owner, repoName: repoName))
    }

    var body: some View {
        VStack(spacing: 0) {
            CompactHeader(
                title: "Issues",
                trailing: AnyView(
                    Button { showNewIssue = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                )
            )

            // Filter chips
            HStack(spacing: 8) {
                FilterChip(label: "Open", active: vm.stateFilter == "open") {
                    vm.stateFilter = "open"
                    Task { await vm.load(reset: true) }
                }
                FilterChip(label: "Closed", active: vm.stateFilter == "closed") {
                    vm.stateFilter = "closed"
                    Task { await vm.load(reset: true) }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appBg)

            Group {
                if vm.isLoading && vm.issues.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = vm.error, vm.issues.isEmpty {
                    ErrorView(message: err) { Task { await vm.load(reset: true) } }
                } else if vm.issues.isEmpty {
                    Text("No \(vm.stateFilter) issues")
                        .font(.system(size: 14))
                        .foregroundColor(Color.appText2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(vm.issues) { issue in
                                NavigationLink(destination: IssueDetailView(owner: owner, repoName: repoName, number: issue.number)) {
                                    IssueRowView(issue: issue)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    if issue.id == vm.issues.last?.id {
                                        Task { await vm.load() }
                                    }
                                }
                            }
                            if vm.isLoading {
                                ProgressView().padding()
                            }
                        }
                    }
                    .refreshable { await vm.load(reset: true) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBg)
        }
        .background(Color.appBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showNewIssue) {
            NewIssueView(owner: owner, repoName: repoName, onCreated: {
                showNewIssue = false
                Task { await vm.load(reset: true) }
            })
        }
        .task { await vm.load(reset: true) }
    }
}

struct IssueRowView: View {
    let issue: GiteaIssue

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: issue.state == "open" ? "circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(issue.state == "open" ? Color.appOpen : .purple)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text("#\(issue.number) by \(issue.user.login)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.appText2)
                    if issue.comments > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "bubble.right").font(.system(size: 11))
                            Text("\(issue.comments)").font(.system(size: 12))
                        }
                        .foregroundColor(Color.appText2)
                    }
                }

                if !issue.labels.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(issue.labels.prefix(3)) { label in
                            LabelBadgeView(label: label)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(Divider(), alignment: .bottom)
    }
}

struct NewIssueView: View {
    let owner: String
    let repoName: String
    let onCreated: () -> Void

    @State private var title = ""
    @State private var issueBody = ""
    @State private var isSubmitting = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Issue title", text: $title)
                }
                Section("Description") {
                    TextEditor(text: $issueBody)
                        .frame(minHeight: 120)
                }
                if let err = error {
                    Section {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("New Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { Task { await submit() } }
                        .disabled(title.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        do {
            _ = try await AppState.shared.api!.createIssue(owner: owner, repo: repoName, title: title, body: issueBody)
            onCreated()
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}
