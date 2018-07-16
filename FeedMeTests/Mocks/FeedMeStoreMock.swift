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
