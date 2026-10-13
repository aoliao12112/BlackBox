"""Generate the 35 deterministic synthetic business-card fixtures."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
GROUND_TRUTH = ROOT / "Tests" / "GroundTruth"
FONT_CANDIDATES = [
    Path(r"C:\Windows\Fonts\msyh.ttc"),
    Path(r"C:\Windows\Fonts\simhei.ttf"),
    Path(r"C:\Windows\Fonts\arial.ttf"),
]


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in FONT_CANDIDATES:
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def field_lines(data: dict) -> list[tuple[str, str]]:
    labels = [
        ("name", "Name"), ("company", "Company"), ("jobTitle", "Title"),
        ("department", "Dept"), ("mobile", "Mobile"), ("officePhone", "Tel"),
        ("fax", "Fax"), ("email", "Email"), ("website", "Web"),
        ("address", "Addr"), ("postalCode", "ZIP"),
    ]
    lines = [(label, str(data[key])) for key, label in labels if data.get(key)]
    lines.extend(("Email", str(value)) for value in data.get("additionalEmails", []))
    return lines


def make_card(spec: dict, index: int) -> Image.Image:
    category = spec["category"]
    vertical = category == "竖版/特殊布局"
    canvas_size = (900, 1300) if vertical else (1400, 900)
    card_box = (105, 95, 795, 1205) if vertical else (100, 107, 1300, 793)

    canvas = Image.new("RGB", canvas_size, (224, 229, 236))
    draw = ImageDraw.Draw(canvas)
    if category == "复杂Logo/背景":
        for x in range(0, canvas_size[0], 32):
            color = (214 + (x // 32) % 2 * 12, 224, 238)
            draw.rectangle((x, 0, x + 31, canvas_size[1]), fill=color)

    x0, y0, x1, y1 = card_box
    draw.rounded_rectangle((x0 + 14, y0 + 18, x1 + 14, y1 + 18), radius=22, fill=(120, 125, 135))
    draw.rounded_rectangle(card_box, radius=22, fill=(252, 252, 249), outline=(70, 82, 104), width=4)

    accent = [(26, 102, 180), (19, 133, 110), (146, 69, 156), (196, 91, 58)][index % 4]
    draw.rounded_rectangle((x0, y0, x0 + (24 if vertical else 30), y1), radius=12, fill=accent)
    draw.ellipse((x1 - 150, y0 + 38, x1 - 55, y0 + 133), fill=accent)
    draw.text((x1 - 126, y0 + 61), "BB", font=font(30), fill="white")

    truth = spec["ground_truth"]
    lines = field_lines(truth)
    usable_width = x1 - x0 - 145
    start_x = x0 + 65
    current_y = y0 + 60
    name = truth.get("name")
    if name:
        draw.text((start_x, current_y), name, font=font(46 if not vertical else 40), fill=(20, 25, 35))
        current_y += 75

    body = [(label, value) for label, value in lines if label != "Name"]
    body_size = 27 if vertical else 29
    line_height = 50 if vertical else 48
    for label, value in body:
        text = f"{label}: {value}"
        # Keep long values visible without changing their exact textual content.
        while ImageDraw.Draw(Image.new("RGB", (1, 1))).textlength(text, font=font(body_size)) > usable_width and body_size > 18:
            body_size -= 1
        draw.text((start_x, current_y), text, font=font(body_size), fill=(32, 39, 51))
        current_y += line_height

    draw.text((start_x, y1 - 52), spec["card_id"], font=font(19), fill=(125, 130, 138))

    if category == "拍摄质量较差":
        canvas = ImageEnhance.Contrast(canvas).enhance(0.72)
        canvas = ImageEnhance.Brightness(canvas).enhance(0.82)
        canvas = canvas.filter(ImageFilter.GaussianBlur(radius=0.9))
    return canvas


def main() -> None:
    files = sorted(GROUND_TRUTH.glob("gt_*.json"))
    for index, json_path in enumerate(files):
        spec = json.loads(json_path.read_text(encoding="utf-8"))
        image = make_card(spec, index)
        image.save(GROUND_TRUTH / spec["image_file"], "JPEG", quality=92, optimize=True)
    print(f"Generated {len(files)} images in {GROUND_TRUTH}")


if __name__ == "__main__":
    main()
