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
make test          # 启动模拟器 → 录屏 → 跑 UI 测试 → 生成报告+视频
make demo          # 同上，但放慢节奏（每步暂停 0.6s），肉眼更好看清操作
make open          # 浏览器打开 HTML 报告
make video         # 打开自动操作录屏 build/demo.mp4
make result        # 用 Xcode 打开 xcresult（含每个用例逐步截图）
```

指定模拟器机型 / 关闭录屏 / 自定义放慢秒数：

```bash
SIMULATOR="iPhone 15" make test
RECORD=0 make test                 # 不录屏
UITEST_SLOWMO=1.0 make test        # 每步暂停 1 秒
```

## 报告输出

跑完后在 `build/` 目录：
- `report.html` — 图形化报告（按页面分组、通过率、失败原因+提示）
- `report.md` — Markdown 报告
- `demo.mp4` — **自动操作全过程录屏**，直观展示机器人操作 App
- `TestResults.xcresult` — Xcode 原生结果包，含每个用例的**逐步截图和失败录屏**

## “模拟真人操作”是怎么实现的

XCUITest 通过系统 Accessibility 框架驱动界面，`tap()` / `typeText()` / `swipeLeft()`
会在**真实运行的模拟器/真机**上产生真实的点击、键入、滑动事件——就是机器人替人操作 App。

三种「看得见」的方式：
1. **实时观看**：`make test` 时模拟器自动弹出，肉眼可见自动操作
2. **录屏视频**：跑完得到 `build/demo.mp4`，整段自动操作过程，可分享
3. **逐步截图**：每个用例自动截图并附进 xcresult，`make result` 逐步回放；失败也带最终界面

## 真机运行（可选）

操作代码与模拟器完全一致，只需换 destination 并配置签名：

1. 真机连电脑并在设备上「信任此电脑」
2. 拿到设备 UDID：`xcrun xctrace list devices`
3. 在 `project.yml` 的 target settings 里加签名：
   ```yaml
   DEVELOPMENT_TEAM: <你的 Apple Team ID>
   CODE_SIGNING_ALLOWED: YES
   CODE_SIGN_STYLE: Automatic
   ```
4. 运行时指定真机：
   ```bash
   xcodegen generate
   xcodebuild test -project UITestDemo.xcodeproj -scheme UITestDemo \
     -destination 'platform=iOS,id=<设备UDID>' \
     -resultBundlePath build/TestResults.xcresult
   ```
> 真机录屏用 Xcode 或 QuickTime；simctl 的 recordVideo 仅支持模拟器。
