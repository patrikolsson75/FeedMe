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

        guard result.isSuccess else {
            return
        }

        let context = store.newBackgroundContext()
        guard let feedInContext = store.feed(feed: feed, in: context) else {
            assertionFailure("Could not fetch FeedMO from background context")
            return
        }

//        var newArticle = store.newArticle(in: context)
//        newArticle.feed = feedInContext
//        newArticle.guid = UUID().uuidString
//        newArticle.title = Date().description
//        newArticle.previewText = "Test"
//        newArticle.published = Date()
//        newArticle.isNew = true

        if let rssFeed = result.rssFeed {
            parseRSS(rssFeed: rssFeed, into: context, on: feedInContext)
        } else if let atomFeed = result.atomFeed {
            parseATOM(atomFeed: atomFeed, into: context, on: feedInContext)
        }

    }

    private func parseRSS(rssFeed: RSSFeed, into context: FeedMeStoreContext, on feed: Feed) {
        guard let feedItems = rssFeed.items else { return }

        print("Downloaded \(feedItems.count) for \(rssFeed.title ?? "n/a")")
        feedItems.forEach({ [store] feedItem in

            if isCancelled {
                return
            }

            guard let guid = feedItem.guid?.value ?? feedItem.link else { return }
            if store.existsArticle(with: guid, in: context) {
                guard var existingArticle = store.article(with: guid, in: context) else {
                    return
                }
                if let feedItemPubDate = feedItem.pubDate,
                    let existingPubDate = existingArticle.published,
                    existingPubDate < feedItemPubDate {
                    existingArticle.update(with: feedItem)
                    print("Updated article \(existingArticle.title ?? "")")
                }
            } else {
                var newArticle = store.newArticle(in: context)
                newArticle.feed = feed
                newArticle.guid = guid
                newArticle.isNew = true
                newArticle.update(with: feedItem)

            }
            store.save(context)
        })
    }

    private func parseATOM(atomFeed: AtomFeed, into context: FeedMeStoreContext, on feed: Feed) {
        guard let feedItems = atomFeed.entries else { return }

        print("Downloaded \(feedItems.count) for \(atomFeed.title ?? "n/a")")
        feedItems.forEach({ [store] feedItem in

            if isCancelled {
                return
            }

            guard let guid = feedItem.id else { return }
            if store.existsArticle(with: guid, in: context) {
                guard var existingArticle = store.article(with: guid, in: context) else {
                    return
                }
                if let feedItemPubDate = feedItem.published,
                    let existingPubDate = existingArticle.published,
                    existingPubDate < feedItemPubDate {
                    existingArticle.update(with: feedItem)
                    print("Updated article \(existingArticle.title ?? "")")
                }
            } else {
                var newArticle = store.newArticle(in: context)
                newArticle.feed = feed
                newArticle.guid = guid
                newArticle.isNew = true
                newArticle.update(with: feedItem)

            }
            store.save(context)
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
        if image.url == nil,
            let mediaContents = feedItem.media?.mediaContents?.first,
            mediaContents.attributes?.type?.hasPrefix("image") ?? false,
            let urlString = mediaContents.attributes?.url,
            let imageURL = URL(string: urlString) {
            image.url = imageURL
        }
        articleURL = URL(string: feedItem.link ?? "")
        published = feedItem.pubDate
    }

    mutating func update(with feedItem: AtomFeedEntry) {
        var itemPreviewText = feedItem.content?.value?.withoutHtml
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
        if image.url == nil,
            let mediaContents = feedItem.media?.mediaContents?.first,
            mediaContents.attributes?.type?.hasPrefix("image") ?? false,
            let urlString = mediaContents.attributes?.url,
            let imageURL = URL(string: urlString) {
            image.url = imageURL
        }
        articleURL = URL(string: feedItem.links?.first?.attributes?.href ?? "")
        published = feedItem.published ?? feedItem.updated
    }

}
