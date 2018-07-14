//
//  Cache.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-14.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import UIKit

class Cache {
    static let shared = Cache()
    private let imageCache = NSCache<NSString, UIImage>()
    private init() {
    }

    func image(for key: String) -> UIImage? {
        return imageCache.object(forKey: NSString(string: key))
    }

    func store(_ image: UIImage, for key: String) {
        imageCache.setObject(image, forKey: NSString(string: key))
    }
}
