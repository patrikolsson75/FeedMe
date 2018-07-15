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

    var articles: [Article] = []
    var store: FeedMeStore = FeedMeCoreDataStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = UITableViewAutomaticDimension
        NotificationCenter.default.addObserver(forName: .updatedFeed, object: nil, queue: OperationQueue.current) { [store] _ in
            DispatchQueue.main.async { [weak self, store] in
                self?.articles = store.allArticles()
                self?.tableView.reloadData()
            }
        }
        refreshData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleListTableViewCell", for: indexPath) as? ArticleListTableViewCell else {
            return UITableViewCell()
        }
        let article = articles[indexPath.row]
        cell.titleLabel.text = article.title
        cell.previewLabel.text = article.previewText
        cell.thumbnailURL = article.imageURL

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = articles[indexPath.row]
        guard let url = article.articleURL else { return }
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        let web = SFSafariViewController(url: url, configuration: configuration)
        present(web, animated: true, completion: nil)
    }

    func refreshData() {
        FeedFetcher(with: URL(string: "https://9to5mac.com/feed/")!).fetch()
        FeedFetcher(with: URL(string: "http://feeds.feedburner.com/TheIphoneBlog")!).fetch()
        FeedFetcher(with: URL(string: "http://feeds.macrumors.com/MacRumors-All")!).fetch()
        FeedFetcher(with: URL(string: "http://f1blogg.teknikensvarld.se/feed/")!).fetch()
        FeedFetcher(with: URL(string: "http://feeds.feedburner.com/f1fanatic")!).fetch()
    }
}
