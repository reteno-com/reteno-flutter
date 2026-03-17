import UserNotifications
import Reteno

final class NotificationService: RetenoNotificationServiceExtension {
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        guard
            let content = request.content.mutableCopy() as? UNMutableNotificationContent
        else {
            super.didReceive(request, withContentHandler: contentHandler)
            return
        }

        if hasCarouselPayload(content.userInfo) {
            content.categoryIdentifier = "ImageCarousel"
            registerCarouselCategoryIfNeeded()
        }

        let normalizedRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: request.trigger
        )

        super.didReceive(normalizedRequest, withContentHandler: contentHandler)
    }

    private func hasCarouselPayload(_ userInfo: [AnyHashable: Any]) -> Bool {
        if let images = userInfo["es_notification_images"] as? [String] {
            return !images.isEmpty
        }

        if let images = userInfo["es_notification_images"] as? String {
            return !images.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return false
    }

    private func registerCarouselCategoryIfNeeded() {
        let semaphore = DispatchSemaphore(value: 0)
        var categories = Set<UNNotificationCategory>()

        UNUserNotificationCenter.current().getNotificationCategories { existing in
            categories = existing
            semaphore.signal()
        }
        semaphore.wait()

        categories = Set(categories.filter { $0.identifier != "ImageCarousel" })
        categories.insert(
            UNNotificationCategory(identifier: "ImageCarousel", actions: [], intentIdentifiers: [])
        )
        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }
}
