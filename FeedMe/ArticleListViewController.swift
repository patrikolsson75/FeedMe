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

    let store: FeedMeStore
    var sections: [Section] = []

    init(store: FeedMeStore) {
        self.store = store
    }

    func update() {
        let articles: [Article] = store.allArticles()
        sections = []
        let newArticles = articles.filter({ article -> Bool in
            return article.isNew
        })
        if newArticles.count > 0 {
            let newArticleSection = Section(title: "New", articles: newArticles)
            sections.append(newArticleSection)
        }

        let oldArticles = articles.filter({ article -> Bool in
            return !article.isNew
        })
        if oldArticles.count > 0 {
            let oldArticleSection = Section(title: "Old", articles: oldArticles)
            sections.append(oldArticleSection)
        }
    }

}

class ArticleListViewController: UITableViewController {

    lazy var articleListController = ArticleListController(store: FeedMeCoreDataStore.shared)
    lazy var feedFetcher = FeedFetcher(store: FeedMeCoreDataStore.shared)
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

        NotificationCenter.default.addObserver(forName: .fetchingFeedCount, object: nil, queue: nil, using: { [weak self, statusLabel, statusSpinner, articleListController] notification in
            guard let operationCount = notification.userInfo?["operationCount"] as? Int else { return }
            DispatchQueue.main.async {
                if operationCount > 0 {
                    statusLabel?.text = "Loading"
                    statusSpinner?.startAnimating()
                } else {
                    self?.updateStatusLabel()
                    statusSpinner?.stopAnimating()
                    refreshControl.endRefreshing()
                    articleListController.update()
                    self?.tableView.reloadData()
                }
            }
        })

        articleListController.update()
        tableView.reloadData()
        updateStatusLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleImageListTableViewCell", for: indexPath) as? ArticleImageListTableViewCell else {
            return UITableViewCell()
        }
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
