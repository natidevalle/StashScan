//
//  EditItemSheet.swift
//  StashScan
//

import SwiftUI

struct EditItemSheet: View {
    let item: Item
    let onSave: (String, Int?) -> Void
    let onSaveAndMove: (String, Int?) -> Void
    let onDismiss: () -> Void

    @State private var localName: String
    @State private var quantityEnabled: Bool
    @State private var localQty: Int

    init(
        item: Item,
        onSave: @escaping (String, Int?) -> Void,
        onSaveAndMove: @escaping (String, Int?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.item = item
        self.onSave = onSave
        self.onSaveAndMove = onSaveAndMove
        self.onDismiss = onDismiss
        _localName        = State(initialValue: item.name)
        _quantityEnabled  = State(initialValue: item.quantity != nil)
        _localQty         = State(initialValue: item.quantity ?? 0)
    }

    private var trimmedName: String { localName.trimmingCharacters(in: .whitespaces) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: DETAILS card
                    sectionHeader("DETAILS")

                    VStack(spacing: 0) {
                        // Name row
                        HStack {
                            Text("Name")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(Color(.label))
                            Spacer()
                            TextField("Item name", text: $localName)
                                .font(.system(size: 17, weight: .regular))
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color(.label))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider()

                        // Quantity row
                        HStack {
                            Text("Quantity")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(Color(.label))
                            Spacer()
                            if quantityEnabled {
                                Stepper("\(localQty)", value: $localQty, in: 0...999)
                                    .fixedSize()
                            } else {
                                Button("None") {
                                    quantityEnabled = true
                                    localQty = 0
                                }
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(Color(.secondaryLabel))
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Spacer().frame(height: 20)

                    // MARK: Move card
                    Button {
                        onSaveAndMove(trimmedName, quantityEnabled ? localQty : nil)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.dsAccent)
                            Text("Move to…")
                                .font(.callout)
                                .foregroundStyle(Color.dsAccent)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color(.label))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(trimmedName, quantityEnabled ? localQty : nil)
                        onDismiss()
                    }
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(canSave ? Color.dsAccent : Color(.tertiaryLabel))
                    .disabled(!canSave)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color(.secondaryLabel))
            .padding(.top, 20)
            .padding(.bottom, 6)
            .padding(.horizontal, 4)
    }
}
