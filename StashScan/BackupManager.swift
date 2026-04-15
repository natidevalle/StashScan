//
//  BackupManager.swift
//  StashScan
//
//  Serialises all data to/from a JSON backup file.
//

import Foundation
import SwiftData

// MARK: - Backup DTOs

struct BackupFile: Codable {
    let app: String
    let version: Int
    let exportedAt: Date
    var locations: [LocationBackup]
}

struct LocationBackup: Codable {
    let id: UUID
    let name: String
    var zones: [ZoneBackup]
}

struct ZoneBackup: Codable {
    let id: UUID
    let name: String
    var containers: [ContainerBackup]
}

struct ContainerBackup: Codable {
    let id: UUID
    let name: String
    let type: ContainerType
    let notes: String
    let photo: String?
    let locationId: UUID
    let zoneId: UUID
    let qrCode: UUID
    let createdAt: Date
    let updatedAt: Date
    var items: [ItemBackup]
}

struct ItemBackup: Codable {
    let id: UUID
    let name: String
    let quantity: Int?
}

// MARK: - Import Result

struct ImportResult {
    let locations: Int
    let zones: Int
    let containers: Int
    let items: Int
}

// MARK: - Errors

enum BackupError: LocalizedError {
    case notAStashScanBackup
    case decodingFailed
    case encodingFailed(Error)
    case fileWriteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAStashScanBackup:
            return "This file doesn't appear to be a valid StashScan backup."
        case .decodingFailed:
            return "Could not read the backup file. It may be corrupted or from an unsupported version."
        case .encodingFailed(let e):
            return "Could not create the backup: \(e.localizedDescription)"
        case .fileWriteFailed(let e):
            return "Could not write the backup file: \(e.localizedDescription)"
        }
    }
}

// MARK: - BackupManager

final class BackupManager {
    static let shared = BackupManager()
    private init() {}

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: Export

    func export(context: ModelContext) throws -> URL {
        let locations = try context.fetch(FetchDescriptor<Location>())

        let backup = BackupFile(
            app: "StashScan",
            version: 1,
            exportedAt: Date(),
            locations: locations.map { loc in
                LocationBackup(
                    id: loc.id,
                    name: loc.name,
                    zones: loc.zones.map { zone in
                        ZoneBackup(
                            id: zone.id,
                            name: zone.name,
                            containers: zone.containers.map { container in
                                ContainerBackup(
                                    id: container.id,
                                    name: container.name,
                                    type: container.type,
                                    notes: container.notes,
                                    photo: container.photo,
                                    locationId: container.locationId,
                                    zoneId: container.zoneId,
                                    qrCode: container.qrCode,
                                    createdAt: container.createdAt,
                                    updatedAt: container.updatedAt,
                                    items: container.items.map { item in
                                        ItemBackup(
                                            id: item.id,
                                            name: item.name,
                                            quantity: item.quantity
                                        )
                                    }
                                )
                            }
                        )
                    }
                )
            }
        )

        let data: Data
        do {
            data = try encoder.encode(backup)
        } catch {
            throw BackupError.encodingFailed(error)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "stashscan-backup-\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw BackupError.fileWriteFailed(error)
        }

        return url
    }

    // MARK: Import

    func importBackup(from url: URL, context: ModelContext) throws -> ImportResult {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw BackupError.decodingFailed
        }

        let backup: BackupFile
        do {
            backup = try decoder.decode(BackupFile.self, from: data)
        } catch {
            throw BackupError.notAStashScanBackup
        }

        guard backup.app == "StashScan", backup.version == 1 else {
            throw BackupError.notAStashScanBackup
        }

        // Pre-build lookup maps for deduplication
        let locationMap = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<Location>()).map { ($0.id, $0) }
        )
        let zoneMap = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<Zone>()).map { ($0.id, $0) }
        )
        let containerMap = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<Container>()).map { ($0.id, $0) }
        )
        let existingItemIds = Set(try context.fetch(FetchDescriptor<Item>()).map { $0.id })

        var importedLocations = 0
        var importedZones = 0
        var importedContainers = 0
        var importedItems = 0

        for locBackup in backup.locations {
            let location: Location
            if let existing = locationMap[locBackup.id] {
                location = existing
            } else {
                let newLocation = Location(name: locBackup.name)
                newLocation.id = locBackup.id
                context.insert(newLocation)
                location = newLocation
                importedLocations += 1
            }

            for zoneBackup in locBackup.zones {
                let zone: Zone
                if let existing = zoneMap[zoneBackup.id] {
                    zone = existing
                } else {
                    let newZone = Zone(name: zoneBackup.name, location: location)
                    newZone.id = zoneBackup.id
                    context.insert(newZone)
                    zone = newZone
                    importedZones += 1
                }

                for containerBackup in zoneBackup.containers {
                    let container: Container
                    if let existing = containerMap[containerBackup.id] {
                        container = existing
                    } else {
                        let newContainer = Container(
                            name: containerBackup.name,
                            type: containerBackup.type,
                            notes: containerBackup.notes,
                            photo: containerBackup.photo,
                            locationId: containerBackup.locationId,
                            zoneId: containerBackup.zoneId,
                            zone: zone
                        )
                        newContainer.id = containerBackup.id
                        newContainer.qrCode = containerBackup.qrCode
                        newContainer.createdAt = containerBackup.createdAt
                        newContainer.updatedAt = containerBackup.updatedAt
                        context.insert(newContainer)
                        container = newContainer
                        importedContainers += 1
                    }

                    for itemBackup in containerBackup.items {
                        if !existingItemIds.contains(itemBackup.id) {
                            let item = Item(
                                name: itemBackup.name,
                                quantity: itemBackup.quantity,
                                container: container
                            )
                            item.id = itemBackup.id
                            context.insert(item)
                            importedItems += 1
                        }
                    }
                }
            }
        }

        try context.save()

        return ImportResult(
            locations: importedLocations,
            zones: importedZones,
            containers: importedContainers,
            items: importedItems
        )
    }
}
