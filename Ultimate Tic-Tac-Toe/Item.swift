//
//  Item.swift
//  Ultimate Tic-Tac-Toe
//
//  Created by Edison Law on 12/3/24.
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