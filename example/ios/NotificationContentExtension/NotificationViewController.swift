import UIKit
import UserNotifications
import UserNotificationsUI
import ImageIO

public final class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private let emptyLabel = UILabel()

    private var images: [UIImage] = []
    private var carouselTimer: Timer?
    private var renderedSize: CGSize = .zero

    public override func viewDidLoad() {
        super.viewDidLoad()

        preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 260)
        view.backgroundColor = .white

        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.delegate = self
        view.addSubview(scrollView)

        pageControl.hidesForSinglePage = true
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.25)
        view.addSubview(pageControl)

        emptyLabel.text = "Carousel images were not loaded."
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        emptyLabel.textColor = .darkGray
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let bounds = view.bounds
        scrollView.frame = bounds
        emptyLabel.frame = CGRect(x: 16, y: 16, width: bounds.width - 32, height: bounds.height - 32)

        pageControl.sizeToFit()
        pageControl.frame = CGRect(
            x: (bounds.width - pageControl.bounds.width) / 2,
            y: bounds.height - pageControl.bounds.height - 12,
            width: pageControl.bounds.width,
            height: pageControl.bounds.height
        )

        guard !images.isEmpty, renderedSize != bounds.size else { return }
        renderedSize = bounds.size
        layoutImages()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }

    public func didReceive(_ notification: UNNotification) {
        stopTimer()

        let content = notification.request.content
        let attachmentImages = content.attachments.compactMap { loadImage(from: $0.url) }
        if !attachmentImages.isEmpty {
            apply(images: attachmentImages)
            return
        }

        let payloadURLs = imageURLs(from: content.userInfo)
        guard !payloadURLs.isEmpty else {
            apply(images: [])
            return
        }

        downloadImages(from: payloadURLs) { [weak self] downloadedImages in
            self?.apply(images: downloadedImages)
        }
    }

    public func didReceive(
        _ response: UNNotificationResponse,
        completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void
    ) {
        completion(.doNotDismiss)
    }

    private func apply(images newImages: [UIImage]) {
        DispatchQueue.main.async {
            self.images = newImages
            self.pageControl.numberOfPages = newImages.count
            self.pageControl.currentPage = 0
            self.emptyLabel.isHidden = !newImages.isEmpty
            self.scrollView.isHidden = newImages.isEmpty
            self.pageControl.isHidden = newImages.count <= 1
            self.renderedSize = .zero
            self.layoutImages()
            if newImages.count > 1 {
                self.startTimer()
            }
        }
    }

    private func layoutImages() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        let size = scrollView.bounds.size
        guard size.width > 0, size.height > 0, !images.isEmpty else {
            scrollView.contentSize = .zero
            return
        }

        for (index, image) in images.enumerated() {
            let imageView = UIImageView(frame: CGRect(x: CGFloat(index) * size.width, y: 0, width: size.width, height: size.height))
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.backgroundColor = .white
            imageView.image = image
            scrollView.addSubview(imageView)
        }

        scrollView.contentSize = CGSize(width: size.width * CGFloat(images.count), height: size.height)
        scrollView.setContentOffset(.zero, animated: false)
    }

    private func startTimer() {
        carouselTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self, self.images.count > 1 else { return }
            let nextPage = (self.pageControl.currentPage + 1) % self.images.count
            let offset = CGPoint(x: CGFloat(nextPage) * self.scrollView.bounds.width, y: 0)
            self.scrollView.setContentOffset(offset, animated: true)
            self.pageControl.currentPage = nextPage
        }
    }

    private func stopTimer() {
        carouselTimer?.invalidate()
        carouselTimer = nil
    }

    private func loadImage(from url: URL) -> UIImage? {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if let data = try? Data(contentsOf: url) {
            if let image = UIImage(data: data) {
                return image
            }
            if let source = CGImageSourceCreateWithData(data as CFData, nil),
               let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(contentsOfFile: url.path)
    }

    private func imageURLs(from userInfo: [AnyHashable: Any]) -> [URL] {
        var urls: [URL] = []

        if let rawImages = userInfo["es_notification_images"] as? [String] {
            urls.append(contentsOf: rawImages.compactMap(URL.init(string:)))
        }

        if let rawImages = userInfo["es_notification_images"] as? String {
            let normalized = rawImages.replacingOccurrences(of: "\\", with: "")
            if let data = normalized.data(using: .utf8),
               let decoded = try? JSONDecoder().decode([String].self, from: data) {
                urls.append(contentsOf: decoded.compactMap(URL.init(string:)))
            }
            urls.append(contentsOf: extractURLs(from: normalized))
        }

        var seen = Set<String>()
        return urls.filter {
            let value = $0.absoluteString
            if seen.contains(value) {
                return false
            }
            seen.insert(value)
            return true
        }
    }

    private func extractURLs(from text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector.matches(in: text, options: [], range: range).compactMap { $0.url }
    }

    private func downloadImages(from urls: [URL], completion: @escaping ([UIImage]) -> Void) {
        let group = DispatchGroup()
        let lock = NSLock()
        var downloadedImages: [UIImage] = []

        for url in urls {
            group.enter()
            URLSession.shared.dataTask(with: url) { data, _, _ in
                defer { group.leave() }
                guard let data, let image = UIImage(data: data) else { return }
                lock.lock()
                downloadedImages.append(image)
                lock.unlock()
            }.resume()
        }

        group.notify(queue: .main) {
            completion(downloadedImages)
        }
    }
}

extension NotificationViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage(for: scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPage(for: scrollView)
    }

    private func updateCurrentPage(for scrollView: UIScrollView) {
        let width = max(scrollView.bounds.width, 1)
        let page = Int(round(scrollView.contentOffset.x / width))
        pageControl.currentPage = max(0, min(page, max(images.count - 1, 0)))
    }
}
