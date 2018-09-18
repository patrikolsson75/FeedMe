//
//  FeedListViewController.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-30.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import UIKit
import FeedKit

class FeedListViewController: UITableViewController {

    var store: FeedMeStore = FeedMeCoreDataStore.shared
    lazy var feedResultsController =  store.feedResultsController()

    override func viewDidLoad() {
        super.viewDidLoad()
        feedResultsController.willChangeContent = { [tableView] in
            tableView?.beginUpdates()
        }
        feedResultsController.didChangeContent = { [tableView] in
            tableView?.endUpdates()
        }
        feedResultsController.insertRowsAtIndexPaths = { [tableView] indexPaths in
            tableView?.insertRows(at: indexPaths, with: .fade)
        }
        feedResultsController.deleteRowsAtIndexPaths = { [tableView] indexPaths in
            tableView?.deleteRows(at: indexPaths, with: .fade)
        }
        feedResultsController.updateRowsAtIndexPath = { [weak self, tableView, feedResultsController] indexPath in
            let feed: Feed = feedResultsController.item(at: indexPath)
            if let cell = tableView?.cellForRow(at: indexPath) {
                self?.configure(cell, for: feed)
            }
        }
        feedResultsController.insertSections = { [tableView] indexSet in
            tableView?.insertSections(indexSet, with: .fade)
        }
        feedResultsController.deleteSections = { [tableView] indexSet in
            tableView?.deleteSections(indexSet, with: .fade)
        }
        feedResultsController.performFetch()
        setEditing(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return feedResultsController.sectionCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedResultsController.itemCount(in: section)
    }

    fileprivate func configure(_ cell: UITableViewCell, for feed: Feed) {
        cell.textLabel?.text = feed.title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let feed: Feed = feedResultsController.item(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedListItemCell", for: indexPath)
        configure(cell, for: feed)
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let feed: Feed = feedResultsController.item(at: indexPath)
            store.delete(feed)
        }
    }

    @IBAction func addFeedButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: NSLocalizedString("Add source", comment: ""), message: "This is an alert.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Add", comment: ""), style: .default, handler: { [weak self] _ in
            guard let feedString = alert.textFields?[0].text else {
                return
            }
            self?.add(feed: feedString)
        }))
        alert.addTextField { (textField) in
            textField.placeholder = "www.mysite.com/feed"
        }
        self.present(alert, animated: true, completion: nil)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FeedListViewController {
    func add(feed urlString: String) {
        guard let feedURL = URL(string: urlString) else {
            return
        }
        let loadingView = UIAlertController(title: NSLocalizedString("Verifying...", comment: ""), message: nil, preferredStyle: .alert)
        present(loadingView, animated: true, completion: nil)
        let feedParser = FeedParser(URL: feedURL)
        feedParser.parseAsync { [weak self, store] (result) in
            self?.dismiss(animated: true, completion: nil)
            if result.isSuccess {
                print("Success")
                let context = store.newBackgroundContext()
                var newFeed = store.newFeed(in: context)
                newFeed.feedURL = feedURL
                if result.rssFeed?.title != nil {
                    newFeed.title = result.rssFeed?.title
                } else if result.atomFeed?.title != nil {
                    newFeed.title = result.atomFeed?.title
                } else {
                    newFeed.title = feedURL.absoluteString
                }
                store.save(context)
            } else {
                print("Fail!")
            }
        }
    }
}
