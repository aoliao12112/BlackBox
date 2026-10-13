//
//  FlowLayout.swift
//  blackbox
//
//  Week 2 · 简单流式布局（给标签用）
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = compute(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = compute(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }
    
    private struct Result {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
    }
    
    private func compute(proposal: ProposedViewSize, subviews: Subviews) -> Result {
        let maxWidth = proposal.width ?? 300
        var result = Result()
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            result.positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            result.size.width = max(result.size.width, x)
            result.size.height = max(result.size.height, y + rowHeight)
        }
        return result
    }
}
