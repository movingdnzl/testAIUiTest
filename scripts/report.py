#!/usr/bin/env python3
"""从 xcresulttool 的 JSON 输出生成 Markdown + HTML 测试报告。

支持 Xcode 16 的 `test-results summary` / `test-results tests` 格式，
无法解析时回退到仅用退出码给出概要。
"""
import json
import os
import datetime


def load(env_key):
    raw = os.environ.get(env_key, "").strip()
    if not raw:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def walk_tests(node, cases):
    """递归遍历 test-results tests 树，收集叶子用例。"""
    if isinstance(node, dict):
        children = node.get("children") or node.get("subtests")
        if children:
            for c in children:
                walk_tests(c, cases)
        elif node.get("nodeType") in ("Test Case", "Test", None) and node.get("name"):
            if node.get("result") in ("Passed", "Failed", "Skipped", "Expected Failure"):
                cases.append({
                    "name": node.get("name", "?"),
                    "result": node.get("result", "?"),
                    "duration": node.get("duration", ""),
                })
        # 有些格式把 name/result 放在含 children 的同一节点，已在上面处理
    elif isinstance(node, list):
        for c in node:
            walk_tests(c, cases)


def collect_cases(tests_json):
    cases = []
    if not tests_json:
        return cases
    root = tests_json.get("testNodes") or tests_json.get("children") or tests_json
    walk_tests(root, cases)
    # 去重
    seen = set()
    uniq = []
    for c in cases:
        key = c["name"]
        if key not in seen:
            seen.add(key)
            uniq.append(c)
    return uniq


def main():
    summary = load("SUMMARY_JSON")
    tests = load("TESTS_JSON")
    test_exit = os.environ.get("TEST_EXIT", "0")
    md_path = os.environ["REPORT_MD"]
    html_path = os.environ["REPORT_HTML"]
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    total = passed = failed = skipped = 0
    if summary:
        total = summary.get("totalTestCount", 0)
        passed = summary.get("passedTests", 0)
        failed = summary.get("failedTests", 0)
        skipped = summary.get("skippedTests", 0)

    cases = collect_cases(tests)
    if not summary and cases:
        total = len(cases)
        passed = sum(1 for c in cases if c["result"] == "Passed")
        failed = sum(1 for c in cases if c["result"] == "Failed")
        skipped = sum(1 for c in cases if c["result"] == "Skipped")

    overall = "PASSED" if (failed == 0 and test_exit == "0") else "FAILED"
    rate = f"{(passed / total * 100):.1f}%" if total else "N/A"

    # ---- Markdown ----
    md = []
    md.append(f"# UI 自动化测试报告\n")
    md.append(f"- 生成时间: {now}")
    md.append(f"- 总体结果: **{overall}**")
    md.append(f"- 用例总数: {total}  |  通过: {passed}  |  失败: {failed}  |  跳过: {skipped}")
    md.append(f"- 通过率: {rate}\n")
    md.append("## 用例明细\n")
    if cases:
        md.append("| 用例 | 结果 | 耗时 |")
        md.append("| --- | --- | --- |")
        for c in cases:
            icon = {"Passed": "PASS", "Failed": "FAIL", "Skipped": "SKIP"}.get(c["result"], c["result"])
            md.append(f"| {c['name']} | {icon} | {c['duration']} |")
    else:
        md.append("_未能从 xcresult 解析到用例明细，请用 `xcrun xcresulttool` 或 Xcode 打开 xcresult 查看。_")
    md.append("")
    with open(md_path, "w") as f:
        f.write("\n".join(md))

    # ---- HTML ----
    color = "#2e7d32" if overall == "PASSED" else "#c62828"
    rows = ""
    for c in cases:
        rc = {"Passed": "#2e7d32", "Failed": "#c62828", "Skipped": "#f9a825"}.get(c["result"], "#555")
        rows += f"<tr><td>{c['name']}</td><td style='color:{rc};font-weight:600'>{c['result']}</td><td>{c['duration']}</td></tr>"
    if not rows:
        rows = "<tr><td colspan=3>未解析到用例明细</td></tr>"

    html = f"""<!doctype html><html lang="zh"><head><meta charset="utf-8">
<title>UI 自动化测试报告</title>
<style>
body{{font-family:-apple-system,Helvetica,Arial,sans-serif;margin:40px;color:#222}}
h1{{margin-bottom:4px}}
.badge{{display:inline-block;padding:6px 14px;border-radius:6px;color:#fff;background:{color};font-weight:700}}
.stats{{margin:16px 0;font-size:15px}}
.stats span{{margin-right:18px}}
table{{border-collapse:collapse;width:100%;margin-top:12px}}
th,td{{border:1px solid #e0e0e0;padding:8px 12px;text-align:left;font-size:14px}}
th{{background:#fafafa}}
.time{{color:#888;font-size:13px}}
</style></head><body>
<h1>UI 自动化测试报告</h1>
<div class="time">{now}</div>
<p class="badge">{overall}</p>
<div class="stats">
<span>总数: <b>{total}</b></span>
<span style="color:#2e7d32">通过: <b>{passed}</b></span>
<span style="color:#c62828">失败: <b>{failed}</b></span>
<span style="color:#f9a825">跳过: <b>{skipped}</b></span>
<span>通过率: <b>{rate}</b></span>
</div>
<table><thead><tr><th>用例</th><th>结果</th><th>耗时</th></tr></thead>
<tbody>{rows}</tbody></table>
</body></html>"""
    with open(html_path, "w") as f:
        f.write(html)

    print(f"报告已生成: {overall}  ({passed}/{total} 通过)")


if __name__ == "__main__":
    main()
