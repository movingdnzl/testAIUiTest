#!/usr/bin/env python3
"""从 xcresulttool 的 JSON 输出生成 Markdown + HTML 测试报告。

报告按「页面/功能」分组，每条用例用中文说明测的是什么功能，
通过/失败用颜色和图标一眼可见。

支持 Xcode 16 的 `test-results summary` / `test-results tests` 格式。
"""
import json
import os
import datetime

# ---- 页面顺序与中文名 ----
PAGES = [
    ("Login", "登录页"),
    ("Counter", "计数器页"),
    ("Todo", "待办页"),
    ("Form", "表单页"),
    ("Settings", "设置页"),
]

# ---- 测试方法名 -> (页面key, 功能中文描述) ----
# 方法名在整个工程内唯一，直接按方法名映射。
FEATURE_MAP = {
    # 登录页
    "testEmptyValidation":     ("Login", "账号或密码为空时，提示「必填」"),
    "testInvalidCredentials":  ("Login", "输入错误密码时，提示「凭证无效」"),
    "testSuccessfulLogin":     ("Login", "输入正确账号密码 admin/123456，登录成功并显示欢迎语"),
    # 计数器页
    "testIncrement":           ("Counter", "连续点「+」，计数正确累加"),
    "testDecrement":           ("Counter", "点「-」，计数正确递减"),
    "testNoNegative":          ("Counter", "计数为 0 时再减，不会变成负数"),
    "testReset":               ("Counter", "点「重置」，计数归零"),
    # 待办页
    "testEmptyState":          ("Todo", "没有任务时，显示空态提示"),
    "testAddTask":             ("Todo", "输入内容点「新增」，任务出现在列表"),
    "testToggleTask":          ("Todo", "点击任务，切换为「已完成」状态"),
    "testDeleteTask":          ("Todo", "左滑任务点删除，任务被移除"),
    # 表单页
    "testFillAndSave":         ("Form", "填写姓名和邮箱后保存，摘要正确显示输入内容"),
    "testToggleNotifications": ("Form", "关闭通知开关后保存，摘要显示 notif off"),
    "testAdjustAgeSlider":     ("Form", "拖动年龄滑块后保存，摘要包含年龄"),
    # 设置页
    "testToggleDarkMode":      ("Settings", "切换「深色模式」开关，状态正确改变"),
    "testChangeAccent":        ("Settings", "切换主题分段控件，选中项正确变化"),
    "testResetCancel":         ("Settings", "重置弹窗点「取消」，状态保持不变"),
    "testResetConfirm":        ("Settings", "重置弹窗点「确认」，状态变为已重置"),
}

# ---- 失败时的「人话提示」：该功能挂了通常要排查什么 ----
FAILURE_HINT = {
    "testEmptyValidation":     "登录按钮的空值校验没生效，或提示文案与预期不一致。检查 LoginView 的 login() 校验逻辑。",
    "testInvalidCredentials":  "错误密码没有被拦截。检查账号密码比对逻辑与错误提示。",
    "testSuccessfulLogin":     "正确账号密码没能登录成功，或欢迎语没出现。检查登录成功分支与 login_welcome_label。",
    "testIncrement":           "点「+」计数没正确累加。检查 counter_increment_button 的加法逻辑。",
    "testDecrement":           "点「-」计数没正确递减。检查 counter_decrement_button 的减法逻辑。",
    "testNoNegative":          "计数在 0 时被减成了负数。检查递减前的 count > 0 判断。",
    "testReset":               "重置没有把计数归零。检查 counter_reset_button 的 reset 逻辑。",
    "testEmptyState":          "无任务时没显示空态提示。检查 items 为空时的 todo_empty_label 分支。",
    "testAddTask":             "新增的任务没出现在列表。检查 addItem() 与列表渲染。",
    "testToggleTask":          "点击任务没能切换完成状态。检查 toggle() 逻辑与点击手势。",
    "testDeleteTask":          "滑动删除失败，或删除按钮文案不是 'Delete'。检查 onDelete 与滑动删除交互。",
    "testFillAndSave":         "填写后保存的摘要不含输入内容。检查 save() 拼接与 form_summary_label。",
    "testToggleNotifications": "关闭通知开关后摘要没显示 off。检查 toggle 绑定与 save() 中通知状态。",
    "testAdjustAgeSlider":     "拖动滑块后保存摘要没体现年龄。检查 form_age_slider 绑定与 save()。",
    "testToggleDarkMode":      "深色模式开关状态没变化。检查 settings_dark_toggle 绑定的 isDarkMode。",
    "testChangeAccent":        "分段控件切换后选中项没变。检查 settings_accent_picker 的 selection 绑定。",
    "testResetCancel":         "重置弹窗点取消后状态却变了。检查 Cancel 按钮不应触发重置。",
    "testResetConfirm":        "重置弹窗点确认后状态没更新为已重置。检查 Confirm 按钮的重置逻辑。",
}

# xcresult 里的用例结果取值
RESULTS = {"Passed", "Failed", "Skipped", "Expected Failure"}


def esc(s):
    """HTML 转义，防止失败信息里的特殊字符破坏页面。"""
    return (str(s).replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace('"', "&quot;"))


def load(env_key):
    raw = os.environ.get(env_key, "").strip()
    if not raw:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def collect_failures(node, msgs):
    """从一个用例节点里递归收集所有失败信息文本。"""
    if isinstance(node, dict):
        if node.get("nodeType") in ("Failure Message", "Failure") and node.get("name"):
            msgs.append(node["name"].strip())
        for c in node.get("children") or node.get("subtests") or []:
            collect_failures(c, msgs)
    elif isinstance(node, list):
        for c in node:
            collect_failures(c, msgs)


def is_test_case(node):
    if node.get("nodeType") == "Test Case":
        return True
    name = node.get("name", "")
    return node.get("result") in RESULTS and name.endswith("()")


def walk_tests(node, cases):
    """递归遍历 test-results tests 树，收集用例（含失败信息）。"""
    if isinstance(node, list):
        for c in node:
            walk_tests(c, cases)
        return
    if not isinstance(node, dict):
        return
    if is_test_case(node):
        failures = []
        collect_failures(node, failures)
        cases.append({
            "name": node.get("name", "?"),
            "result": node.get("result", "?"),
            "duration": node.get("duration", ""),
            "failures": failures,
        })
        return
    for c in node.get("children") or node.get("subtests") or []:
        walk_tests(c, cases)


def collect_cases(tests_json):
    cases = []
    if not tests_json:
        return cases
    root = tests_json.get("testNodes") or tests_json.get("children") or tests_json
    walk_tests(root, cases)
    seen, uniq = set(), []
    for c in cases:
        if c["name"] not in seen:
            seen.add(c["name"])
            uniq.append(c)
    return uniq


def method_key(name):
    """把 'testSuccessfulLogin()' 归一化为 'testSuccessfulLogin'。"""
    return name.split("(")[0].strip()


def build_groups(cases):
    """把用例按页面归组，附上中文功能描述。"""
    groups = {key: {"cn": cn, "items": []} for key, cn in PAGES}
    other = {"cn": "其他", "items": []}
    for c in cases:
        key = method_key(c["name"])
        page, desc = FEATURE_MAP.get(key, (None, c["name"]))
        item = {
            "desc": desc,
            "result": c["result"],
            "raw": key,
            "duration": c["duration"],
            "failures": c.get("failures", []),
            "hint": FAILURE_HINT.get(key, ""),
        }
        (groups.get(page) or other)["items"].append(item)
    ordered = [(k, groups[k]) for k, _ in PAGES if groups[k]["items"]]
    if other["items"]:
        ordered.append(("Other", other))
    return ordered


def main():
    summary = load("SUMMARY_JSON")
    tests = load("TESTS_JSON")
    test_exit = os.environ.get("TEST_EXIT", "0")
    md_path = os.environ["REPORT_MD"]
    html_path = os.environ["REPORT_HTML"]
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    cases = collect_cases(tests)
    total = passed = failed = skipped = 0
    if summary:
        total = summary.get("totalTestCount", 0)
        passed = summary.get("passedTests", 0)
        failed = summary.get("failedTests", 0)
        skipped = summary.get("skippedTests", 0)
    if not summary and cases:
        total = len(cases)
        passed = sum(1 for c in cases if c["result"] == "Passed")
        failed = sum(1 for c in cases if c["result"] == "Failed")
        skipped = sum(1 for c in cases if c["result"] == "Skipped")

    overall = "全部通过" if (failed == 0 and test_exit == "0") else "存在失败"
    overall_ok = (failed == 0 and test_exit == "0")
    rate = f"{(passed / total * 100):.0f}%" if total else "N/A"
    groups = build_groups(cases)

    # ---------------- Markdown ----------------
    md = [f"# UI 自动化测试报告\n",
          f"- 生成时间：{now}",
          f"- 总体结果：**{overall}**",
          f"- 通过 {passed} / 共 {total}（通过率 {rate}）  失败 {failed}  跳过 {skipped}\n"]
    for _, g in groups:
        gp = sum(1 for i in g["items"] if i["result"] == "Passed")
        md.append(f"## {g['cn']}  （{gp}/{len(g['items'])} 通过）\n")
        for i in g["items"]:
            mark = {"Passed": "✅ 通过", "Failed": "❌ 失败", "Skipped": "⏭️ 跳过"}.get(i["result"], i["result"])
            md.append(f"- {mark} — {i['desc']}")
            if i["result"] == "Failed":
                if i["hint"]:
                    md.append(f"    - 💡 提示：{i['hint']}")
                for fm in i["failures"]:
                    md.append(f"    - 🔍 失败信息：`{fm}`")
        md.append("")
    with open(md_path, "w") as f:
        f.write("\n".join(md))

    # ---------------- HTML ----------------
    banner_bg = "#e8f5e9" if overall_ok else "#ffebee"
    banner_fg = "#2e7d32" if overall_ok else "#c62828"
    banner_icon = "✅" if overall_ok else "⚠️"

    sections = ""
    for _, g in groups:
        items = g["items"]
        gp = sum(1 for i in items if i["result"] == "Passed")
        gf = sum(1 for i in items if i["result"] == "Failed")
        head_color = "#c62828" if gf else "#2e7d32"
        rows = ""
        for i in items:
            r = i["result"]
            if r == "Passed":
                icon, txt, rowbg, tc = "✅", "通过", "#ffffff", "#2e7d32"
            elif r == "Failed":
                icon, txt, rowbg, tc = "❌", "失败", "#fff5f5", "#c62828"
            elif r == "Skipped":
                icon, txt, rowbg, tc = "⏭️", "跳过", "#fffdf3", "#f9a825"
            else:
                icon, txt, rowbg, tc = "•", r, "#fff", "#555"

            reason = ""
            if r == "Failed":
                parts = ""
                if i["hint"]:
                    parts += f"<div class='hint'>💡 <b>可能原因：</b>{esc(i['hint'])}</div>"
                for fm in i["failures"]:
                    parts += f"<div class='fmsg'>🔍 {esc(fm)}</div>"
                if not i["failures"]:
                    parts += "<div class='fmsg'>🔍 未从 xcresult 提取到具体断言信息，可用 Xcode 打开 xcresult 查看录屏。</div>"
                reason = (f"<tr style='background:{rowbg}'><td></td>"
                          f"<td colspan='2' class='reason'>{parts}</td></tr>")

            rows += (f"<tr style='background:{rowbg}'>"
                     f"<td class='st' style='color:{tc}'>{icon} {txt}</td>"
                     f"<td class='desc'>{esc(i['desc'])}</td>"
                     f"<td class='raw'>{esc(i['raw'])}</td></tr>{reason}")
        sections += f"""
        <div class="card">
          <div class="card-head">
            <span class="page">{g['cn']}</span>
            <span class="count" style="color:{head_color}">{gp}/{len(items)} 通过{'' if not gf else f' · {gf} 失败'}</span>
          </div>
          <table>
            <thead><tr><th style="width:90px">结果</th><th>测试的功能</th><th style="width:200px">用例</th></tr></thead>
            <tbody>{rows}</tbody>
          </table>
        </div>"""

    html = f"""<!doctype html><html lang="zh"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>UI 自动化测试报告</title>
<style>
:root{{color-scheme:light}}
*{{box-sizing:border-box}}
body{{font-family:-apple-system,"PingFang SC",Helvetica,Arial,sans-serif;margin:0;background:#f5f6f8;color:#1c1c1e}}
.wrap{{max-width:900px;margin:0 auto;padding:32px 20px 60px}}
h1{{font-size:22px;margin:0 0 4px}}
.time{{color:#8a8a8e;font-size:13px;margin-bottom:20px}}
.banner{{background:{banner_bg};color:{banner_fg};border-radius:14px;padding:20px 24px;margin-bottom:14px;display:flex;align-items:center;gap:16px}}
.banner .big{{font-size:30px}}
.banner .title{{font-size:20px;font-weight:700}}
.banner .sub{{font-size:14px;opacity:.9;margin-top:2px}}
.kpis{{display:flex;gap:10px;margin-bottom:24px;flex-wrap:wrap}}
.kpi{{flex:1;min-width:120px;background:#fff;border-radius:12px;padding:14px 16px;box-shadow:0 1px 3px rgba(0,0,0,.06)}}
.kpi .n{{font-size:26px;font-weight:700}}
.kpi .l{{font-size:13px;color:#8a8a8e;margin-top:2px}}
.card{{background:#fff;border-radius:12px;box-shadow:0 1px 3px rgba(0,0,0,.06);margin-bottom:16px;overflow:hidden}}
.card-head{{display:flex;justify-content:space-between;align-items:center;padding:14px 18px;border-bottom:1px solid #f0f0f2}}
.card-head .page{{font-size:16px;font-weight:700}}
.card-head .count{{font-size:14px;font-weight:600}}
table{{border-collapse:collapse;width:100%}}
th,td{{text-align:left;padding:11px 18px;font-size:14px;border-bottom:1px solid #f4f4f6}}
th{{background:#fafafa;color:#8a8a8e;font-weight:600;font-size:12px}}
tr:last-child td{{border-bottom:none}}
.st{{font-weight:700;white-space:nowrap}}
.desc{{color:#1c1c1e}}
.raw{{color:#b0b0b5;font-family:ui-monospace,Menlo,monospace;font-size:12px}}
.reason{{padding-top:0;padding-bottom:12px}}
.hint{{background:#fff3e0;border-left:3px solid #fb8c00;padding:8px 12px;border-radius:6px;font-size:13px;color:#5d4037;margin-bottom:6px}}
.fmsg{{background:#fdecea;border-left:3px solid #e53935;padding:8px 12px;border-radius:6px;font-size:12px;color:#7a2a25;font-family:ui-monospace,Menlo,monospace;white-space:pre-wrap;word-break:break-word;margin-bottom:6px}}
.legend{{font-size:13px;color:#8a8a8e;margin-top:18px}}
</style></head><body>
<div class="wrap">
  <h1>UI 自动化测试报告</h1>
  <div class="time">{now}</div>

  <div class="banner">
    <div class="big">{banner_icon}</div>
    <div>
      <div class="title">{overall}</div>
      <div class="sub">共 {total} 项功能测试，通过率 {rate}</div>
    </div>
  </div>

  <div class="kpis">
    <div class="kpi"><div class="n">{total}</div><div class="l">功能总数</div></div>
    <div class="kpi"><div class="n" style="color:#2e7d32">{passed}</div><div class="l">通过</div></div>
    <div class="kpi"><div class="n" style="color:#c62828">{failed}</div><div class="l">失败</div></div>
    <div class="kpi"><div class="n" style="color:#f9a825">{skipped}</div><div class="l">跳过</div></div>
  </div>

  {sections}

  <div class="legend">✅ 通过 = 该功能按预期工作　❌ 失败 = 该功能有问题需修复　⏭️ 跳过 = 未执行</div>
</div>
</body></html>"""
    with open(html_path, "w") as f:
        f.write(html)

    print(f"报告已生成：{overall}（{passed}/{total} 通过）")


if __name__ == "__main__":
    main()
