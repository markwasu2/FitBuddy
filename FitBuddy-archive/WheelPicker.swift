import SwiftUI

struct WheelPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    
    var body: some View {
        Picker("", selection: $value) {
            ForEach(Array(stride(from: range.lowerBound, through: range.upperBound, by: step)), id: \.self) { item in
                Text("\(item)")
                    .font(.system(size: 17))
                    .tag(item)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .clipped()
    }
}

struct WheelPickerDouble: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    init(value: Binding<Double>, range: ClosedRange<Double>, step: Double = 1.0) {
        self._value = value
        self.range = range
        self.step = step
    }
    
    var body: some View {
        Picker("", selection: $value) {
            ForEach(Array(stride(from: range.lowerBound, through: range.upperBound, by: step)), id: \.self) { item in
                Text(String(format: "%.0f", item))
                    .tag(item)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .clipped()
    }
}

#Preview {
    WheelPicker(value: .constant(25), range: 5...100, step: 1)
        .frame(height: 120)
        .padding()
} 