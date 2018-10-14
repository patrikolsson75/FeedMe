//
//  FeedAnalyzer.swift
//  FeedMe
//
//  Created by Patrik Olsson on 2018-10-14.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation

class FeedAnalyzer {

    enum AnalyzeResult {
        case undetermined
        case weekly
    }

    func analyze(articles: [Article]) -> AnalyzeResult {
        guard articles.count > 3 else {
            return .undetermined
        }
        let sortedArticles = articles.sorted { (lhs, rhs) -> Bool in
            guard let lhsPublished = lhs.published,
                let rhsPublished = rhs.published else {
                    return false
            }
            return lhsPublished < rhsPublished
        }
        guard let firstDate = sortedArticles.first?.published,
            let lastDate = sortedArticles.last?.published else {
                return .undetermined
        }
        let numberOfWeeks = firstDate.weeks(to: lastDate) + 1
        let numberOfArticles = sortedArticles.count
        let numberOfArticlesPerWeek = numberOfArticles / numberOfWeeks
        if numberOfArticlesPerWeek < 3 {
            return .weekly
        } else {
            return .undetermined
        }
    }

}

private extension Date {
    func weeks(to toDate: Date) -> Int {
        let weekDiff = Calendar.current.dateComponents([.weekOfYear], from: self, to: toDate)
        return weekDiff.weekOfYear ?? 0
    }
}
