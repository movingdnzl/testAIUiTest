import SwiftUI

/// 页面 2：计数器
/// 功能：加、减、重置。计数不会低于 0。
struct CounterView: View {
    @State private var count = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("\(count)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .accessibilityIdentifier("counter_value_label")

                HStack(spacing: 20) {
                    Button {
                        if count > 0 { count -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill").font(.largeTitle)
                    }
                    .accessibilityIdentifier("counter_decrement_button")

                    Button {
                        count += 1
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.largeTitle)
                    }
                    .accessibilityIdentifier("counter_increment_button")
                }

                Button("Reset") { count = 0 }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("counter_reset_button")
            }
            .padding()
            .navigationTitle("Counter")
        }
    }
}

#Preview {
    CounterView()
}
