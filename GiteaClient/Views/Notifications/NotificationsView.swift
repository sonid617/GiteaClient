import SwiftUI

struct NotificationsView: View {
    var onUnreadChange: ((Int) -> Void)? = nil

    @StateObject private var vm: NotificationsViewModel

    init(onUnreadChange: ((Int) -> Void)? = nil) {
        self.onUnreadChange = onUnreadChange
        _vm = StateObject(wrappedValue: NotificationsViewModel(api: AppState.shared.api!))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                InboxHeader(showAll: $vm.showAll, onMarkAllRead: {
                    Task { await vm.markAllRead() }
                })

                Group {
                    if vm.isLoading && vm.notifications.isEmpty {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if vm.notifications.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 42))
                                .foregroundColor(Color.appText3)
                            Text("All caught up!")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("You have no \(vm.showAll ? "" : "unread ")notifications.")
                                .font(.system(size: 13))
                                .foregroundColor(Color.appText2)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 40)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(vm.notifications) { notification in
                                    notificationRow(notification)
                                        .contextMenu {
                                            if notification.unread {
                                                Button("Mark as Read") {
                                                    Task { await vm.markRead(notification: notification) }
                                                }
                                            }
                                        }
                                }
                            }
                        }
                        .refreshable { await vm.load() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBg)
            }
            .background(Color.appBg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: vm.showAll) { _ in Task { await vm.load() } }
            .onChange(of: vm.notifications) { _ in
                onUnreadChange?(vm.notifications.filter { $0.unread }.count)
            }
            .task { await vm.load() }
        }
    }

    @ViewBuilder
    private func notificationRow(_ notification: GiteaNotification) -> some View {
        let row = NotificationRowView(notification: notification)
        if let dest = notification.parsedDestination {
            NavigationLink(destination: dest.isPullRequest
                ? AnyView(PRDetailView(owner: dest.owner, repoName: dest.repoName, index: dest.number))
                : AnyView(IssueDetailView(owner: dest.owner, repoName: dest.repoName, number: dest.number))
            ) { row }
            .buttonStyle(.plain)
        } else {
            row
        }
    }
}

struct NotificationRowView: View {
    let notification: GiteaNotification

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(notification.unread ? Color.appDanger : Color.clear)
                .frame(width: 7, height: 7)
                .padding(.top, 5)

            Image(systemName: notification.typeIcon)
                .font(.system(size: 14))
                .foregroundColor(Color.appText2)
                .frame(width: 20)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(notification.repository.fullName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appText2)
                Text(notification.subject.title)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Text(notification.subject.type)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                    Text(relativeDate(notification.updatedAt))
                        .font(.system(size: 11))
                        .foregroundColor(Color.appText3)
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(Divider(), alignment: .bottom)
        .background(notification.unread ? Color.appCard : Color.appBg)
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
        return ""
    }
}
