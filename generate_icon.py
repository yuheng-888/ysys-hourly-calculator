#!/usr/bin/env python3
"""
生成时薪计算器应用图标
使用 Pillow 绘制靛蓝/紫色渐变背景 + 音频波形 + 时钟元素
"""
import math
import os

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("需要安装 Pillow: pip3 install Pillow")
    exit(1)

def create_icon(size):
    """创建指定尺寸的应用图标"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 圆角矩形背景（macOS 风格）
    corner = size // 5
    # 靛蓝到紫色渐变背景
    for y in range(size):
        ratio = y / size
        r = int(79 * (1 - ratio) + 128 * ratio)   # indigo → purple
        g = int(70 * (1 - ratio) + 0 * ratio)
        b = int(229 * (1 - ratio) + 200 * ratio)
        draw.rectangle([0, y, size, y + 1], fill=(r, g, b, 255))
    
    # 应用圆角蒙版
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=corner, fill=255)
    img.putalpha(mask)
    
    # 绘制音频波形（中间区域）
    center_y = size * 0.42
    wave_width = size * 0.6
    start_x = size * 0.2
    num_bars = 9
    bar_width = wave_width / (num_bars * 2)
    heights = [0.15, 0.25, 0.4, 0.55, 0.65, 0.55, 0.4, 0.25, 0.15]
    
    for i, h in enumerate(heights):
        x = start_x + i * (wave_width / (num_bars - 1)) - bar_width / 2
        bar_h = size * h * 0.45
        y1 = center_y - bar_h / 2
        y2 = center_y + bar_h / 2
        # 白色半透明波形条
        draw.rounded_rectangle(
            [int(x), int(y1), int(x + bar_width), int(y2)],
            radius=int(bar_width / 2),
            fill=(255, 255, 255, 220)
        )
    
    # 绘制底部 ¥ 符号（尺寸太小时跳过）
    if size >= 64:
        try:
            font_size = int(size * 0.22)
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except:
            font = ImageFont.load_default()
        
        text = "¥"
        bbox = draw.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        tx = (size - tw) / 2
        ty = size * 0.68
        draw.text((tx, ty), text, fill=(255, 255, 255, 240), font=font)
    
    return img

def main():
    # 输出目录
    output_dir = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "autuo sound time v2",
        "Assets.xcassets",
        "AppIcon.appiconset"
    )
    os.makedirs(output_dir, exist_ok=True)
    
    # macOS 需要的所有尺寸
    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    
    print("生成应用图标...")
    for filename, px_size in sizes.items():
        icon = create_icon(px_size)
        path = os.path.join(output_dir, filename)
        icon.save(path, "PNG")
        print(f"  {filename} ({px_size}x{px_size})")
    
    print(f"\n图标已保存到: {output_dir}")
    print("共生成 10 个图标文件")

if __name__ == "__main__":
    main()
