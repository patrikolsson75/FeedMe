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

struct Article {
    let title: String
    let text: String
    var thumbnail: URL?
    let url: URL?
}

class ArticleListViewController: UITableViewController {

    var articles: [Article] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = UITableViewAutomaticDimension
        let feedURL = URL(string: "https://9to5mac.com/feed/")!
//        let feedURL = URL(string: "http://feeds.feedburner.com/TheIphoneBlog")!
//        let feedURL = URL(string: "http://feeds.macrumors.com/MacRumors-All")!
        let parser = FeedParser(URL: feedURL)
        parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            // Do your thing, then back to the Main thread
            DispatchQueue.main.async { [weak self] in
                guard let feed = result.rssFeed, result.isSuccess else {
                    let alert = UIAlertController(title: "Can't load", message: result.error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                    return
                }
                guard let feedItems = feed.items else { return }
                self?.articles = feedItems.compactMap { item -> Article in
                    let thumbnailURL = item.media?.mediaThumbnails?.first?.attributes?.url
                    return Article(title: item.title ?? "n/a",
                                   text: item.description?.withoutHtml ?? "n/a",
                                   thumbnail: URL(string: thumbnailURL ?? ""),
                                   url: URL(string: item.link ?? ""))
                }
                self?.tableView.reloadData()
            }
        }
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
        cell.previewLabel.text = article.text
        cell.thumbnailURL = article.thumbnail

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = articles[indexPath.row]
        guard let url = article.url else { return }
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        let web = SFSafariViewController(url: url, configuration: configuration)
        present(web, animated: true, completion: nil)
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

extension String {
    var withoutHtml: String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}
