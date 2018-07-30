//
//  FeedFetcher.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-14.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
import FeedKit

class FeedFetcher: NSObject {

    let store: FeedMeStore
    let notificationCenter: NotificationCenter
    let dataDownloader: DataDownloader
    var fetchFeedQueueOperationCountObservation: NSKeyValueObservation?

    lazy var fetchFeedQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "FetchFeed queue"
        queue.maxConcurrentOperationCount = 3
        return queue
    }()

    var lastFetched: Date? {
        get {
            return UserDefaults.standard.object(forKey: "lastFetchedDate") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastFetchedDate")
        }
    }

    init(store: FeedMeStore,
         dataDownloader: DataDownloader = SimpleDataDownloader(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.store = store
        self.dataDownloader = dataDownloader
        self.notificationCenter = notificationCenter
        super.init()
        fetchFeedQueueOperationCountObservation = fetchFeedQueue.observe(\.operationCount) { (queue, change) in
            notificationCenter.post(name: .fetchingFeedCount, object: nil, userInfo: ["operationCount": queue.operationCount])
        }

    }

    func fetch() {
        let context = store.newBackgroundContext()
        store.checkAllArticlesAsOld(in: context)
        store.save(context)
        let feeds = store.allFeeds()
        guard feeds.count > 0 else {
            notificationCenter.post(name: .fetchingFeedCount, object: nil, userInfo: ["operationCount": 0])
            return
        }
        feeds.forEach { feed in
            let fetchOperation = FetchFeedOperation(feed: feed, store: store, dataDownloader: dataDownloader)
            fetchFeedQueue.addOperation(fetchOperation)
        }
        lastFetched = Date()
    }

}

extension Notification.Name {
    static let fetchingFeedCount = Notification.Name("fetchingFeedCount")
}


