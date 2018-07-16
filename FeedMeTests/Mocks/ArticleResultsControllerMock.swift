//
//  ArticleResultsControllerMock.swift
//  FeedMeTests
//
//  Created by Patrik Olsson on 2018-07-16.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
@testable import FeedMe

class ArticleResultsControllerMock: ArticleResultsController {
    func articleCount(in section: Int) -> Int {
        return 0
    }

    var willChangeContent: (() -> Void)?

    var insertRowsAtIndexPaths: (([IndexPath]) -> Void)?

    var deleteRowsAtIndexPaths: (([IndexPath]) -> Void)?

    var updateRowsAtIndexPath: ((IndexPath) -> Void)?

    var didChangeContent: (() -> Void)?

    var sectionCount: Int = 0

    var articleCount: Int = 0

    func article(at indexPath: IndexPath) -> Article {
        return ArticleMock()
    }

    func performFetch() {

    }

}
