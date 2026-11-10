"""验证 Swift 里 KsuLogo 的归一化参数与上游 pathData 一致，并渲染对照图。"""
from PIL import Image, ImageDraw

VIEWPORT = 108.0
GROUP_SCALE = 0.135

def norm(raw):
    return raw * GROUP_SCALE / VIEWPORT

raw = {
    "frame_min": 259.0, "frame_max": 541.0, "stroke": 18.0,
    "a_min": 257.0, "a_max": 407.0,
    "b_min": 393.0, "b_max": 543.0,
}

n = {k: norm(v) for k, v in raw.items()}

print("=== 上游归一化坐标 ===")
for k in ("frame_min", "frame_max", "stroke", "a_min", "a_max", "b_min", "b_max"):
    print("  %-10s %.6f" % (k, n[k]))

print()
print("=== Swift 常量核对 ===")
swift = {
    "minV": 0.3125, "span": 0.375,
    "frameMin": 0.32375, "frameSize": 0.3525, "strokeW": 0.0225,
    "aMin": 0.32125, "boxSize": 0.1875, "bMin": 0.49125,
}
expect = {
    "minV": n["frame_min"] - n["stroke"] / 2,
    "span": (n["frame_max"] + n["stroke"] / 2) - (n["frame_min"] - n["stroke"] / 2),
    "frameMin": n["frame_min"],
    "frameSize": n["frame_max"] - n["frame_min"],
    "strokeW": n["stroke"],
    "aMin": n["a_min"],
    "boxSize": n["a_max"] - n["a_min"],
    "bMin": n["b_min"],
}
ok = True
for k, v in expect.items():
    d = abs(swift[k] - v)
    flag = "OK " if d < 1e-9 else "差异"
    if d >= 1e-9:
        ok = False
    print("  %-10s swift=%.6f  computed=%.6f  %s" % (k, swift[k], v, flag))
print()
print("一致性:", "全部通过" if ok else "有不一致")
