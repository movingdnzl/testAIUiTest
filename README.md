# testAIUiTest — iOS UI 自动化测试演示

一个 SwiftUI 演示 App + XCUITest UI 自动化测试，跑完自动生成 HTML/Markdown 测试报告。

## 项目结构

```
testAIUiTest/
├── project.yml            # XcodeGen 工程定义（生成 .xcodeproj）
├── Makefile               # 常用命令
├── App/                   # 被测 App（5 个页面）
│   ├── App.swift          # @main 入口
│   ├── RootView.swift     # TabView 承载 5 个页面
│   └── Pages/
│       ├── LoginView.swift        # 页面1 登录
│       ├── CounterView.swift      # 页面2 计数器
│       ├── TodoView.swift         # 页面3 待办
│       ├── ProfileFormView.swift  # 页面4 表单
│       └── SettingsView.swift     # 页面5 设置
├── UITests/               # XCUITest UI 自动化用例
│   ├── UITestBase.swift           # 基类：启动 App / 切 Tab
│   ├── LoginUITests.swift         # 3 用例
│   ├── CounterUITests.swift       # 4 用例
│   ├── TodoUITests.swift          # 4 用例
│   ├── ProfileFormUITests.swift   # 3 用例
│   └── SettingsUITests.swift      # 4 用例
└── scripts/
    ├── run-tests.sh       # 一键：生成工程→跑测试→出报告
    ├── make-report.sh     # 从 xcresult 提取数据
    └── report.py          # 生成 HTML/Markdown 报告
```

## 5 个页面功能与测试点

| 页面 | 功能 | UI 测试用例 |
| --- | --- | --- |
| 登录 | 账号/密码校验，`admin/123456` 登录成功 | 空值校验、错误凭证、登录成功 |
| 计数器 | 加/减/重置，不为负 | 递增、递减、非负、重置 |
| 待办 | 新增/勾选完成/滑动删除 | 空态、新增、勾选、删除 |
| 表单 | 姓名/邮箱/年龄滑块/通知开关/保存 | 填写保存、开关、滑块 |
| 设置 | 深色模式/主题分段/重置弹窗 | 深色切换、分段切换、弹窗取消/确认 |

> App 内所有可交互控件都设置了 `accessibilityIdentifier`，测试通过 ID 精准定位，稳定可靠。

## 环境要求

1. **完整版 Xcode**（App Store 安装，非 Command Line Tools）
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   xcodebuild -version   # 能输出版本即 OK
   ```
2. **XcodeGen**（生成工程）+ 可选 **xcbeautify**（美化日志）
   ```bash
   brew install xcodegen xcbeautify
   ```

## 一键运行

```bash
make test          # 生成工程 → 跑 UI 自动化测试 → 生成报告
make open          # 浏览器打开 HTML 报告
make result        # 用 Xcode 打开 xcresult（含每步截图/录屏）
```

指定模拟器机型：

```bash
SIMULATOR="iPhone 15" make test
```

## 报告输出

跑完后在 `build/` 目录：
- `report.html` — 图形化报告（总体结果、通过率、用例明细表）
- `report.md` — Markdown 报告
- `TestResults.xcresult` — Xcode 原生结果包，双击可看每个用例的**逐步截图和失败录屏**

## “看到自动化测试效果”的方式

- 跑 `make test` 时，**iOS 模拟器会自动打开**，可以肉眼看到脚本自动点击、输入、切页面
- 跑完用 `make result` 打开 xcresult，逐用例回放每一步的 UI 截图
- 用 `make open` 看汇总报告
