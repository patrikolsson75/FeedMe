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
        return NSEntityDescription.insertNewObject(forEntityName: "Article", into: context) as! ArticleMO
    }

    func allArticles() -> [Article] {
        let articlesFetch = NSFetchRequest<ArticleMO>(entityName: "Article")
        let publishedSort = NSSortDescriptor(key: "published", ascending: false)
        articlesFetch.sortDescriptors = [publishedSort]

        do {
            return try persistentContainer.viewContext.fetch(articlesFetch)
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
    }

    func articlesResultsController() -> ArticleResultsController {
        let articlesFetch = NSFetchRequest<ArticleMO>(entityName: "Article")
        let publishedSort = NSSortDescriptor(key: "published", ascending: false)
        articlesFetch.sortDescriptors = [publishedSort]
        let fc = NSFetchedResultsController(fetchRequest: articlesFetch, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        return ArticleResultsControllerCoreData(fc: fc)
    }

    func newBackgroundContext() -> FeedMeStoreContext {
        return persistentContainer.newBackgroundContext() as FeedMeStoreContext
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
}

class ArticleMO: NSManagedObject {

    @NSManaged var title: String?
    @NSManaged var previewText: String?
    @NSManaged var imageURL: URL?
    @NSManaged var articleURL: URL?
    @NSManaged var guid: String
    @NSManaged var published: Date?
}

extension ArticleMO: Article {}

class ArticleResultsControllerCoreData: NSObject, ArticleResultsController {

    let fc: NSFetchedResultsController<ArticleMO>

    var willChangeContent: (() -> Void)? = nil
    var insertRowsAtIndexPaths: (([IndexPath]) -> Void)? = nil
    var deleteRowsAtIndexPaths: (([IndexPath]) -> Void)? = nil
    var updateRowsAtIndexPath: ((IndexPath) -> Void)? = nil
    var didChangeContent: (() -> Void)? = nil

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
}

extension ArticleResultsControllerCoreData: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        willChangeContent?()
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
