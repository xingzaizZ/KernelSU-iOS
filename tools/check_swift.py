import os

root = r"D:\工作台\KernelSU-iOS\KernelSU"
issues = []
for name in sorted(os.listdir(root)):
    if not name.endswith(".swift"):
        continue
    p = os.path.join(root, name)
    s = open(p, encoding="utf-8").read()
    for a, b, label in [("{", "}", "curly"), ("(", ")", "paren"), ("[", "]", "bracket")]:
        d = s.count(a) - s.count(b)
        if d != 0:
            issues.append("%s: %s 不平衡 %+d" % (name, label, d))
    if s.count('"""') % 2:
        issues.append("%s: 多行字符串定界符奇数" % name)
    print("%-24s lines=%4d braces=%+d" % (name, len(s.splitlines()), s.count("{") - s.count("}")))

print("\n--- 问题 ---")
print("\n".join(issues) if issues else "无明显问题")
