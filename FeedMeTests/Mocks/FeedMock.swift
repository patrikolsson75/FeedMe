//
//  FeedMock.swift
//  FeedMeTests
//
//  Created by Patrik Olsson on 2018-07-16.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
@testable import FeedMe

class FeedMock: Feed {
    var feedURL: URL = URL(string: "http://www.example.com")!
}
