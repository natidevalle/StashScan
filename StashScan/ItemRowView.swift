//
//  ItemRowView.swift
//  StashScan
//

import SwiftUI

struct ItemRowView: View {
    let item: Item
    let onTap: () -> Void
    let onMove: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(item.name)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color(.label))
                Spacer()
                if let qty = item.quantity {
                    Text("×\(qty)")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(.secondaryLabel))
                        .monospacedDigit()
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
          //  .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .frame(minHeight: 30)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
