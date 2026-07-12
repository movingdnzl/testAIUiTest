import SwiftUI

struct TodoItem: Identifiable {
    let id = UUID()
    var title: String
    var isDone = false
}

/// 页面 3：待办列表
/// 功能：输入新增、点击勾选完成、滑动删除、空态提示。
struct TodoView: View {
    @State private var newTitle = ""
    @State private var items: [TodoItem] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    TextField("New task", text: $newTitle)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("todo_input_field")

                    Button("Add", action: addItem)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("todo_add_button")
                }
                .padding(.horizontal)

                if items.isEmpty {
                    Spacer()
                    Text("No tasks yet")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("todo_empty_label")
                    Spacer()
                } else {
                    List {
                        ForEach(items) { item in
                            HStack {
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isDone ? .green : .gray)
                                Text(item.title)
                                    .strikethrough(item.isDone)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { toggle(item) }
                            .accessibilityIdentifier("todo_row_\(item.title)")
                        }
                        .onDelete(perform: delete)
                    }
                    .accessibilityIdentifier("todo_list")
                }
            }
            .navigationTitle("Todo (\(items.count))")
        }
    }

    private func addItem() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        items.append(TodoItem(title: trimmed))
        newTitle = ""
    }

    private func toggle(_ item: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isDone.toggle()
    }

    private func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}

#Preview {
    TodoView()
}
