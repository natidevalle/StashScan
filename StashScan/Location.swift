//
//  Location.swift
//  StashScan
//

import Foundation
import SwiftData

@Model
final class Location {
    var id: UUID
    var name: String

    @Relationship(deleteRule: .cascade, inverse: \Zone.location)
    var zones: [Zone]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.zones = []
    }

    /// Removes photo files for every container in every zone from the filesystem,
    /// then deletes this Location (and cascades to its Zones, their Containers,
    /// and those Containers' Items). Use this instead of calling context.delete(_:) directly.
    func delete(from context: ModelContext) {
        for zone in zones {
            for container in zone.containers {
                if let url = container.photoURL {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
        context.delete(self)
    }
}
