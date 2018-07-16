//
//  FeedFetcherTest.swift
//  FeedMeTests
//
//  Created by Patrik Olsson on 2018-07-15.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import XCTest
import FeedKit
@testable import FeedMe

class FeedFetcherTest: XCTestCase {

    func testThatItParse_9to5mac() {
        let store = FeedMeStoreMock()
        let dataDownloader = DataDownloaderMock()
        let rssData = contentsOfXMLFile(named: "9to5mac")
        let notificationCenter = NotificationCenter()
        let fetcher = FeedFetcher(store: store, dataDownloader: dataDownloader, notificationCenter: notificationCenter)
        let asyncExpectation = expectation(description: "updatedFeed")

        notificationCenter.addObserver(forName: .fetchingFeedCount, object: nil, queue: nil, using: { notification in
            guard let operationCount = notification.userInfo?["operationCount"] as? Int,
            operationCount == 0 else { return }
            asyncExpectation.fulfill()
        })
        dataDownloader.dataContentsOfURLMock = rssData
        store.newArticlesReturned = []
        store.articleWithGUIDReturnMock = nil
        fetcher.fetch([URL(string: "https://9to5mac.com/feed/")!])

        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(store.newArticlesReturned.count, 50)

        let firstArticle = store.newArticlesReturned.first
        XCTAssertEqual(firstArticle?.title, "Uber focuses on passenger safety as it starts rolling out continuous driver background checks")
        XCTAssertEqual(firstArticle?.previewText, "To improve the safety of both its customers and its drivers, Uber is now pushing out a more aggressive background check program to ensure drivers are fit for the job. more&#8230;")
        XCTAssertEqual(firstArticle?.imageURL?.absoluteString, "https://9to5mac.files.wordpress.com/2018/02/uber.jpg?quality=82&strip=all")
        XCTAssertEqual(firstArticle?.articleURL?.absoluteString, "https://9to5mac.com/2018/07/13/uber-focuses-on-passenger-safety-as-it-starts-rolling-out-continuous-driver-background-checks/")
        XCTAssertEqual(firstArticle?.guid, "http://9to5mac.com/?p=542515")
        XCTAssertEqual(firstArticle?.published?.description, "2018-07-13 17:09:57 +0000")
    }

    func testThatItParse_iMore() {
        let store = FeedMeStoreMock()
        let dataDownloader = DataDownloaderMock()
        let rssData = contentsOfXMLFile(named: "imore")
        let notificationCenter = NotificationCenter()
        let fetcher = FeedFetcher(store: store, dataDownloader: dataDownloader, notificationCenter: notificationCenter)
        let asyncExpectation = expectation(description: "updatedFeed")

        notificationCenter.addObserver(forName: .fetchingFeedCount, object: nil, queue: nil, using: { notification in
            guard let operationCount = notification.userInfo?["operationCount"] as? Int,
                operationCount == 0 else { return }
            asyncExpectation.fulfill()
        })
        dataDownloader.dataContentsOfURLMock = rssData
        store.newArticlesReturned = []
        store.articleWithGUIDReturnMock = nil
        fetcher.fetch([URL(string: "http://feeds.feedburner.com/TheIphoneBlog")!])

        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(store.newArticlesReturned.count, 30)

        let firstArticle = store.newArticlesReturned.first
        XCTAssertEqual(firstArticle?.title, "Here's every Nintendo Switch game available now (and what's to come later this year)")
        XCTAssertEqual(firstArticle?.previewText, "Nintendo Switch has tons of awesome games available right now! Plus, there are dozens more in the pipeline. When the Switch first launched, there were less than a dozen titles available for sale. But, as time goes by, and as game makers realize the popularity of Nintendo's hybrid mobile console, more and more titles are being added to the list all of the time. Here are all the games available right now, in digital and game card form, as well as games that are officially coming to Switch sometime in the future. What's new? New games released and announced games coming soon Here's where you'll find everything new that is either now available in the Switch eShop or as a physical game card, as well as games that have recently been announced as coming to the Switch. New physical game cartridges Captain Toad Treasure Tracker - July 13 - $39.99 Octopath Traveler - July 13 - $59.99 Physical game cartridges you can pre-order right now! Adventure Time: Pirates of the Enchridion - Availab...")
        XCTAssertEqual(firstArticle?.imageURL?.absoluteString, nil)
        XCTAssertEqual(firstArticle?.articleURL?.absoluteString, "http://feedproxy.google.com/~r/TheIphoneBlog/~3/ujIN3PPnpCc/nintendo-switch-games")
        XCTAssertEqual(firstArticle?.guid, "42798.pbsds0 at https://www.imore.com")
        XCTAssertEqual(firstArticle?.published?.description, "2018-07-13 22:02:00 +0000")
    }
}

class ArticleMock: Article {
    var title: String?

    var previewText: String?

    var imageURL: URL?

    var articleURL: URL?

    var guid: String = ""

    var published: Date?

}

class FeedMeStoreContextMock: FeedMeStoreContext {
}

extension XCTest {
    func contentsOfXMLFile(named: String) -> Data {
        let path = Bundle(for: type(of: self)).path(forResource: named, ofType: "xml")!
        return NSData(contentsOfFile: path)! as Data
    }
}

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

class DataDownloaderMock: DataDownloader {

    var dataContentsOfURLMock: Data? = nil
    func data(contentsOf dataURL: URL) -> Data? {
        return dataContentsOfURLMock
    }

}
