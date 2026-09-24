#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT_PREFS = ROOT / "Preferences" / "Resources"
OUT_LAYOUT = ROOT / "layout" / "Library" / "PreferenceLoader" / "Preferences"

OUT_PREFS.mkdir(parents=True, exist_ok=True)
OUT_LAYOUT.mkdir(parents=True, exist_ok=True)

def create_icon(size: int) -> Image.Image:
    # High resolution canvas for supersampling
    scale = 4
    base_sz = size * scale
    img = Image.new("RGBA", (base_sz, base_sz), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Outer squircle gradient background (Deep Cyan/Sapphire Crystal)
    bg_col_top = (16, 32, 60, 255)
    bg_col_bottom = (6, 12, 28, 255)
    
    # Draw vertical gradient
    for y in range(base_sz):
        ratio = y / float(base_sz)
        r = int(bg_col_top[0] * (1 - ratio) + bg_col_bottom[0] * ratio)
        g = int(bg_col_top[1] * (1 - ratio) + bg_col_bottom[1] * ratio)
        b = int(bg_col_top[2] * (1 - ratio) + bg_col_bottom[2] * ratio)
        draw.line([(0, y), (base_sz, y)], fill=(r, g, b, 255))

    # Mask with smooth continuous rounded rectangle
    mask = Image.new("L", (base_sz, base_sz), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner_r = int(base_sz * 0.23)
    mask_draw.rounded_rectangle((0, 0, base_sz - 1, base_sz - 1), radius=corner_r, fill=255)

    img.putalpha(mask)
    draw = ImageDraw.Draw(img)

    # Diagonal glass glare
    glare = Image.new("RGBA", (base_sz, base_sz), (0, 0, 0, 0))
    glare_draw = ImageDraw.Draw(glare)
    glare_draw.polygon([
        (0, 0),
        (base_sz, 0),
        (0, base_sz)
    ], fill=(255, 255, 255, 30))
    img = Image.alpha_composite(img, glare)
    draw = ImageDraw.Draw(img)

    # Draw 2x2 grid representing big grid apps inside liquid glass container
    pad = int(base_sz * 0.22)
    gap = int(base_sz * 0.08)
    tile_sz = (base_sz - pad * 2 - gap) // 2
    tile_r = int(tile_sz * 0.28)

    colors = [
        ((56, 189, 248, 240), (14, 116, 144, 240)),  # Cyan / Sky
        ((96, 165, 250, 240), (29, 78, 216, 240)),   # Blue
        ((129, 140, 248, 240), (67, 56, 202, 240)),  # Indigo
        ((192, 132, 252, 240), (126, 34, 206, 240)), # Purple
    ]

    coords = [
        (pad, pad),
        (pad + tile_sz + gap, pad),
        (pad, pad + tile_sz + gap),
        (pad + tile_sz + gap, pad + tile_sz + gap)
    ]

    for (x, y), (c_top, c_bot) in zip(coords, colors):
        # Tile shadow
        draw.rounded_rectangle((x + 2 * scale, y + 3 * scale, x + tile_sz + 2 * scale, y + tile_sz + 3 * scale),
                               radius=tile_r, fill=(0, 0, 0, 90))
        # Tile body
        draw.rounded_rectangle((x, y, x + tile_sz, y + tile_sz),
                               radius=tile_r, fill=c_top)
        # Tile inner shine
        draw.line([(x + tile_r, y + 2 * scale), (x + tile_sz - tile_r, y + 2 * scale)],
                  fill=(255, 255, 255, 120), width=max(1, scale))

    # Border stroke
    draw.rounded_rectangle((0, 0, base_sz - 1, base_sz - 1), radius=corner_r,
                           outline=(255, 255, 255, 60), width=max(1, scale))

    return img.resize((size, size), Image.Resampling.LANCZOS)

def create_banner(width: int, height: int) -> Image.Image:
    scale = 2
    bw = width * scale
    bh = height * scale
    banner = Image.new("RGBA", (bw, bh), (0, 0, 0, 255))
    draw = ImageDraw.Draw(banner)

    # Gradient background
    for y in range(bh):
        ratio = y / float(bh)
        r = int(10 * (1 - ratio) + 4 * ratio)
        g = int(24 * (1 - ratio) + 8 * ratio)
        b = int(50 * (1 - ratio) + 20 * ratio)
        draw.line([(0, y), (bw, y)], fill=(r, g, b, 255))

    # Glowing decorative orbs
    glow = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((bw - int(bh * 0.9), -int(bh * 0.2), bw + int(bh * 0.3), int(bh * 0.9)),
                      fill=(56, 189, 248, 45))
    glow_draw.ellipse((bw - int(bh * 1.4), int(bh * 0.1), bw - int(bh * 0.2), int(bh * 1.2)),
                      fill=(99, 102, 241, 35))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=25 * scale))
    banner = Image.alpha_composite(banner, glow)
    draw = ImageDraw.Draw(banner)

    # Stylized grid outline in banner right side
    grid_x = bw - int(bh * 1.0)
    grid_y = int(bh * 0.18)
    card_w = int(bh * 0.68)
    card_h = int(bh * 0.68)
    card_r = int(card_w * 0.22)
    
    # Glass card behind
    draw.rounded_rectangle((grid_x, grid_y, grid_x + card_w, grid_y + card_h),
                           radius=card_r, fill=(255, 255, 255, 18),
                           outline=(255, 255, 255, 50), width=2 * scale)

    # 4 mini app tiles inside card
    t_pad = int(card_w * 0.16)
    t_gap = int(card_w * 0.12)
    t_sz = (card_w - t_pad * 2 - t_gap) // 2
    t_r = int(t_sz * 0.26)
    
    t_coords = [
        (grid_x + t_pad, grid_y + t_pad),
        (grid_x + t_pad + t_sz + t_gap, grid_y + t_pad),
        (grid_x + t_pad, grid_y + t_pad + t_sz + t_gap),
        (grid_x + t_pad + t_sz + t_gap, grid_y + t_pad + t_sz + t_gap)
    ]
    t_colors = [
        (56, 189, 248, 220),
        (96, 165, 250, 220),
        (129, 140, 248, 220),
        (192, 132, 252, 220)
    ]
    for (tx, ty), col in zip(t_coords, t_colors):
        draw.rounded_rectangle((tx, ty, tx + t_sz, ty + t_sz), radius=t_r, fill=col)

    return banner.resize((width, height), Image.Resampling.LANCZOS)

def main():
    print("Generating ListApp icons...")
    icon29 = create_icon(29)
    icon58 = create_icon(58)
    icon87 = create_icon(87)

    icon29.save(OUT_PREFS / "icon.png")
    icon58.save(OUT_PREFS / "icon@2x.png")
    icon87.save(OUT_PREFS / "icon@3x.png")

    icon29.save(OUT_LAYOUT / "icon.png")
    icon58.save(OUT_LAYOUT / "icon@2x.png")

    print("Generating ListApp banner...")
    banner1 = create_banner(400, 160)
    banner2 = create_banner(800, 320)
    banner1.save(OUT_PREFS / "banner.png")
    banner2.save(OUT_PREFS / "banner@2x.png")

    print("Assets generated successfully!")

if __name__ == "__main__":
    main()
