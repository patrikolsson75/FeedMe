//
//  FeedMeStore.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-14.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import UIKit

protocol FeedMeStoreContext: class {
}

protocol FeedMeStore {
    func save(_ context: FeedMeStoreContext)
    func newArticle(in context: FeedMeStoreContext) -> Article
    func newFeed(in context: FeedMeStoreContext) -> Feed
    func allArticles() -> [Article]
    func articles(for feedURL: URL, in context: FeedMeStoreContext) -> [Article]
    func articlesResultsController() -> ItemResultsController
    func feedResultsController() -> ItemResultsController
    func newBackgroundContext() -> FeedMeStoreContext
    func article(with guid: String, in context: FeedMeStoreContext) -> Article?
    func load(_ article: Article, from context: FeedMeStoreContext) -> Article?
    func existsArticle(with guid: String, in context: FeedMeStoreContext) -> Bool
    func allFeeds() -> [Feed]
    func feed(feed: Feed, in context: FeedMeStoreContext) -> Feed?
    func prePopulateFeeds()
    func load(_ image: RemoteImage, from context: FeedMeStoreContext) -> RemoteImage?
    func checkAllArticlesAsOld(in context: FeedMeStoreContext)
    func delete(_ feed: Feed)
    func deleteArticles(olderThen days: Int, in context: FeedMeStoreContext)
}

enum DownloadStatus: Int16 {
    case notDownloaded = 0
    case inProgress = 1
    case downloaded = 2
    case error = 3
}

protocol RemoteImage {
    var url: URL? { get set }
    var urlStatus: DownloadStatus { get set }
}

protocol Article {
    var identifier: String { get }
    var feed: Feed { get set }
    var title: String? { get set }
    var previewText: String? { get set }
    var articleURL: URL? { get set }
    var guid: String { get set }
    var published: Date? { get set }
    var image: RemoteImage { get set }
    var isNew: Bool { get set }
}

protocol Feed {
    var title: String? { get set }
    var feedURL: URL { get set }
}

protocol ItemResultsController {
    var sectionCount: Int { get }
    func itemCount(in section: Int) -> Int
    func item<Item>(at indexPath: IndexPath) -> Item
    func indexPath(for identifier: String) -> IndexPath?
    func performFetch()
    func titleForHeader(in section: Int) -> String?
    var willChangeContent: (() -> Void)? { get set }
    var insertRowsAtIndexPaths: (([IndexPath]) -> Void)? { get set }
    var deleteRowsAtIndexPaths: (([IndexPath]) -> Void)? { get set }
    var updateRowsAtIndexPath: ((IndexPath) -> Void)? { get set }
    var didChangeContent: (() -> Void)? { get set }
    var insertSections: ((IndexSet) -> Void)? { get set }
    var deleteSections: ((IndexSet) -> Void)? { get set }
}

