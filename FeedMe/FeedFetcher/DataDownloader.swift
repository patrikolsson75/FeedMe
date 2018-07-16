//
//  DataDownloader.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-16.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation

protocol DataDownloader {
    func data(contentsOf dataURL: URL) -> Data?
}

class SimpleDataDownloader: DataDownloader {
    func data(contentsOf dataURL: URL) -> Data? {
        return try? Data(contentsOf: dataURL)
    }
}
