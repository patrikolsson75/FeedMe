//
//  ArticleListViewController.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-13.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import UIKit
import SafariServices

class ArticleListViewController: UITableViewController {

    var store: FeedMeStore = FeedMeCoreDataStore.shared
    lazy var articlesResultsController =  store.articlesResultsController()
    lazy var feedFetcher = FeedFetcher(store: store)
    @IBOutlet var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusSpinner: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = UITableViewAutomaticDimension

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refreshData), for: UIControlEvents.valueChanged)
        self.refreshControl = refreshControl

        toolbarItems = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                        UIBarButtonItem(customView: statusView),
                        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)]

        NotificationCenter.default.addObserver(forName: .fetchingFeedCount, object: nil, queue: nil, using: { [statusLabel, statusSpinner] notification in
            guard let operationCount = notification.userInfo?["operationCount"] as? Int else { return }
            DispatchQueue.main.async {
                if operationCount > 0 {
                    statusLabel?.text = "Loading"
                    statusSpinner?.startAnimating()
                } else {
                    statusLabel?.text = ""
                    statusSpinner?.stopAnimating()
                    refreshControl.endRefreshing()
                }
            }
        })

        articlesResultsController.willChangeContent = { [tableView] in
            tableView?.beginUpdates()
        }
        articlesResultsController.didChangeContent = { [tableView] in
            tableView?.endUpdates()
        }
        articlesResultsController.insertRowsAtIndexPaths = { [tableView] indexPaths in
            tableView?.insertRows(at: indexPaths, with: .none)
        }
        articlesResultsController.deleteRowsAtIndexPaths = { [tableView] indexPaths in
            tableView?.deleteRows(at: indexPaths, with: .none)
        }
        articlesResultsController.updateRowsAtIndexPath = { [weak self, tableView] indexPath in
            guard let cell = tableView?.cellForRow(at: indexPath) as? ArticleListTableViewCell else { return }
            self?.configure(cell, at: indexPath)
        }
        articlesResultsController.performFetch()
        refreshData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return articlesResultsController.sectionCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articlesResultsController.articleCount(in: section)
    }


    fileprivate func configure(_ cell: ArticleListTableViewCell, at indexPath: IndexPath) {
        let article = articlesResultsController.article(at: indexPath)
        cell.titleLabel.text = article.title
        cell.previewLabel.text = article.previewText
        cell.thumbnailURL = article.image.url
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleListTableViewCell", for: indexPath) as? ArticleListTableViewCell else {
            return UITableViewCell()
        }
        configure(cell, at: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = articlesResultsController.article(at: indexPath)
        guard let url = article.articleURL else { return }
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        let web = SFSafariViewController(url: url, configuration: configuration)
        present(web, animated: true, completion: nil)
    }

    @objc
    func refreshData() {
        feedFetcher.fetch()
    }
}
