//
//  ArticleListViewController.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-13.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import UIKit
import SafariServices

class ArticleListController {

    struct Section {
        let title: String
        let articles: [Article]
    }

    var sections: [Section] = []

    func update(articles: [Article]) {
        sections = []
        sections.append(Section(title: "", articles: articles))
    }

}

class ArticleListViewController: UITableViewController {

    lazy var articleListController = ArticleListController()
    lazy var feedFetcher = FeedFetcher(store: FeedMeCoreDataStore.shared)
    @IBOutlet var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusSpinner: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refreshData), for: UIControl.Event.valueChanged)
        self.refreshControl = refreshControl

        toolbarItems = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                        UIBarButtonItem(customView: statusView),
                        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)]

        NotificationCenter.default.addObserver(forName: .fetchingFeedCount, object: nil, queue: nil, using: { [weak self, statusLabel, statusSpinner] notification in
            guard let operationCount = notification.userInfo?["operationCount"] as? Int else { return }
            DispatchQueue.main.async {
                if operationCount > 0 {
                    statusLabel?.text = "Loading \(operationCount) feeds..."
                    statusSpinner?.startAnimating()
                } else {
                    statusSpinner?.stopAnimating()
                    refreshControl.endRefreshing()
                    self?.updateStatusLabel()
                    self?.updateArticleList()
                }
            }
        })

        updateArticleList()
        updateStatusLabel()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return articleListController.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articleListController.sections[section].articles.count
    }


    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return articleListController.sections[section].title
    }

    fileprivate func configure(_ cell: ArticleImageListTableViewCell, for article: Article) {
        cell.titleLabel.text = article.title
        cell.previewLabel.text = article.previewText
        if article.isNew {
            cell.previewLabel.textColor = UIColor.init(named: "textColor")
            cell.titleLabel.textColor = UIColor.init(named: "textColor")
        } else {
            cell.previewLabel.textColor = UIColor.init(named: "unreadTextColor")
            cell.titleLabel.textColor = UIColor.init(named: "unreadTextColor")
        }
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
        let article: Article = articleListController.sections[indexPath.section].articles[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleImageListTableViewCell", for: indexPath) as! ArticleImageListTableViewCell
        configure(cell, for: article)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article: Article = articleListController.sections[indexPath.section].articles[indexPath.row]
        guard let url = article.articleURL else { return }
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        let web = SFSafariViewController(url: url, configuration: configuration)
        web.restorationIdentifier = "SFArticleViewController"
        web.preferredBarTintColor = .black
        web.preferredControlTintColor = .white
        present(web, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let article: Article = articleListController.sections[indexPath.section].articles[indexPath.row]
        guard let url = article.articleURL else {
            return UISwipeActionsConfiguration(actions: [])
        }
        let readingListAction = UIContextualAction(style: .normal, title: .addToReadingList) { [weak self] (action, view, completionHandler) in
            do {
                try SSReadingList.default()?.addItem(with: url,
                                                     title: article.title,
                                                     previewText: article.previewText)
                completionHandler(true)
            } catch {
                self?.showAlert(message: "Unexpected error: \(error).")
                completionHandler(false)
            }

        }
        return UISwipeActionsConfiguration(actions: [readingListAction])
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

    func updateArticleList() {
        articleListController.update(articles: FeedMeCoreDataStore.shared.allArticles())
        tableView.reloadData()
    }

    @IBAction func unwindToArticleList(_ sender: UIStoryboardSegue) {
//        let sourceViewController = sender.source
        // Use data from the view controller which initiated the unwind segue
    }
}

extension ArticleListViewController: UIDataSourceModelAssociation {
    func modelIdentifierForElement(at idx: IndexPath, in view: UIView) -> String? {
        guard !idx.isEmpty else {
            return nil
        }
        let article: Article = articleListController.sections[idx.section].articles[idx.row]
        return article.identifier
    }

    func indexPathForElement(withModelIdentifier identifier: String, in view: UIView) -> IndexPath? {
        for (sectionIndex, section) in articleListController.sections.enumerated() {
            let articleIndex = section.articles.index { (article) -> Bool in
                return article.identifier == identifier
            }
            if articleIndex != nil {
                return IndexPath(row: articleIndex!, section: sectionIndex)
            }
        }
        return nil
    }

}
