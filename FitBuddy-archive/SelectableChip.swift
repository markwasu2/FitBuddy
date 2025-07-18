import SwiftUI

struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .default))
                .foregroundColor(isSelected ? Color.accent : Color.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accent.opacity(0.15) : Color.background)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accent : Color.textSecondary, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct ChipFlowLayout: View {
    let items: [String]
    @Binding var selectedItems: Set<String>
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(items, id: \.self) { item in
                SelectableChip(
                    title: item,
                    isSelected: selectedItems.contains(item)
                ) {
                    if selectedItems.contains(item) {
                        selectedItems.remove(item)
                    } else {
                        selectedItems.insert(item)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SelectableChip(title: "Dumbbells", isSelected: true) {}
        SelectableChip(title: "Yoga Mat", isSelected: false) {}
        
        ChipFlowLayout(
            items: ["Body-weight", "Dumbbells", "Kettlebell", "Bench", "Pull-up Bar"],
            selectedItems: .constant(["Dumbbells", "Bench"])
        )
    }
    .padding()
} 