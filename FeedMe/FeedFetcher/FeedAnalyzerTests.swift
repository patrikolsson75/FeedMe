//
//  FeedAnalyzerTests.swift
//  FeedMeTests
//
//  Created by Patrik Olsson on 2018-10-14.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import XCTest
@testable import FeedMe

// Weekly
// max 2 articles per 7 days
// min range of 14 days
// min 4 articles

class FeedAnalyzerTests: XCTestCase {

    var analyzer: FeedAnalyzer!
    var articleMocker: ArticleDateMocker!
    var startDate: Date!

    override func setUp() {
        analyzer = FeedAnalyzer()
        startDate = Date()
        articleMocker = ArticleDateMocker(startDate: startDate)
    }

    func testThatAnalyzeReturnUndeterminedForZeroArticles() {
        XCTAssertEqual(analyzer.analyze(articles: []), .undetermined)
    }

    func testThatAnalyzeReturnUndeterminedForOneArticle() {
        let article = ArticleMock()
        article.published = Date()
        XCTAssertEqual(analyzer.analyze(articles: [article]), .undetermined)
    }

    func testThatAnalyzeReturnUndeterminedForJustOverWeekly() {
        let articles = [articleMocker.article(addDays: 0),
                        articleMocker.article(addDays: 1),
                        articleMocker.article(addDays: 2),
                        articleMocker.article(addDays: 8),
                        articleMocker.article(addDays: 9),
                        articleMocker.article(addDays: 10),
                        articleMocker.article(addDays: 15),
                        articleMocker.article(addDays: 16),
                        articleMocker.article(addDays: 17)]
        XCTAssertEqual(analyzer.analyze(articles: articles), .undetermined)
    }

    func testThatAnalyzeReturnWeeklyForJustOnWeekly() {
        let articles = [articleMocker.article(addDays: 0),
                        articleMocker.article(addDays: 1),
                        articleMocker.article(addDays: 8),
                        articleMocker.article(addDays: 9),
                        articleMocker.article(addDays: 15),
                        articleMocker.article(addDays: 16)]
        XCTAssertEqual(analyzer.analyze(articles: articles), .weekly)
    }
}

class ArticleDateMocker {
    let startDate: Date
    private let calendar = Calendar.current
    init(startDate: Date) {
        self.startDate = startDate
    }
    func article(addDays days: Int) -> ArticleMock {
        let article = ArticleMock()
        article.published = calendar.date(byAdding: .day, value: days, to: startDate)
        return article
    }
}
