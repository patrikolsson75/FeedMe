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
    func allArticles() -> [Article]
    func articlesResultsController() -> ArticleResultsController
    func newBackgroundContext() -> FeedMeStoreContext
    func article(with guid: String, in context: FeedMeStoreContext) -> Article?
}

protocol Article {
    var title: String? { get set }
    var previewText: String? { get set }
    var imageURL: URL? { get set }
    var articleURL: URL? { get set }
    var guid: String { get set }
    var published: Date? { get set }
}

protocol ArticleResultsController {
    var sectionCount: Int { get }
    var articleCount: Int { get }
    func article(at indexPath: IndexPath) -> Article
    func performFetch()
}
