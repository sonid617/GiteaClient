import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm: ExploreViewModel

    init() {
        _vm = StateObject(wrappedValue: ExploreViewModel(api: AppState.shared.api!))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LargeHeader(title: "Explore", searchText: $vm.query, placeholder: "Search repositories")

                Group {
                    if vm.isLoading && vm.repos.isEmpty {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let err = vm.error, vm.repos.isEmpty {
                        ErrorView(message: err) { Task { await vm.search(reset: true) } }
                    } else if vm.repos.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(Color.appText3)
                            Text("No results")
                                .font(.headline)
                                .foregroundColor(Color.appText2)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(vm.repos) { repo in
                                    NavigationLink(destination: RepoDetailView(owner: repo.owner.login, repoName: repo.name)) {
                                        RepoRowView(repo: repo)
                                    }
                                    .buttonStyle(.plain)
                                    .onAppear {
                                        if repo.id == vm.repos.last?.id {
                                            Task { await vm.search() }
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
                        .refreshable { await vm.search(reset: true) }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBg)
            }
            .background(Color.appBg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: vm.query) { _ in
                if vm.query.isEmpty { Task { await vm.search(reset: true) } }
            }
            .onSubmit { Task { await vm.search(reset: true) } }
            .task { await vm.search(reset: true) }
        }
    }
}
