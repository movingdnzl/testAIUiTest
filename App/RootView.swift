import SwiftUI

/// 根视图：底部 TabBar 承载 5 个演示页面。
/// 每个 Tab 都设置了 accessibilityIdentifier，供 XCUITest 定位切换。
struct RootView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        TabView {
            LoginView()
                .tabItem { Label("Login", systemImage: "person.circle") }
                .accessibilityIdentifier("tab_login")

            CounterView()
                .tabItem { Label("Counter", systemImage: "plusminus.circle") }
                .accessibilityIdentifier("tab_counter")

            TodoView()
                .tabItem { Label("Todo", systemImage: "checklist") }
                .accessibilityIdentifier("tab_todo")

            ProfileFormView()
                .tabItem { Label("Form", systemImage: "square.and.pencil") }
                .accessibilityIdentifier("tab_form")

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .accessibilityIdentifier("tab_settings")
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    RootView()
}
