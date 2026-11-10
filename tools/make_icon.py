"""
按 tiann/KernelSU 上游原版图标重绘 iOS AppIcon。

上游来源（GPL-3.0）：
  manager/app/src/main/res/drawable/ic_launcher_foreground.xml
    viewport 108，group scale 0.135
      <path M 259 259 H 541 V 541 H 259 Z strokeWidth 18 />         描边方框
      <path M 257 257 H 407 V 407 H 257 V 257 Z fill />              方块 A（左上）
      <path M 393 393 H 543 V 543 H 393 V 393 Z fill />              方块 B（右下）
  manager/app/src/main/res/values/colors.xml
      ic_launcher_background  #FFFFFFFF
      ic_launcher_foreground  #FF1E110D

几何还原（108 视口，乘以 0.135 后）：
  描边框  34.965 .. 73.035   线宽 2.43
  方块 A  34.695 .. 54.945
  方块 B  53.055 .. 73.305
图形整体中心落在 54.135（即画布正中）。

iOS 1024 尺度再按 UPSCALE 放大，让图形占比接近 iOS 惯例（约 61%）。
"""
from PIL import Image, ImageDraw

# ---- 上游参数（原文照抄，勿改）----
VIEWPORT = 108.0
GROUP_SCALE = 0.135
STROKE_RAW = 18.0

FRAME_MIN_RAW, FRAME_MAX_RAW = 259.0, 541.0     # 描边方框
BOX_A_MIN_RAW, BOX_A_MAX_RAW = 257.0, 407.0     # 方块 A
BOX_B_MIN_RAW, BOX_B_MAX_RAW = 393.0, 543.0     # 方块 B

BG_COLOR     = (255, 255, 255)     # ic_launcher_background #FFFFFFFF
FG_COLOR     = (0x1E, 0x11, 0x0D)  # ic_launcher_foreground #FF1E110D

# ---- 目标参数 ----
S = 1024
UPSCALE = 1.70      # 相对 iOS 原始映射的放大倍数
SS = 4              # 超采样倍数（抗锯齿）

unit = (S / VIEWPORT) * UPSCALE     # 1 个 viewport 单位 -> 1024 空间像素


def px(raw):
    """把上游 pathData 原始坐标转成 1024 画布上的像素坐标（保持中心对齐）。"""
    v = raw * GROUP_SCALE                    # 落到 108 视口
    return S / 2 + (v - VIEWPORT / 2) * unit


def main():
    img = Image.new("RGB", (S * SS, S * SS), BG_COLOR)
    d = ImageDraw.Draw(img)

    def box(raw_min, raw_max):
        a, b = px(raw_min), px(raw_max)
        return [a * SS, a * SS, b * SS, b * SS]

    stroke_w = STROKE_RAW * GROUP_SCALE * unit * SS

    # 1) 描边方框（stroke 居中，Pillow 的 rectangle 也是居中于边界线）
    d.rectangle(box(FRAME_MIN_RAW, FRAME_MAX_RAW),
                outline=FG_COLOR, width=max(1, int(round(stroke_w))))

    # 2) 方块 A（左上，填充）
    d.rectangle(box(BOX_A_MIN_RAW, BOX_A_MAX_RAW), fill=FG_COLOR)

    # 3) 方块 B（右下，填充）—— 覆盖在 A 与框之上，形成原版的错位叠压
    d.rectangle(box(BOX_B_MIN_RAW, BOX_B_MAX_RAW), fill=FG_COLOR)

    out = img.resize((S, S), Image.LANCZOS)
    dst = r"D:\工作台\KernelSU-iOS\KernelSU\Resources\Assets.xcassets\AppIcon.appiconset\icon-1024.png"
    out.save(dst, optimize=True)
    print("icon written:", dst)
    print("图形包围盒 x:", round(px(BOX_A_MIN_RAW), 1), "->", round(px(BOX_B_MAX_RAW), 1))


if __name__ == "__main__":
    main()
