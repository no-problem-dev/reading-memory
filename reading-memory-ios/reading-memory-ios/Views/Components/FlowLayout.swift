import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return CGSize(width: result.width, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for row in result.rows {
            for item in row {
                let x = item.x + bounds.minX
                let y = item.y + bounds.minY
                
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }
}

struct FlowResult {
    struct Item {
        let subview: LayoutSubview
        let size: CGSize
        var x: CGFloat
        var y: CGFloat
    }
    
    let rows: [[Item]]
    let width: CGFloat
    let height: CGFloat
    
    init(in width: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var rows: [[Item]] = []
        var currentRow: [Item] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: width, height: .infinity))
            
            // Check if we need to wrap to the next line
            if x + size.width > width && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = []
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            currentRow.append(Item(subview: subview, size: size, x: x, y: y))
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        self.rows = rows
        self.width = width
        self.height = y + maxHeight
    }
}