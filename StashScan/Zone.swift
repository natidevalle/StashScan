//
//  Zone.swift
//  StashScan
//

import Foundation
import SwiftData

@Model
final class Zone {
    var id: UUID
    var name: String

    var location: Location?

    @Relationship(deleteRule: .cascade, inverse: \Container.zone)
    var containers: [Container]

    init(name: String, location: Location? = nil) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.containers = []
    }

    /// Removes photo files for all containers in this zone from the filesystem,
    /// then deletes this Zone (and cascades to its Containers and their Items).
    /// Use this instead of calling context.delete(_:) directly.
    func delete(from context: ModelContext) {
        for container in containers {
            if let photoPath = container.photo {
                try? FileManager.default.removeItem(atPath: photoPath)
            }
        }
        context.delete(self)
    }
}
