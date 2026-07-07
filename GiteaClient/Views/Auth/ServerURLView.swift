import SwiftUI

struct ServerURLView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = AuthViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)

                    VStack(spacing: 8) {
                        Text("Connect to Gitea")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Enter your Gitea server address")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer().frame(height: 40)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Server URL")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        TextField("https://git.example.com", text: $vm.serverURL)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .submitLabel(.continue)
                    }

                    if let err = vm.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(err)
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: {
                        Task {
                            if await vm.validateServerURL() {
                                appState.pendingServerURL = vm.serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
                                appState.screen = .login
                            }
                        }
                    }) {
                        HStack {
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(vm.isLoading || vm.serverURL.isEmpty)
                }
                .padding(.horizontal, 24)

                Spacer()

                Text("Your self-hosted Gitea instance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
            }
            .environmentObject(vm)
        }
    }
}
