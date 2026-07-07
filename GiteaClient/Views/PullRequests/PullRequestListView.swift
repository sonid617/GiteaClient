import SwiftUI

struct PRListView: View {
    let owner: String
    let repoName: String

    @StateObject private var vm: PRListViewModel

    init(owner: String, repoName: String) {
        self.owner = owner
        self.repoName = repoName
        _vm = StateObject(wrappedValue: PRListViewModel(api: AppState.shared.api!, owner: owner, repoName: repoName))
    }

    var body: some View {
        VStack(spacing: 0) {
            CompactHeader(title: "Pull Requests")

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
                if vm.isLoading && vm.pullRequests.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = vm.error, vm.pullRequests.isEmpty {
                    ErrorView(message: err) { Task { await vm.load(reset: true) } }
                } else if vm.pullRequests.isEmpty {
                    Text("No \(vm.stateFilter) pull requests")
                        .font(.system(size: 14))
                        .foregroundColor(Color.appText2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(vm.pullRequests) { pr in
                                NavigationLink(destination: PRDetailView(owner: owner, repoName: repoName, index: pr.number)) {
                                    PRRowView(pr: pr)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    if pr.id == vm.pullRequests.last?.id {
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
        .task { await vm.load(reset: true) }
    }
}

struct PRRowView: View {
    let pr: GiteaPullRequest

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: pr.stateIcon)
                .font(.system(size: 16))
                .foregroundColor(prStateColor)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(pr.title)
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text("#\(pr.number) by \(pr.user.login)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.appText2)
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.branch").font(.system(size: 10))
                        Text(pr.head.label).font(.system(size: 12)).lineLimit(1)
                    }
                    .foregroundColor(Color.appText2)
                }

                if !pr.labels.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(pr.labels.prefix(3)) { label in LabelBadgeView(label: label) }
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

    private var prStateColor: Color {
        if pr.merged { return .purple }
        return pr.state == "open" ? Color.appOpen : Color.appDanger
    }
}
