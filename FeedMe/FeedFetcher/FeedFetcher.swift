//
//  FeedFetcher.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-14.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
import FeedKit

class FeedFetcher: NSObject {

    let store: FeedMeStore
    let notificationCenter: NotificationCenter
    let dataDownloader: DataDownloader
    var fetchFeedQueueOperationCountObservation: NSKeyValueObservation?

    lazy var fetchFeedQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "FetchFeed queue"
        queue.maxConcurrentOperationCount = 3
        return queue
    }()

    init(store: FeedMeStore,
         dataDownloader: DataDownloader = SimpleDataDownloader(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.store = store
        self.dataDownloader = dataDownloader
        self.notificationCenter = notificationCenter
        super.init()
        fetchFeedQueueOperationCountObservation = fetchFeedQueue.observe(\.operationCount) { (queue, change) in
            notificationCenter.post(name: .fetchingFeedCount, object: nil, userInfo: ["operationCount": queue.operationCount])
        }

    }

    func fetch(_ feedURLS: [URL]) {
        feedURLS.forEach { feedURL in
            let op = FetchFeedOperation(feedURL: feedURL, store: store, dataDownloader: dataDownloader)
            fetchFeedQueue.addOperation(op)
        }
    }

}

extension String {
    var removingRepeatingNewlines: String {
        return components(separatedBy: .newlines).filter { !$0.isEmpty }.joined(separator: " ")
    }
    var removingRepeatingWhiteSpace: String {
        return components(separatedBy: .whitespaces).filter { $0.count > 0 }.joined(separator: " ")
    }
    var withoutHtml: String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

extension Article {
    mutating func update(with feedItem: RSSFeedItem) {
        var itemPreviewText = feedItem.description?.withoutHtml
        itemPreviewText = itemPreviewText?.trimmingCharacters(in: .whitespacesAndNewlines)
        itemPreviewText = itemPreviewText?.removingRepeatingNewlines
        itemPreviewText = itemPreviewText?.removingRepeatingWhiteSpace
        title = feedItem.title
        previewText = itemPreviewText
        imageURL = URL(string: feedItem.media?.mediaThumbnails?.first?.attributes?.url ?? "")
        articleURL = URL(string: feedItem.link ?? "")
        published = feedItem.pubDate
    }
}

extension Notification.Name {
    static let fetchingFeedCount = Notification.Name("fetchingFeedCount")
}

protocol DataDownloader {
    func data(contentsOf dataURL: URL) -> Data?
}

class SimpleDataDownloader: DataDownloader {
    func data(contentsOf dataURL: URL) -> Data? {
        return try? Data(contentsOf: dataURL)
    }

}

class FetchFeedOperation: Operation {

    let feedURL: URL
    let store: FeedMeStore
    let dataDownloader: DataDownloader

    init(feedURL: URL, store: FeedMeStore, dataDownloader: DataDownloader) {
        self.feedURL = feedURL
        self.store = store
        self.dataDownloader = dataDownloader
    }

    override func main() {
        if isCancelled {
            return
        }

        guard let feedData = dataDownloader.data(contentsOf: feedURL) else { return }

        let parser = FeedParser(data: feedData)
        let result = parser.parse()

        if isCancelled {
            return
        }

        guard let feed = result.rssFeed, result.isSuccess, let feedItems = feed.items else {
            return
        }

        print("Downloaded \(feedItems.count) for \(feed.title ?? "n/a")")

        let backgroundContext = store.newBackgroundContext()

        feedItems.forEach({ [store] feedItem in

            if isCancelled {
                return
            }

            guard let guid = feedItem.guid?.value else { return }
            if var existingArticle = store.article(with: guid, in: backgroundContext) {
                existingArticle.update(with: feedItem)
            } else {
                var newArticle = store.newArticle(in: backgroundContext)
                newArticle.guid = guid
                newArticle.update(with: feedItem)
            }
        })
        store.save(backgroundContext)
    }
}
