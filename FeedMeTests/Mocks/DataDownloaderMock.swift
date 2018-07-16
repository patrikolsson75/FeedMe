//
//  DataDownloaderMock.swift
//  FeedMeTests
//
//  Created by Patrik Olsson on 2018-07-16.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
@testable import FeedMe

class DataDownloaderMock: DataDownloader {

    var dataContentsOfURLMock: Data? = nil
    func data(contentsOf dataURL: URL) -> Data? {
        return dataContentsOfURLMock
    }

}
