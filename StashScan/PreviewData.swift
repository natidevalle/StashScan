//
//  PreviewData.swift
//  StashScan
//
//  In-memory container with seed data for SwiftUI previews.
//

import SwiftData
import Foundation

@MainActor
let previewContainer: ModelContainer = {
    let schema = Schema([Location.self, Zone.self, Container.self, Item.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let ctx = container.mainContext

    // --- Locations ---
    let garage = Location(name: "Garage")
    let basement = Location(name: "Basement")
    let office = Location(name: "Home Office")
    ctx.insert(garage)
    ctx.insert(basement)
    ctx.insert(office)

    // --- Zones ---
    let wallShelves = Zone(name: "Wall Shelves", location: garage)
    let workbench   = Zone(name: "Workbench",    location: garage)
    ctx.insert(wallShelves)
    ctx.insert(workbench)

    let storageArea = Zone(name: "Storage Area",    location: basement)
    let laundry     = Zone(name: "Laundry Corner",  location: basement)
    ctx.insert(storageArea)
    ctx.insert(laundry)

    let deskDrawers = Zone(name: "Desk Drawers", location: office)
    ctx.insert(deskDrawers)

    // --- Containers ---
    let toolBox = Container(
        name: "Tool Box",
        type: .box,
        notes: "Hand tools — hammer, screwdrivers, pliers",
        locationId: garage.id,
        zoneId: wallShelves.id,
        zone: wallShelves
    )
    let cables = Container(
        name: "Cables Bin",
        type: .bin,
        notes: "USB-A, HDMI, and extension cables",
        locationId: garage.id,
        zoneId: wallShelves.id,
        zone: wallShelves
    )
    let holiday = Container(
        name: "Holiday Decorations",
        type: .box,
        notes: "Christmas ornaments and lights",
        locationId: basement.id,
        zoneId: storageArea.id,
        zone: storageArea
    )
    let officeSupplies = Container(
        name: "Office Supplies",
        type: .drawer,
        notes: "Pens, sticky notes, tape",
        locationId: office.id,
        zoneId: deskDrawers.id,
        zone: deskDrawers
    )
    ctx.insert(toolBox)
    ctx.insert(cables)
    ctx.insert(holiday)
    ctx.insert(officeSupplies)

    return container
}()
