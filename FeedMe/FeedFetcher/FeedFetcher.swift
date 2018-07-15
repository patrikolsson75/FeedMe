//
//  FeedFetcher.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-14.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
import FeedKit

class FeedFetcher {

    let store: FeedMeStore
    let parser: FeedParser
    let parseQueue: DispatchQueue
    let notificationCenter: NotificationCenter

    init(with data: Data,
         using store: FeedMeStore = FeedMeCoreDataStore.shared,
         on parseQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
         notify notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.parser = FeedParser(data: data)
        self.store = store
        self.parseQueue = parseQueue
        self.notificationCenter = notificationCenter
    }

    init(with url: URL,
         using store: FeedMeStore = FeedMeCoreDataStore.shared,
         on parseQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
         notify notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.parser = FeedParser(URL: url)
        self.store = store
        self.parseQueue = parseQueue
        self.notificationCenter = notificationCenter
    }

    func fetch() {
        let backgroundContext = store.newBackgroundContext()

        parser.parseAsync(queue: parseQueue) { [store, notificationCenter] (result) in
            guard let feed = result.rssFeed, result.isSuccess, let feedItems = feed.items else {
                return
            }
            feedItems.forEach({ [store] feedItem in
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
            notificationCenter.post(name: .updatedFeed, object: nil)
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
    static let updatedFeed = Notification.Name("updatedFeed")
}
