//
//  StringExtension.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-07-16.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation

extension String {
    var removingRepeatingNewlines: String {
        return components(separatedBy: .newlines).filter { !$0.isEmpty }.joined(separator: " ")
    }
    var removingRepeatingWhiteSpace: String {
        return components(separatedBy: .whitespaces).filter { $0.count > 0 }.joined(separator: " ")
    }
    var withoutHtml: String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

extension String {
    static let OK = NSLocalizedString("OK", comment: "")
    static let addToReadingList = NSLocalizedString("Add to Reading List", comment: "")
}
