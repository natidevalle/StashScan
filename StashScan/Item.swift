//
//  Item.swift
//  StashScan
//

import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID
    var name: String
    var quantity: Int?

    var container: Container?

    init(name: String, quantity: Int? = nil, container: Container? = nil) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.container = container
    }
}
