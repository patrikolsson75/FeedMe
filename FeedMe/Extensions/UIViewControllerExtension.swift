//
//  UIViewControllerExtension.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-10-14.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(title: String? = nil, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: .OK, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
