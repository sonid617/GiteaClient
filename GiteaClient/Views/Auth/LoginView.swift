import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = AuthViewModel()
    @State private var showPassword = false
    @State private var editingServerURL = false
    @State private var serverURLDraft = ""

    var serverURL: String {
        KeychainHelper.shared.read(forKey: "serverURL") ?? appState.pendingServerURL
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 78)

                // App icon + title
                VStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.accentColor)
                        )
                    Text("Sign in")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)
                        .tracking(-0.4)
                    Text("Connect to your Gitea server")
                        .font(.system(size: 14))
                        .foregroundColor(Color.appText2)
                }

                Spacer().frame(height: 32)

                VStack(spacing: 16) {
                    // Server URL chip
                    if editingServerURL {
                        HStack(spacing: 8) {
                            TextField("https://git.example.com", text: $serverURLDraft)
                                .font(.system(size: 14))
                                .autocorrectionDisabled()
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                                .padding(.horizontal, 12).padding(.vertical, 11)
                                .background(Color.appCard)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
                            Button("Save") {
                                vm.serverURL = serverURLDraft
                                editingServerURL = false
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 11)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .buttonStyle(.plain)
                        }
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "network")
                                .font(.system(size: 15))
                                .foregroundColor(Color.appText2)
                            Text(serverURL)
                                .font(.system(size: 13))
                                .foregroundColor(Color.appText2)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button("Change") {
                                serverURLDraft = serverURL
                                editingServerURL = true
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(Color.appCardAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Username
                    VStack(alignment: .leading, spacing: 6) {
                        Text("USERNAME")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.appText2)
                            .tracking(0.4)
                        TextField("Username", text: $vm.username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .font(.system(size: 15))
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(Color.appCard)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
                    }

                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PASSWORD")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.appText2)
                            .tracking(0.4)
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("Password", text: $vm.password)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("Password", text: $vm.password)
                                }
                            }
                            .font(.system(size: 15))
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(Color.appText2)
                                    .font(.system(size: 17))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
                    }

                    if let err = vm.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(err)
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Color.appDanger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: { Task { await vm.login() } }) {
                        HStack(spacing: 8) {
                            if vm.isLoading {
                                ProgressView().tint(.white).scaleEffect(0.8)
                            } else {
                                Text("Sign In").font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isLoading || vm.username.isEmpty || vm.password.isEmpty)

                    Text("A token will be created automatically in your Gitea account.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.appText3)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)
            }
        }
        .background(Color.appBg.ignoresSafeArea())
        .onAppear {
            let pending = AppState.shared.pendingServerURL
            if !pending.isEmpty {
                vm.serverURL = pending
            } else if let url = KeychainHelper.shared.read(forKey: "serverURL") {
                vm.serverURL = url
            }
        }
    }
}
