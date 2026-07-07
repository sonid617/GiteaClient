import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [GiteaNotification] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showAll = false

    private let api: GiteaAPIClient

    init(api: GiteaAPIClient) {
        self.api = api
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            notifications = try await api.notifications(all: showAll)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func markAllRead() async {
        do {
            try await api.markAllNotificationsRead()
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func markRead(notification: GiteaNotification) async {
        do {
            try await api.markNotificationRead(id: notification.id)
            notifications.removeAll { $0.id == notification.id }
        } catch {}
    }
}
