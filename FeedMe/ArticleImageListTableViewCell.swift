//
//  ArticleListTableViewCell.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-13.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import UIKit

class ArticleImageListTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var previewLabel: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var sourceTitleLabel: UILabel!
    @IBOutlet weak var publishedDateLabel: UILabel!
    @IBOutlet weak var thumbnailHeight: NSLayoutConstraint!

    private var imageDownloadTask: URLSessionDataTask?

    var thumbnailURL: URL? {
        didSet {
            guard let newURL = thumbnailURL else {
                thumbnailHeight.constant = 0
                setNeedsLayout()
                return
            }
            thumbnailHeight.constant = 75
            setNeedsLayout()
            downloadThumbnail(from: newURL)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
    private func downloadThumbnail(from url: URL) {
        if let cachedImage = Cache.shared.image(for: url.absoluteString) {
            DispatchQueue.main.async { [weak self] in
                self?.showThumbnail(cachedImage)
            }
            return
        }
        imageDownloadTask?.cancel()
        imageDownloadTask = URLSession.shared.dataTask(with: url, completionHandler: { [weak self, thumbnailURL] (data, response, error) in

            if error != nil {
                print(error!)
                return
            }

            guard let image = UIImage(data: data!) else { return }

            Cache.shared.store(image, for: url.absoluteString)

            guard thumbnailURL == url else { return }

            DispatchQueue.main.async { [weak self] in
                self?.showThumbnail(image)
            }
        })
        imageDownloadTask?.resume()
    }
    
    private func showThumbnail(_ image: UIImage) {
        thumbnail.image = image
    }
}
