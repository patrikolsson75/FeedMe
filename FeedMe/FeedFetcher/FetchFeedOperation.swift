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

    let feed: Feed
    let store: FeedMeStore
    let dataDownloader: DataDownloader

    init(feed: Feed, store: FeedMeStore, dataDownloader: DataDownloader) {
        self.feed = feed
        self.store = store
        self.dataDownloader = dataDownloader
    }

    override func main() {
        if isCancelled {
            return
        }

        guard let feedData = dataDownloader.data(contentsOf: feed.feedURL) else { return }

        let parser = FeedParser(data: feedData)
        let result = parser.parse()

        if isCancelled {
            return
        }

        guard let rssFeed = result.rssFeed, result.isSuccess, let feedItems = rssFeed.items else {
            return
        }

        print("Downloaded \(feedItems.count) for \(rssFeed.title ?? "n/a")")

        let context = store.newBackgroundContext()
        guard let feedInContext = store.feed(feed: feed, in: context) else {
            assertionFailure("Could not fetch FeedMO from background context")
            return
        }

        feedItems.forEach({ [store] feedItem in

            if isCancelled {
                return
            }

            guard let guid = feedItem.guid?.value else { return }
            if store.existsArticle(with: guid, in: context) {
                guard var existingArticle = store.article(with: guid, in: context) else {
                    return
                }
                existingArticle.update(with: feedItem)
                store.save(context)
            } else {
                var newArticle = store.newArticle(in: context)
                newArticle.feed = feedInContext
                newArticle.guid = guid
                newArticle.update(with: feedItem)
                store.save(context)
            }

        })

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
        if let mediaThumbnail = feedItem.media?.mediaThumbnails?.first?.attributes?.url,
            let mediaThumbnailURL = URL(string: mediaThumbnail) {
            if image.url != mediaThumbnailURL {
                image.url = mediaThumbnailURL
            }
        }
        articleURL = URL(string: feedItem.link ?? "")
        published = feedItem.pubDate
    }
}
