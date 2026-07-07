import SwiftUI

struct RepositoryListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm: RepositoryViewModel
    @State private var searchText = ""

    init() {
        _vm = StateObject(wrappedValue: RepositoryViewModel(api: AppState.shared.api!))
    }

    var filteredRepos: [GiteaRepository] {
        guard !searchText.isEmpty else { return vm.repos }
        return vm.repos.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LargeHeader(title: "Repos", searchText: $searchText, placeholder: "Filter repositories")

                Group {
                    if vm.isLoading && vm.repos.isEmpty {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let err = vm.error, vm.repos.isEmpty {
                        ErrorView(message: err) { Task { await vm.loadMyRepos(reset: true) } }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredRepos) { repo in
                                    NavigationLink(destination: RepoDetailView(owner: repo.owner.login, repoName: repo.name)) {
                                        RepoRowView(repo: repo)
                                    }
                                    .buttonStyle(.plain)
                                    .onAppear {
                                        if repo.id == vm.repos.last?.id {
                                            Task { await vm.loadMyRepos() }
                                        }
                                    }
                                }
                                if vm.isLoading {
                                    ProgressView().padding()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 24)
                        }
                        .refreshable { await vm.loadMyRepos(reset: true) }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBg)
            }
            .background(Color.appBg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .task { await vm.loadMyRepos(reset: true) }
        }
    }
}
