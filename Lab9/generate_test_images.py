# generate_test_images.py
import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np

# Cria pasta de saída
os.makedirs('test_images', exist_ok=True)

# Definições de tamanho para cada imagem
sizes = [
    ('checkerboard_254x254.png', 254, 254),
    ('stripes_128x128.png', 128, 128),
    ('siemens_star_254x128.png', 254, 128),
    ('text_silhouette_64x64.png', 64, 64),
    ('geometric_shapes_128x254.png', 128, 254),
    ('fine_grid_32x32.png', 32, 32),
]


def generate_checkerboard(path, w, h):
    tile = 16
    img = Image.new('L', (w, h), 255)
    draw = ImageDraw.Draw(img)
    for y in range(0, h, tile):
        for x in range(0, w, tile):
            if ((x // tile + y // tile) % 2) == 0:
                draw.rectangle([x, y, x + tile - 1, y + tile - 1], fill=0)
    img.save(path)


def generate_stripes(path, w, h):
    stripe = 16
    img = Image.new('L', (w, h), 255)
    draw = ImageDraw.Draw(img)
    # Verticais
    for i in range(0, w, stripe * 2):
        draw.rectangle([i, 0, i + stripe - 1, h], fill=0)
    # Horizontais
    for i in range(0, h, stripe * 2):
        draw.rectangle([0, i, w, i + stripe - 1], fill=0)
    img.save(path)


def generate_siemens_star(path, w, h):
    img = Image.new('L', (w, h), 255)
    draw = ImageDraw.Draw(img)
    cx, cy = w // 2, h // 2
    num_rays = 32
    radius = min(cx, cy)
    for i in range(num_rays):
        angle = 2 * np.pi * i / num_rays
        x = cx + int(np.cos(angle) * radius)
        y = cy + int(np.sin(angle) * radius)
        color = 0 if (i % 2) == 0 else 255
        draw.line((cx, cy, x, y), fill=color, width=1)
    img.save(path)


def generate_text_silhouette(path, w, h):
    img = Image.new('L', (w, h), 255)
    draw = ImageDraw.Draw(img)
    try:
        font_size = int(min(w, h) * 0.6)
        font = ImageFont.truetype("arial.ttf", font_size)
    except IOError:
        font = ImageFont.load_default()
    text = "SOBEL"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((w - tw) / 2, (h - th) / 2), text, font=font, fill=0)
    img.save(path)


def generate_geometric_shapes(path, w, h):
    img = Image.new('L', (w, h), 255)
    draw = ImageDraw.Draw(img)
    # Retângulo
    draw.rectangle([10, 10, 60, 60], outline=0, width=2)
    # Círculo
    draw.ellipse([w // 4, 10, w // 4 + 60, 70], outline=0, width=2)
    # Triângulo
    draw.polygon([
        (3 * w // 4 - 30, h - 10),
        (3 * w // 4 + 10, 10),
        (3 * w // 4 + 50, h - 10)
    ], outline=0, width=2)
    img.save(path)


def generate_fine_grid(path, w, h):
    spacing = 8
    img = Image.new('L', (w, h), 255)
    draw = ImageDraw.Draw(img)
    for x in range(0, w, spacing):
        draw.line((x, 0, x, h), fill=0)
    for y in range(0, h, spacing):
        draw.line((0, y, w, y), fill=0)
    img.save(path)


def main():
    generators = [
        generate_checkerboard,
        generate_stripes,
        generate_siemens_star,
        generate_text_silhouette,
        generate_geometric_shapes,
        generate_fine_grid,
    ]
    for (name, w, h), gen in zip(sizes, generators):
        path = os.path.join('test_images', name)
        gen(path, w, h)
        print(f"Gerado {name} ({w}x{h})")


if __name__ == '__main__':
    main()
