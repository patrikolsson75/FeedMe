//
//  ArticleListTableViewCell.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-13.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import UIKit

class ArticleListTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var previewLabel: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!

    var thumbnailURL: URL? {
        didSet {
            guard let newURL = thumbnailURL else { return }
            downloadThumbnail(from: newURL)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        thumbnail.image = nil
        super.prepareForReuse()
    }
    private func downloadThumbnail(from url: URL) {
        URLSession.shared.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in

            if error != nil {
                print(error!)
                return
            }

            DispatchQueue.main.async { [weak self] in
                self?.thumbnail.image = UIImage(data: data!)
            }
        }).resume()

    }
}
