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

    var store: FeedMeStore = FeedMeCoreDataStore.shared

    func fetch(_ feedURL: URL) {
        let parser = FeedParser(URL: feedURL)
        let backgroundContext = store.newBackgroundContext()

        parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { [store] (result) in
            guard let feed = result.rssFeed, result.isSuccess, let feedItems = feed.items else {
                return
            }
            feedItems.forEach({ [store] feedItem in
                guard let guid = feedItem.guid?.value else { return }
                if var existingArticle = store.article(with: guid, in: backgroundContext) {
                    existingArticle.title = feedItem.title
                    existingArticle.previewText = feedItem.description?.withoutHtml
                    existingArticle.imageURL = URL(string: feedItem.media?.mediaThumbnails?.first?.attributes?.url ?? "")
                    existingArticle.articleURL = URL(string: feedItem.link ?? "")
                    existingArticle.published = feedItem.pubDate
                } else {
                    var newArticle = store.newArticle(in: backgroundContext)
                    newArticle.guid = guid
                    newArticle.title = feedItem.title
                    newArticle.previewText = feedItem.description?.withoutHtml
                    newArticle.imageURL = URL(string: feedItem.media?.mediaThumbnails?.first?.attributes?.url ?? "")
                    newArticle.articleURL = URL(string: feedItem.link ?? "")
                    newArticle.published = feedItem.pubDate
                }
            })
            store.save(backgroundContext)
            NotificationCenter.default.post(name: .updatedFeed, object: nil)
        }
    }
}

extension Notification.Name {
    static let updatedFeed = Notification.Name("updatedFeed")
}
