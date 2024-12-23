//
//  ArticleMock.swift
//  FeedMeTests
//
//  Created by Patrik Olsson on 2018-07-16.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
@testable import FeedMe

class ArticleMock: Article {
    var identifier: String = ""

    var isNew: Bool = false

    var feed: Feed = FeedMock()
    
    var image: RemoteImage = RemoteImageMock()
    
    var title: String?

    var previewText: String?

    var articleURL: URL?

    var guid: String = ""

    var published: Date?

}
