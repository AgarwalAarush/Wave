//
//  Item.swift
//  Wave
//
//  Created by Aarush Agarwal on 2/19/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
