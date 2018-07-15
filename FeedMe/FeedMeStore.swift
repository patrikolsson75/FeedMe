//
//  FeedMeStore.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-14.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import UIKit
import CoreData

class FeedMeStore: NSObject {

    static let shared = FeedMeStore()

    private override init() {
        super.init()
    }

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FeedMe")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    func save(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func newArticle(in context: NSManagedObjectContext) -> ArticleMO {
        return NSEntityDescription.insertNewObject(forEntityName: "Article", into: context) as! ArticleMO
    }

    func allArticles() -> [ArticleMO] {
        let articlesFetch = NSFetchRequest<ArticleMO>(entityName: "Article")
        let publishedSort = NSSortDescriptor(key: "published", ascending: false)
        articlesFetch.sortDescriptors = [publishedSort]

        do {
            return try persistentContainer.viewContext.fetch(articlesFetch)
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    func article(with guid: String, in context: NSManagedObjectContext) -> ArticleMO? {
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
