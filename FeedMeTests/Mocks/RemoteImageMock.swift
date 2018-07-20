//
//  RemoteImageMock.swift
//  FeedMeTests
//
//  Created by Patrik Olsson on 2018-07-20.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
@testable import FeedMe

class RemoteImageMock: RemoteImage {
    var url: URL?
    
    var urlStatus: DownloadStatus = .notDownloaded
    
}
