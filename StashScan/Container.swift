//
//  Container.swift
//  StashScan
//

import Foundation
import SwiftData

enum ContainerType: String, Codable, CaseIterable {
    case box     = "Box"
    case bag     = "Bag"
    case bin     = "Bin"
    case drawer  = "Drawer"
    case shelf   = "Shelf"
    case other   = "Other"
}

@Model
final class Container {
    var id: UUID
    var name: String
    var type: ContainerType
    var notes: String
    var photo: String?
    var locationId: UUID
    var zoneId: UUID
    var qrCode: UUID
    var createdAt: Date
    var updatedAt: Date

    var zone: Zone?

    @Relationship(deleteRule: .cascade, inverse: \Item.container)
    var items: [Item]

    init(
        name: String,
        type: ContainerType,
        notes: String = "",
        photo: String? = nil,
        locationId: UUID,
        zoneId: UUID,
        zone: Zone? = nil
    ) {
        let now = Date()
        let containerID = UUID()
        self.id = containerID
        self.name = name
        self.type = type
        self.notes = notes
        self.photo = photo
        self.locationId = locationId
        self.zoneId = zoneId
        self.qrCode = containerID   // qrCode encodes the same UUID as id
        self.createdAt = now
        self.updatedAt = now
        self.zone = zone
        self.items = []
    }

    /// Removes the associated photo file from the filesystem (if present) then
    /// deletes this Container from the model context. Use this instead of
    /// calling context.delete(_:) directly when a photo may exist.
    func delete(from context: ModelContext) {
        if let photoPath = photo {
            try? FileManager.default.removeItem(atPath: photoPath)
        }
        context.delete(self)
    }
}
