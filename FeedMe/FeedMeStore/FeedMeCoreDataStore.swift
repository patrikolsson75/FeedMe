//
//  FeedMeCoreDataStore.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-15.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext: FeedMeStoreContext {}

class FeedMeCoreDataStore: NSObject, FeedMeStore {

    static let shared = FeedMeCoreDataStore()

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FeedMe")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    func save(_ context: FeedMeStoreContext) {
        guard let context = context as? NSManagedObjectContext else { return }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func newArticle(in context: FeedMeStoreContext) -> Article {
        guard let context = context as? NSManagedObjectContext else {
            assertionFailure("Can't save none NSManagedObjectContext")
            return ArticleMO()
        }
        let articleMO = NSEntityDescription.insertNewObject(forEntityName: "Article", into: context) as! ArticleMO
        let remoteImageMO = NSEntityDescription.insertNewObject(forEntityName: "RemoteImage", into: context) as! RemoteImageMO
        articleMO.imageMO = remoteImageMO
        return articleMO
    }

    func allArticles() -> [Article] {
        let articlesFetch = NSFetchRequest<ArticleMO>(entityName: "Article")
        let publishedSort = NSSortDescriptor(key: "published", ascending: false)
        articlesFetch.sortDescriptors = [publishedSort]

        do {
            return try persistentContainer.viewContext.fetch(articlesFetch)
        } catch {
            fatalError("Failed to fetch Articles: \(error)")
        }
    }

    func articles(for feedURL: URL, in context: FeedMeStoreContext) -> [Article] {
        guard let context = context as? NSManagedObjectContext else {
            assertionFailure("Context is not NSManagedObjectContext")
            return []
        }
        let fetchRequest = NSFetchRequest<ArticleMO>(entityName: "Article")
        let predicateID = NSPredicate(format: "feedMO.feedURL == %@", feedURL.absoluteString)
        fetchRequest.predicate = predicateID
        let publishedSort = NSSortDescriptor(key: "published", ascending: false)
        fetchRequest.sortDescriptors = [publishedSort]

        do {
            return try context.fetch(fetchRequest)
        } catch {
            fatalError("Failed to fetch Articles: \(error)")
        }
    }

    func articlesResultsController() -> ArticleResultsController {
        let articlesFetch = NSFetchRequest<ArticleMO>(entityName: "Article")
        let publishedSort = NSSortDescriptor(key: "published", ascending: false)
        articlesFetch.sortDescriptors = [publishedSort]
        let fc = NSFetchedResultsController(fetchRequest: articlesFetch, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: "isNew", cacheName: nil)
        return ArticleResultsControllerCoreData(fc: fc)
    }

    func newBackgroundContext() -> FeedMeStoreContext {
        let newContext = persistentContainer.newBackgroundContext()
        return newContext as FeedMeStoreContext
    }

    func article(with guid: String, in context: FeedMeStoreContext) -> Article? {
        guard let context = context as? NSManagedObjectContext else {
            assertionFailure("Context is not NSManagedObjectContext")
            return nil
        }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Article")
        let predicateID = NSPredicate(format: "guid == %@", guid)
        fetchRequest.predicate = predicateID
        do {

            let results = try context.fetch(fetchRequest)
            return results.first as? ArticleMO
        }
        catch let error {
            print(error.localizedDescription)
            return nil
        }
    }

    func existsArticle(with guid: String, in context: FeedMeStoreContext) -> Bool {
        guard let context = context as? NSManagedObjectContext else {
            assertionFailure("Context is not NSManagedObjectContext")
            return false
        }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Article")
        let predicateID = NSPredicate(format: "guid == %@", guid)
        fetchRequest.predicate = predicateID
        fetchRequest.includesSubentities = false

        var entitiesCount = 0

        do {
            entitiesCount = try context.count(for: fetchRequest)
        }
        catch {
            print("error executing fetch request: \(error)")
        }

        return entitiesCount > 0
    }

    func load(_ article: Article, from context: FeedMeStoreContext) -> Article? {
        guard let context = context as? NSManagedObjectContext else {
            assertionFailure("Context is not NSManagedObjectContext")
            return nil
        }
        guard let articleMO = article as? ArticleMO else {
            assertionFailure("Article objects is not ArticleMO")
            return nil
        }
        return context.object(with: articleMO.objectID) as? Article
    }

    func load(_ image: RemoteImage, from context: FeedMeStoreContext) -> RemoteImage? {
        guard let context = context as? NSManagedObjectContext else {
            assertionFailure("Context is not NSManagedObjectContext")
            return nil
        }
        guard let managedObject = image as? RemoteImageMO else {
            assertionFailure("RemoteImage objects is not RemoteImageMO")
            return nil
        }
        return context.object(with: managedObject.objectID) as? RemoteImageMO
    }

    func allFeeds() -> [Feed] {
        let fetchRequest = NSFetchRequest<FeedMO>(entityName: "Feed")
//        let publishedSort = NSSortDescriptor(key: "published", ascending: false)
//        articlesFetch.sortDescriptors = [publishedSort]

        do {
            return try persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            fatalError("Failed to fetch Feeds: \(error)")
        }
    }

    func feed(feed: Feed, in context: FeedMeStoreContext) -> Feed? {
        guard let context = context as? NSManagedObjectContext else {
            assertionFailure("Context is not NSManagedObjectContext")
            return nil
        }
        guard let feedMO = feed as? FeedMO else {
            assertionFailure("Feed objects is not FeedMO")
            return nil
        }
        return context.object(with: feedMO.objectID) as? Feed
    }

    func prePopulateFeeds() {
        guard allFeeds().count == 0 else { return }
        print("Prepopulating Feeds...")
        let feedURLS = [
//            URL(string: "https://9to5mac.com/feed/")!,
//            URL(string: "http://feeds.feedburner.com/TheIphoneBlog")!,
//            URL(string: "http://feeds.macrumors.com/MacRumors-All")!,
//            URL(string: "http://f1blogg.teknikensvarld.se/feed/")!,
//            URL(string: "http://feeds.feedburner.com/f1fanatic")!,
            URL(string: "https://www.svt.se/nyheter/rss.xml")!,
            URL(string: "https://www.dn.se/rss")!,
            URL(string: "https://www.svd.se/?service=rss")!,
            URL(string: "http://www.aftonbladet.se/rss.xml")!
        ]
        let context = persistentContainer.newBackgroundContext()
        feedURLS.forEach { feedURL in
            let feedMO = NSEntityDescription.insertNewObject(forEntityName: "Feed", into: context) as! FeedMO
            feedMO.feedURL = feedURL
        }
        save(context)
    }

    func checkAllArticlesAsOld(in context: FeedMeStoreContext) {
        guard let context = context as? NSManagedObjectContext else {
            assertionFailure("Context is not NSManagedObjectContext")
            return
        }

        // Create Entity Description
        let entityDescription = NSEntityDescription.entity(forEntityName: "Article", in: context)

        // Initialize Batch Update Request
        let batchUpdateRequest = NSBatchUpdateRequest(entity: entityDescription!)

        // Configure Batch Update Request
        batchUpdateRequest.resultType = .updatedObjectIDsResultType
        batchUpdateRequest.propertiesToUpdate = ["isNew": NSNumber(value: false)]

        do {
            try context.execute(batchUpdateRequest)
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
    }
}

class RemoteImageMO: NSManagedObject {
    @NSManaged var url: URL?
    @NSManaged var urlStatusMO: Int16
}

extension RemoteImageMO: RemoteImage {
    var urlStatus: DownloadStatus {
        get {
            return DownloadStatus(rawValue: self.urlStatusMO) ?? .notDownloaded
        }
        set {
            self.urlStatusMO = newValue.rawValue
        }
    }


}

class ArticleMO: NSManagedObject {
    @NSManaged var feedMO: FeedMO
    @NSManaged var title: String?
    @NSManaged var previewText: String?
    @NSManaged var articleURL: URL?
    @NSManaged var guid: String
    @NSManaged var published: Date?
    @NSManaged var imageMO: RemoteImageMO
    @NSManaged var isNew: Bool
}

class FeedMO: NSManagedObject {
    @NSManaged var title: String?
    @NSManaged var feedURL: URL
    @NSManaged var articles: NSSet?
}

extension ArticleMO: Article {
    var identifier: String {
        return String(describing: objectID.uriRepresentation())
    }

    var image: RemoteImage {
        get {
            return imageMO
        }
        set {
            guard let managedImage = newValue as? RemoteImageMO else { return }
            imageMO = managedImage
        }
    }


    var feed: Feed {
        get {
            return feedMO
        }
        set {
            guard let managedFeed = newValue as? FeedMO else { return }
            feedMO = managedFeed
        }
    }
}

extension FeedMO: Feed {}

class ArticleResultsControllerCoreData: NSObject, ArticleResultsController {

    let fc: NSFetchedResultsController<ArticleMO>

    var willChangeContent: (() -> Void)? = nil
    var insertRowsAtIndexPaths: (([IndexPath]) -> Void)? = nil
    var deleteRowsAtIndexPaths: (([IndexPath]) -> Void)? = nil
    var updateRowsAtIndexPath: ((IndexPath) -> Void)? = nil
    var didChangeContent: (() -> Void)? = nil
    var insertSections: ((IndexSet) -> Void)? = nil
    var deleteSections: ((IndexSet) -> Void)? = nil

    init(fc: NSFetchedResultsController<ArticleMO>) {
        self.fc = fc
        super.init()
        self.fc.delegate = self
    }
    var sectionCount: Int {
        return fc.sections?.count ?? 0
    }

    func articleCount(in section: Int) -> Int {
        guard let sections = fc.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    func article(at indexPath: IndexPath) -> Article {
        return fc.object(at: indexPath)
    }

    func performFetch() {
        try? fc.performFetch()
    }

    func indexPath(for identifier: String) -> IndexPath? {
        if let url = URL(string: identifier),
            let objectID = fc.managedObjectContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
            let object = fc.managedObjectContext.object(with: objectID) as? ArticleMO
        {
            return fc.indexPath(forObject: object)
        }
        print("Can't find indexPath for \(identifier)")
        return nil
    }

    func titleForHeader(in section: Int) -> String? {
        guard let sectionInfo = fc.sections?[section] else {
            return nil
        }
        return sectionInfo.name
    }
}

extension ArticleResultsControllerCoreData: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        willChangeContent?()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            insertSections?(IndexSet(integer: sectionIndex))
        case .delete:
            deleteSections?(IndexSet(integer: sectionIndex))
        default:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            insertRowsAtIndexPaths?([newIndexPath])
        case .delete:
            guard let indexPath = indexPath else { return }
            deleteRowsAtIndexPaths?([indexPath])
        case .update:
            guard let indexPath = indexPath else { return }
            updateRowsAtIndexPath?(indexPath)
        case .move:
            guard let newIndexPath = newIndexPath else { return }
            guard let indexPath = indexPath else { return }
            deleteRowsAtIndexPaths?([indexPath])
            insertRowsAtIndexPaths?([newIndexPath])
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        didChangeContent?()
    }

}
