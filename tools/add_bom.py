import io, glob, os

# PowerShell 5.1 在读取无 BOM 的 UTF-8 时会按 ANSI(GBK) 解码，
# 中文全角标点会把引号配对搞乱，导致解析器报假语法错。统一补 UTF-8 BOM。
targets = [
    r"D:\工作台\KernelSU-iOS\tools\push_and_build.ps1",
    r"D:\工作台\KernelSU-iOS\tools\push_to_github.ps1",
]

for p in targets:
    if not os.path.exists(p):
        print("skip (missing):", p)
        continue
    raw = open(p, "rb").read()
    if raw.startswith(b"\xef\xbb\xbf"):
        print("already BOM:", os.path.basename(p))
        continue
    text = raw.decode("utf-8")
    with open(p, "wb") as f:
        f.write(b"\xef\xbb\xbf")
        f.write(text.encode("utf-8"))
    print("wrote BOM:", os.path.basename(p), len(text), "chars")
