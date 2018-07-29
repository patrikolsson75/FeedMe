//
//  FeedMeStoreMock.swift
//  FeedMeTests
//
//  Created by Patrik Olsson on 2018-07-16.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
@testable import FeedMe

class FeedMeStoreMock: FeedMeStore {
    func checkAllArticlesAsOld(in context: FeedMeStoreContext) {
    }

    func articles(for feedURL: URL, in context: FeedMeStoreContext) -> [Article] {
        return []
    }
    
    func load(_ article: Article, from context: FeedMeStoreContext) -> Article? {
        return nil
    }
    
    func existsArticle(with guid: String, in context: FeedMeStoreContext) -> Bool {
        return false
    }
    
    var feedInContextReturnMock: Feed?
    func feed(feed: Feed, in context: FeedMeStoreContext) -> Feed? {
        return feedInContextReturnMock
    }
    
    func load(_ image: RemoteImage, from context: FeedMeStoreContext) -> RemoteImage? {
        return nil
    }
    
    var allFeedsReturnMock: [Feed] = []
    func allFeeds() -> [Feed] {
        return allFeedsReturnMock
    }

    func prePopulateFeeds() {
    }

    func articlesResultsController() -> ArticleResultsController {
        return ArticleResultsControllerMock()
    }


    func save(_ context: FeedMeStoreContext) {
    }

    var newArticlesReturned: [ArticleMock] = []
    func newArticle(in context: FeedMeStoreContext) -> Article {
        let newArticle = ArticleMock()
        newArticlesReturned.append(newArticle)
        return newArticle
    }

    func allArticles() -> [Article] {
        return []
    }

    func newBackgroundContext() -> FeedMeStoreContext {
        return FeedMeStoreContextMock()
    }

    var articleWithGUIDReturnMock: Article? = nil
    func article(with guid: String, in context: FeedMeStoreContext) -> Article? {
        return articleWithGUIDReturnMock
    }

}
