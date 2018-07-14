//
//  ArticleListViewController.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-13.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import UIKit
import FeedKit
import SafariServices

class FeedFetcher {
    func fetch(completion: @escaping (() -> Void)) {
        let feedURL = URL(string: "https://9to5mac.com/feed/")!
        //        let feedURL = URL(string: "http://feeds.feedburner.com/TheIphoneBlog")!
        //        let feedURL = URL(string: "http://feeds.macrumors.com/MacRumors-All")!
        //        let feedURL = URL(string: "http://f1blogg.teknikensvarld.se/feed/")!
        let parser = FeedParser(URL: feedURL)
        parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            guard let feed = result.rssFeed, result.isSuccess, let feedItems = feed.items else {
                completion()
                return
            }
            let store = FeedMeStore.shared
            feedItems.forEach({ feedItem in
                guard let guid = feedItem.guid?.value else { return }
                if let existingArticle = store.article(with: guid) {
                    existingArticle.title = feedItem.title
                    existingArticle.previewText = feedItem.description?.withoutHtml
                    existingArticle.imageURL = URL(string: feedItem.media?.mediaThumbnails?.first?.attributes?.url ?? "")
                    existingArticle.articleURL = URL(string: feedItem.link ?? "")
                    existingArticle.published = feedItem.pubDate
                } else {
                    let newArticle = store.newArticle()
                    newArticle.guid = guid
                    newArticle.title = feedItem.title
                    newArticle.previewText = feedItem.description?.withoutHtml
                    newArticle.imageURL = URL(string: feedItem.media?.mediaThumbnails?.first?.attributes?.url ?? "")
                    newArticle.articleURL = URL(string: feedItem.link ?? "")
                    newArticle.published = feedItem.pubDate
                }
            })
            store.saveContext()
            completion()
        }
    }
}

class ArticleListViewController: UITableViewController {

    var articles: [ArticleMO] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = UITableViewAutomaticDimension
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
        let fetcher = FeedFetcher()
        fetcher.fetch { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.articles = FeedMeStore.shared.allArticles()
                self?.tableView.reloadData()
            }
        }
    }
}

extension String {
    var withoutHtml: String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}
