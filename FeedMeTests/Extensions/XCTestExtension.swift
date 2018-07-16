//
//  XCTestExtension.swift
//  FeedMeTests
//
//  Created by Patrik Olsson on 2018-07-16.
//  Copyright © 2018 Patrik Olsson. All rights reserved.
//

import Foundation
import XCTest

extension XCTest {
    func contentsOfXMLFile(named: String) -> Data {
        let path = Bundle(for: type(of: self)).path(forResource: named, ofType: "xml")!
        return NSData(contentsOfFile: path)! as Data
    }
}
