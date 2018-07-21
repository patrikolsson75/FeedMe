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

        NotificationCenter.default.addObserver(forName: .fetchingFeedCount, object: nil, queue: nil, using: { [weak self, statusLabel, statusSpinner] notification in
            guard let operationCount = notification.userInfo?["operationCount"] as? Int else { return }
            DispatchQueue.main.async {
                if operationCount > 0 {
                    statusLabel?.text = "Loading"
                    statusSpinner?.startAnimating()
                } else {
                    self?.updateStatusLabel()
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
            tableView?.insertRows(at: indexPaths, with: .fade)
        }
        articlesResultsController.deleteRowsAtIndexPaths = { [tableView] indexPaths in
            tableView?.deleteRows(at: indexPaths, with: .fade)
        }
        articlesResultsController.updateRowsAtIndexPath = { [weak self, tableView, articlesResultsController] indexPath in
            let article = articlesResultsController.article(at: indexPath)
            if let cell = tableView?.cellForRow(at: indexPath) as? ArticleImageListTableViewCell {
                self?.configure(cell, for: article)
            }
        }
        articlesResultsController.performFetch()
        refreshData()
        updateStatusLabel()
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


    fileprivate func configure(_ cell: ArticleImageListTableViewCell, for article: Article) {
        cell.titleLabel.text = article.title
        cell.previewLabel.text = article.previewText
        cell.thumbnailURL = article.image.url
        cell.sourceTitleLabel.text = article.feed.title
        if let publishedDate = article.published {
            cell.publishedDateLabel.text = publishedDateFormatter.string(from: publishedDate)
        } else {
            cell.publishedDateLabel.text = ""
        }
    }

    lazy var publishedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let article = articlesResultsController.article(at: indexPath)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleImageListTableViewCell", for: indexPath) as? ArticleImageListTableViewCell else {
            return UITableViewCell()
        }
        configure(cell, for: article)
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

    func updateStatusLabel() {
        guard let lastFetchedDate = feedFetcher.lastFetched else {
            statusLabel.text = NSLocalizedString("Never updated", comment: "")
            return
        }
        let dateString = publishedDateFormatter.string(from: lastFetchedDate)
        statusLabel.text = String.localizedStringWithFormat(NSLocalizedString("Last updated %@", comment: ""), dateString)
    }
}

extension ArticleListViewController: UIDataSourceModelAssociation {
    func modelIdentifierForElement(at idx: IndexPath, in view: UIView) -> String? {
        let article = articlesResultsController.article(at: idx)
        return article.identifier
    }

    func indexPathForElement(withModelIdentifier identifier: String, in view: UIView) -> IndexPath? {
        return articlesResultsController.indexPath(for: identifier)
    }

}
