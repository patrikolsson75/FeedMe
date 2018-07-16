//
//  FetchFeedOperation.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-16.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
import FeedKit

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

private extension Article {
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
