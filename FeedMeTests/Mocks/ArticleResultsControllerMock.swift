//
//  ArticleResultsControllerMock.swift
//  FeedMeTests
//
//  Created by Patrik Olsson on 2018-07-16.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
@testable import FeedMe

class ItemResultsControllerMock: ItemResultsController {
    func itemCount(in section: Int) -> Int {
        return 0
    }

    func item<Item>(at indexPath: IndexPath) -> Item {
        return ArticleMock() as! Item
    }

    func titleForHeader(in section: Int) -> String? {
        return nil
    }

    var insertSections: ((IndexSet) -> Void)?

    var deleteSections: ((IndexSet) -> Void)?

    func indexPath(for identifier: String) -> IndexPath? {
        return nil
    }

    var willChangeContent: (() -> Void)?

    var insertRowsAtIndexPaths: (([IndexPath]) -> Void)?

    var deleteRowsAtIndexPaths: (([IndexPath]) -> Void)?

    var updateRowsAtIndexPath: ((IndexPath) -> Void)?

    var didChangeContent: (() -> Void)?

    var sectionCount: Int = 0

    var articleCount: Int = 0

    func performFetch() {

    }

}
